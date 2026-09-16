import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class ExitPracticeIconButton extends StatelessWidget {
  const ExitPracticeIconButton({
    super.key,
    required this.showConfirmation,
    required this.onExitConfirmed,
  });

  final bool showConfirmation;
  final VoidCallback onExitConfirmed;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return IconButton(
      key: const ValueKey('exit-practice-button'),
      tooltip: localizations.exitSimulacro,
      onPressed: () => _handlePressed(context),
      icon: const Icon(Icons.close),
    );
  }

  Future<void> _handlePressed(BuildContext context) async {
    if (!showConfirmation) {
      onExitConfirmed();
      return;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => const _ExitPracticeConfirmationDialog(),
    );

    if (shouldExit == true && context.mounted) {
      onExitConfirmed();
    }
  }
}

class _ExitPracticeConfirmationDialog extends StatelessWidget {
  const _ExitPracticeConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.exitSimulacroConfirmationTitle),
      content: Text(localizations.exitSimulacroConfirmationMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(localizations.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(localizations.exitSimulacro),
        ),
      ],
    );
  }
}
