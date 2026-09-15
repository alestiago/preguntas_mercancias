abstract interface class SettingsStore {
  Future<bool> loadAnswerShuffleEnabled();

  Stream<bool> watchAnswerShuffleEnabled();

  Future<void> setAnswerShuffleEnabled(bool enabled);

  Future<void> close();
}
