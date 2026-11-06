import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/app.dart';
import 'package:pm_app/src/onboarding/view/onboarding_view.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../fixtures/question_fixtures.dart';
import '../../helpers/fake_question_progress_store.dart';
import '../../helpers/fake_settings_store.dart';
import '../../helpers/pump_app.dart';

const _homeTitle = 'Tu progreso';

void main() {
  late FakeQuestionProgressStore progressStore;
  late FakeSettingsStore settingsStore;

  setUp(() {
    progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);
  });

  Future<void> pumpAppWith(WidgetTester tester, FakeSettingsStore store) {
    settingsStore = store;
    addTearDown(store.close);
    return tester.pumpApp(
      loadQuestions: (_) async => buildQuestions(),
      questionProgressStore: progressStore,
      settingsStore: store,
    );
  }

  testWidgets('first launch: onboarding, start, then home; relaunch skips it', (
    tester,
  ) async {
    await pumpAppWith(tester, FakeSettingsStore(onboardingCompleted: false));

    expect(find.byType(OnboardingView), findsOneWidget);
    expect(find.text('Prepara el examen de mercancías'), findsOneWidget);
    expect(find.text(_homeTitle), findsNothing);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('onboarding-next-button')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('onboarding-start-button')));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingView), findsNothing);
    expect(find.text(_homeTitle), findsOneWidget);
    expect(settingsStore.onboardingCompleted, isTrue);

    // Relaunch with the same persisted store.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpApp(
      loadQuestions: (_) async => buildQuestions(),
      questionProgressStore: progressStore,
      settingsStore: settingsStore,
    );

    expect(find.byType(OnboardingView), findsNothing);
    expect(find.text(_homeTitle), findsOneWidget);
  });

  testWidgets('skip goes home and persists completion', (tester) async {
    await pumpAppWith(tester, FakeSettingsStore(onboardingCompleted: false));

    await tester.tap(find.byKey(const ValueKey('onboarding-skip-button')));
    await tester.pumpAndSettle();

    expect(find.text(_homeTitle), findsOneWidget);
    expect(settingsStore.onboardingCompleted, isTrue);
  });

  testWidgets('a completed flag goes straight home', (tester) async {
    await pumpAppWith(tester, FakeSettingsStore(onboardingCompleted: true));

    expect(find.byType(OnboardingView), findsNothing);
    expect(find.text(_homeTitle), findsOneWidget);
  });

  testWidgets('an unreadable flag goes home', (tester) async {
    await pumpAppWith(
      tester,
      FakeSettingsStore(onboardingCompleted: false)
        ..onboardingLoadError = StateError('read failed'),
    );

    expect(find.byType(OnboardingView), findsNothing);
    expect(find.text(_homeTitle), findsOneWidget);
  });

  testWidgets('a failed write still goes home', (tester) async {
    await pumpAppWith(
      tester,
      FakeSettingsStore(onboardingCompleted: false)
        ..onboardingWriteError = StateError('write failed'),
    );

    await tester.tap(find.byKey(const ValueKey('onboarding-skip-button')));
    await tester.pumpAndSettle();

    expect(find.text(_homeTitle), findsOneWidget);
    expect(settingsStore.onboardingCompleted, isFalse);
  });

  testWidgets('shows a loader until settings load', (tester) async {
    final store = _DelayedOnboardingStore();
    addTearDown(store.close);

    await tester.pumpWidget(
      PreguntasMercanciasApp(
        dependencies: AppDependencies(
          questionProgressStore: progressStore,
          settingsStore: store,
          loadQuestionCatalog: () async => QuestionCatalog(buildQuestions()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(OnboardingView), findsNothing);
    expect(find.text(_homeTitle), findsNothing);

    store.completeLoad(false);
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingView), findsOneWidget);
  });
}

final class _DelayedOnboardingStore extends FakeSettingsStore {
  final _load = Completer<bool>();

  void completeLoad(bool completed) => _load.complete(completed);

  @override
  Future<bool> loadOnboardingCompleted() => _load.future;
}
