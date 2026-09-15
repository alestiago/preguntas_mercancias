part of 'practice_bloc.dart';

@immutable
sealed class PracticeState {
  const PracticeState({
    required this.selectedSection,
    this.isReviewMode = false,
    this.isPendingMode = false,
    this.isSimulacroMode = false,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.progressSnapshot = const QuestionProgressSnapshot.empty(),
  });

  final String? selectedSection;
  final bool isReviewMode;
  final bool isPendingMode;
  final bool isSimulacroMode;
  final int correctCount;
  final int incorrectCount;
  final QuestionProgressSnapshot progressSnapshot;
}

final class PracticeLoading extends PracticeState {
  const PracticeLoading({
    required super.selectedSection,
    super.isReviewMode,
    super.isPendingMode,
    super.isSimulacroMode,
  });
}

final class PracticeLoadFailure extends PracticeState {
  const PracticeLoadFailure({
    required super.selectedSection,
    super.isReviewMode,
    super.isPendingMode,
    super.isSimulacroMode,
    required this.error,
  });

  final Object error;
}

final class PracticeLoaded extends PracticeState {
  const PracticeLoaded({
    required super.selectedSection,
    required this.questions,
    this.currentIndex = 0,
    this.selectedOptionsByQuestionCode = const {},
    this.isRecordingAnswer = false,
    super.isReviewMode,
    super.isPendingMode,
    super.isSimulacroMode,
    super.correctCount,
    super.incorrectCount,
    super.progressSnapshot,
  });

  final List<Question> questions;
  final int currentIndex;
  final Map<String, QuestionOption> selectedOptionsByQuestionCode;
  final bool isRecordingAnswer;

  QuestionOption? get selectedOption =>
      selectedOptionsByQuestionCode[currentQuestion.code];

  bool get answered => selectedOption != null;

  bool get isLastQuestion => currentIndex == questions.length - 1;

  bool get isFilteredPracticeMode => isReviewMode || isPendingMode;

  List<Question> get remainingFilteredQuestions {
    if (!isFilteredPracticeMode) {
      return questions;
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

  bool get isFilteredPracticeComplete =>
      isFilteredPracticeMode && remainingFilteredQuestions.isEmpty;

  double get progress =>
      questions.isEmpty ? 0 : (currentIndex + 1) / questions.length;

  Question get currentQuestion => questions[currentIndex];

  PracticeLoaded copyWith({
    List<Question>? questions,
    int? currentIndex,
    Map<String, QuestionOption>? selectedOptionsByQuestionCode,
    bool? isRecordingAnswer,
    int? correctCount,
    int? incorrectCount,
    QuestionProgressSnapshot? progressSnapshot,
  }) {
    return PracticeLoaded(
      selectedSection: selectedSection,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOptionsByQuestionCode:
          selectedOptionsByQuestionCode ?? this.selectedOptionsByQuestionCode,
      isRecordingAnswer: isRecordingAnswer ?? this.isRecordingAnswer,
      isReviewMode: isReviewMode,
      isPendingMode: isPendingMode,
      isSimulacroMode: isSimulacroMode,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      progressSnapshot: progressSnapshot ?? this.progressSnapshot,
    );
  }

  PracticeLoaded restart() {
    return PracticeLoaded(
      selectedSection: selectedSection,
      questions: questions,
      isReviewMode: isReviewMode,
      isPendingMode: isPendingMode,
      isSimulacroMode: isSimulacroMode,
      progressSnapshot: progressSnapshot,
    );
  }
}
