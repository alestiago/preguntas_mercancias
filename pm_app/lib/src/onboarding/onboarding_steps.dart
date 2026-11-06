import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// One onboarding page: an illustration slot, a title and a body.
@immutable
final class OnboardingStep {
  const OnboardingStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  /// Shown in the illustration placeholder until the final artwork lands.
  final IconData icon;
  final String title;
  final String body;
}

/// The onboarding pages, in order.
///
/// Every claim here must match current app behavior. If a claim changes (for
/// example the simulacro length), update `app_es.arb` in the same change.
List<OnboardingStep> onboardingSteps(AppLocalizations l10n) {
  return [
    OnboardingStep(
      icon: Icons.local_shipping_outlined,
      title: l10n.onboardingBankTitle,
      body: l10n.onboardingBankBody,
    ),
    OnboardingStep(
      icon: Icons.menu_book_outlined,
      title: l10n.onboardingPracticeTitle,
      body: l10n.onboardingPracticeBody,
    ),
    OnboardingStep(
      icon: Icons.replay_outlined,
      title: l10n.onboardingReviewTitle,
      body: l10n.onboardingReviewBody,
    ),
    OnboardingStep(
      icon: Icons.timer_outlined,
      title: l10n.onboardingSimulacroTitle,
      body: l10n.onboardingSimulacroBody,
    ),
  ];
}
