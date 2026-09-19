// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/practice_question_policy.dart';
import 'package:pm_app/src/practice/practice_session_config.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

const _questionCount = 4475;
const _measurementRuns = 9;

void main() {
  test('R26 filtered navigation benchmark', _runBenchmark);
}

void _runBenchmark() {
  const policy = PracticeQuestionPolicy();
  final questions = _buildQuestions();
  final progressSnapshot = _buildProgress(questions);
  final remainingQuestions = policy.selectEligible(
    questions: questions,
    mode: PracticeMode.pending,
    progressSnapshot: progressSnapshot,
  );
  final currentIndex = questions.length ~/ 2 - 1;

  _legacyNextIndex(questions, remainingQuestions, currentIndex);
  policy.nextEligibleIndex(
    questions: questions,
    currentIndex: currentIndex,
    mode: PracticeMode.pending,
    progressSnapshot: progressSnapshot,
  );

  final legacy = _medianMicros(
    () => _legacyNextIndex(questions, remainingQuestions, currentIndex),
  );
  final linear = _medianMicros(
    () => policy.nextEligibleIndex(
      questions: questions,
      currentIndex: currentIndex,
      mode: PracticeMode.pending,
      progressSnapshot: progressSnapshot,
    ),
  );

  print('questions=$_questionCount eligible=${remainingQuestions.length}');
  print('legacyMedianMicros=$legacy');
  print('linearMedianMicros=$linear');
  print('speedup=${(legacy / linear).toStringAsFixed(1)}x');
}

int _legacyNextIndex(
  List<Question> questions,
  List<Question> remainingQuestions,
  int currentIndex,
) {
  final nextQuestion = remainingQuestions.firstWhere(
    (question) => questions.indexOf(question) > currentIndex,
    orElse: () => remainingQuestions.first,
  );
  return questions.indexOf(nextQuestion);
}

List<Question> _buildQuestions() {
  const answers = [
    QuestionAnswer(option: QuestionOption.a, text: 'A'),
    QuestionAnswer(option: QuestionOption.b, text: 'B'),
    QuestionAnswer(option: QuestionOption.c, text: 'C'),
    QuestionAnswer(option: QuestionOption.d, text: 'D'),
  ];
  return List.generate(
    _questionCount,
    (index) => Question(
      code: 'Q${index.toString().padLeft(6, '0')}',
      section: '1A',
      prompt: 'Question $index',
      answers: answers,
      correctOption: QuestionOption.a,
      norma: 'Benchmark',
    ),
    growable: false,
  );
}

QuestionProgressSnapshot _buildProgress(List<Question> questions) {
  final answeredAt = DateTime.utc(2026);
  return QuestionProgressSnapshot(
    byQuestionCode: {
      for (final question in questions.skip(questions.length ~/ 2))
        question.code: QuestionProgress(
          questionCode: question.code,
          section: question.section,
          lastSelectedOption: QuestionOption.a,
          correctOption: QuestionOption.a,
          lastAnswerWasCorrect: true,
          attempts: 1,
          correctAttempts: 1,
          incorrectAttempts: 0,
          firstAnsweredAt: answeredAt,
          lastAnsweredAt: answeredAt,
        ),
    },
  );
}

int _medianMicros(int? Function() operation) {
  final measurements = <int>[];
  var checksum = 0;
  for (var run = 0; run < _measurementRuns; run += 1) {
    final stopwatch = Stopwatch()..start();
    checksum += operation() ?? -1;
    stopwatch.stop();
    measurements.add(stopwatch.elapsedMicroseconds);
  }
  if (checksum == -_measurementRuns) {
    throw StateError('The benchmark found no eligible question.');
  }
  measurements.sort();
  return measurements[measurements.length ~/ 2];
}
