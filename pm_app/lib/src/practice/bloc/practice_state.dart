part of 'practice_bloc.dart';

enum PracticePrimaryAction { next, finish, restart }

enum PracticeExitPolicy { allow, confirm, blocked }

@immutable
sealed class PendingBatchState extends Equatable {
  const PendingBatchState();
}

final class PendingBatchReady extends PendingBatchState {
  const PendingBatchReady();

  @override
  List<Object?> get props => const [PendingBatchReady];
}

final class PendingBatchLoading extends PendingBatchState {
  const PendingBatchLoading();

  @override
  List<Object?> get props => const [PendingBatchLoading];
}

final class PendingBatchFailure extends PendingBatchState {
  const PendingBatchFailure(this.error);

  final Object error;

  @override
  List<Object?> get props => [PendingBatchFailure, error];
}

final class PendingBatchExhausted extends PendingBatchState {
  const PendingBatchExhausted();

  @override
  List<Object?> get props => const [PendingBatchExhausted];
}

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

  PracticeExitPolicy get exitPolicy {
    final state = this;
    if (state is! PracticeLoaded) {
      return PracticeExitPolicy.allow;
    }
    if (state.isRecordingAnswer) {
      return PracticeExitPolicy.blocked;
    }
    if (mode == PracticeMode.simulacro &&
        state.selectedOptionsByQuestionCode.isNotEmpty) {
      return PracticeExitPolicy.confirm;
    }
    return PracticeExitPolicy.allow;
  }

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
    Map<String, QuestionAnswerPresentation> answerPresentationsByQuestionCode =
        const {},
    bool isRecordingAnswer = false,
    PendingBatchState pendingBatchState = const PendingBatchExhausted(),
    required PracticeSessionConfig session,
    int correctAttemptCount = 0,
    int incorrectAttemptCount = 0,
    QuestionProgressSnapshot progressSnapshot =
        const QuestionProgressSnapshot.empty(),
  }) {
    assert(correctAttemptCount >= 0);
    assert(incorrectAttemptCount >= 0);

    final normalizedQuestions = List<Question>.unmodifiable(questions);
    final normalizedPresentations =
        Map<String, QuestionAnswerPresentation>.unmodifiable({
          for (final question in normalizedQuestions)
            question.code:
                answerPresentationsByQuestionCode[question.code] ??
                QuestionAnswerPresentation.inSourceOrder(question),
        });

    return PracticeLoaded._(
      selectedSection: selectedSection,
      questions: normalizedQuestions,
      currentIndex: currentIndex,
      selectedOptionsByQuestionCode: Map.unmodifiable(
        selectedOptionsByQuestionCode,
      ),
      answerPresentationsByQuestionCode: normalizedPresentations,
      isRecordingAnswer: isRecordingAnswer,
      pendingBatchState: pendingBatchState,
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
    required this.answerPresentationsByQuestionCode,
    required this.isRecordingAnswer,
    required this.pendingBatchState,
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
  final Map<String, QuestionAnswerPresentation>
  answerPresentationsByQuestionCode;
  final bool isRecordingAnswer;
  final PendingBatchState pendingBatchState;

  QuestionOption? get selectedOption =>
      selectedOptionsByQuestionCode[currentQuestion.code];

  QuestionAnswerPresentation get currentAnswerPresentation =>
      answerPresentationsByQuestionCode[currentQuestion.code]!;

  SessionQuestionStatus sessionStatusFor(Question question) {
    return practiceQuestionPolicy.sessionStatusFor(
      question,
      selectedOptionsByQuestionCode[question.code],
    );
  }

  bool get answered =>
      sessionStatusFor(currentQuestion) != SessionQuestionStatus.unanswered;

  bool get isLastQuestion => currentIndex == questions.length - 1;

  PracticeCompletionPolicy get completionPolicy => session.completionPolicy;

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

  bool get isFilteredPracticeComplete {
    if (!isFilteredPracticeMode || remainingFilteredQuestions.isNotEmpty) {
      return false;
    }
    return mode != PracticeMode.pending ||
        pendingBatchState is PendingBatchExhausted;
  }

  bool get isAwaitingPendingBatch =>
      mode == PracticeMode.pending &&
      remainingFilteredQuestions.isEmpty &&
      pendingBatchState is! PendingBatchExhausted;

  PracticePrimaryAction get primaryAction {
    return switch (completionPolicy) {
      PracticeCompletionPolicy.finishWhenEligibleQuestionsExhausted =>
        isFilteredPracticeComplete
            ? PracticePrimaryAction.finish
            : PracticePrimaryAction.next,
      PracticeCompletionPolicy.finishAtTerminalQuestionAllowingSkipped =>
        isLastQuestion
            ? PracticePrimaryAction.finish
            : PracticePrimaryAction.next,
      PracticeCompletionPolicy.restartAtTerminalQuestion =>
        isLastQuestion
            ? PracticePrimaryAction.restart
            : PracticePrimaryAction.next,
    };
  }

  bool get isPrimaryActionEnabled {
    if (isRecordingAnswer || isAwaitingPendingBatch) {
      return false;
    }
    return primaryAction == PracticePrimaryAction.next || answered;
  }

  bool get isPreviousActionEnabled => currentIndex > 0 && !isRecordingAnswer;

  double get progress =>
      questions.isEmpty ? 0 : (currentIndex + 1) / questions.length;

  Question get currentQuestion => questions[currentIndex];

  PracticeLoaded copyWith({
    List<Question>? questions,
    int? currentIndex,
    Map<String, QuestionOption>? selectedOptionsByQuestionCode,
    Map<String, QuestionAnswerPresentation>? answerPresentationsByQuestionCode,
    bool? isRecordingAnswer,
    PendingBatchState? pendingBatchState,
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
      answerPresentationsByQuestionCode:
          answerPresentationsByQuestionCode ??
          this.answerPresentationsByQuestionCode,
      isRecordingAnswer: isRecordingAnswer ?? this.isRecordingAnswer,
      pendingBatchState: pendingBatchState ?? this.pendingBatchState,
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
      answerPresentationsByQuestionCode: answerPresentationsByQuestionCode,
      progressSnapshot: progressSnapshot,
      pendingBatchState: pendingBatchState,
    );
  }

  @override
  List<Object?> get props => [
    PracticeLoaded,
    ...super.props,
    questions,
    currentIndex,
    selectedOptionsByQuestionCode,
    answerPresentationsByQuestionCode,
    isRecordingAnswer,
    pendingBatchState,
  ];
}
