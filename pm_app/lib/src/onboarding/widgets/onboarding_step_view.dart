import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../onboarding_steps.dart';
import 'onboarding_illustration_placeholder.dart';

/// The content of one onboarding page.
class OnboardingStepView extends StatelessWidget {
  const OnboardingStepView({super.key, required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.pageHorizontalInset,
        vertical: 24,
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: OnboardingIllustrationPlaceholder(icon: step.icon),
          ),
          const SizedBox(height: 32),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: AppTypography.emphasizedWeight,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
