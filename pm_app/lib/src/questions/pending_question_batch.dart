import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:pm_questions/pm_questions.dart';

@immutable
final class PendingQuestionBatch extends Equatable {
  PendingQuestionBatch({
    required Iterable<Question> questions,
    required this.hasMore,
  }) : questions = List.unmodifiable(questions);

  final List<Question> questions;
  final bool hasMore;

  @override
  List<Object?> get props => [PendingQuestionBatch, questions, hasMore];
}
