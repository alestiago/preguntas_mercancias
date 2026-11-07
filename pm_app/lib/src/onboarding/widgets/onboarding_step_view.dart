import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../onboarding_steps.dart';

/// The text of one onboarding page.
///
/// The illustration isn't part of the page: `OnboardingView` draws one shared
/// scene on top, so it stays still while the pages slide. This view leaves
/// [illustrationSpace] empty at the top for it. The empty space still belongs
/// to the page, so swiping over the illustration changes the page.
class OnboardingStepView extends StatelessWidget {
  const OnboardingStepView({
    super.key,
    required this.step,
    required this.illustrationSpace,
  });

  final OnboardingStep step;
  final double illustrationSpace;

  /// Keeps the title and body to a similar measure. A body that runs the full
  /// width of the screen looks unbalanced under a shorter title.
  static const textMaxWidth = 320.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        SizedBox(height: illustrationSpace),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppLayout.pageHorizontalInset,
              vertical: 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: textMaxWidth),
                child: Column(
                  children: [
                    Text(
                      step.title,
                      key: const ValueKey('onboarding-step-title'),
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: AppTypography.emphasizedWeight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      step.body,
                      key: const ValueKey('onboarding-step-body'),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
