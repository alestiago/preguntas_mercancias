import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/l10n/app_localizations.dart';
import 'package:pm_app/src/onboarding/onboarding_steps.dart';
import 'package:pm_app/src/onboarding/view/onboarding_view.dart';

import '../../../helpers/pump_app.dart';

const _steps = [
  OnboardingStep(icon: Icons.looks_one, title: 'Uno', body: 'Primero'),
  OnboardingStep(icon: Icons.looks_two, title: 'Dos', body: 'Segundo'),
  OnboardingStep(icon: Icons.looks_3, title: 'Tres', body: 'Tercero'),
];

const _skip = ValueKey('onboarding-skip-button');
const _next = ValueKey('onboarding-next-button');
const _start = ValueKey('onboarding-start-button');

void main() {
  group('OnboardingView', () {
    late int finishedCount;

    Future<void> pumpView(WidgetTester tester) async {
      finishedCount = 0;
      await tester.pumpLocalizedPage(
        OnboardingView(steps: _steps, onFinished: () => finishedCount += 1),
      );
    }

    testWidgets('starts on the first step with skip and next', (tester) async {
      await pumpView(tester);

      expect(find.text('Uno'), findsOneWidget);
      expect(find.text('Primero'), findsOneWidget);
      expect(find.text('Saltar'), findsOneWidget);
      expect(find.text('Siguiente'), findsOneWidget);
      expect(find.byKey(_start), findsNothing);
      expect(find.bySemanticsLabel('Página 1 de 3'), findsOneWidget);
    });

    testWidgets('next advances one step at a time', (tester) async {
      await pumpView(tester);

      await tester.tap(find.byKey(_next));
      await tester.pumpAndSettle();

      expect(find.text('Dos'), findsOneWidget);
      expect(find.bySemanticsLabel('Página 2 de 3'), findsOneWidget);
      expect(finishedCount, 0);
    });

    testWidgets('swiping advances', (tester) async {
      await pumpView(tester);

      await tester.fling(
        find.byKey(const ValueKey('onboarding-page-view')),
        const Offset(-400, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Dos'), findsOneWidget);
    });

    testWidgets('skip finishes from any step but the last', (tester) async {
      await pumpView(tester);

      await tester.tap(find.byKey(_skip));
      await tester.pump();

      expect(finishedCount, 1);
    });

    testWidgets('last step shows start instead of skip and next', (
      tester,
    ) async {
      await pumpView(tester);

      for (var i = 0; i < _steps.length - 1; i++) {
        await tester.tap(find.byKey(_next));
        await tester.pumpAndSettle();
      }

      expect(find.text('Tres'), findsOneWidget);
      expect(find.byKey(_next), findsNothing);
      // Kept in the tree (maintainSize) so the layout doesn't jump, but hidden.
      expect(find.text('Saltar').hitTestable(), findsNothing);
      expect(find.bySemanticsLabel('Página 3 de 3'), findsOneWidget);

      await tester.tap(find.byKey(_start));
      await tester.pump();

      expect(finishedCount, 1);
    });
  });

  testWidgets('onboardingSteps has four localized steps', (tester) async {
    late List<OnboardingStep> steps;
    await tester.pumpLocalizedPage(
      Builder(
        builder: (context) {
          steps = onboardingSteps(AppLocalizations.of(context));
          return const SizedBox();
        },
      ),
    );

    expect(steps.map((step) => step.title), [
      'Prepara el examen de mercancías',
      'Practica a tu ritmo',
      'Los fallos vuelven hasta que los aciertas',
      'Ponte a prueba',
    ]);
  });
}
