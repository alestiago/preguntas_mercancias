import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../questions/load_questions.dart';
import '../../questions/pending_question_batch.dart';
import '../practice_question_policy.dart';
import '../question_answer_presentation.dart';
import '../practice_session_config.dart';

part 'practice_event.dart';
part 'practice_state.dart';

class PracticeBloc extends Bloc<PracticeEvent, PracticeState> {
  PracticeBloc({
    this.loadQuestions = loadQuestionsFromBank,
    this.loadMoreQuestions,
    this.session = const PracticeSessionConfig.standard(),
    required this.questionProgressStore,
    Random? answerShuffleRandom,
  }) : _answerShuffleRandom = answerShuffleRandom ?? Random(),
       super(
         PracticeLoading(
           selectedSection: session.initialSection,
           session: session,
         ),
       ) {
    on<PracticeLoadRequested>(_onLoadRequested, transformer: restartable());
    on<AnswerPressed>(_onAnswerPressed, transformer: droppable());
    on<PendingBatchLoadRequested>(
      _onPendingBatchLoadRequested,
      transformer: concurrent(),
    );
    on<NextQuestionPressed>(_onNextQuestionPressed);
    on<PreviousQuestionPressed>(_onPreviousQuestionPressed);
    on<QuestionNavigationPressed>(_onQuestionNavigationPressed);
  }

  final LoadQuestions loadQuestions;
  final LoadMoreQuestions? loadMoreQuestions;
  final PracticeSessionConfig session;
  final QuestionProgressStore questionProgressStore;
  final Random _answerShuffleRandom;
  int _sessionGeneration = 0;

  Future<void> _onLoadRequested(
    PracticeLoadRequested event,
    Emitter<PracticeState> emit,
  ) {
    final selectedSection = switch (event) {
      SectionSelected(:final section) => section,
      PracticeStarted() || RetryPressed() => state.selectedSection,
    };
    // Re-selecting the active section is intentionally a no-op: reloading it
    // would discard the current session's navigation and answer presentation.
    if (event is SectionSelected && state.selectedSection == selectedSection) {
      return Future.value();
    }

    final generation = ++_sessionGeneration;
    return _load(emit, selectedSection, generation);
  }

  Future<void> _onAnswerPressed(
    AnswerPressed event,
    Emitter<PracticeState> emit,
  ) async {
    final currentState = state;
    // Only the first selection for an open question is an attempt. The
    // droppable transformer and this state guard prevent duplicate writes.
    if (currentState is! PracticeLoaded || currentState.answered) {
      return;
    }

    final generation = _sessionGeneration;
    final question = currentState.currentQuestion;
    final isCorrect = question.isCorrect(event.option);
    final answeredState = currentState.copyWith(
      selectedOptionsByQuestionCode: {
        ...currentState.selectedOptionsByQuestionCode,
        question.code: event.option,
      },
      isRecordingAnswer: true,
      correctAttemptCount:
          currentState.correctAttemptCount + (isCorrect ? 1 : 0),
      incorrectAttemptCount:
          currentState.incorrectAttemptCount + (isCorrect ? 0 : 1),
    );

    emit(answeredState);

    final PracticeLoaded recordedState;
    try {
      await questionProgressStore.recordAnswer(
        QuestionAnswerRecord(
          questionCode: question.code,
          section: question.section,
          selectedOption: event.option,
          correctOption: question.correctOption,
        ),
      );
      if (!_isCurrentSession(generation, emit)) {
        return;
      }

      final progressSnapshot = await questionProgressStore.loadSnapshot();
      if (!_isCurrentSession(generation, emit)) {
        return;
      }

      final latestState = state;
      if (latestState is! PracticeLoaded) {
        return;
      }
      recordedState = latestState.copyWith(
        progressSnapshot: progressSnapshot,
        isRecordingAnswer: false,
      );
      emit(recordedState);
    } catch (error, stackTrace) {
      if (_isCurrentSession(generation, emit)) {
        final latestState = state;
        if (latestState is PracticeLoaded) {
          emit(latestState.copyWith(isRecordingAnswer: false));
        }
      }
      addError(error, stackTrace);
      return;
    }

    add(_PendingRefillRequested(generation));
  }

  Future<void> _onPendingBatchLoadRequested(
    PendingBatchLoadRequested event,
    Emitter<PracticeState> emit,
  ) async {
    final generation = switch (event) {
      _PendingRefillRequested(:final sessionGeneration) => sessionGeneration,
      PendingBatchRetried() => _sessionGeneration,
    };
    if (!_isCurrentSession(generation, emit)) {
      return;
    }
    final currentState = state;
    if (currentState is! PracticeLoaded) {
      return;
    }
    if (event is PendingBatchRetried &&
        currentState.pendingBatchState is! PendingBatchFailure) {
      return;
    }

    await _loadMorePendingQuestionsIfNeeded(currentState, generation, emit);
  }

  Future<void> _loadMorePendingQuestionsIfNeeded(
    PracticeLoaded currentState,
    int generation,
    Emitter<PracticeState> emit,
  ) async {
    final loadMore = loadMoreQuestions;
    // Refill requests are advisory. Ignore them until pending mode reaches its
    // threshold, and while a load or terminal exhaustion is already known.
    if (currentState.mode != PracticeMode.pending ||
        loadMore == null ||
        currentState.pendingBatchState is PendingBatchExhausted ||
        currentState.pendingBatchState is PendingBatchLoading ||
        currentState.remainingFilteredQuestions.length >
            session.pendingLoadThreshold) {
      return;
    }

    emit(currentState.copyWith(pendingBatchState: const PendingBatchLoading()));

    final loadedQuestionCodes = currentState.questions
        .map((question) => question.code)
        .toSet();
    final PendingQuestionBatch batch;
    try {
      batch = await loadMore(
        currentState.selectedSection,
        loadedQuestionCodes,
        currentState.progressSnapshot,
      );
    } catch (error, stackTrace) {
      if (_isCurrentSession(generation, emit)) {
        final latestState = state;
        if (latestState is PracticeLoaded) {
          emit(
            latestState.copyWith(pendingBatchState: PendingBatchFailure(error)),
          );
        }
      }
      addError(error, stackTrace);
      return;
    }
    if (!_isCurrentSession(generation, emit)) {
      return;
    }

    final latestState = state;
    if (latestState is! PracticeLoaded) {
      return;
    }
    final latestQuestionCodes = latestState.questions
        .map((question) => question.code)
        .toSet();
    final pendingQuestions = practiceQuestionPolicy.selectEligible(
      questions: batch.questions,
      mode: PracticeMode.pending,
      progressSnapshot: latestState.progressSnapshot,
      excludedQuestionCodes: latestQuestionCodes,
    );
    if (pendingQuestions.isEmpty && batch.hasMore) {
      emit(
        latestState.copyWith(
          pendingBatchState: PendingBatchFailure(
            StateError(
              'The pending question source reported more results but '
              'returned no new questions.',
            ),
          ),
        ),
      );
      return;
    }

    emit(
      latestState.copyWith(
        questions: List<Question>.unmodifiable([
          ...latestState.questions,
          ...pendingQuestions,
        ]),
        answerPresentationsByQuestionCode: {
          ...latestState.answerPresentationsByQuestionCode,
          ..._answerPresentationsFor(pendingQuestions),
        },
        pendingBatchState: batch.hasMore
            ? const PendingBatchReady()
            : const PendingBatchExhausted(),
      ),
    );
  }

  void _onNextQuestionPressed(
    NextQuestionPressed event,
    Emitter<PracticeState> emit,
  ) {
    final currentState = state;
    if (currentState is! PracticeLoaded || currentState.isRecordingAnswer) {
      return;
    }

    if (!currentState.isPrimaryActionEnabled ||
        currentState.primaryAction == PracticePrimaryAction.finish) {
      return;
    }

    if (currentState.isFilteredPracticeMode) {
      final nextState = _nextFilteredState(currentState);
      if (nextState != null) {
        emit(nextState);
      }
      return;
    }

    if (currentState.primaryAction == PracticePrimaryAction.restart) {
      emit(currentState.restart());
      return;
    }

    emit(currentState.copyWith(currentIndex: currentState.currentIndex + 1));
  }

  void _onPreviousQuestionPressed(
    PreviousQuestionPressed event,
    Emitter<PracticeState> emit,
  ) {
    final currentState = state;
    if (currentState is! PracticeLoaded ||
        currentState.currentIndex == 0 ||
        currentState.isRecordingAnswer) {
      return;
    }

    emit(currentState.copyWith(currentIndex: currentState.currentIndex - 1));
  }

  void _onQuestionNavigationPressed(
    QuestionNavigationPressed event,
    Emitter<PracticeState> emit,
  ) {
    final currentState = state;
    if (currentState is! PracticeLoaded || currentState.isRecordingAnswer) {
      return;
    }

    if (event.index < 0 || event.index >= currentState.questions.length) {
      return;
    }

    emit(currentState.copyWith(currentIndex: event.index));
  }

  PracticeLoaded? _nextFilteredState(PracticeLoaded state) {
    final nextQuestionIndex = practiceQuestionPolicy.nextEligibleIndex(
      questions: state.questions,
      currentIndex: state.currentIndex,
      mode: state.mode,
      progressSnapshot: state.progressSnapshot,
    );
    if (nextQuestionIndex == null) {
      return null;
    }

    final nextQuestion = state.questions[nextQuestionIndex];

    final selectedOptionsByQuestionCode = {
      ...state.selectedOptionsByQuestionCode,
    };
    if (state.mode == PracticeMode.review) {
      // A review question remains eligible after an incorrect answer. Reopen
      // its selection when it becomes the active retry so the previous
      // result does not prevent another attempt. Attempt totals remain in
      // correctAttemptCount and incorrectAttemptCount.
      selectedOptionsByQuestionCode.remove(nextQuestion.code);
    }

    return state.copyWith(
      currentIndex: nextQuestionIndex,
      selectedOptionsByQuestionCode: selectedOptionsByQuestionCode,
    );
  }

  Future<void> _load(
    Emitter<PracticeState> emit,
    String? selectedSection,
    int generation,
  ) async {
    emit(PracticeLoading(selectedSection: selectedSection, session: session));

    try {
      final questions = await loadQuestions(selectedSection);
      if (!_isCurrentSession(generation, emit)) {
        return;
      }
      final progressSnapshot = await questionProgressStore.loadSnapshot();
      if (!_isCurrentSession(generation, emit)) {
        return;
      }
      final loadedQuestions = practiceQuestionPolicy.selectEligible(
        questions: questions,
        mode: session.mode,
        progressSnapshot: progressSnapshot,
      );
      final loadedState = PracticeLoaded(
        selectedSection: selectedSection,
        questions: loadedQuestions,
        answerPresentationsByQuestionCode: _answerPresentationsFor(
          loadedQuestions,
        ),
        progressSnapshot: progressSnapshot,
        pendingBatchState:
            session.mode == PracticeMode.pending && loadMoreQuestions != null
            ? const PendingBatchReady()
            : const PendingBatchExhausted(),
        session: session,
      );
      emit(loadedState);
      if (loadedState.mode == PracticeMode.pending &&
          loadedState.pendingBatchState is PendingBatchReady &&
          loadedState.remainingFilteredQuestions.length <=
              session.pendingLoadThreshold) {
        add(_PendingRefillRequested(generation));
      }
    } catch (error) {
      if (!_isCurrentSession(generation, emit)) {
        return;
      }
      emit(
        PracticeLoadFailure(
          selectedSection: selectedSection,
          session: session,
          error: error,
        ),
      );
    }
  }

  bool _isCurrentSession(int generation, Emitter<PracticeState> emit) {
    // Awaited work from an older load is intentionally discarded. Cancellation
    // cannot undo I/O that already started, so generation is the commit guard.
    return generation == _sessionGeneration && !emit.isDone && !isClosed;
  }

  Map<String, QuestionAnswerPresentation> _answerPresentationsFor(
    Iterable<Question> questions,
  ) {
    return {
      for (final question in questions)
        question.code: QuestionAnswerPresentation.forSession(
          question,
          shuffleAnswers: session.shuffleAnswers,
          random: _answerShuffleRandom,
        ),
    };
  }

  @override
  Future<void> close() {
    _sessionGeneration += 1;
    return super.close();
  }
}
