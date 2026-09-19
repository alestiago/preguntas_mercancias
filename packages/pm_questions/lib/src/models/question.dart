import 'package:equatable/equatable.dart';

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

final class QuestionAnswer extends Equatable {
  const QuestionAnswer({required this.option, required this.text});

  final QuestionOption option;
  final String text;

  @override
  List<Object?> get props => [QuestionAnswer, option, text];
}

/// A valid canonical question.
///
/// Direct construction enforces the domain invariants relied on by answer
/// lookup and presentation: non-blank fields, exactly one answer for every
/// option, non-blank answer text, and a present correct option.
final class Question extends Equatable {
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
    _requireNonBlank(code, 'code');
    _requireNonBlank(section, 'section');
    _requireNonBlank(prompt, 'prompt');
    _requireNonBlank(norma, 'norma');
    if (doctrinalReference != null) {
      _requireNonBlank(doctrinalReference, 'doctrinalReference');
    }

    final normalizedAnswers = List<QuestionAnswer>.unmodifiable(answers);
    if (normalizedAnswers.length != QuestionOption.values.length) {
      throw ArgumentError.value(
        normalizedAnswers,
        'answers',
        'Must contain exactly one answer for options A, B, C, and D.',
      );
    }

    final answerOptions = <QuestionOption>{};
    for (final answer in normalizedAnswers) {
      _requireNonBlank(answer.text, 'answers.${answer.option.code}.text');
      if (!answerOptions.add(answer.option)) {
        throw ArgumentError.value(
          normalizedAnswers,
          'answers',
          'Contains duplicate option ${answer.option.code}.',
        );
      }
    }
    if (!answerOptions.contains(correctOption)) {
      throw ArgumentError.value(
        correctOption,
        'correctOption',
        'Must identify one of the question answers.',
      );
    }

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

  QuestionAnswer get correctAnswer => answerFor(correctOption);

  /// Looks up an answer by its canonical identity.
  ///
  /// Returns `null` when the option is not part of this question. This is
  /// useful when displaying persisted data from a different bank edition.
  QuestionAnswer? answerForOrNull(QuestionOption option) {
    for (final answer in answers) {
      if (answer.option == option) {
        return answer;
      }
    }
    return null;
  }

  QuestionAnswer answerFor(QuestionOption option) {
    return answerForOrNull(option) ??
        (throw StateError(
          'Question $code does not contain option ${option.code}.',
        ));
  }

  bool isCorrect(QuestionOption option) {
    return option == correctOption;
  }

  @override
  List<Object?> get props => [
    Question,
    code,
    section,
    prompt,
    answers,
    correctOption,
    norma,
    doctrinalReference,
    shuffleable,
  ];
}

void _requireNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Must not be blank.');
  }
}
