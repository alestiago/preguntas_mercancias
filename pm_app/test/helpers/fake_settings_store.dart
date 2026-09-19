import 'dart:async';

import 'package:pm_persistence/pm_persistence.dart';

class FakeSettingsStore implements SettingsStore {
  factory FakeSettingsStore({
    bool answerShuffleEnabled = true,
    bool emitCurrentValueOnWatch = true,
  }) {
    return FakeSettingsStore._(answerShuffleEnabled, emitCurrentValueOnWatch);
  }

  FakeSettingsStore._(
    this._answerShuffleEnabled,
    this._emitCurrentValueOnWatch,
  );

  bool _answerShuffleEnabled;
  final bool _emitCurrentValueOnWatch;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> loadAnswerShuffleEnabled() async => _answerShuffleEnabled;

  @override
  Stream<bool> watchAnswerShuffleEnabled() {
    if (!_emitCurrentValueOnWatch) {
      return _controller.stream;
    }

    return _watchWithCurrentValue();
  }

  Stream<bool> _watchWithCurrentValue() async* {
    yield _answerShuffleEnabled;
    yield* _controller.stream;
  }

  @override
  Future<void> setAnswerShuffleEnabled(bool enabled) async {
    _answerShuffleEnabled = enabled;
    _controller.add(enabled);
  }

  @override
  Future<void> close() {
    return _controller.close();
  }
}
