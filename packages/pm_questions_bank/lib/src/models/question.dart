import 'package:collection/collection.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

const _nonBlankPattern = r'\S';
const _optionCodes = ['A', 'B', 'C', 'D'];
const _questionAnswerListEquality = ListEquality<QuestionAnswer>();

enum QuestionOption {
  a,
  b,
  c,
  d;

  factory QuestionOption.fromCode(String code) {
    return switch (code.trim().toUpperCase()) {
      'A' => QuestionOption.a,
      'B' => QuestionOption.b,
      'C' => QuestionOption.c,
      'D' => QuestionOption.d,
      _ => throw FormatException('Unknown question option: $code'),
    };
  }

  String get code => name.toUpperCase();
}

final class QuestionAnswer {
  const QuestionAnswer({required this.option, required this.text});

  final QuestionOption option;
  final String text;

  static final Schema jsonSchema = S.object(
    required: ['option', 'text'],
    additionalProperties: false,
    properties: {
      'option': S.string(enumValues: _optionCodes),
      'text': S.string(pattern: _nonBlankPattern),
    },
  );

  Map<String, Object?> toJson() {
    return {'option': option.code, 'text': text};
  }

  static Future<QuestionAnswer> fromJson(Map<String, Object?> json) async {
    await _throwIfInvalid(jsonSchema, json);
    return QuestionAnswer._fromValidatedJson(json);
  }

  factory QuestionAnswer._fromValidatedJson(Map<String, Object?> json) {
    return QuestionAnswer(
      option: QuestionOption.fromCode(json['option'] as String),
      text: json['text'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuestionAnswer &&
            runtimeType == other.runtimeType &&
            option == other.option &&
            text == other.text;
  }

  @override
  int get hashCode => Object.hash(option, text);
}

final class Question {
  factory Question({
    required String code,
    required String section,
    required String prompt,
    required Iterable<QuestionAnswer> answers,
    required QuestionOption correctOption,
    required String norma,
    String? doctrinalReference,
    bool shuffleable = true,
  }) {
    final normalizedAnswers = List<QuestionAnswer>.unmodifiable(answers);

    return Question._(
      code: code,
      section: section,
      prompt: prompt,
      answers: normalizedAnswers,
      correctOption: correctOption,
      norma: norma,
      doctrinalReference: doctrinalReference,
      shuffleable: shuffleable,
    );
  }

  const Question._({
    required this.code,
    required this.section,
    required this.prompt,
    required this.answers,
    required this.correctOption,
    required this.norma,
    required this.doctrinalReference,
    required this.shuffleable,
  });

  final String code;
  final String section;
  final String prompt;
  final List<QuestionAnswer> answers;
  final QuestionOption correctOption;
  final String norma;
  final String? doctrinalReference;

  /// Whether the answers can be presented in a random order.
  ///
  /// Some answers reference other options positionally (e.g. "Todas las
  /// anteriores" or "Las respuestas A y B son correctas"), so shuffling
  /// them would make the question incoherent.
  final bool shuffleable;

  static final Schema jsonSchema = S.object(
    required: [
      'code',
      'section',
      'prompt',
      'answers',
      'correctOption',
      'norma',
    ],
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

  QuestionAnswer get correctAnswer => answerFor(correctOption);

  QuestionAnswer answerFor(QuestionOption option) {
    return answers.firstWhere((answer) => answer.option == option);
  }

  bool isCorrect(QuestionOption option) {
    return option == correctOption;
  }

  Map<String, Object?> toJson() {
    return {
      'code': code,
      'section': section,
      'prompt': prompt,
      'answers': answers.map((answer) => answer.toJson()).toList(),
      'correctOption': correctOption.code,
      'norma': norma,
      if (doctrinalReference != null) 'doctrinalReference': doctrinalReference,
      if (!shuffleable) 'shuffleable': shuffleable,
    };
  }

  static Future<Question> fromJson(Map<String, Object?> json) async {
    await _throwIfInvalid(jsonSchema, json);
    return Question._fromValidatedJson(json);
  }

  factory Question._fromValidatedJson(Map<String, Object?> json) {
    final rawAnswers = json['answers'] as List<Object?>;

    return Question(
      code: json['code'] as String,
      section: json['section'] as String,
      prompt: json['prompt'] as String,
      answers: rawAnswers.cast<Map<String, Object?>>().map(
        QuestionAnswer._fromValidatedJson,
      ),
      correctOption: QuestionOption.fromCode(json['correctOption'] as String),
      norma: json['norma'] as String,
      doctrinalReference: json['doctrinalReference'] as String?,
      shuffleable: json['shuffleable'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Question &&
            runtimeType == other.runtimeType &&
            code == other.code &&
            section == other.section &&
            prompt == other.prompt &&
            _questionAnswerListEquality.equals(answers, other.answers) &&
            correctOption == other.correctOption &&
            norma == other.norma &&
            doctrinalReference == other.doctrinalReference &&
            shuffleable == other.shuffleable;
  }

  @override
  int get hashCode => Object.hash(
    code,
    section,
    prompt,
    Object.hashAll(answers),
    correctOption,
    norma,
    doctrinalReference,
    shuffleable,
  );
}

final Schema _answersSchema = S.combined(
  allOf: [
    S.list(
      items: QuestionAnswer.jsonSchema,
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

Future<void> _throwIfInvalid(Schema schema, Map<String, Object?> json) async {
  final errors = await schema.validate(json);
  if (errors.isEmpty) {
    return;
  }

  throw FormatException(
    errors.map((error) => error.toErrorString()).join('\n'),
  );
}
