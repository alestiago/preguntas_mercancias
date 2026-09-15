import '../models/models.dart';

final class QuestionTxtParser {
  const QuestionTxtParser({this.nonShuffleableCodes = const {}});

  /// Codes of questions whose answers must never be shuffled.
  ///
  /// Some answers reference other options positionally (e.g. "Todas las
  /// anteriores" or "Las respuestas A y B son correctas"), so shuffling
  /// them would make the question incoherent.
  final Set<String> nonShuffleableCodes;

  Future<List<Question>> parse(String source) async {
    final records = _parseRecords(source);
    final questions = <Question>[];

    for (final record in records) {
      questions.add(await _questionFromRecord(record));
    }

    return List.unmodifiable(questions);
  }

  List<Map<String, String>> _parseRecords(String source) {
    final records = <Map<String, String>>[];
    var currentRecord = <String, String>{};
    String? currentLabel;

    for (final rawLine in source.split('\n')) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty) {
        continue;
      }

      final match = _fieldPattern.firstMatch(line);
      if (match != null) {
        final label = match.group(1)!;
        final value = match.group(2)!.trim();

        if (label == _Field.code.label && currentRecord.isNotEmpty) {
          records.add(currentRecord);
          currentRecord = <String, String>{};
        }

        currentRecord[label] = value;
        currentLabel = label;
        continue;
      }

      if (currentLabel == null) {
        throw FormatException('Unexpected line without a field label: $line');
      }

      currentRecord[currentLabel] = _appendContinuation(
        currentRecord[currentLabel],
        line.trim(),
      );
    }

    if (currentRecord.isNotEmpty) {
      records.add(currentRecord);
    }

    return records;
  }

  Future<Question> _questionFromRecord(Map<String, String> record) async {
    final code = record[_Field.code.label];
    final json = <String, Object?>{
      'code': code,
      'section': code == null ? null : _sectionFromCode(code),
      'prompt': record[_Field.prompt.label],
      'answers': [
        for (final option in QuestionOption.values)
          if (record.containsKey(option.code))
            {'option': option.code, 'text': record[option.code]},
      ],
      'correctOption': record[_Field.solution.label],
      'norma': record[_Field.norma.label],
      if (record.containsKey(_Field.doctrinalReference.label))
        'doctrinalReference': record[_Field.doctrinalReference.label],
      if (code != null && nonShuffleableCodes.contains(code))
        'shuffleable': false,
    };

    try {
      return await Question.fromJson(json);
    } on FormatException catch (error) {
      throw FormatException('Invalid question record for "$code": $error');
    }
  }
}

enum _Field {
  code('COD'),
  prompt('PREGUNTA'),
  solution('SOLUCION'),
  norma('NORMA'),
  doctrinalReference('REFERENCIA DOCTRINAL');

  const _Field(this.label);

  final String label;
}

final _fieldPattern = RegExp(
  r'^(COD|PREGUNTA|A|B|C|D|SOLUCION|NORMA|REFERENCIA DOCTRINAL):\s*(.*)$',
);

String _appendContinuation(String? currentValue, String continuation) {
  if (currentValue == null || currentValue.isEmpty) {
    return continuation;
  }

  return '$currentValue\n$continuation';
}

String _sectionFromCode(String code) {
  final match = RegExp(r'^(\d+[A-Z])').firstMatch(code.trim().toUpperCase());
  return match?.group(1) ?? code.trim();
}
