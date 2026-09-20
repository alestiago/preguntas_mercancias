import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../questions/load_questions.dart';
import '../../practice/practice_question_policy.dart';

part 'home_event.dart';
part 'home_state.dart';

final class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required this.loadQuestionCatalog,
    required this.questionProgressStore,
  }) : super(const HomeLoading()) {
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

  final LoadQuestionCatalog loadQuestionCatalog;
  final QuestionProgressStore questionProgressStore;
  late final StreamSubscription<QuestionProgressSnapshot> _progressSubscription;
  int _readGeneration = 0;
  QuestionCatalog? _catalog;
  QuestionProgressSnapshot? _progressSnapshot;

  Future<void> _onReadRequested(
    HomeReadRequested event,
    Emitter<HomeState> emit,
  ) async {
    final generation = ++_readGeneration;
    await _loadCatalog(emit, generation);
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

  Future<void> _loadCatalog(Emitter<HomeState> emit, int generation) async {
    _catalog = null;
    emit(const HomeLoading());

    try {
      final catalog = await loadQuestionCatalog();
      if (!_isCurrentRead(generation, emit)) {
        return;
      }
      _catalog = catalog;
      _emitLoadedIfReady(emit);
    } catch (error) {
      if (_isCurrentRead(generation, emit)) {
        emit(HomeLoadFailure(error));
      }
    }
  }

  void _emitLoadedIfReady(Emitter<HomeState> emit) {
    final catalog = _catalog;
    final progressSnapshot = _progressSnapshot;
    if (catalog == null || progressSnapshot == null || emit.isDone) {
      return;
    }

    emit(HomeLoaded(catalog: catalog, progressSnapshot: progressSnapshot));
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
