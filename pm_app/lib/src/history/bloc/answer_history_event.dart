part of 'answer_history_bloc.dart';

@immutable
sealed class AnswerHistoryEvent {
  const AnswerHistoryEvent();
}

final class _AnswerHistoryChanged extends AnswerHistoryEvent {
  const _AnswerHistoryChanged(this.answers);

  final List<QuestionAnswerRecord> answers;
}

final class _AnswerHistoryObservationFailed extends AnswerHistoryEvent {
  const _AnswerHistoryObservationFailed(this.error);

  final Object error;
}
