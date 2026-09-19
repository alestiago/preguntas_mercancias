import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../bloc/practice_bloc.dart';

class PracticeSessionFooter extends StatelessWidget {
  const PracticeSessionFooter({
    super.key,
    required this.primaryAction,
    required this.isPrimaryActionEnabled,
    required this.isPreviousActionEnabled,
    required this.onPrimaryAction,
    required this.onPreviousQuestion,
  });

  final PracticePrimaryAction primaryAction;
  final bool isPrimaryActionEnabled;
  final bool isPreviousActionEnabled;
  final VoidCallback onPrimaryAction;
  final VoidCallback onPreviousQuestion;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Row(
      children: [
        const Spacer(),
        Flexible(
          fit: FlexFit.loose,
          child: OutlinedButton.icon(
            key: const ValueKey('previous-question-button'),
            onPressed: isPreviousActionEnabled ? onPreviousQuestion : null,
            icon: const Icon(Icons.arrow_back),
            label: Text(
              localizations.previousQuestion,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          fit: FlexFit.loose,
          child: FilledButton.icon(
            key: const ValueKey('next-question-button'),
            onPressed: isPrimaryActionEnabled ? onPrimaryAction : null,
            icon: Icon(switch (primaryAction) {
              PracticePrimaryAction.finish => Icons.check,
              PracticePrimaryAction.restart => Icons.refresh,
              PracticePrimaryAction.next => Icons.arrow_forward,
            }),
            label: Text(switch (primaryAction) {
              PracticePrimaryAction.finish => localizations.finishPractice,
              PracticePrimaryAction.restart => localizations.restartPractice,
              PracticePrimaryAction.next => localizations.nextQuestion,
            }, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}
