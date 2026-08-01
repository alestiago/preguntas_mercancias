part of 'practice_bloc.dart';

@immutable
sealed class PracticeEvent {
  const PracticeEvent();
}

final class PracticeStarted extends PracticeEvent {
  const PracticeStarted();
}

final class SectionSelected extends PracticeEvent {
  const SectionSelected(this.section);

  final String? section;
}

final class AnswerPressed extends PracticeEvent {
  const AnswerPressed(this.option);

  final QuestionOption option;
}

final class NextQuestionPressed extends PracticeEvent {
  const NextQuestionPressed();
}

final class RetryPressed extends PracticeEvent {
  const RetryPressed();
}
