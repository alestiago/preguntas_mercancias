import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

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
