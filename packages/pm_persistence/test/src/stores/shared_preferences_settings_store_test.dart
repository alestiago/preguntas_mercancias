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
  });
}
