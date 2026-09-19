import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class ExitPracticeIconButton extends StatelessWidget {
  const ExitPracticeIconButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return IconButton(
      key: const ValueKey('exit-practice-button'),
      tooltip: localizations.exitSimulacro,
      onPressed: onPressed,
      icon: const Icon(Icons.close),
    );
  }
}

Future<bool> showExitPracticeConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => const _ExitPracticeConfirmationDialog(),
      ) ??
      false;
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
