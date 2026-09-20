import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

import 'practice_question_policy.dart';
import 'practice_session_config.dart';

@immutable
final class SessionQuestionRequest extends Equatable {
  SessionQuestionRequest({
    required this.section,
    required Set<String> excludedQuestionCodes,
    required this.progressSnapshot,
    required this.requestedSize,
  }) : excludedQuestionCodes = Set.unmodifiable(excludedQuestionCodes) {
    if (requestedSize != null && requestedSize! <= 0) {
      throw ArgumentError.value(
        requestedSize,
        'requestedSize',
        'Must be greater than zero when supplied.',
      );
    }
  }

  final String? section;
  final Set<String> excludedQuestionCodes;
  final QuestionProgressSnapshot progressSnapshot;
  final int? requestedSize;

  @override
  List<Object?> get props => [
    SessionQuestionRequest,
    section,
    excludedQuestionCodes,
    progressSnapshot,
    requestedSize,
  ];
}

@immutable
final class SessionQuestionBatch extends Equatable {
  SessionQuestionBatch({
    required Iterable<Question> questions,
    required this.hasMore,
  }) : questions = List.unmodifiable(questions);

  final List<Question> questions;
  final bool hasMore;

  @override
  List<Object?> get props => [SessionQuestionBatch, questions, hasMore];
}

abstract interface class SessionQuestionSource {
  PracticeMode get mode;

  Future<SessionQuestionBatch> load(SessionQuestionRequest request);
}

final class CatalogSessionQuestionSource implements SessionQuestionSource {
  CatalogSessionQuestionSource({required this.catalog, required this.mode}) {
    if (mode != PracticeMode.standard &&
        mode != PracticeMode.review &&
        mode != PracticeMode.pending) {
      throw ArgumentError.value(
        mode,
        'mode',
        'Catalog sources support standard, review, and pending practice.',
      );
    }
  }

  final QuestionCatalog catalog;

  @override
  final PracticeMode mode;

  @override
  Future<SessionQuestionBatch> load(SessionQuestionRequest request) async {
    final section = request.section?.trim().toUpperCase();
    if (section != null && !catalog.bySection.containsKey(section)) {
      throw ArgumentError.value(
        request.section,
        'request.section',
        'Expected one of: ${catalog.bySection.keys.join(', ')}.',
      );
    }
    final eligibleQuestions = practiceQuestionPolicy.selectEligible(
      questions: catalog.questions,
      mode: mode,
      progressSnapshot: request.progressSnapshot,
      section: section,
      excludedQuestionCodes: request.excludedQuestionCodes,
    );
    if (mode != PracticeMode.pending) {
      return SessionQuestionBatch(questions: eligibleQuestions, hasMore: false);
    }

    final requestedSize = request.requestedSize;
    if (requestedSize == null) {
      throw ArgumentError.notNull('request.requestedSize');
    }
    final questions = eligibleQuestions
        .take(requestedSize)
        .toList(growable: false);
    return SessionQuestionBatch(
      questions: questions,
      hasMore: eligibleQuestions.length > questions.length,
    );
  }
}

final class FixedSessionQuestionSource implements SessionQuestionSource {
  FixedSessionQuestionSource({
    required Iterable<Question> questions,
    required this.mode,
  }) : questions = List.unmodifiable(questions) {
    if (mode != PracticeMode.simulacro && mode != PracticeMode.singleQuestion) {
      throw ArgumentError.value(
        mode,
        'mode',
        'Fixed sources support simulacro and single-question practice.',
      );
    }
  }

  final List<Question> questions;

  @override
  final PracticeMode mode;

  @override
  Future<SessionQuestionBatch> load(SessionQuestionRequest request) async {
    return SessionQuestionBatch(questions: questions, hasMore: false);
  }
}
