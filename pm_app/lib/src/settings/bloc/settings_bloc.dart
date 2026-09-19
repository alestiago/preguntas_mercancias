import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:pm_persistence/pm_persistence.dart';

part 'settings_event.dart';
part 'settings_state.dart';

final class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required this.settingsStore}) : super(const SettingsLoading()) {
    on<SettingsStarted>(_onStarted);
    on<AnswerShuffleToggled>(_onAnswerShuffleToggled);
    on<_AnswerShuffleEnabledChanged>(_onAnswerShuffleEnabledChanged);

    _answerShuffleSubscription = settingsStore
        .watchAnswerShuffleEnabled()
        .listen(
          (enabled) => add(_AnswerShuffleEnabledChanged(enabled)),
          onError: addError,
        );
  }

  final SettingsStore settingsStore;
  late final StreamSubscription<bool> _answerShuffleSubscription;

  Future<void> _onStarted(
    SettingsStarted event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final answerShuffleEnabled = await settingsStore
          .loadAnswerShuffleEnabled();
      emit(SettingsLoaded(answerShuffleEnabled: answerShuffleEnabled));
    } catch (error) {
      emit(SettingsLoadFailure(error));
    }
  }

  Future<void> _onAnswerShuffleToggled(
    AnswerShuffleToggled event,
    Emitter<SettingsState> emit,
  ) {
    return settingsStore.setAnswerShuffleEnabled(event.enabled);
  }

  void _onAnswerShuffleEnabledChanged(
    _AnswerShuffleEnabledChanged event,
    Emitter<SettingsState> emit,
  ) {
    final currentState = state;
    if (currentState is! SettingsLoaded) {
      emit(SettingsLoaded(answerShuffleEnabled: event.answerShuffleEnabled));
      return;
    }

    emit(
      currentState.copyWith(answerShuffleEnabled: event.answerShuffleEnabled),
    );
  }

  @override
  Future<void> close() async {
    await _answerShuffleSubscription.cancel();
    return super.close();
  }
}
