import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _seedColor = Color(0xFF136F63);
  static const _scaffoldBackgroundColor = Color(0xFFF6F7F9);
  static const _incorrectColor = Color(0xFFC62828);
  static const _incorrectContainerColor = Color(0xFFFFEBEE);
  static const _onIncorrectContainerColor = Color(0xFFB71C1C);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(seedColor: _seedColor).copyWith(
      error: _incorrectColor,
      errorContainer: _incorrectContainerColor,
      onErrorContainer: _onIncorrectContainerColor,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _scaffoldBackgroundColor,
      useMaterial3: true,
      extensions: const [AppResultColors.light()],
    );
  }
}

abstract final class AppLayout {
  static const maxContentWidth = 860.0;
  static const pageHorizontalInset = 20.0;
  static const cardRadius = 8.0;
  static const pillRadius = 999.0;
}

abstract final class AppTypography {
  static const emphasizedWeight = FontWeight.w700;
  static const strongWeight = FontWeight.w800;
}

@immutable
final class AppResultColors extends ThemeExtension<AppResultColors> {
  const AppResultColors({
    required this.correct,
    required this.correctContainer,
    required this.onCorrectContainer,
  });

  const AppResultColors.light()
    : correct = const Color(0xFF2E7D32),
      correctContainer = const Color(0xFFE8F5E9),
      onCorrectContainer = const Color(0xFF1B5E20);

  final Color correct;
  final Color correctContainer;
  final Color onCorrectContainer;

  static AppResultColors of(BuildContext context) {
    return Theme.of(context).extension<AppResultColors>() ??
        const AppResultColors.light();
  }

  @override
  AppResultColors copyWith({
    Color? correct,
    Color? correctContainer,
    Color? onCorrectContainer,
  }) {
    return AppResultColors(
      correct: correct ?? this.correct,
      correctContainer: correctContainer ?? this.correctContainer,
      onCorrectContainer: onCorrectContainer ?? this.onCorrectContainer,
    );
  }

  @override
  AppResultColors lerp(covariant AppResultColors? other, double t) {
    if (other == null) {
      return this;
    }

    return AppResultColors(
      correct: Color.lerp(correct, other.correct, t)!,
      correctContainer: Color.lerp(
        correctContainer,
        other.correctContainer,
        t,
      )!,
      onCorrectContainer: Color.lerp(
        onCorrectContainer,
        other.onCorrectContainer,
        t,
      )!,
    );
  }
}
