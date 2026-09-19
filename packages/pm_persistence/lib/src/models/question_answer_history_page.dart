import 'package:equatable/equatable.dart';

import 'question_answer_record.dart';

/// A newest-first, bounded prefix of the persisted answer history.
final class QuestionAnswerHistoryPage extends Equatable {
  QuestionAnswerHistoryPage({
    required Iterable<QuestionAnswerRecord> answers,
    required this.hasMore,
  }) : answers = List.unmodifiable(answers);

  final List<QuestionAnswerRecord> answers;
  final bool hasMore;

  @override
  List<Object?> get props => [QuestionAnswerHistoryPage, answers, hasMore];
}
