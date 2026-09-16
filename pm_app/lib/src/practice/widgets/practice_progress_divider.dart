import 'package:flutter/material.dart';

class PracticeProgressDivider extends StatelessWidget {
  const PracticeProgressDivider({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LinearProgressIndicator(
      value: progress.clamp(0, 1).toDouble(),
      minHeight: 5,
      backgroundColor: colorScheme.surfaceContainerHighest,
      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
    );
  }
}
