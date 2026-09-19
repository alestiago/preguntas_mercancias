import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../questions/load_questions.dart';
import '../../practice/practice_question_policy.dart';
import '../../practice/practice_session_config.dart';

part 'home_event.dart';
part 'home_state.dart';

final class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required this.loadQuestions, required this.questionProgressStore})
    : super(const HomeLoading()) {
    on<HomeReadRequested>(_onReadRequested, transformer: restartable());
    on<_HomeProgressSnapshotChanged>(_onProgressSnapshotChanged);

    _progressSubscription = questionProgressStore.watchSnapshot().listen(
      (snapshot) => add(_HomeProgressSnapshotChanged(snapshot)),
      onError: addError,
    );
  }

  final LoadQuestions loadQuestions;
  final QuestionProgressStore questionProgressStore;
  late final StreamSubscription<QuestionProgressSnapshot> _progressSubscription;
  int _readGeneration = 0;

  Future<void> _onReadRequested(
    HomeReadRequested event,
    Emitter<HomeState> emit,
  ) async {
    final generation = ++_readGeneration;
    if (event is! HomeProgressRefreshed) {
      await _loadAll(emit, generation);
      return;
    }

    final currentState = state;
    if (currentState is! HomeLoaded) {
      await _loadAll(emit, generation);
      return;
    }

    try {
      final progressSnapshot = await questionProgressStore.loadSnapshot();
      if (!_isCurrentRead(generation, emit)) {
        return;
      }
      final latestState = state;
      if (latestState is HomeLoaded) {
        emit(latestState.copyWith(progressSnapshot: progressSnapshot));
      }
    } catch (error) {
      if (_isCurrentRead(generation, emit)) {
        emit(HomeLoadFailure(error));
      }
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

    _readGeneration += 1;
    emit(currentState.copyWith(progressSnapshot: event.progressSnapshot));
  }

  Future<void> _loadAll(Emitter<HomeState> emit, int generation) async {
    emit(const HomeLoading());

    try {
      final questions = await loadQuestions(null);
      if (!_isCurrentRead(generation, emit)) {
        return;
      }
      final progressSnapshot = await questionProgressStore.loadSnapshot();
      if (!_isCurrentRead(generation, emit)) {
        return;
      }

      emit(
        HomeLoaded(questions: questions, progressSnapshot: progressSnapshot),
      );
    } catch (error) {
      if (_isCurrentRead(generation, emit)) {
        emit(HomeLoadFailure(error));
      }
    }
  }

  bool _isCurrentRead(int generation, Emitter<HomeState> emit) {
    return generation == _readGeneration && !emit.isDone && !isClosed;
  }

  @override
  Future<void> close() async {
    _readGeneration += 1;
    await _progressSubscription.cancel();
    return super.close();
  }
}
