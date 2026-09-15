import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'settings_store.dart';

const _answerShuffleEnabledKey = 'answer_shuffle_enabled';

final class SharedPreferencesSettingsStore implements SettingsStore {
  final _answerShuffleController = StreamController<bool>.broadcast();

  @override
  Future<bool> loadAnswerShuffleEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_answerShuffleEnabledKey) ?? true;
  }

  @override
  Stream<bool> watchAnswerShuffleEnabled() async* {
    yield await loadAnswerShuffleEnabled();
    yield* _answerShuffleController.stream;
  }

  @override
  Future<void> setAnswerShuffleEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_answerShuffleEnabledKey, enabled);
    _answerShuffleController.add(enabled);
  }

  @override
  Future<void> close() {
    return _answerShuffleController.close();
  }
}
