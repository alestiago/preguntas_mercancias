import 'dart:async';

import 'package:pm_persistence/pm_persistence.dart';

class FakeSettingsStore implements SettingsStore {
  FakeSettingsStore({this._answerShuffleEnabled = true});

  bool _answerShuffleEnabled;
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

  void emitError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  @override
  Future<void> close() {
    closeCallCount += 1;
    return _controller.close();
  }
}
