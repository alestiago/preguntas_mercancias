import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

part 'answer_history_event.dart';
part 'answer_history_state.dart';

final class AnswerHistoryBloc
    extends Bloc<AnswerHistoryEvent, AnswerHistoryState> {
  AnswerHistoryBloc({
    required QuestionProgressStore questionProgressStore,
    required Iterable<Question> questions,
    int pageSize = 100,
  }) : _questionsByCode = _indexQuestionsByCode(questions),
       _pageSize = pageSize,
       _visibleLimit = pageSize,
       assert(pageSize > 0),
       super(const AnswerHistoryLoading()) {
    _questionProgressStore = questionProgressStore;
    on<AnswerHistoryRetried>(_onRetried);
    on<AnswerHistoryMoreRequested>(_onMoreRequested);
    on<_AnswerHistoryChanged>(_onHistoryChanged);
    on<_AnswerHistoryObservationFailed>(_onObservationFailed);

    _watchHistory();
  }

  late final QuestionProgressStore _questionProgressStore;
  final Map<String, Question> _questionsByCode;
  final int _pageSize;
  int _visibleLimit;
  StreamSubscription<QuestionAnswerHistoryPage>? _historySubscription;

  void _watchHistory() {
    _historySubscription = _questionProgressStore
        .watchAnswerHistory(limit: _visibleLimit)
        .listen(
          (page) {
            if (!isClosed) {
              add(_AnswerHistoryChanged(page));
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (isClosed) {
              return;
            }
            add(_AnswerHistoryObservationFailed(error));
            addError(error, stackTrace);
          },
        );
  }

  Future<void> _onRetried(
    AnswerHistoryRetried event,
    Emitter<AnswerHistoryState> emit,
  ) async {
    emit(const AnswerHistoryLoading());
    _cancelHistoryWatch();
    try {
      final page = await _questionProgressStore.loadAnswerHistory(
        limit: _visibleLimit,
      );
      if (!emit.isDone) {
        _emitHistory(page, emit);
        _watchHistory();
      }
    } catch (error) {
      if (!emit.isDone) {
        emit(AnswerHistoryFailure(error));
      }
    }
  }

  Future<void> _onMoreRequested(
    AnswerHistoryMoreRequested event,
    Emitter<AnswerHistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AnswerHistoryLoaded ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));
    _visibleLimit += _pageSize;
    _cancelHistoryWatch();

    try {
      final page = await _questionProgressStore.loadAnswerHistory(
        limit: _visibleLimit,
      );
      if (!emit.isDone) {
        _emitHistory(page, emit);
        _watchHistory();
      }
    } catch (error) {
      if (!emit.isDone) {
        emit(AnswerHistoryFailure(error));
      }
    }
  }

  void _onHistoryChanged(
    _AnswerHistoryChanged event,
    Emitter<AnswerHistoryState> emit,
  ) {
    _emitHistory(event.page, emit);
  }

  void _emitHistory(
    QuestionAnswerHistoryPage page,
    Emitter<AnswerHistoryState> emit,
  ) {
    if (page.answers.isEmpty) {
      emit(const AnswerHistoryEmpty());
      return;
    }

    emit(
      AnswerHistoryLoaded(
        sections: _groupHistoryByDate(page.answers, _questionsByCode),
        hasMore: page.hasMore,
      ),
    );
  }

  void _onObservationFailed(
    _AnswerHistoryObservationFailed event,
    Emitter<AnswerHistoryState> emit,
  ) {
    emit(AnswerHistoryFailure(event.error));
  }

  void _cancelHistoryWatch() {
    final subscription = _historySubscription;
    _historySubscription = null;
    if (subscription != null) {
      // Cancellation takes effect immediately for event delivery, while some
      // stream adapters complete their cleanup future on a later event turn.
      // The replacement read must not be blocked on that adapter detail.
      unawaited(subscription.cancel());
    }
  }

  @override
  Future<void> close() async {
    await _historySubscription?.cancel();
    return super.close();
  }
}

Map<String, Question> _indexQuestionsByCode(Iterable<Question> questions) {
  return Map.unmodifiable({
    for (final question in questions) question.code: question,
  });
}

List<AnswerHistorySection> _groupHistoryByDate(
  Iterable<QuestionAnswerRecord> answers,
  Map<String, Question> questionsByCode,
) {
  final entriesByDate = <DateTime, List<AnswerHistoryEntry>>{};

  // The persistence contract already supplies stable newest-first ordering.
  // Iterating directly avoids sorting the growing visible prefix again.
  for (final answer in answers) {
    // Persisted instants are presented and grouped in the device's local day.
    final answeredAt = answer.answeredAt.toLocal();
    final date = DateTime(answeredAt.year, answeredAt.month, answeredAt.day);
    entriesByDate
        .putIfAbsent(date, () => [])
        .add(
          AnswerHistoryEntry(
            answer: answer,
            question: questionsByCode[answer.questionCode],
          ),
        );
  }

  return [
    for (final entry in entriesByDate.entries)
      AnswerHistorySection(date: entry.key, entries: entry.value),
  ];
}
