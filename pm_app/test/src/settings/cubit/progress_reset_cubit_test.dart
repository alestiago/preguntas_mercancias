import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/settings/cubit/progress_reset_cubit.dart';

import '../../../helpers/fake_question_progress_store.dart';

void main() {
  test('exposes busy and success states around a reset', () async {
    final store = _ControlledProgressStore();
    final cubit = ProgressResetCubit(questionProgressStore: store);
    addTearDown(() async {
      store.completeClear();
      await cubit.close();
      await store.close();
    });

    final reset = cubit.reset();
    expect(cubit.state, const ProgressResetInProgress());

    store.completeClear();
    await reset;

    expect(cubit.state, const ProgressResetSuccess());
    expect(store.clearCallCount, 1);
  });

  test('ignores repeated reset requests while one is active', () async {
    final store = _ControlledProgressStore();
    final cubit = ProgressResetCubit(questionProgressStore: store);
    addTearDown(() async {
      store.completeClear();
      await cubit.close();
      await store.close();
    });

    final firstReset = cubit.reset();
    await cubit.reset();

    expect(store.clearCallCount, 1);

    store.completeClear();
    await firstReset;
  });

  test('surfaces reset failures', () async {
    final error = StateError('Reset failed.');
    final store = _FailingProgressStore(error);
    final cubit = ProgressResetCubit(questionProgressStore: store);
    addTearDown(() async {
      await cubit.close();
      await store.close();
    });

    await cubit.reset();

    expect(cubit.state, ProgressResetFailure(error));
  });
}

final class _ControlledProgressStore extends FakeQuestionProgressStore {
  final Completer<void> _clearCompleter = Completer<void>();
  int clearCallCount = 0;

  @override
  Future<void> clear() async {
    clearCallCount += 1;
    await _clearCompleter.future;
    await super.clear();
  }

  void completeClear() {
    if (!_clearCompleter.isCompleted) {
      _clearCompleter.complete();
    }
  }
}

final class _FailingProgressStore extends FakeQuestionProgressStore {
  _FailingProgressStore(this.error);

  final Object error;

  @override
  Future<void> clear() async => throw error;
}
