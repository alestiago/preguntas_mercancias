import 'package:pm_questions/pm_questions.dart';
import 'package:test/test.dart';

const _unspecified = Object();

Matcher isAQuestion({
  Object? code = _unspecified,
  Object? section = _unspecified,
  Object? prompt = _unspecified,
  Object? answers = _unspecified,
  Object? correctOption = _unspecified,
  Object? norma = _unspecified,
  Object? doctrinalReference = _unspecified,
  Object? shuffleable = _unspecified,
  Object? correctAnswer = _unspecified,
}) {
  return isA<Question>()
      .having((question) => question.code, 'code', _orAnything(code))
      .having((question) => question.section, 'section', _orAnything(section))
      .having((question) => question.prompt, 'prompt', _orAnything(prompt))
      .having((question) => question.answers, 'answers', _orAnything(answers))
      .having(
        (question) => question.correctOption,
        'correctOption',
        _orAnything(correctOption),
      )
      .having((question) => question.norma, 'norma', _orAnything(norma))
      .having(
        (question) => question.doctrinalReference,
        'doctrinalReference',
        _orAnything(doctrinalReference),
      )
      .having(
        (question) => question.shuffleable,
        'shuffleable',
        _orAnything(shuffleable),
      )
      .having(
        (question) => question.correctAnswer,
        'correctAnswer',
        _orAnything(correctAnswer),
      );
}

Matcher isAQuestionAnswer({
  Object? option = _unspecified,
  Object? text = _unspecified,
}) {
  return isA<QuestionAnswer>()
      .having((answer) => answer.option, 'option', _orAnything(option))
      .having((answer) => answer.text, 'text', _orAnything(text));
}

Object? _orAnything(Object? matcher) {
  return identical(matcher, _unspecified) ? anything : matcher;
}
