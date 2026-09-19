part of 'practice_bloc.dart';

@immutable
sealed class PracticeState extends Equatable {
  const PracticeState({
    required this.selectedSection,
    required this.session,
    this.correctAttemptCount = 0,
    this.incorrectAttemptCount = 0,
    this.progressSnapshot = const QuestionProgressSnapshot.empty(),
  });

  final String? selectedSection;
  final PracticeSessionConfig session;

  /// Correct attempts made in this session, including review retries.
  final int correctAttemptCount;

  /// Incorrect attempts made in this session, including review retries.
  final int incorrectAttemptCount;
  final QuestionProgressSnapshot progressSnapshot;

  int get totalAttemptCount => correctAttemptCount + incorrectAttemptCount;

  PracticeMode get mode => session.mode;

  bool get isQuestionDrawerNavigationEnabled =>
      this is PracticeLoaded && mode == PracticeMode.simulacro;

  @override
  List<Object?> get props => [
    selectedSection,
    session,
    correctAttemptCount,
    incorrectAttemptCount,
    progressSnapshot,
  ];
}

final class PracticeLoading extends PracticeState {
  const PracticeLoading({
    required super.selectedSection,
    required super.session,
  });

  @override
  List<Object?> get props => [PracticeLoading, ...super.props];
}

final class PracticeLoadFailure extends PracticeState {
  const PracticeLoadFailure({
    required super.selectedSection,
    required super.session,
    required this.error,
  });

  final Object error;

  @override
  List<Object?> get props => [PracticeLoadFailure, ...super.props, error];
}

final class PracticeLoaded extends PracticeState {
  factory PracticeLoaded({
    required String? selectedSection,
    required Iterable<Question> questions,
    int currentIndex = 0,
    Map<String, QuestionOption> selectedOptionsByQuestionCode = const {},
    bool isRecordingAnswer = false,
    required PracticeSessionConfig session,
    int correctAttemptCount = 0,
    int incorrectAttemptCount = 0,
    QuestionProgressSnapshot progressSnapshot =
        const QuestionProgressSnapshot.empty(),
  }) {
    assert(correctAttemptCount >= 0);
    assert(incorrectAttemptCount >= 0);

    return PracticeLoaded._(
      selectedSection: selectedSection,
      questions: List.unmodifiable(questions),
      currentIndex: currentIndex,
      selectedOptionsByQuestionCode: Map.unmodifiable(
        selectedOptionsByQuestionCode,
      ),
      isRecordingAnswer: isRecordingAnswer,
      session: session,
      correctAttemptCount: correctAttemptCount,
      incorrectAttemptCount: incorrectAttemptCount,
      progressSnapshot: progressSnapshot,
    );
  }

  const PracticeLoaded._({
    required super.selectedSection,
    required this.questions,
    required this.currentIndex,
    required this.selectedOptionsByQuestionCode,
    required this.isRecordingAnswer,
    required super.session,
    required super.correctAttemptCount,
    required super.incorrectAttemptCount,
    required super.progressSnapshot,
  });

  final List<Question> questions;
  final int currentIndex;

  /// The latest retained answer result for each question in this session.
  ///
  /// Review navigation may temporarily remove an entry to reopen a retry;
  /// attempt totals remain available separately on [PracticeState].
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
    int? correctAttemptCount,
    int? incorrectAttemptCount,
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
      correctAttemptCount: correctAttemptCount ?? this.correctAttemptCount,
      incorrectAttemptCount:
          incorrectAttemptCount ?? this.incorrectAttemptCount,
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

  @override
  List<Object?> get props => [
    PracticeLoaded,
    ...super.props,
    questions,
    currentIndex,
    selectedOptionsByQuestionCode,
    isRecordingAnswer,
  ];
}
