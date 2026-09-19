import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/app/theme/app_theme.dart';
import 'package:pm_app/src/app/widgets/app_loading_indicator.dart';
import 'package:pm_app/src/app/widgets/app_message_panel.dart';

void main() {
  testWidgets('loading indicator owns the shared loading presentation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AppLoadingIndicator()),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.getSize(find.byType(SizedBox).last), const Size.square(36));
  });

  testWidgets('message panel supports an optional action', (tester) async {
    var actionCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AppMessagePanel(
          message: 'Could not load.',
          icon: Icons.error_outline,
          actionLabel: 'Retry',
          onAction: () => actionCount += 1,
        ),
      ),
    );

    expect(find.text('Could not load.'), findsOneWidget);
    await tester.tap(find.text('Retry'));

    expect(actionCount, 1);
  });
}
