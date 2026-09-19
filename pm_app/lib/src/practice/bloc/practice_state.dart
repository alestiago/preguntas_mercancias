part of 'practice_bloc.dart';

@immutable
sealed class PracticeState {
  const PracticeState({
    required this.selectedSection,
    required this.session,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.progressSnapshot = const QuestionProgressSnapshot.empty(),
  });

  final String? selectedSection;
  final PracticeSessionConfig session;
  final int correctCount;
  final int incorrectCount;
  final QuestionProgressSnapshot progressSnapshot;

  PracticeMode get mode => session.mode;

  bool get isQuestionDrawerNavigationEnabled =>
      this is PracticeLoaded && mode == PracticeMode.simulacro;
}

final class PracticeLoading extends PracticeState {
  const PracticeLoading({
    required super.selectedSection,
    required super.session,
  });
}

final class PracticeLoadFailure extends PracticeState {
  const PracticeLoadFailure({
    required super.selectedSection,
    required super.session,
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
    required super.session,
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

  SessionQuestionStatus sessionStatusFor(Question question) {
    return practiceQuestionPolicy.sessionStatusFor(
      question,
      selectedOptionsByQuestionCode[question.code],
    );
  }

  bool get answered =>
      sessionStatusFor(currentQuestion) != SessionQuestionStatus.unanswered;

  bool get showExitConfirmation => selectedOptionsByQuestionCode.isNotEmpty;

  bool get isLastQuestion => currentIndex == questions.length - 1;

  bool get isFilteredPracticeMode =>
      mode == PracticeMode.review || mode == PracticeMode.pending;

  List<Question> get remainingFilteredQuestions {
    if (!isFilteredPracticeMode) {
      return questions;
    }

    return practiceQuestionPolicy.selectEligible(
      questions: questions,
      mode: mode,
      progressSnapshot: progressSnapshot,
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
      session: session,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOptionsByQuestionCode:
          selectedOptionsByQuestionCode ?? this.selectedOptionsByQuestionCode,
      isRecordingAnswer: isRecordingAnswer ?? this.isRecordingAnswer,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      progressSnapshot: progressSnapshot ?? this.progressSnapshot,
    );
  }

  PracticeLoaded restart() {
    return PracticeLoaded(
      selectedSection: selectedSection,
      session: session,
      questions: questions,
      progressSnapshot: progressSnapshot,
    );
  }
}
