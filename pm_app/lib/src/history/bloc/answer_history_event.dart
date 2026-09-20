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

final class _AnswerHistoryObservationRequested extends AnswerHistoryEvent {
  const _AnswerHistoryObservationRequested(this.limit);

  final int limit;
}
