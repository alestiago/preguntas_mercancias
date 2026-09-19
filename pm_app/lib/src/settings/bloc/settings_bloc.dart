import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:pm_persistence/pm_persistence.dart';

part 'settings_event.dart';
part 'settings_state.dart';

final class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required this.settingsStore}) : super(const SettingsLoading()) {
    on<AnswerShuffleToggled>(
      _onAnswerShuffleToggled,
      transformer: sequential(),
    );
    on<_AnswerShuffleEnabledChanged>(_onAnswerShuffleEnabledChanged);
    on<_SettingsObservationFailed>(_onObservationFailed);

    _answerShuffleSubscription = settingsStore
        .watchAnswerShuffleEnabled()
        .listen(
          (enabled) => add(_AnswerShuffleEnabledChanged(enabled)),
          onError: (Object error, StackTrace stackTrace) {
            if (!isClosed) {
              add(_SettingsObservationFailed(error));
            }
            addError(error, stackTrace);
          },
        );
  }

  final SettingsStore settingsStore;
  late final StreamSubscription<bool> _answerShuffleSubscription;

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

  void _onObservationFailed(
    _SettingsObservationFailed event,
    Emitter<SettingsState> emit,
  ) {
    emit(SettingsLoadFailure(event.error));
  }

  @override
  Future<void> close() async {
    await _answerShuffleSubscription.cancel();
    return super.close();
  }
}
