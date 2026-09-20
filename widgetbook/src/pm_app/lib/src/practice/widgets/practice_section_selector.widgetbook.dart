import 'package:flutter/material.dart';
import 'package:pm_app/component_library.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../../../support/callback_notification.dart';
import '../../../../../support/use_case_frame.dart';

final practiceSectionSelectorComponent = WidgetbookComponent(
  name: 'PracticeSectionSelector',
  useCases: [
    WidgetbookUseCase(
      name: 'Interactive',
      builder: (context) {
        final selectedSection = context.knobs.objectOrNull.dropdown(
          label: 'Selected section',
          options: questionBankManifest.sections,
          labelBuilder: (section) => section,
        );
        return _InteractiveSectionSelector(
          key: ValueKey(selectedSection),
          initialSection: selectedSection,
        );
      },
    ),
  ],
);

class _InteractiveSectionSelector extends StatefulWidget {
  const _InteractiveSectionSelector({super.key, required this.initialSection});

  final String? initialSection;

  @override
  State<_InteractiveSectionSelector> createState() =>
      _InteractiveSectionSelectorState();
}

class _InteractiveSectionSelectorState
    extends State<_InteractiveSectionSelector> {
  late String? _selectedSection = widget.initialSection;

  @override
  Widget build(BuildContext context) {
    return UseCaseFrame(
      padding: EdgeInsets.zero,
      builder: (context) => PracticeSectionSelector(
        selectedSection: _selectedSection,
        onSectionSelected: (section) {
          setState(() => _selectedSection = section);
          showCallbackNotification(
            context,
            'onSectionSelected',
            section ?? 'all sections',
          );
        },
      ),
    );
  }
}
