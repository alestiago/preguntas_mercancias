import 'package:flutter/material.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../../l10n/app_localizations.dart';

class PracticeSectionSelector extends StatelessWidget {
  const PracticeSectionSelector({
    super.key,
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final String? selectedSection;
  final ValueChanged<String?> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            ChoiceChip(
              label: Text(localizations.allSections),
              selected: selectedSection == null,
              onSelected: (_) => onSectionSelected(null),
            ),
            const SizedBox(width: 8),
            for (final section in questionBankManifest.sections) ...[
              ChoiceChip(
                label: Text(section),
                selected: selectedSection == section,
                onSelected: (_) => onSectionSelected(section),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}
