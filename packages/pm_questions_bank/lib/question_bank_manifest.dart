/// Metadata and deterministic asset paths for the bundled question bank.
final class QuestionBankManifest {
  const QuestionBankManifest._({required this.edition, required this.sections});

  final String edition;
  final List<String> sections;

  String get sourceDirectoryPath => 'assets/$edition';

  String get outputDirectoryPath => 'assets/${edition}_json';

  String get nonShuffleableCodesPath =>
      '$sourceDirectoryPath/non_shuffleable.txt';

  String sourceAssetPath(String section) {
    final normalizedSection = normalizeSection(section);
    return '$sourceDirectoryPath/pm$normalizedSection.txt';
  }

  String outputAssetPath(String section) {
    final normalizedSection = normalizeSection(section);
    return '$outputDirectoryPath/pm$normalizedSection.json';
  }

  String runtimeAssetPath(String section) {
    return 'packages/pm_questions_bank/${outputAssetPath(section)}';
  }

  String normalizeSection(String section) {
    final normalizedSection = section.trim().toUpperCase();
    if (!sections.contains(normalizedSection)) {
      throw ArgumentError.value(
        section,
        'section',
        'Expected one of: ${sections.join(', ')}.',
      );
    }
    return normalizedSection;
  }
}

const questionBankManifest = QuestionBankManifest._(
  edition: 'pm_260326',
  sections: ['1A', '1B', '1C', '1D', '1E', '1F', '1G', '1H'],
);
