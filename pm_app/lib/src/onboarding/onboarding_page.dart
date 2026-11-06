import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'onboarding_steps.dart';
import 'view/onboarding_view.dart';

/// Route entry for onboarding.
///
/// The first-launch gate passes an [onFinished] that persists completion.
/// A replay (debug Settings entry, O03) passes one that pops back.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    return OnboardingView(
      steps: onboardingSteps(AppLocalizations.of(context)),
      onFinished: onFinished,
    );
  }
}
