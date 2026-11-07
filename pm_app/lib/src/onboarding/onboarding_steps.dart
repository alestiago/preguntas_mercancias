import 'package:flutter/foundation.dart';

import '../../l10n/app_localizations.dart';

/// One onboarding page: a title and a body.
///
/// The illustration is shared by all pages (see `OnboardingRoad`).
@immutable
final class OnboardingStep {
  const OnboardingStep({required this.title, required this.body});

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
      title: l10n.onboardingBankTitle,
      body: l10n.onboardingBankBody,
    ),
    OnboardingStep(
      title: l10n.onboardingPracticeTitle,
      body: l10n.onboardingPracticeBody,
    ),
    OnboardingStep(
      title: l10n.onboardingReviewTitle,
      body: l10n.onboardingReviewBody,
    ),
    OnboardingStep(
      title: l10n.onboardingSimulacroTitle,
      body: l10n.onboardingSimulacroBody,
    ),
  ];
}
