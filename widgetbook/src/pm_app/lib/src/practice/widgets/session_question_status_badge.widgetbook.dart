import 'package:flutter/material.dart';
import 'package:pm_app/component_library.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../../../support/use_case_frame.dart';

enum _BadgePresentation { navigation, summary }

final sessionQuestionStatusBadgeComponent = WidgetbookComponent(
  name: 'SessionQuestionStatusBadge',
  useCases: [
    WidgetbookUseCase(
      name: 'Interactive',
      builder: (context) {
        final status = context.knobs.object.segmented(
          label: 'Status',
          options: SessionQuestionStatus.values,
          labelBuilder: (status) => status.name,
        );
        final presentation = context.knobs.object.segmented(
          label: 'Presentation',
          options: _BadgePresentation.values,
          labelBuilder: (presentation) => presentation.name,
        );

        return UseCaseFrame(
          builder: (_) => switch (presentation) {
            _BadgePresentation.navigation =>
              SessionQuestionStatusBadge.navigation(status: status),
            _BadgePresentation.summary => SessionQuestionStatusBadge.summary(
              status: status,
            ),
          },
        );
      },
    ),
    WidgetbookUseCase(
      name: 'All statuses',
      builder: (_) => UseCaseFrame(
        builder: (_) => Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final status in SessionQuestionStatus.values)
              SessionQuestionStatusBadge.navigation(status: status),
            for (final status in SessionQuestionStatus.values)
              SessionQuestionStatusBadge.summary(status: status),
          ],
        ),
      ),
    ),
  ],
);
