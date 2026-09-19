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
    on<_AnswerHistoryChanged>(_onHistoryChanged);
    on<_AnswerHistoryObservationFailed>(_onObservationFailed);

    _historySubscription = questionProgressStore.watchAnswerHistory().listen(
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

  final Map<String, Question> _questionsByCode;
  late final StreamSubscription<List<QuestionAnswerRecord>>
  _historySubscription;

  void _onHistoryChanged(
    _AnswerHistoryChanged event,
    Emitter<AnswerHistoryState> emit,
  ) {
    if (event.answers.isEmpty) {
      emit(const AnswerHistoryEmpty());
      return;
    }

    emit(
      AnswerHistoryLoaded(
        sections: _groupHistoryByDate(event.answers, _questionsByCode),
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
