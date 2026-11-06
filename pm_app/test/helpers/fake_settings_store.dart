import 'dart:async';

import 'package:pm_persistence/pm_persistence.dart';

class FakeSettingsStore implements SettingsStore {
  FakeSettingsStore({
    this._answerShuffleEnabled = true,
    this.onboardingCompleted = false,
  });

  bool _answerShuffleEnabled;

  /// The stored onboarding flag. Tests read it to assert what was persisted.
  bool onboardingCompleted;

  /// When set, [loadOnboardingCompleted] throws this error.
  Object? onboardingLoadError;

  /// When set, [setOnboardingCompleted] throws this error without storing.
  Object? onboardingWriteError;

  /// How many times [setOnboardingCompleted] was called.
  int onboardingWriteCount = 0;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  int closeCallCount = 0;

  @override
  Future<bool> loadAnswerShuffleEnabled() async => _answerShuffleEnabled;

  @override
  Stream<bool> watchAnswerShuffleEnabled() async* {
    yield _answerShuffleEnabled;
    yield* _controller.stream;
  }

  @override
  Future<void> setAnswerShuffleEnabled(bool enabled) async {
    _answerShuffleEnabled = enabled;
    _controller.add(enabled);
  }

  @override
  Future<bool> loadOnboardingCompleted() async {
    if (onboardingLoadError case final error?) {
      throw error;
    }
    return onboardingCompleted;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    onboardingWriteCount += 1;
    if (onboardingWriteError case final error?) {
      throw error;
    }
    onboardingCompleted = completed;
  }

  void emitError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  @override
  Future<void> close() {
    closeCallCount += 1;
    return _controller.close();
  }
}
