import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../questions/load_questions.dart';

part 'practice_event.dart';
part 'practice_state.dart';

class PracticeBloc extends Bloc<PracticeEvent, PracticeState> {
  PracticeBloc({
    this.loadQuestions = loadQuestionsFromBank,
    QuestionProgressStore? questionProgressStore,
    String? initialSection = '1A',
    this.isReviewMode = false,
  }) : questionProgressStore =
           questionProgressStore ?? DriftQuestionProgressStore.defaults(),
       _ownsQuestionProgressStore = questionProgressStore == null,
       super(
         PracticeLoading(
           selectedSection: initialSection,
           isReviewMode: isReviewMode,
         ),
       ) {
    on<PracticeStarted>(_onStarted);
    on<SectionSelected>(_onSectionSelected);
    on<AnswerPressed>(_onAnswerPressed);
    on<NextQuestionPressed>(_onNextQuestionPressed);
    on<RetryPressed>(_onRetryPressed);
  }

  final LoadQuestions loadQuestions;
  final QuestionProgressStore questionProgressStore;
  final bool isReviewMode;
  final bool _ownsQuestionProgressStore;

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
      selectedOption: event.option,
      isRecordingAnswer: true,
      correctCount: currentState.correctCount + (isCorrect ? 1 : 0),
      incorrectCount: currentState.incorrectCount + (isCorrect ? 0 : 1),
    );

    emit(answeredState);

    try {
      await questionProgressStore.recordAnswer(
        QuestionAnswerRecord(
          questionCode: question.code,
          section: question.section,
          selectedOption: event.option,
          correctOption: question.correctOption,
        ),
      );

      emit(
        answeredState.copyWith(
          progressSnapshot: await questionProgressStore.loadSnapshot(),
          isRecordingAnswer: false,
        ),
      );
    } catch (error, stackTrace) {
      emit(answeredState.copyWith(isRecordingAnswer: false));
      addError(error, stackTrace);
    }
  }

  void _onNextQuestionPressed(
    NextQuestionPressed event,
    Emitter<PracticeState> emit,
  ) {
    final currentState = state;
    if (currentState is! PracticeLoaded ||
        !currentState.answered ||
        currentState.isRecordingAnswer) {
      return;
    }

    if (currentState.isReviewMode) {
      final nextState = _nextReviewState(currentState);
      if (nextState != null) {
        emit(nextState);
      }
      return;
    }

    if (currentState.isLastQuestion) {
      emit(currentState.restart());
      return;
    }

    emit(
      currentState.copyWith(
        currentIndex: currentState.currentIndex + 1,
        selectedOption: null,
      ),
    );
  }

  PracticeLoaded? _nextReviewState(PracticeLoaded state) {
    final remainingQuestions = state.remainingReviewQuestions;
    if (remainingQuestions.isEmpty) {
      return null;
    }

    final currentQuestionIndex = state.currentIndex;
    final nextQuestion = remainingQuestions.firstWhere(
      (question) => state.questions.indexOf(question) > currentQuestionIndex,
      orElse: () => remainingQuestions.first,
    );

    return PracticeLoaded(
      selectedSection: state.selectedSection,
      questions: remainingQuestions,
      currentIndex: remainingQuestions.indexOf(nextQuestion),
      correctCount: state.correctCount,
      incorrectCount: state.incorrectCount,
      progressSnapshot: state.progressSnapshot,
      isReviewMode: state.isReviewMode,
    );
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
    emit(
      PracticeLoading(
        selectedSection: selectedSection,
        isReviewMode: isReviewMode,
      ),
    );

    try {
      final questions = await loadQuestions(selectedSection);
      final progressSnapshot = await questionProgressStore.loadSnapshot();
      final loadedQuestions = isReviewMode
          ? _reviewQuestionsFrom(questions, progressSnapshot)
          : List<Question>.unmodifiable(questions);
      emit(
        PracticeLoaded(
          selectedSection: selectedSection,
          questions: loadedQuestions,
          progressSnapshot: progressSnapshot,
          isReviewMode: isReviewMode,
        ),
      );
    } catch (error) {
      emit(
        PracticeLoadFailure(
          selectedSection: selectedSection,
          isReviewMode: isReviewMode,
          error: error,
        ),
      );
    }
  }

  List<Question> _reviewQuestionsFrom(
    List<Question> questions,
    QuestionProgressSnapshot progressSnapshot,
  ) {
    return List<Question>.unmodifiable(
      questions.where((question) {
        final progress = progressSnapshot.progressFor(question.code);
        return progress != null && progress.correctAttempts == 0;
      }),
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
