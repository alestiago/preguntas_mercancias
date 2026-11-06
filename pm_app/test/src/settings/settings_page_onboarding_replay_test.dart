import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/onboarding/view/onboarding_view.dart';
import 'package:pm_app/src/settings/bloc/settings_bloc.dart';
import 'package:pm_app/src/settings/settings_page.dart';
import 'package:pm_persistence/pm_persistence.dart';

import '../../helpers/fake_question_progress_store.dart';
import '../../helpers/fake_settings_store.dart';
import '../../helpers/pump_app.dart';

const _replayTile = ValueKey('replay-onboarding-tile');

void main() {
  late FakeSettingsStore settingsStore;
  late FakeQuestionProgressStore progressStore;

  setUp(() {
    settingsStore = FakeSettingsStore(onboardingCompleted: true);
    progressStore = FakeQuestionProgressStore();
    addTearDown(settingsStore.close);
    addTearDown(progressStore.close);
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    required bool showDeveloperOptions,
  }) {
    return tester.pumpLocalizedPage(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<QuestionProgressStore>.value(value: progressStore),
          RepositoryProvider<SettingsStore>.value(value: settingsStore),
        ],
        child: BlocProvider(
          create: (_) => SettingsBloc(settingsStore: settingsStore),
          child: SettingsPage(showDeveloperOptions: showDeveloperOptions),
        ),
      ),
    );
  }

  testWidgets('hides the replay entry outside debug', (tester) async {
    await pumpSettings(tester, showDeveloperOptions: false);

    expect(find.byKey(_replayTile), findsNothing);
  });

  testWidgets('replays onboarding and returns without touching the flag', (
    tester,
  ) async {
    await pumpSettings(tester, showDeveloperOptions: true);

    await tester.tap(find.byKey(_replayTile));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingView), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-skip-button')));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingView), findsNothing);
    expect(find.byKey(_replayTile), findsOneWidget);
    expect(settingsStore.onboardingWriteCount, 0);
  });

  testWidgets('defaults to showing the entry in debug builds', (tester) async {
    expect(const SettingsPage().showDeveloperOptions, isTrue);
  });
}
