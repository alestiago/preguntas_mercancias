import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../questions/load_questions.dart';

part 'practice_event.dart';
part 'practice_state.dart';

typedef LoadMoreQuestions =
    Future<List<Question>> Function(
      String? section,
      Set<String> loadedQuestionCodes,
      QuestionProgressSnapshot progressSnapshot,
    );

class PracticeBloc extends Bloc<PracticeEvent, PracticeState> {
  PracticeBloc({
    this.loadQuestions = loadQuestionsFromBank,
    this.loadMoreQuestions,
    this.pendingBatchSize = 10,
    this.pendingLoadThreshold = 5,
    QuestionProgressStore? questionProgressStore,
    Random? answerShuffleRandom,
    String? initialSection = '1A',
    this.isReviewMode = false,
    this.isPendingMode = false,
    this.isSimulacroMode = false,
    this.shuffleAnswers = true,
  }) : assert(
         [
               isReviewMode,
               isPendingMode,
               isSimulacroMode,
             ].where((isEnabled) => isEnabled).length <=
             1,
       ),
       assert(pendingBatchSize > 0),
       assert(pendingLoadThreshold >= 0),
       questionProgressStore =
           questionProgressStore ?? DriftQuestionProgressStore.defaults(),
       _answerShuffleRandom = answerShuffleRandom ?? Random(),
       _ownsQuestionProgressStore = questionProgressStore == null,
       super(
         PracticeLoading(
           selectedSection: initialSection,
           isReviewMode: isReviewMode,
           isPendingMode: isPendingMode,
           isSimulacroMode: isSimulacroMode,
         ),
       ) {
    on<PracticeStarted>(_onStarted);
    on<SectionSelected>(_onSectionSelected);
    on<AnswerPressed>(_onAnswerPressed);
    on<NextQuestionPressed>(_onNextQuestionPressed);
    on<PreviousQuestionPressed>(_onPreviousQuestionPressed);
    on<QuestionNavigationPressed>(_onQuestionNavigationPressed);
    on<RetryPressed>(_onRetryPressed);
  }

  final LoadQuestions loadQuestions;
  final LoadMoreQuestions? loadMoreQuestions;
  final int pendingBatchSize;
  final int pendingLoadThreshold;
  final QuestionProgressStore questionProgressStore;
  final bool isReviewMode;
  final bool isPendingMode;
  final bool isSimulacroMode;
  final bool shuffleAnswers;
  final Random _answerShuffleRandom;
  final bool _ownsQuestionProgressStore;
  bool _pendingQuestionSourceExhausted = false;

  Future<void> _onStarted(PracticeStarted event, Emitter<PracticeState> emit) {
    return _load(emit, state.selectedSection);
  }

  Future<void> _onSectionSelected(
    SectionSelected event,
    Emitter<PracticeState> emit,
  ) {
    if (state.selectedSection == event.section) {
      return Future.value();
    }

    return _load(emit, event.section);
  }

  Future<void> _onAnswerPressed(
    AnswerPressed event,
    Emitter<PracticeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PracticeLoaded || currentState.answered) {
      return;
    }

    final question = currentState.currentQuestion;
    final isCorrect = question.isCorrect(event.option);
    final answeredState = currentState.copyWith(
      selectedOptionsByQuestionCode: {
        ...currentState.selectedOptionsByQuestionCode,
        question.code: event.option,
      },
      isRecordingAnswer: true,
      correctCount: currentState.correctCount + (isCorrect ? 1 : 0),
      incorrectCount: currentState.incorrectCount + (isCorrect ? 0 : 1),
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

      recordedState = answeredState.copyWith(
        progressSnapshot: await questionProgressStore.loadSnapshot(),
        isRecordingAnswer: false,
      );
      emit(recordedState);
    } catch (error, stackTrace) {
      emit(answeredState.copyWith(isRecordingAnswer: false));
      addError(error, stackTrace);
      return;
    }

    await _loadMorePendingQuestionsIfNeeded(recordedState, emit);
  }

  Future<void> _loadMorePendingQuestionsIfNeeded(
    PracticeLoaded currentState,
    Emitter<PracticeState> emit,
  ) async {
    final loadMore = loadMoreQuestions;
    if (!currentState.isPendingMode ||
        loadMore == null ||
        _pendingQuestionSourceExhausted ||
        currentState.remainingFilteredQuestions.length > pendingLoadThreshold) {
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
    if (loadedQuestions.length < pendingBatchSize) {
      _pendingQuestionSourceExhausted = true;
    }

    final pendingQuestions = _questionsWithShuffledAnswers(
      loadedQuestions.where((question) {
        return !loadedQuestionCodes.contains(question.code) &&
            currentState.progressSnapshot.progressFor(question.code) == null;
      }),
    );
    if (pendingQuestions.isEmpty) {
      return;
    }

    emit(
      currentState.copyWith(
        questions: List<Question>.unmodifiable([
          ...currentState.questions,
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

    return state.copyWith(currentIndex: state.questions.indexOf(nextQuestion));
  }

  Future<void> _onRetryPressed(
    RetryPressed event,
    Emitter<PracticeState> emit,
  ) {
    return _load(emit, state.selectedSection);
  }

  Future<void> _load(
    Emitter<PracticeState> emit,
    String? selectedSection,
  ) async {
    _pendingQuestionSourceExhausted = false;
    emit(
      PracticeLoading(
        selectedSection: selectedSection,
        isReviewMode: isReviewMode,
        isPendingMode: isPendingMode,
        isSimulacroMode: isSimulacroMode,
      ),
    );

    try {
      final questions = await loadQuestions(selectedSection);
      final progressSnapshot = await questionProgressStore.loadSnapshot();
      final loadedQuestions = _questionsWithShuffledAnswers(
        _questionsForCurrentMode(questions, progressSnapshot),
      );
      emit(
        PracticeLoaded(
          selectedSection: selectedSection,
          questions: loadedQuestions,
          progressSnapshot: progressSnapshot,
          isReviewMode: isReviewMode,
          isPendingMode: isPendingMode,
          isSimulacroMode: isSimulacroMode,
        ),
      );
    } catch (error) {
      emit(
        PracticeLoadFailure(
          selectedSection: selectedSection,
          isReviewMode: isReviewMode,
          isPendingMode: isPendingMode,
          isSimulacroMode: isSimulacroMode,
          error: error,
        ),
      );
    }
  }

  List<Question> _questionsForCurrentMode(
    List<Question> questions,
    QuestionProgressSnapshot progressSnapshot,
  ) {
    if (!isReviewMode && !isPendingMode) {
      return List<Question>.unmodifiable(questions);
    }

    return List<Question>.unmodifiable(
      questions.where((question) {
        final progress = progressSnapshot.progressFor(question.code);
        if (isReviewMode) {
          return progress != null && progress.correctAttempts == 0;
        }

        return progress == null;
      }),
    );
  }

  List<Question> _questionsWithShuffledAnswers(Iterable<Question> questions) {
    return List<Question>.unmodifiable(
      questions.map(_questionWithShuffledAnswers),
    );
  }

  Question _questionWithShuffledAnswers(Question question) {
    if (!shuffleAnswers || !question.shuffleable) {
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
  Future<void> close() async {
    if (_ownsQuestionProgressStore) {
      await questionProgressStore.close();
    }

    return super.close();
  }
}
