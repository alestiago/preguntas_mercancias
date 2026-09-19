part of 'practice_bloc.dart';

@immutable
sealed class PracticeEvent {
  const PracticeEvent();
}

sealed class PracticeLoadRequested extends PracticeEvent {
  const PracticeLoadRequested();
}

final class PracticeStarted extends PracticeLoadRequested {
  const PracticeStarted();
}

final class SectionSelected extends PracticeLoadRequested {
  const SectionSelected(this.section);

  final String? section;
}

final class AnswerPressed extends PracticeEvent {
  const AnswerPressed(this.option);

  final QuestionOption option;
}

sealed class PendingBatchLoadRequested extends PracticeEvent {
  const PendingBatchLoadRequested();
}

final class PendingBatchRetried extends PendingBatchLoadRequested {
  const PendingBatchRetried();
}

final class _PendingRefillRequested extends PendingBatchLoadRequested {
  const _PendingRefillRequested(this.sessionGeneration);

  final int sessionGeneration;
}

final class NextQuestionPressed extends PracticeEvent {
  const NextQuestionPressed();
}

final class PreviousQuestionPressed extends PracticeEvent {
  const PreviousQuestionPressed();
}

final class QuestionNavigationPressed extends PracticeEvent {
  const QuestionNavigationPressed(this.index);

  final int index;
}

final class RetryPressed extends PracticeLoadRequested {
  const RetryPressed();
}
