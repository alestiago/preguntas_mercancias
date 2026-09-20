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
    this.progressSnapshot = const QuestionProgressSnapshot.empty(),
  });

  final String? selectedSection;
  final PracticeSessionConfig session;
  final QuestionProgressSnapshot progressSnapshot;

  SessionAnswers get answers => const SessionAnswers.empty();

  int get correctAttemptCount => answers.correctAttemptCount;

  int get incorrectAttemptCount => answers.incorrectAttemptCount;

  int get totalAttemptCount => answers.totalAttemptCount;

  PracticeMode get mode => session.mode;

  bool get isQuestionDrawerNavigationEnabled =>
      this is PracticeLoaded && session.allowsQuestionNavigation;

  PracticeExitPolicy get exitPolicy {
    final state = this;
    if (state is! PracticeLoaded) {
      return PracticeExitPolicy.allow;
    }
    if (state.isRecordingAnswer) {
      return PracticeExitPolicy.blocked;
    }
    if (session.confirmsExitAfterAnswer && state.answers.hasSelections) {
      return PracticeExitPolicy.confirm;
    }
    return PracticeExitPolicy.allow;
  }

  @override
  List<Object?> get props => [selectedSection, session, progressSnapshot];
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
  const PracticeLoaded({
    required super.selectedSection,
    required super.session,
    required this.practiceSession,
    this.isRecordingAnswer = false,
    this.pendingBatchState = const PendingBatchExhausted(),
    super.progressSnapshot,
  });

  final PracticeSession practiceSession;
  final bool isRecordingAnswer;
  final PendingBatchState pendingBatchState;

  List<Question> get questions => practiceSession.questions.questions;

  Map<String, QuestionAnswerPresentation>
  get answerPresentationsByQuestionCode =>
      practiceSession.questions.presentationsByQuestionCode;

  int get currentIndex => practiceSession.currentIndex;

  Map<String, QuestionOption> get selectedOptionsByQuestionCode =>
      answers.selectedOptionsByQuestionCode;

  @override
  SessionAnswers get answers => practiceSession.answers;

  QuestionOption? get selectedOption => practiceSession.selectedOption;

  QuestionAnswerPresentation get currentAnswerPresentation =>
      practiceSession.currentAnswerPresentation;

  SessionQuestionStatus sessionStatusFor(Question question) {
    return practiceQuestionPolicy.sessionStatusFor(
      question,
      answers.selectedOptionFor(question),
    );
  }

  bool get answered =>
      sessionStatusFor(currentQuestion) != SessionQuestionStatus.unanswered;

  bool get isLastQuestion => currentIndex == questions.length - 1;

  PracticeCompletionPolicy get completionPolicy => session.completionPolicy;

  bool get isFilteredPracticeMode => session.usesFilteredQuestionEligibility;

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
    return session.pendingOptions == null ||
        pendingBatchState is PendingBatchExhausted;
  }

  bool get isAwaitingPendingBatch =>
      session.pendingOptions != null &&
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

  Question get currentQuestion => practiceSession.currentQuestion;

  PracticeLoaded copyWith({
    PracticeSession? practiceSession,
    bool? isRecordingAnswer,
    PendingBatchState? pendingBatchState,
    QuestionProgressSnapshot? progressSnapshot,
  }) {
    return PracticeLoaded(
      selectedSection: selectedSection,
      session: session,
      practiceSession: practiceSession ?? this.practiceSession,
      isRecordingAnswer: isRecordingAnswer ?? this.isRecordingAnswer,
      pendingBatchState: pendingBatchState ?? this.pendingBatchState,
      progressSnapshot: progressSnapshot ?? this.progressSnapshot,
    );
  }

  PracticeLoaded restart() {
    return copyWith(practiceSession: practiceSession.restart());
  }

  @override
  List<Object?> get props => [
    PracticeLoaded,
    ...super.props,
    practiceSession,
    isRecordingAnswer,
    pendingBatchState,
  ];
}
