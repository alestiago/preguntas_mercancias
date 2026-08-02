part of 'practice_bloc.dart';

const _unset = Object();

@immutable
sealed class PracticeState {
  const PracticeState({
    required this.selectedSection,
    this.isReviewMode = false,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.progressSnapshot = const QuestionProgressSnapshot.empty(),
  });

  final String? selectedSection;
  final bool isReviewMode;
  final int correctCount;
  final int incorrectCount;
  final QuestionProgressSnapshot progressSnapshot;
}

final class PracticeLoading extends PracticeState {
  const PracticeLoading({required super.selectedSection, super.isReviewMode});
}

final class PracticeLoadFailure extends PracticeState {
  const PracticeLoadFailure({
    required super.selectedSection,
    super.isReviewMode,
    required this.error,
  });

  final Object error;
}

final class PracticeLoaded extends PracticeState {
  const PracticeLoaded({
    required super.selectedSection,
    required this.questions,
    this.currentIndex = 0,
    this.selectedOption,
    this.isRecordingAnswer = false,
    super.isReviewMode,
    super.correctCount,
    super.incorrectCount,
    super.progressSnapshot,
  });

  final List<Question> questions;
  final int currentIndex;
  final QuestionOption? selectedOption;
  final bool isRecordingAnswer;

  bool get answered => selectedOption != null;

  bool get isLastQuestion => currentIndex == questions.length - 1;

  List<Question> get remainingReviewQuestions {
    if (!isReviewMode) {
      return questions;
    }

    return List<Question>.unmodifiable(
      questions.where((question) {
        final progress = progressSnapshot.progressFor(question.code);
        return progress != null && progress.correctAttempts == 0;
      }),
    );
  }

  bool get isReviewComplete => isReviewMode && remainingReviewQuestions.isEmpty;

  double get progress =>
      questions.isEmpty ? 0 : (currentIndex + 1) / questions.length;

  Question get currentQuestion => questions[currentIndex];

  PracticeLoaded copyWith({
    List<Question>? questions,
    int? currentIndex,
    Object? selectedOption = _unset,
    bool? isRecordingAnswer,
    int? correctCount,
    int? incorrectCount,
    QuestionProgressSnapshot? progressSnapshot,
  }) {
    return PracticeLoaded(
      selectedSection: selectedSection,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOption: identical(selectedOption, _unset)
          ? this.selectedOption
          : selectedOption as QuestionOption?,
      isRecordingAnswer: isRecordingAnswer ?? this.isRecordingAnswer,
      isReviewMode: isReviewMode,
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
      progressSnapshot: progressSnapshot,
    );
  }
}
