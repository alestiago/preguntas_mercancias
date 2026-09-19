import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../questions/load_questions.dart';
import '../../questions/pending_question_batch.dart';
import '../../practice/practice_question_policy.dart';
import '../../practice/practice_session_config.dart';

part 'home_event.dart';
part 'home_state.dart';

final class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required this.loadQuestions, required this.questionProgressStore})
    : super(const HomeLoading()) {
    on<HomeReadRequested>(_onReadRequested, transformer: restartable());
    on<_HomeProgressSnapshotChanged>(_onProgressSnapshotChanged);
    on<_HomeProgressObservationFailed>(_onProgressObservationFailed);

    _progressSubscription = questionProgressStore.watchSnapshot().listen(
      (snapshot) => add(_HomeProgressSnapshotChanged(snapshot)),
      onError: (Object error, StackTrace stackTrace) {
        if (!isClosed) {
          add(_HomeProgressObservationFailed(error));
        }
        addError(error, stackTrace);
      },
    );
  }

  final LoadQuestions loadQuestions;
  final QuestionProgressStore questionProgressStore;
  late final StreamSubscription<QuestionProgressSnapshot> _progressSubscription;
  int _readGeneration = 0;
  List<Question>? _questions;
  QuestionProgressSnapshot? _progressSnapshot;

  Future<void> _onReadRequested(
    HomeReadRequested event,
    Emitter<HomeState> emit,
  ) async {
    final generation = ++_readGeneration;
    await _loadQuestions(emit, generation);
  }

  void _onProgressSnapshotChanged(
    _HomeProgressSnapshotChanged event,
    Emitter<HomeState> emit,
  ) {
    _progressSnapshot = event.progressSnapshot;
    _emitLoadedIfReady(emit);
  }

  void _onProgressObservationFailed(
    _HomeProgressObservationFailed event,
    Emitter<HomeState> emit,
  ) {
    _readGeneration += 1;
    _progressSnapshot = null;
    emit(HomeLoadFailure(event.error));
  }

  Future<void> _loadQuestions(Emitter<HomeState> emit, int generation) async {
    _questions = null;
    emit(const HomeLoading());

    try {
      final questions = await loadQuestions(null);
      if (!_isCurrentRead(generation, emit)) {
        return;
      }
      _questions = List.unmodifiable(questions);
      _emitLoadedIfReady(emit);
    } catch (error) {
      if (_isCurrentRead(generation, emit)) {
        emit(HomeLoadFailure(error));
      }
    }
  }

  void _emitLoadedIfReady(Emitter<HomeState> emit) {
    final questions = _questions;
    final progressSnapshot = _progressSnapshot;
    if (questions == null || progressSnapshot == null || emit.isDone) {
      return;
    }

    emit(HomeLoaded(questions: questions, progressSnapshot: progressSnapshot));
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
