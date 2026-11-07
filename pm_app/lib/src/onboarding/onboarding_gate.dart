import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/widgets/app_loading_indicator.dart';
import '../settings/bloc/settings_bloc.dart';
import 'onboarding_page.dart';

enum _GateDestination { loading, onboarding, home }

/// Shows onboarding on first launch and [home] otherwise.
///
/// Never blocks the app: if settings fail to load, the user goes home.
/// Completing onboarding updates [SettingsBloc], and this widget swaps to
/// [home] without a navigation call.
class OnboardingGate extends StatelessWidget {
  const OnboardingGate({super.key, required this.home});

  final Widget home;

  static _GateDestination _destinationFor(SettingsState state) {
    return switch (state) {
      SettingsLoading() => _GateDestination.loading,
      SettingsLoaded(onboardingCompleted: false) => _GateDestination.onboarding,
      SettingsLoaded() || SettingsLoadFailure() => _GateDestination.home,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (previous, current) =>
          _destinationFor(previous) != _destinationFor(current),
      builder: (context, state) {
        return switch (_destinationFor(state)) {
          _GateDestination.loading => const Scaffold(
            body: AppLoadingIndicator(),
          ),
          _GateDestination.onboarding => OnboardingPage(
            onFinished: () =>
                context.read<SettingsBloc>().add(const OnboardingCompleted()),
          ),
          _GateDestination.home => home,
        };
      },
    );
  }
}
