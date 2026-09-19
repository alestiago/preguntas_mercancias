import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../questions/load_questions.dart';
import '../practice_question_policy.dart';
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
    on<_PendingRefillRequested>(
      _onPendingRefillRequested,
      transformer: droppable(),
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
  bool _pendingQuestionSourceExhausted = false;
  int _sessionGeneration = 0;

  Future<void> _onLoadRequested(
    PracticeLoadRequested event,
    Emitter<PracticeState> emit,
  ) {
    final selectedSection = switch (event) {
      SectionSelected(:final section) => section,
      PracticeStarted() || RetryPressed() => state.selectedSection,
    };
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

  Future<void> _onPendingRefillRequested(
    _PendingRefillRequested event,
    Emitter<PracticeState> emit,
  ) async {
    if (!_isCurrentSession(event.sessionGeneration, emit)) {
      return;
    }
    final currentState = state;
    if (currentState is! PracticeLoaded) {
      return;
    }

    await _loadMorePendingQuestionsIfNeeded(
      currentState,
      event.sessionGeneration,
      emit,
    );
  }

  Future<void> _loadMorePendingQuestionsIfNeeded(
    PracticeLoaded currentState,
    int generation,
    Emitter<PracticeState> emit,
  ) async {
    final loadMore = loadMoreQuestions;
    if (currentState.mode != PracticeMode.pending ||
        loadMore == null ||
        _pendingQuestionSourceExhausted ||
        currentState.remainingFilteredQuestions.length >
            session.pendingLoadThreshold) {
      return;
    }

    final loadedQuestionCodes = currentState.questions
        .map((question) => question.code)
        .toSet();
    final List<Question> loadedQuestions;
    try {
      loadedQuestions = await loadMore(
        currentState.selectedSection,
        loadedQuestionCodes,
        currentState.progressSnapshot,
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      return;
    }
    if (!_isCurrentSession(generation, emit)) {
      return;
    }

    if (loadedQuestions.length < session.pendingBatchSize) {
      _pendingQuestionSourceExhausted = true;
    }

    final latestState = state;
    if (latestState is! PracticeLoaded) {
      return;
    }
    final latestQuestionCodes = latestState.questions
        .map((question) => question.code)
        .toSet();
    final pendingQuestions = _questionsWithShuffledAnswers(
      practiceQuestionPolicy.selectEligible(
        questions: loadedQuestions,
        mode: PracticeMode.pending,
        progressSnapshot: latestState.progressSnapshot,
        excludedQuestionCodes: latestQuestionCodes,
      ),
    );
    if (pendingQuestions.isEmpty) {
      return;
    }

    emit(
      latestState.copyWith(
        questions: List<Question>.unmodifiable([
          ...latestState.questions,
          ...pendingQuestions,
        ]),
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

    final isTerminalAction =
        currentState.isFilteredPracticeComplete ||
        (currentState.isLastQuestion && !currentState.isFilteredPracticeMode);
    if (isTerminalAction && !currentState.answered) {
      return;
    }

    if (currentState.isFilteredPracticeMode) {
      final nextState = _nextFilteredState(currentState);
      if (nextState != null) {
        emit(nextState);
      }
      return;
    }

    if (currentState.isLastQuestion) {
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
    final remainingQuestions = state.remainingFilteredQuestions;
    if (remainingQuestions.isEmpty) {
      return null;
    }

    final currentQuestionIndex = state.currentIndex;
    final nextQuestion = remainingQuestions.firstWhere(
      (question) => state.questions.indexOf(question) > currentQuestionIndex,
      orElse: () => remainingQuestions.first,
    );

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
      currentIndex: state.questions.indexOf(nextQuestion),
      selectedOptionsByQuestionCode: selectedOptionsByQuestionCode,
    );
  }

  Future<void> _load(
    Emitter<PracticeState> emit,
    String? selectedSection,
    int generation,
  ) async {
    _pendingQuestionSourceExhausted = false;
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
      final loadedQuestions = _questionsWithShuffledAnswers(
        practiceQuestionPolicy.selectEligible(
          questions: questions,
          mode: session.mode,
          progressSnapshot: progressSnapshot,
        ),
      );
      emit(
        PracticeLoaded(
          selectedSection: selectedSection,
          questions: loadedQuestions,
          progressSnapshot: progressSnapshot,
          session: session,
        ),
      );
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
    return generation == _sessionGeneration && !emit.isDone && !isClosed;
  }

  List<Question> _questionsWithShuffledAnswers(Iterable<Question> questions) {
    return List<Question>.unmodifiable(
      questions.map(_questionWithShuffledAnswers),
    );
  }

  Question _questionWithShuffledAnswers(Question question) {
    if (!session.shuffleAnswers || !question.shuffleable) {
      return question;
    }

    final shuffledAnswers = List<QuestionAnswer>.of(question.answers);
    if (shuffledAnswers.length < 2) {
      return question;
    }

    final originalCorrectAnswerIndex = shuffledAnswers.indexWhere(
      (answer) => answer.option == question.correctOption,
    );
    shuffledAnswers.shuffle(_answerShuffleRandom);

    if (originalCorrectAnswerIndex >= 0 &&
        shuffledAnswers[originalCorrectAnswerIndex].option ==
            question.correctOption) {
      final swapIndex =
          (originalCorrectAnswerIndex + 1) % shuffledAnswers.length;
      final swappedAnswer = shuffledAnswers[swapIndex];
      shuffledAnswers[swapIndex] = shuffledAnswers[originalCorrectAnswerIndex];
      shuffledAnswers[originalCorrectAnswerIndex] = swappedAnswer;
    }

    return Question(
      code: question.code,
      section: question.section,
      prompt: question.prompt,
      answers: shuffledAnswers,
      correctOption: question.correctOption,
      norma: question.norma,
      doctrinalReference: question.doctrinalReference,
      shuffleable: question.shuffleable,
    );
  }

  @override
  Future<void> close() {
    _sessionGeneration += 1;
    return super.close();
  }
}
