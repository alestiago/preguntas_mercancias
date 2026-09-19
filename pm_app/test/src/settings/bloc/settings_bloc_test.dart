import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/settings/bloc/settings_bloc.dart';

import '../../../helpers/fake_settings_store.dart';

void main() {
  group('SettingsBloc', () {
    late FakeSettingsStore settingsStore;

    tearDown(() => settingsStore.close());

    blocTest<SettingsBloc, SettingsState>(
      'loads the persisted answer shuffle preference',
      setUp: () {
        settingsStore = FakeSettingsStore(
          answerShuffleEnabled: false,
          emitCurrentValueOnWatch: false,
        );
      },
      build: () => SettingsBloc(settingsStore: settingsStore),
      act: (bloc) => bloc.add(const SettingsStarted()),
      expect: () => [
        isA<SettingsLoaded>().having(
          (state) => state.answerShuffleEnabled,
          'answer shuffle enabled',
          isFalse,
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'persists answer shuffle toggles',
      setUp: () {
        settingsStore = FakeSettingsStore(emitCurrentValueOnWatch: false);
      },
      build: () => SettingsBloc(settingsStore: settingsStore),
      seed: () => const SettingsLoaded(answerShuffleEnabled: true),
      act: (bloc) => bloc.add(const AnswerShuffleToggled(false)),
      expect: () => [
        isA<SettingsLoaded>().having(
          (state) => state.answerShuffleEnabled,
          'answer shuffle enabled',
          isFalse,
        ),
      ],
      verify: (_) async {
        expect(await settingsStore.loadAnswerShuffleEnabled(), isFalse);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'reflects changes made outside the bloc',
      setUp: () {
        settingsStore = FakeSettingsStore(emitCurrentValueOnWatch: false);
      },
      build: () => SettingsBloc(settingsStore: settingsStore),
      seed: () => const SettingsLoaded(answerShuffleEnabled: true),
      act: (_) => settingsStore.setAnswerShuffleEnabled(false),
      expect: () => [
        isA<SettingsLoaded>().having(
          (state) => state.answerShuffleEnabled,
          'answer shuffle enabled',
          isFalse,
        ),
      ],
    );
  });
}
