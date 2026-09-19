import 'package:json_schema_builder/json_schema_builder.dart';

import '../models/question.dart';

const _nonBlankPattern = r'\S';
const _optionCodes = ['A', 'B', 'C', 'D'];

/// Validates and maps questions at the JSON ingestion boundary.
abstract final class QuestionJsonCodec {
  static Future<Question> decode(Map<String, Object?> json) async {
    await _throwIfInvalid(_questionSchema, json);
    final rawAnswers = json['answers']! as List<Object?>;

    return Question(
      code: json['code']! as String,
      section: json['section']! as String,
      prompt: json['prompt']! as String,
      answers: rawAnswers.cast<Map<String, Object?>>().map(_decodeAnswer),
      correctOption: QuestionOption.fromCode(json['correctOption']! as String),
      norma: json['norma']! as String,
      doctrinalReference: json['doctrinalReference'] as String?,
      shuffleable: json['shuffleable'] as bool? ?? true,
    );
  }

  static Map<String, Object?> encode(Question question) {
    return {
      'code': question.code,
      'section': question.section,
      'prompt': question.prompt,
      'answers': question.answers.map(_encodeAnswer).toList(),
      'correctOption': question.correctOption.code,
      'norma': question.norma,
      if (question.doctrinalReference != null)
        'doctrinalReference': question.doctrinalReference,
      if (!question.shuffleable) 'shuffleable': question.shuffleable,
    };
  }

  static QuestionAnswer _decodeAnswer(Map<String, Object?> json) {
    return QuestionAnswer(
      option: QuestionOption.fromCode(json['option']! as String),
      text: json['text']! as String,
    );
  }

  static Map<String, Object?> _encodeAnswer(QuestionAnswer answer) {
    return {'option': answer.option.code, 'text': answer.text};
  }
}

final Schema _answerSchema = S.object(
  required: ['option', 'text'],
  additionalProperties: false,
  properties: {
    'option': S.string(enumValues: _optionCodes),
    'text': S.string(pattern: _nonBlankPattern),
  },
);

final Schema _answersSchema = S.combined(
  allOf: [
    S.list(
      items: _answerSchema,
      minItems: _optionCodes.length,
      maxItems: _optionCodes.length,
    ),
    for (final optionCode in _optionCodes)
      S.list(
        contains: S.object(
          required: ['option'],
          properties: {'option': S.string(constValue: optionCode)},
        ),
        minContains: 1,
        maxContains: 1,
      ),
  ],
);

final Schema _questionSchema = S.object(
  required: ['code', 'section', 'prompt', 'answers', 'correctOption', 'norma'],
  additionalProperties: false,
  properties: {
    'code': S.string(pattern: _nonBlankPattern),
    'section': S.string(pattern: _nonBlankPattern),
    'prompt': S.string(pattern: _nonBlankPattern),
    'answers': _answersSchema,
    'correctOption': S.string(enumValues: _optionCodes),
    'norma': S.string(pattern: _nonBlankPattern),
    'doctrinalReference': S.string(pattern: _nonBlankPattern),
    'shuffleable': S.boolean(),
  },
);

Future<void> _throwIfInvalid(Schema schema, Map<String, Object?> json) async {
  final errors = await schema.validate(json);
  if (errors.isEmpty) {
    return;
  }

  throw FormatException(
    errors.map((error) => error.toErrorString()).join('\n'),
  );
}
