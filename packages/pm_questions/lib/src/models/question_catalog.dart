import 'dart:collection';

import 'package:equatable/equatable.dart';

import 'question.dart';

/// An immutable, indexed view of one ordered question bank.
final class QuestionCatalog extends Equatable {
  factory QuestionCatalog(Iterable<Question> questions) {
    final orderedQuestions = List<Question>.unmodifiable(questions);
    final questionsByCode = <String, Question>{};
    final mutableQuestionsBySection = <String, List<Question>>{};

    for (final question in orderedQuestions) {
      if (questionsByCode.containsKey(question.code)) {
        throw ArgumentError.value(
          question.code,
          'questions',
          'Contains duplicate question code ${question.code}.',
        );
      }

      questionsByCode[question.code] = question;
      mutableQuestionsBySection
          .putIfAbsent(question.section, () => <Question>[])
          .add(question);
    }

    final questionsBySection = <String, List<Question>>{
      for (final entry in mutableQuestionsBySection.entries)
        entry.key: List<Question>.unmodifiable(entry.value),
    };

    return QuestionCatalog._(
      questions: orderedQuestions,
      byCode: UnmodifiableMapView(questionsByCode),
      bySection: UnmodifiableMapView(questionsBySection),
    );
  }

  const QuestionCatalog._({
    required this.questions,
    required this.byCode,
    required this.bySection,
  });

  final List<Question> questions;
  final Map<String, Question> byCode;
  final Map<String, List<Question>> bySection;

  @override
  List<Object?> get props => [QuestionCatalog, questions, byCode, bySection];
}
