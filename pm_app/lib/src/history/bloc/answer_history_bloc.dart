import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

part 'answer_history_event.dart';
part 'answer_history_state.dart';

final class AnswerHistoryBloc
    extends Bloc<AnswerHistoryEvent, AnswerHistoryState> {
  AnswerHistoryBloc({
    required QuestionProgressStore questionProgressStore,
    required Iterable<Question> questions,
  }) : _questionsByCode = _indexQuestionsByCode(questions),
       super(const AnswerHistoryLoading()) {
    _questionProgressStore = questionProgressStore;
    on<AnswerHistoryRetried>(_onRetried);
    on<_AnswerHistoryChanged>(_onHistoryChanged);
    on<_AnswerHistoryObservationFailed>(_onObservationFailed);

    _watchHistory();
  }

  late final QuestionProgressStore _questionProgressStore;
  final Map<String, Question> _questionsByCode;
  late final StreamSubscription<List<QuestionAnswerRecord>>
  _historySubscription;

  void _watchHistory() {
    _historySubscription = _questionProgressStore.watchAnswerHistory().listen(
      (answers) {
        if (!isClosed) {
          add(_AnswerHistoryChanged(List.unmodifiable(answers)));
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
    try {
      final answers = await _questionProgressStore.loadAnswerHistory();
      if (!emit.isDone) {
        _emitHistory(answers, emit);
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
    _emitHistory(event.answers, emit);
  }

  void _emitHistory(
    Iterable<QuestionAnswerRecord> answers,
    Emitter<AnswerHistoryState> emit,
  ) {
    if (answers.isEmpty) {
      emit(const AnswerHistoryEmpty());
      return;
    }

    emit(
      AnswerHistoryLoaded(
        sections: _groupHistoryByDate(answers, _questionsByCode),
      ),
    );
  }

  void _onObservationFailed(
    _AnswerHistoryObservationFailed event,
    Emitter<AnswerHistoryState> emit,
  ) {
    emit(AnswerHistoryFailure(event.error));
  }

  @override
  Future<void> close() async {
    await _historySubscription.cancel();
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
  final sortedAnswers = answers.toList(growable: false)
    ..sort((a, b) => b.answeredAt.compareTo(a.answeredAt));
  final entriesByDate = <DateTime, List<AnswerHistoryEntry>>{};

  for (final answer in sortedAnswers) {
    final answeredAt = answer.answeredAt;
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
