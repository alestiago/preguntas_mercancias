import 'dart:async';

import 'package:pm_persistence/pm_persistence.dart';

class FakeSettingsStore implements SettingsStore {
  FakeSettingsStore({bool answerShuffleEnabled = true})
    : _answerShuffleEnabled = answerShuffleEnabled;

  bool _answerShuffleEnabled;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

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
  Future<void> close() {
    return _controller.close();
  }
}
