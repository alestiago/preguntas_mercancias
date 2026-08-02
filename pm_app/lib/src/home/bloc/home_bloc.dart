import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:pm_persistence/pm_persistence.dart';

import '../../questions/load_questions.dart';

part 'home_event.dart';
part 'home_state.dart';

final class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required this.loadQuestions, required this.questionProgressStore})
    : super(const HomeLoading()) {
    on<HomeStarted>(_onStarted);
    on<HomeRetried>(_onStarted);
    on<HomeProgressRefreshed>(_onProgressRefreshed);
    on<_HomeProgressSnapshotChanged>(_onProgressSnapshotChanged);

    _progressSubscription = questionProgressStore.watchSnapshot().listen(
      (snapshot) => add(_HomeProgressSnapshotChanged(snapshot)),
      onError: addError,
    );
  }

  final LoadQuestions loadQuestions;
  final QuestionProgressStore questionProgressStore;
  late final StreamSubscription<QuestionProgressSnapshot> _progressSubscription;

  Future<void> _onStarted(HomeEvent event, Emitter<HomeState> emit) async {
    await _loadAll(emit);
  }

  Future<void> _onProgressRefreshed(
    HomeProgressRefreshed event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomeLoaded) {
      await _loadAll(emit);
      return;
    }

    try {
      emit(
        currentState.copyWith(
          progressSnapshot: await questionProgressStore.loadSnapshot(),
        ),
      );
    } catch (error) {
      emit(HomeLoadFailure(error));
    }
  }

  void _onProgressSnapshotChanged(
    _HomeProgressSnapshotChanged event,
    Emitter<HomeState> emit,
  ) {
    final currentState = state;
    if (currentState is! HomeLoaded) {
      return;
    }

    emit(currentState.copyWith(progressSnapshot: event.progressSnapshot));
  }

  Future<void> _loadAll(Emitter<HomeState> emit) async {
    emit(const HomeLoading());

    try {
      final questions = await loadQuestions(null);
      final progressSnapshot = await questionProgressStore.loadSnapshot();

      emit(
        HomeLoaded(
          questionCodes: questions.map((question) => question.code).toSet(),
          progressSnapshot: progressSnapshot,
        ),
      );
    } catch (error) {
      emit(HomeLoadFailure(error));
    }
  }

  @override
  Future<void> close() async {
    await _progressSubscription.cancel();
    return super.close();
  }
}
