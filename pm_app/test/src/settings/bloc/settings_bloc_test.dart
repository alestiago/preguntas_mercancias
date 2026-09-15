import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/settings/bloc/settings_bloc.dart';

import '../../../helpers/fake_settings_store.dart';

void main() {
  group('SettingsBloc', () {
    test('loads the persisted answer shuffle preference', () async {
      final settingsStore = FakeSettingsStore(answerShuffleEnabled: false);
      addTearDown(settingsStore.close);
      final bloc = SettingsBloc(settingsStore: settingsStore);
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is SettingsLoaded,
      );
      bloc.add(const SettingsStarted());
      final loaded = await loadedFuture as SettingsLoaded;

      expect(loaded.answerShuffleEnabled, isFalse);
    });

    test('persists answer shuffle toggles', () async {
      final settingsStore = FakeSettingsStore();
      addTearDown(settingsStore.close);
      final bloc = SettingsBloc(settingsStore: settingsStore);
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is SettingsLoaded,
      );
      bloc.add(const SettingsStarted());
      await loadedFuture;

      final toggledFuture = bloc.stream.firstWhere(
        (state) => state is SettingsLoaded && !state.answerShuffleEnabled,
      );
      bloc.add(const AnswerShuffleToggled(false));
      final toggled = await toggledFuture as SettingsLoaded;

      expect(toggled.answerShuffleEnabled, isFalse);
      expect(await settingsStore.loadAnswerShuffleEnabled(), isFalse);
    });

    test('reflects changes made outside the bloc', () async {
      final settingsStore = FakeSettingsStore();
      addTearDown(settingsStore.close);
      final bloc = SettingsBloc(settingsStore: settingsStore);
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is SettingsLoaded,
      );
      bloc.add(const SettingsStarted());
      await loadedFuture;

      final changedFuture = bloc.stream.firstWhere(
        (state) => state is SettingsLoaded && !state.answerShuffleEnabled,
      );
      await settingsStore.setAnswerShuffleEnabled(false);
      final changed = await changedFuture as SettingsLoaded;

      expect(changed.answerShuffleEnabled, isFalse);
    });
  });
}
