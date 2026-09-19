import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';

import '../../l10n/app_localizations.dart';
import 'bloc/settings_bloc.dart';

const appVersion = '1.0.0+1';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.settingsTitle)),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(localizations.appVersion),
              subtitle: const Text(appVersion),
            ),
            const Divider(height: 1),
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                return SwitchListTile(
                  key: const ValueKey('shuffle-answers-switch'),
                  secondary: const Icon(Icons.shuffle),
                  title: Text(localizations.shuffleAnswersTitle),
                  subtitle: Text(localizations.shuffleAnswersSubtitle),
                  value: state.answerShuffleEnabled,
                  onChanged: state is SettingsLoaded
                      ? (enabled) => context.read<SettingsBloc>().add(
                          AnswerShuffleToggled(enabled),
                        )
                      : null,
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              key: const ValueKey('reset-progress-tile'),
              leading: Icon(Icons.restart_alt, color: colorScheme.error),
              title: Text(
                localizations.resetProgress,
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => _confirmResetProgress(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmResetProgress(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(localizations.resetProgressConfirmationTitle),
        content: Text(localizations.resetProgressConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirm-reset-progress-button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(localizations.resetProgress),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await context.read<QuestionProgressStore>().clear();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(localizations.progressReset)));
  }
}
