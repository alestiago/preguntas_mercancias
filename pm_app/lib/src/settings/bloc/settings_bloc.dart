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
    on<OnboardingCompleted>(_onOnboardingCompleted);
    on<_SettingsObservationRequested>(_onObservationRequested);

    add(const _SettingsObservationRequested());
  }

  final SettingsStore settingsStore;

  /// Read once at startup, then only changed by [OnboardingCompleted].
  bool _onboardingCompleted = true;

  Future<void> _onAnswerShuffleToggled(
    AnswerShuffleToggled event,
    Emitter<SettingsState> emit,
  ) {
    return settingsStore.setAnswerShuffleEnabled(event.enabled);
  }

  /// Emits the completed state before persisting it, so the app moves on even
  /// if the write fails. A failed write only means onboarding shows again on
  /// the next launch.
  Future<void> _onOnboardingCompleted(
    OnboardingCompleted event,
    Emitter<SettingsState> emit,
  ) async {
    _onboardingCompleted = true;
    final currentState = state;
    if (currentState is SettingsLoaded) {
      emit(currentState.copyWith(onboardingCompleted: true));
    }

    try {
      await settingsStore.setOnboardingCompleted(true);
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }

  Future<void> _onObservationRequested(
    _SettingsObservationRequested event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      _onboardingCompleted = await settingsStore.loadOnboardingCompleted();
    } on Object catch (error, stackTrace) {
      // Never block the app on a preferences error: treat it as completed.
      addError(error, stackTrace);
      _onboardingCompleted = true;
    }

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
      return SettingsLoaded(
        answerShuffleEnabled: answerShuffleEnabled,
        onboardingCompleted: _onboardingCompleted,
      );
    }

    return currentState.copyWith(answerShuffleEnabled: answerShuffleEnabled);
  }
}
