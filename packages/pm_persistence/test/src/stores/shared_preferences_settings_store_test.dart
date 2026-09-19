import 'package:flutter_test/flutter_test.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesSettingsStore', () {
    late SharedPreferencesSettingsStore store;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      store = SharedPreferencesSettingsStore();
    });

    tearDown(() => store.close());

    test('defaults answer shuffle to enabled', () async {
      expect(await store.loadAnswerShuffleEnabled(), isTrue);
    });

    test('persists answer shuffle preference', () async {
      await store.setAnswerShuffleEnabled(false);

      expect(await store.loadAnswerShuffleEnabled(), isFalse);
    });

    test('emits updates to watchers', () async {
      final values = <bool>[];
      final subscription = store.watchAnswerShuffleEnabled().listen(values.add);
      addTearDown(subscription.cancel);

      await pumpEventQueue();
      await store.setAnswerShuffleEnabled(false);
      await pumpEventQueue();

      expect(values, [true, false]);
    });

    test('does not lose a write during subscription startup', () async {
      final valuesFuture = store.watchAnswerShuffleEnabled().take(2).toList();

      await store.setAnswerShuffleEnabled(false);

      expect(await valuesFuture, [true, false]);
    });

    test('late subscribers receive the current value', () async {
      await store.setAnswerShuffleEnabled(false);

      expect(await store.watchAnswerShuffleEnabled().first, isFalse);
    });

    test('does not publish an unsuccessful write', () async {
      final failingStore = SharedPreferencesSettingsStore(
        writeBool: (_, _, _) async => false,
      );
      addTearDown(failingStore.close);
      final values = <bool>[];
      final subscription = failingStore.watchAnswerShuffleEnabled().listen(
        values.add,
      );
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      await expectLater(
        failingStore.setAnswerShuffleEnabled(false),
        throwsStateError,
      );
      await pumpEventQueue();

      expect(values, [true]);
      expect(await failingStore.loadAnswerShuffleEnabled(), isTrue);
    });

    test('closes active watchers when disposed', () async {
      final done = expectLater(
        store.watchAnswerShuffleEnabled(),
        emitsInOrder([true, emitsDone]),
      );

      await pumpEventQueue();
      await store.close();

      await done;
    });
  });
}
