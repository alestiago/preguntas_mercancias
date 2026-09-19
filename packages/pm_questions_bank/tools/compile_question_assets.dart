import 'dart:convert';
import 'dart:io';

import 'package:pm_questions/question_ingestion.dart';

const _sourceDirectoryPath = 'assets/pm_260326';
const _outputDirectoryPath = 'assets/pm_260326_json';
const _sections = ['1A', '1B', '1C', '1D', '1E', '1F', '1G', '1H'];
const _nonShuffleableCodesPath = 'assets/pm_260326/non_shuffleable.txt';

Future<void> main() async {
  final sourceDirectory = Directory(_sourceDirectoryPath);
  final outputDirectory = Directory(_outputDirectoryPath);
  final nonShuffleableCodes = await _readNonShuffleableCodes(
    File(_nonShuffleableCodesPath),
  );
  final parser = QuestionTxtParser(nonShuffleableCodes: nonShuffleableCodes);
  final unmatchedCodes = Set<String>.of(nonShuffleableCodes);

  if (!sourceDirectory.existsSync()) {
    stderr.writeln('Source directory not found: ${sourceDirectory.path}');
    exitCode = 1;
    return;
  }

  await outputDirectory.create(recursive: true);

  for (final section in _sections) {
    final sourceFile = File('${sourceDirectory.path}/pm$section.txt');
    final outputFile = File('${outputDirectory.path}/pm$section.json');

    if (!sourceFile.existsSync()) {
      stderr.writeln('Source file not found: ${sourceFile.path}');
      exitCode = 1;
      return;
    }

    final questions = await parser.parse(await sourceFile.readAsString());
    const encoder = JsonEncoder.withIndent('  ');
    await outputFile.writeAsString(
      '${encoder.convert(questions.map(QuestionJsonCodec.encode).toList())}\n',
    );
    unmatchedCodes.removeAll(questions.map((question) => question.code));

    stdout.writeln('Wrote ${questions.length} questions to ${outputFile.path}');
  }

  if (unmatchedCodes.isNotEmpty) {
    stderr.writeln(
      'Warning: ${unmatchedCodes.length} code(s) in '
      '$_nonShuffleableCodesPath did not match any question: '
      '${(unmatchedCodes.toList()..sort()).join(', ')}',
    );
  }
}

Future<Set<String>> _readNonShuffleableCodes(File file) async {
  if (!file.existsSync()) {
    return {};
  }

  final lines = await file.readAsLines();
  return {for (final rawLine in lines) ?_codeFromLine(rawLine)};
}

String? _codeFromLine(String rawLine) {
  final line = rawLine.trim();
  if (line.isEmpty || line.startsWith('#')) {
    return null;
  }

  return line;
}
