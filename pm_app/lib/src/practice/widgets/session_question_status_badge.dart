import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/theme/app_theme.dart';
import '../practice_question_policy.dart';
import '../session_question_status_localizations.dart';

class SessionQuestionStatusBadge extends StatelessWidget {
  const SessionQuestionStatusBadge.navigation({super.key, required this.status})
    : _unansweredIcon = Icons.radio_button_unchecked;

  const SessionQuestionStatusBadge.summary({super.key, required this.status})
    : _unansweredIcon = Icons.horizontal_rule;

  final SessionQuestionStatus status;
  final IconData _unansweredIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      SessionQuestionStatus.unanswered => colorScheme.onSurfaceVariant,
      SessionQuestionStatus.correct => AppResultColors.of(context).correct,
      SessionQuestionStatus.incorrect => colorScheme.error,
    };
    final icon = switch (status) {
      SessionQuestionStatus.unanswered => _unansweredIcon,
      SessionQuestionStatus.correct => Icons.check,
      SessionQuestionStatus.incorrect => Icons.close,
    };

    return Semantics(
      container: true,
      label: status.localizedLabel(AppLocalizations.of(context)),
      child: ExcludeSemantics(
        child: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          child: Icon(icon),
        ),
      ),
    );
  }
}
