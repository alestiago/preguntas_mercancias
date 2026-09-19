import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import 'practice_session_config.dart';

const practiceQuestionPolicy = PracticeQuestionPolicy();

enum LifetimeQuestionStatus { unanswered, needsReview, mastered }

enum SessionQuestionStatus { unanswered, correct, incorrect }

final class PracticeQuestionSummary {
  const PracticeQuestionSummary({
    required this.totalCount,
    required this.masteredCount,
    required this.needsReviewCount,
    required this.unansweredCount,
    required this.unansweredCountsBySection,
  });

  final int totalCount;
  final int masteredCount;
  final int needsReviewCount;
  final int unansweredCount;
  final Map<String, int> unansweredCountsBySection;
}

final class PracticeQuestionPolicy {
  const PracticeQuestionPolicy();

  LifetimeQuestionStatus lifetimeStatusFor(
    Question question,
    QuestionProgressSnapshot progressSnapshot,
  ) {
    final progress = progressSnapshot.progressFor(question.code);
    if (progress == null) {
      return LifetimeQuestionStatus.unanswered;
    }

    return progress.correctAttempts > 0
        ? LifetimeQuestionStatus.mastered
        : LifetimeQuestionStatus.needsReview;
  }

  SessionQuestionStatus sessionStatusFor(
    Question question,
    QuestionOption? selectedOption,
  ) {
    if (selectedOption == null) {
      return SessionQuestionStatus.unanswered;
    }

    return question.isCorrect(selectedOption)
        ? SessionQuestionStatus.correct
        : SessionQuestionStatus.incorrect;
  }

  bool isEligible({
    required Question question,
    required PracticeMode mode,
    required QuestionProgressSnapshot progressSnapshot,
  }) {
    final status = lifetimeStatusFor(question, progressSnapshot);

    return switch (mode) {
      PracticeMode.review => status == LifetimeQuestionStatus.needsReview,
      PracticeMode.pending => status == LifetimeQuestionStatus.unanswered,
      PracticeMode.standard ||
      PracticeMode.simulacro ||
      PracticeMode.singleQuestion => true,
    };
  }

  List<Question> selectEligible({
    required Iterable<Question> questions,
    required PracticeMode mode,
    required QuestionProgressSnapshot progressSnapshot,
    String? section,
    Set<String> excludedQuestionCodes = const {},
    int? limit,
  }) {
    assert(limit == null || limit >= 0);

    final eligibleQuestions = _eligibleQuestions(
      questions: questions,
      mode: mode,
      progressSnapshot: progressSnapshot,
      section: section,
      excludedQuestionCodes: excludedQuestionCodes,
    );

    return List<Question>.unmodifiable(
      limit == null ? eligibleQuestions : eligibleQuestions.take(limit),
    );
  }

  Iterable<Question> _eligibleQuestions({
    required Iterable<Question> questions,
    required PracticeMode mode,
    required QuestionProgressSnapshot progressSnapshot,
    required String? section,
    required Set<String> excludedQuestionCodes,
  }) sync* {
    final selectedQuestionCodes = {...excludedQuestionCodes};

    for (final question in questions) {
      if ((section != null && question.section != section) ||
          selectedQuestionCodes.contains(question.code) ||
          !isEligible(
            question: question,
            mode: mode,
            progressSnapshot: progressSnapshot,
          )) {
        continue;
      }

      selectedQuestionCodes.add(question.code);
      yield question;
    }
  }

  PracticeQuestionSummary summarize({
    required Iterable<Question> questions,
    required QuestionProgressSnapshot progressSnapshot,
  }) {
    var totalCount = 0;
    var masteredCount = 0;
    var needsReviewCount = 0;
    var unansweredCount = 0;
    final unansweredCountsBySection = <String, int>{};
    final knownQuestionCodes = <String>{};

    for (final question in questions) {
      if (!knownQuestionCodes.add(question.code)) {
        continue;
      }

      totalCount += 1;
      switch (lifetimeStatusFor(question, progressSnapshot)) {
        case LifetimeQuestionStatus.mastered:
          masteredCount += 1;
        case LifetimeQuestionStatus.needsReview:
          needsReviewCount += 1;
        case LifetimeQuestionStatus.unanswered:
          unansweredCount += 1;
          unansweredCountsBySection.update(
            question.section,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
      }
    }

    return PracticeQuestionSummary(
      totalCount: totalCount,
      masteredCount: masteredCount,
      needsReviewCount: needsReviewCount,
      unansweredCount: unansweredCount,
      unansweredCountsBySection: Map.unmodifiable(unansweredCountsBySection),
    );
  }
}
