import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:pm_persistence/pm_persistence.dart';

part 'settings_event.dart';
part 'settings_state.dart';

final class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required this.settingsStore}) : super(const SettingsLoading()) {
    on<AnswerShuffleToggled>(
      _onAnswerShuffleToggled,
      transformer: sequential(),
    );
    on<_SettingsObservationRequested>(_onObservationRequested);

    add(const _SettingsObservationRequested());
  }

  final SettingsStore settingsStore;

  Future<void> _onAnswerShuffleToggled(
    AnswerShuffleToggled event,
    Emitter<SettingsState> emit,
  ) {
    return settingsStore.setAnswerShuffleEnabled(event.enabled);
  }

  Future<void> _onObservationRequested(
    _SettingsObservationRequested event,
    Emitter<SettingsState> emit,
  ) {
    return emit.forEach<bool>(
      settingsStore.watchAnswerShuffleEnabled(),
      onData: _stateForAnswerShuffle,
      onError: (error, stackTrace) {
        addError(error, stackTrace);
        return SettingsLoadFailure(error);
      },
    );
  }

  SettingsState _stateForAnswerShuffle(bool answerShuffleEnabled) {
    final currentState = state;
    if (currentState is! SettingsLoaded) {
      return SettingsLoaded(answerShuffleEnabled: answerShuffleEnabled);
    }

    return currentState.copyWith(answerShuffleEnabled: answerShuffleEnabled);
  }
}
