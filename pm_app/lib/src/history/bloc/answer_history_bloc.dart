import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
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
    required QuestionCatalog catalog,
    int pageSize = 100,
  }) : _questionsByCode = catalog.byCode,
       _pageSize = pageSize,
       _visibleLimit = pageSize,
       assert(pageSize > 0),
       super(const AnswerHistoryLoading()) {
    _questionProgressStore = questionProgressStore;
    on<AnswerHistoryRetried>(_onRetried);
    on<AnswerHistoryMoreRequested>(_onMoreRequested);
    on<_AnswerHistoryObservationRequested>(
      _onObservationRequested,
      transformer: restartable(),
    );

    add(_AnswerHistoryObservationRequested(_visibleLimit));
  }

  late final QuestionProgressStore _questionProgressStore;
  final Map<String, Question> _questionsByCode;
  final int _pageSize;
  int _visibleLimit;

  void _onRetried(
    AnswerHistoryRetried event,
    Emitter<AnswerHistoryState> emit,
  ) {
    emit(const AnswerHistoryLoading());
    add(_AnswerHistoryObservationRequested(_visibleLimit));
  }

  void _onMoreRequested(
    AnswerHistoryMoreRequested event,
    Emitter<AnswerHistoryState> emit,
  ) {
    final currentState = state;
    if (currentState is! AnswerHistoryLoaded ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));
    _visibleLimit += _pageSize;
    add(_AnswerHistoryObservationRequested(_visibleLimit));
  }

  Future<void> _onObservationRequested(
    _AnswerHistoryObservationRequested event,
    Emitter<AnswerHistoryState> emit,
  ) {
    return emit.forEach<QuestionAnswerHistoryPage>(
      _questionProgressStore.watchAnswerHistory(limit: event.limit),
      onData: _stateForHistory,
      onError: (error, stackTrace) {
        addError(error, stackTrace);
        return AnswerHistoryFailure(error);
      },
    );
  }

  AnswerHistoryState _stateForHistory(QuestionAnswerHistoryPage page) {
    if (page.answers.isEmpty) {
      return const AnswerHistoryEmpty();
    }

    return AnswerHistoryLoaded(
      sections: _groupHistoryByDate(page.answers, _questionsByCode),
      hasMore: page.hasMore,
    );
  }
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
