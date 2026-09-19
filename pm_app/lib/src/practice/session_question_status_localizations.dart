import '../../l10n/app_localizations.dart';
import 'practice_question_policy.dart';

extension SessionQuestionStatusLocalizations on SessionQuestionStatus {
  String localizedLabel(AppLocalizations localizations) {
    return switch (this) {
      SessionQuestionStatus.unanswered =>
        localizations.practiceSummaryUnanswered,
      SessionQuestionStatus.correct => localizations.correctAnswerFeedbackTitle,
      SessionQuestionStatus.incorrect =>
        localizations.incorrectAnswerFeedbackTitle,
    };
  }
}
