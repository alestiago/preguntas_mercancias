import 'dart:convert';
import 'dart:io';

import 'package:pm_questions_bank/src/parsers/question_txt_parser.dart';

const _sourceDirectoryPath = 'assets/pm_260326';
const _outputDirectoryPath = 'assets/pm_260326_json';
const _sections = ['1A', '1B', '1C', '1D', '1E', '1F', '1G', '1H'];

Future<void> main() async {
  final sourceDirectory = Directory(_sourceDirectoryPath);
  final outputDirectory = Directory(_outputDirectoryPath);
  final parser = QuestionTxtParser();

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
      '${encoder.convert(questions.map((question) => question.toJson()).toList())}\n',
    );

    stdout.writeln('Wrote ${questions.length} questions to ${outputFile.path}');
  }
}
