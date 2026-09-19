part of 'answer_history_bloc.dart';

@immutable
sealed class AnswerHistoryState extends Equatable {
  const AnswerHistoryState();
}

final class AnswerHistoryLoading extends AnswerHistoryState {
  const AnswerHistoryLoading();

  @override
  List<Object?> get props => const [AnswerHistoryLoading];
}

final class AnswerHistoryFailure extends AnswerHistoryState {
  const AnswerHistoryFailure(this.error);

  final Object error;

  @override
  List<Object?> get props => [AnswerHistoryFailure, error];
}

final class AnswerHistoryEmpty extends AnswerHistoryState {
  const AnswerHistoryEmpty();

  @override
  List<Object?> get props => const [AnswerHistoryEmpty];
}

final class AnswerHistoryLoaded extends AnswerHistoryState {
  AnswerHistoryLoaded({required Iterable<AnswerHistorySection> sections})
    : sections = List.unmodifiable(sections);

  final List<AnswerHistorySection> sections;

  @override
  List<Object?> get props => [AnswerHistoryLoaded, sections];
}

final class AnswerHistorySection extends Equatable {
  AnswerHistorySection({
    required this.date,
    required Iterable<AnswerHistoryEntry> entries,
  }) : entries = List.unmodifiable(entries);

  final DateTime date;
  final List<AnswerHistoryEntry> entries;

  @override
  List<Object?> get props => [AnswerHistorySection, date, entries];
}

final class AnswerHistoryEntry extends Equatable {
  const AnswerHistoryEntry({required this.answer, required this.question});

  final QuestionAnswerRecord answer;
  final Question? question;

  @override
  List<Object?> get props => [AnswerHistoryEntry, answer, question];
}
