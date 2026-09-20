import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

import '../practice_launch.dart';
import '../practice_question_policy.dart';
import '../practice_session.dart';
import '../question_answer_presentation.dart';
import '../practice_session_config.dart';
import '../session_answers.dart';
import '../session_question_source.dart';
import '../session_questions.dart';

part 'practice_event.dart';
part 'practice_state.dart';

class PracticeBloc extends Bloc<PracticeEvent, PracticeState> {
  PracticeBloc({
    required this.launch,
    required this.questionProgressStore,
    Random? answerShuffleRandom,
  }) : _answerShuffleRandom = answerShuffleRandom ?? Random(),
       super(
         PracticeLoading(
           selectedSection: launch.config.initialSection,
           session: launch.config,
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

  final PracticeLaunch launch;
  final QuestionProgressStore questionProgressStore;
  final Random _answerShuffleRandom;
  int _sessionGeneration = 0;

  PracticeSessionConfig get session => launch.config;

  SessionQuestionSource get questionSource => launch.source;

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
    final answeredState = currentState.copyWith(
      practiceSession: currentState.practiceSession.recordSelection(
        event.option,
      ),
      isRecordingAnswer: true,
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
    final pendingOptions = session.pendingOptions;
    // Refill requests are advisory. Ignore them until pending mode reaches its
    // threshold, and while a load or terminal exhaustion is already known.
    if (pendingOptions == null ||
        currentState.pendingBatchState is PendingBatchExhausted ||
        currentState.pendingBatchState is PendingBatchLoading ||
        currentState.remainingFilteredQuestions.length >
            pendingOptions.loadThreshold) {
      return;
    }

    emit(currentState.copyWith(pendingBatchState: const PendingBatchLoading()));

    final loadedQuestionCodes = currentState.questions
        .map((question) => question.code)
        .toSet();
    final SessionQuestionBatch batch;
    try {
      batch = await questionSource.load(
        SessionQuestionRequest(
          section: currentState.selectedSection,
          excludedQuestionCodes: loadedQuestionCodes,
          progressSnapshot: currentState.progressSnapshot,
          requestedSize: pendingOptions.batchSize,
        ),
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
        practiceSession: latestState.practiceSession.appendQuestions(
          SessionQuestions(
            questions: pendingQuestions,
            presentationsByQuestionCode: _answerPresentationsFor(
              pendingQuestions,
            ),
          ),
        ),
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
      final nextSession = currentState.practiceSession.moveToNextEligible(
        mode: currentState.mode,
        progressSnapshot: currentState.progressSnapshot,
      );
      if (nextSession != null) {
        emit(currentState.copyWith(practiceSession: nextSession));
      }
      return;
    }

    if (currentState.primaryAction == PracticePrimaryAction.restart) {
      emit(currentState.restart());
      return;
    }

    emit(
      currentState.copyWith(
        practiceSession: currentState.practiceSession.moveToNext(),
      ),
    );
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

    emit(
      currentState.copyWith(
        practiceSession: currentState.practiceSession.moveToPrevious(),
      ),
    );
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

    emit(
      currentState.copyWith(
        practiceSession: currentState.practiceSession.moveTo(event.index),
      ),
    );
  }

  Future<void> _load(
    Emitter<PracticeState> emit,
    String? selectedSection,
    int generation,
  ) async {
    emit(PracticeLoading(selectedSection: selectedSection, session: session));

    try {
      final sourceProgressSnapshot = await questionProgressStore.loadSnapshot();
      if (!_isCurrentSession(generation, emit)) {
        return;
      }
      final pendingOptions = session.pendingOptions;
      final batch = await questionSource.load(
        SessionQuestionRequest(
          section: selectedSection,
          excludedQuestionCodes: const {},
          progressSnapshot: sourceProgressSnapshot,
          requestedSize: pendingOptions?.batchSize,
        ),
      );
      if (!_isCurrentSession(generation, emit)) {
        return;
      }
      // The source may complete after progress changes. Re-read and validate
      // its candidates before committing them to the active session.
      final progressSnapshot = await questionProgressStore.loadSnapshot();
      if (!_isCurrentSession(generation, emit)) {
        return;
      }
      final loadedQuestions = practiceQuestionPolicy.selectEligible(
        questions: batch.questions,
        mode: session.mode,
        progressSnapshot: progressSnapshot,
      );
      final loadedState = PracticeLoaded(
        selectedSection: selectedSection,
        practiceSession: PracticeSession.fromQuestions(
          questions: loadedQuestions,
          presentationsByQuestionCode: _answerPresentationsFor(loadedQuestions),
        ),
        progressSnapshot: progressSnapshot,
        pendingBatchState: pendingOptions != null && batch.hasMore
            ? const PendingBatchReady()
            : const PendingBatchExhausted(),
        session: session,
      );
      emit(loadedState);
      if (pendingOptions != null &&
          loadedState.pendingBatchState is PendingBatchReady &&
          loadedState.remainingFilteredQuestions.length <=
              pendingOptions.loadThreshold) {
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
