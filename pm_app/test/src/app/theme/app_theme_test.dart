import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/app/theme/app_theme.dart';

void main() {
  test('defines shared layout and semantic result tokens', () {
    final theme = AppTheme.light;
    final resultColors = theme.extension<AppResultColors>();

    expect(AppLayout.maxContentWidth, 860);
    expect(resultColors, isNotNull);
    expect(resultColors!.correct, const Color(0xFF2E7D32));
    expect(theme.colorScheme.error, const Color(0xFFC62828));
  });
}
