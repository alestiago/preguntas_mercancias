import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/settings/bloc/settings_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';

import '../../../helpers/fake_settings_store.dart';

void main() {
  test('SettingsState uses value equality', () {
    expect(
      const SettingsLoaded(answerShuffleEnabled: true),
      const SettingsLoaded(answerShuffleEnabled: true),
    );
    expect(
      const SettingsLoaded(answerShuffleEnabled: false),
      isNot(const SettingsLoaded(answerShuffleEnabled: true)),
    );
    expect(const SettingsLoading(), const SettingsLoading());
  });

  group('SettingsBloc', () {
    FakeSettingsStore? settingsStore;

    tearDown(() => settingsStore?.close());

    blocTest<SettingsBloc, SettingsState>(
      'loads the persisted answer shuffle preference',
      setUp: () {
        settingsStore = FakeSettingsStore(answerShuffleEnabled: false);
      },
      build: () => SettingsBloc(settingsStore: settingsStore!),
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
        settingsStore = FakeSettingsStore();
      },
      build: () => SettingsBloc(settingsStore: settingsStore!),
      act: (bloc) async {
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AnswerShuffleToggled(false));
      },
      expect: () => [
        isA<SettingsLoaded>().having(
          (state) => state.answerShuffleEnabled,
          'initial answer shuffle enabled',
          isTrue,
        ),
        isA<SettingsLoaded>().having(
          (state) => state.answerShuffleEnabled,
          'answer shuffle enabled',
          isFalse,
        ),
      ],
      verify: (_) async {
        expect(await settingsStore!.loadAnswerShuffleEnabled(), isFalse);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'reflects changes made outside the bloc',
      setUp: () {
        settingsStore = FakeSettingsStore();
      },
      build: () => SettingsBloc(settingsStore: settingsStore!),
      seed: () => const SettingsLoaded(answerShuffleEnabled: true),
      act: (_) => settingsStore!.setAnswerShuffleEnabled(false),
      expect: () => [
        isA<SettingsLoaded>().having(
          (state) => state.answerShuffleEnabled,
          'answer shuffle enabled',
          isFalse,
        ),
      ],
    );

    test('persists rapid toggles in event order', () async {
      final controlledStore = _ControlledSettingsStore();
      final bloc = SettingsBloc(settingsStore: controlledStore);
      addTearDown(() async {
        await bloc.close();
        await controlledStore.close();
      });

      bloc.add(const AnswerShuffleToggled(false));
      bloc.add(const AnswerShuffleToggled(true));

      await _waitUntil(() => controlledStore.writeCalls.length == 1);
      expect(controlledStore.writeCalls, [false]);

      controlledStore.completeWrite(0);
      await _waitUntil(() => controlledStore.writeCalls.length == 2);
      expect(controlledStore.writeCalls, [false, true]);

      controlledStore.completeWrite(1);
      await _waitUntil(
        () => bloc.state is SettingsLoaded && bloc.state.answerShuffleEnabled,
      );

      expect(controlledStore.answerShuffleEnabled, isTrue);
    });

    test('initializes from the watch stream only', () async {
      final watchOnlyStore = _WatchOnlySettingsStore();
      final bloc = SettingsBloc(settingsStore: watchOnlyStore);
      addTearDown(() async {
        await bloc.close();
        await watchOnlyStore.close();
      });

      await _waitUntil(() => bloc.state is SettingsLoaded);

      expect(bloc.state.answerShuffleEnabled, isFalse);
    });

    test('surfaces observation errors', () async {
      final observedStore = FakeSettingsStore();
      final bloc = SettingsBloc(settingsStore: observedStore);
      addTearDown(() async {
        await bloc.close();
        await observedStore.close();
      });
      await _waitUntil(() => bloc.state is SettingsLoaded);

      final failureFuture = bloc.stream
          .where((state) => state is SettingsLoadFailure)
          .cast<SettingsLoadFailure>()
          .first
          .timeout(const Duration(seconds: 2));
      final error = StateError('Settings watch failed.');
      observedStore.emitError(error);

      expect((await failureFuture).error, error);
    });
  });
}

Future<void> _waitUntil(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TestFailure('Timed out waiting for a test condition.');
    }
    await Future<void>.delayed(Duration.zero);
  }
}

final class _ControlledSettingsStore implements SettingsStore {
  final StreamController<bool> _controller = StreamController.broadcast();
  final List<Completer<void>> _pendingWrites = [];
  final List<bool> writeCalls = [];
  bool answerShuffleEnabled = true;

  @override
  Future<bool> loadAnswerShuffleEnabled() async => answerShuffleEnabled;

  @override
  Stream<bool> watchAnswerShuffleEnabled() async* {
    yield answerShuffleEnabled;
    yield* _controller.stream;
  }

  @override
  Future<void> setAnswerShuffleEnabled(bool enabled) async {
    writeCalls.add(enabled);
    final completer = Completer<void>();
    _pendingWrites.add(completer);
    await completer.future;
    answerShuffleEnabled = enabled;
    _controller.add(enabled);
  }

  void completeWrite(int index) => _pendingWrites[index].complete();

  @override
  Future<void> close() => _controller.close();
}

final class _WatchOnlySettingsStore extends FakeSettingsStore {
  _WatchOnlySettingsStore() : super(answerShuffleEnabled: false);

  @override
  Future<bool> loadAnswerShuffleEnabled() {
    throw StateError(
      'SettingsBloc must initialize from watchAnswerShuffleEnabled().',
    );
  }
}
