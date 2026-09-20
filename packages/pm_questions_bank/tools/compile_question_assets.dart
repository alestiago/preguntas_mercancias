import 'dart:convert';
import 'dart:io';

import 'package:pm_questions/question_ingestion.dart';
import 'package:pm_questions_bank/question_bank_manifest.dart';

Future<void> main() async {
  final sourceDirectory = Directory(questionBankManifest.sourceDirectoryPath);
  final outputDirectory = Directory(questionBankManifest.outputDirectoryPath);
  final nonShuffleableCodes = await _readNonShuffleableCodes(
    File(questionBankManifest.nonShuffleableCodesPath),
  );
  final parser = QuestionTxtParser(nonShuffleableCodes: nonShuffleableCodes);
  final unmatchedCodes = Set<String>.of(nonShuffleableCodes);

  if (!sourceDirectory.existsSync()) {
    stderr.writeln('Source directory not found: ${sourceDirectory.path}');
    exitCode = 1;
    return;
  }

  await outputDirectory.create(recursive: true);

  for (final section in questionBankManifest.sections) {
    final sourceFile = File(questionBankManifest.sourceAssetPath(section));
    final outputFile = File(questionBankManifest.outputAssetPath(section));

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
      '${questionBankManifest.nonShuffleableCodesPath} did not match any '
      'question: '
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
