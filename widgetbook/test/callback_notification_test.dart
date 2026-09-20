import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../src/support/callback_notification.dart';

void main() {
  testWidgets('shows the callback name and value in a SnackBar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showCallbackNotification(context, 'onAnswer', 'option B'),
              child: const Text('Notify'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Notify'));
    await tester.pump();

    expect(find.byKey(callbackNotificationKey), findsOneWidget);
    expect(find.text('onAnswer called with option B'), findsOneWidget);
  });

  testWidgets('replaces the current callback notification', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => showCallbackNotification(context, 'first'),
                  child: const Text('First'),
                ),
                TextButton(
                  onPressed: () => showCallbackNotification(context, 'second'),
                  child: const Text('Second'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('First'));
    await tester.pump();
    await tester.tap(find.text('Second'));
    await tester.pumpAndSettle();

    expect(find.text('first called'), findsNothing);
    expect(find.text('second called'), findsOneWidget);
  });
}
