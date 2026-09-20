import 'package:flutter/material.dart';
import 'package:pm_app/component_library.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../../../support/fixture_factory.dart';
import '../../../../../support/use_case_frame.dart';

enum _DatePreset { today, yesterday, older }

final answerHistoryDateHeaderComponent = WidgetbookComponent(
  name: 'AnswerHistoryDateHeader',
  useCases: [
    WidgetbookUseCase(
      name: 'Interactive',
      builder: (context) {
        final preset = context.knobs.object.segmented(
          label: 'Date',
          options: _DatePreset.values,
          labelBuilder: (preset) => preset.name,
        );
        final entryCount = context.knobs.int.slider(
          label: 'Entry count',
          initialValue: 4,
          min: 0,
          max: 20,
        );
        final now = DateTime.now();
        final date = switch (preset) {
          _DatePreset.today => now,
          _DatePreset.yesterday => now.subtract(const Duration(days: 1)),
          _DatePreset.older => DateTime(2026, 1, 15),
        };

        return UseCaseFrame(
          padding: EdgeInsets.zero,
          builder: (_) => AnswerHistoryDateHeader(
            section: WidgetbookFixtures.historySection(
              date: date,
              entryCount: entryCount,
            ),
          ),
        );
      },
    ),
  ],
);
