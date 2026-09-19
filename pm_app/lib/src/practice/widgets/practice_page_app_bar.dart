import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../bloc/practice_bloc.dart';
import '../practice_session_config.dart';
import 'exit_practice_button.dart';

class PracticePageAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const PracticePageAppBar({
    super.key,
    required this.state,
    required this.onExitConfirmed,
    required this.onOpenQuestionNavigator,
  });

  final PracticeState state;
  final VoidCallback onExitConfirmed;
  final VoidCallback onOpenQuestionNavigator;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    final localizations = AppLocalizations.of(context);

    return AppBar(
      leading: state is PracticeLoaded && state.mode == PracticeMode.simulacro
          ? ExitPracticeIconButton(
              showConfirmation: state.showExitConfirmation,
              onExitConfirmed: onExitConfirmed,
            )
          : null,
      title: state.mode == PracticeMode.simulacro
          ? _SimulacroModeTitle(title: state.localize(localizations))
          : Text(state.localize(localizations)),
      actions: [
        Padding(
          padding: EdgeInsets.only(
            right: state.isQuestionDrawerNavigationEnabled ? 4 : 16,
          ),
          child: _ScorePill(
            correctAttemptCount: state.correctAttemptCount,
            totalAttemptCount: state.totalAttemptCount,
          ),
        ),
        if (state.isQuestionDrawerNavigationEnabled)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              key: const ValueKey('question-navigation-app-bar-button'),
              tooltip: localizations.questionNavigationOpen,
              onPressed: onOpenQuestionNavigator,
              icon: const Icon(Icons.menu),
            ),
          ),
      ],
    );
  }
}

class _SimulacroModeTitle extends StatelessWidget {
  const _SimulacroModeTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: .center,
      crossAxisAlignment: .start,
      children: [
        Center(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: .center,
          ),
        ),
        Center(child: const _SimulacroElapsedTimer()),
      ],
    );
  }
}

class _SimulacroElapsedTimer extends StatefulWidget {
  const _SimulacroElapsedTimer();

  @override
  State<_SimulacroElapsedTimer> createState() => _SimulacroElapsedTimerState();
}

class _SimulacroElapsedTimerState extends State<_SimulacroElapsedTimer> {
  Timer? _timer;
  var _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      key: const ValueKey('simulacro-elapsed-time'),
      _elapsed.timerLabel,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      textAlign: .center,
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({
    required this.correctAttemptCount,
    required this.totalAttemptCount,
  });

  final int correctAttemptCount;
  final int totalAttemptCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);
    final scorePercentage = totalAttemptCount == 0
        ? 0
        : ((correctAttemptCount / totalAttemptCount) * 100).round();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          localizations.scorePill(
            correctAttemptCount,
            totalAttemptCount,
            scorePercentage,
          ),
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

extension _PracticeStateLocalizations on PracticeState {
  String localize(AppLocalizations localizations) {
    return switch (mode) {
      PracticeMode.pending => localizations.pendingQuestions,
      PracticeMode.review => 'Por Repasar',
      PracticeMode.simulacro => localizations.startSimulacro,
      PracticeMode.standard ||
      PracticeMode.singleQuestion => localizations.appTitle,
    };
  }
}

extension _TimerDurationFormatting on Duration {
  String get timerLabel {
    final hours = inHours;
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }
}
