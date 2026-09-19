import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'settings_store.dart';

const _answerShuffleEnabledKey = 'answer_shuffle_enabled';

typedef LoadSharedPreferences = Future<SharedPreferences> Function();
typedef WriteSharedPreferencesBool =
    Future<bool> Function(
      SharedPreferences preferences,
      String key,
      bool value,
    );

final class SharedPreferencesSettingsStore implements SettingsStore {
  SharedPreferencesSettingsStore({
    LoadSharedPreferences? loadPreferences,
    WriteSharedPreferencesBool? writeBool,
  }) : _loadPreferences = loadPreferences ?? SharedPreferences.getInstance,
       _writeBool = writeBool ?? _setBool;

  final LoadSharedPreferences _loadPreferences;
  final WriteSharedPreferencesBool _writeBool;
  final _answerShuffleController = StreamController<bool>.broadcast();
  Future<SharedPreferences>? _preferencesFuture;
  Future<bool>? _initialValueFuture;
  bool? _currentValue;
  int _revision = 0;

  @override
  Future<bool> loadAnswerShuffleEnabled() async {
    await _initialize();
    return _currentValue!;
  }

  @override
  Stream<bool> watchAnswerShuffleEnabled() {
    return Stream.multi((listener) {
      var cancelled = false;
      final revisionAtSubscription = _revision;
      final updates = _answerShuffleController.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener.onCancel = () {
        cancelled = true;
        return updates.cancel();
      };

      _initialize().then(
        (_) {
          if (!cancelled && _revision == revisionAtSubscription) {
            listener.add(_currentValue!);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!cancelled) {
            listener.addError(error, stackTrace);
          }
        },
      );
    });
  }

  @override
  Future<void> setAnswerShuffleEnabled(bool enabled) async {
    final preferences = await _preferences;
    final didWrite = await _writeBool(
      preferences,
      _answerShuffleEnabledKey,
      enabled,
    );
    if (!didWrite) {
      throw StateError('Could not persist the answer shuffle preference.');
    }

    _currentValue = enabled;
    _revision += 1;
    _answerShuffleController.add(enabled);
  }

  @override
  Future<void> close() {
    return _answerShuffleController.close();
  }

  Future<SharedPreferences> get _preferences {
    return _preferencesFuture ??= _loadPreferences();
  }

  Future<bool> _initialize() {
    return _initialValueFuture ??= _loadInitialValue();
  }

  Future<bool> _loadInitialValue() async {
    final preferences = await _preferences;
    return _currentValue =
        preferences.getBool(_answerShuffleEnabledKey) ?? true;
  }

  static Future<bool> _setBool(
    SharedPreferences preferences,
    String key,
    bool value,
  ) {
    return preferences.setBool(key, value);
  }
}
