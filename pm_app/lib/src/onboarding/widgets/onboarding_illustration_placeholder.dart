import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Reserves the space for an onboarding illustration.
///
/// Replace it with the final artwork when it arrives. Keep [aspectRatio], so
/// the page layout doesn't shift.
class OnboardingIllustrationPlaceholder extends StatelessWidget {
  const OnboardingIllustrationPlaceholder({super.key, required this.icon});

  static const aspectRatio = 4 / 3;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppLayout.cardRadius * 2),
          ),
          child: Center(
            child: Icon(icon, size: 72, color: colorScheme.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}
