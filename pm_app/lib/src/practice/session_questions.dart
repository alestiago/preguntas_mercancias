import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:pm_questions/pm_questions.dart';

import 'question_answer_presentation.dart';

@immutable
final class SessionQuestions extends Equatable {
  factory SessionQuestions({
    required Iterable<Question> questions,
    Map<String, QuestionAnswerPresentation> presentationsByQuestionCode =
        const {},
  }) {
    final frozenQuestions = List<Question>.unmodifiable(questions);
    return SessionQuestions._(
      questions: frozenQuestions,
      presentationsByQuestionCode:
          Map<String, QuestionAnswerPresentation>.unmodifiable({
            for (final question in frozenQuestions)
              question.code:
                  presentationsByQuestionCode[question.code] ??
                  QuestionAnswerPresentation.inSourceOrder(question),
          }),
    );
  }

  const SessionQuestions.empty()
    : questions = const [],
      presentationsByQuestionCode = const {};

  const SessionQuestions._({
    required this.questions,
    required this.presentationsByQuestionCode,
  });

  final List<Question> questions;
  final Map<String, QuestionAnswerPresentation> presentationsByQuestionCode;

  SessionQuestions append(SessionQuestions batch) {
    if (batch.questions.isEmpty) {
      return this;
    }
    return SessionQuestions(
      questions: [...questions, ...batch.questions],
      presentationsByQuestionCode: {
        ...presentationsByQuestionCode,
        ...batch.presentationsByQuestionCode,
      },
    );
  }

  @override
  List<Object?> get props => [
    SessionQuestions,
    questions,
    presentationsByQuestionCode,
  ];
}
