import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/theme/app_theme.dart';
import '../bloc/practice_bloc.dart';
import '../format_elapsed_time.dart';
import '../practice_session_clock.dart';
import '../practice_session_config.dart';
import 'exit_practice_button.dart';

class PracticePageAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const PracticePageAppBar({
    super.key,
    required this.state,
    required this.sessionClock,
    required this.onExitRequested,
    required this.onOpenQuestionNavigator,
  });

  final PracticeState state;
  final PracticeSessionClock sessionClock;
  final VoidCallback onExitRequested;
  final VoidCallback onOpenQuestionNavigator;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    final localizations = AppLocalizations.of(context);

    return AppBar(
      leading: state is PracticeLoaded && state.mode == PracticeMode.simulacro
          ? ExitPracticeIconButton(onPressed: onExitRequested)
          : null,
      title: state.mode == PracticeMode.simulacro
          ? _SimulacroModeTitle(
              title: state.localize(localizations),
              sessionClock: sessionClock,
            )
          : Text(
              state.localize(localizations),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      actions: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            end: state.isQuestionDrawerNavigationEnabled ? 4 : 16,
          ),
          child: _ScorePill(
            correctAttemptCount: state.correctAttemptCount,
            totalAttemptCount: state.totalAttemptCount,
          ),
        ),
        if (state.isQuestionDrawerNavigationEnabled)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
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
  const _SimulacroModeTitle({required this.title, required this.sessionClock});

  final String title;
  final PracticeSessionClock sessionClock;

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
        Center(child: _SimulacroElapsedTimer(sessionClock: sessionClock)),
      ],
    );
  }
}

class _SimulacroElapsedTimer extends StatefulWidget {
  const _SimulacroElapsedTimer({required this.sessionClock});

  final PracticeSessionClock sessionClock;

  @override
  State<_SimulacroElapsedTimer> createState() => _SimulacroElapsedTimerState();
}

class _SimulacroElapsedTimerState extends State<_SimulacroElapsedTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
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

    final elapsedTime = formatElapsedTime(widget.sessionClock.elapsed);

    return Semantics(
      label: AppLocalizations.of(context).elapsedTimeSemantics(elapsedTime),
      excludeSemantics: true,
      child: Text(
        key: const ValueKey('simulacro-elapsed-time'),
        elapsedTime,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        textAlign: .center,
      ),
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
    final useCompactLabel =
        MediaQuery.sizeOf(context).width < 400 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final visibleLabel = useCompactLabel
        ? localizations.scorePillCompact(correctAttemptCount, totalAttemptCount)
        : localizations.scorePill(
            correctAttemptCount,
            totalAttemptCount,
            scorePercentage,
          );

    return Semantics(
      label: localizations.scoreSemantics(
        correctAttemptCount,
        totalAttemptCount,
        scorePercentage,
      ),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppLayout.pillRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            visibleLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: AppTypography.strongWeight,
            ),
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
      PracticeMode.review => localizations.reviewPracticeTitle,
      PracticeMode.simulacro => localizations.startSimulacro,
      PracticeMode.standard ||
      PracticeMode.singleQuestion => localizations.appTitle,
    };
  }
}
