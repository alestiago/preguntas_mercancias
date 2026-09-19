part of 'answer_history_bloc.dart';

@immutable
sealed class AnswerHistoryEvent {
  const AnswerHistoryEvent();
}

final class AnswerHistoryRetried extends AnswerHistoryEvent {
  const AnswerHistoryRetried();
}

final class AnswerHistoryMoreRequested extends AnswerHistoryEvent {
  const AnswerHistoryMoreRequested();
}

final class _AnswerHistoryChanged extends AnswerHistoryEvent {
  const _AnswerHistoryChanged(this.page);

  final QuestionAnswerHistoryPage page;
}

final class _AnswerHistoryObservationFailed extends AnswerHistoryEvent {
  const _AnswerHistoryObservationFailed(this.error);

  final Object error;
}
