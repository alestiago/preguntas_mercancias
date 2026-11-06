import 'package:flutter/material.dart';
import 'package:pm_app/component_library.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../../../support/pm_app_assets.dart';
import '../../../../../support/use_case_frame.dart';

final onboardingRoadComponent = WidgetbookComponent(
  name: 'OnboardingRoad',
  useCases: [
    WidgetbookUseCase(
      name: 'Interactive',
      builder: (context) {
        const pageCount = 4;
        final page = context.knobs.double.slider(
          label: 'Page',
          description: 'Fractional page, as while swiping',
          max: pageCount - 1,
          precision: 2,
        );

        return PmAppAssets(
          child: UseCaseFrame(
            builder: (_) => ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: OnboardingRoad(page: page, pageCount: pageCount),
            ),
          ),
        );
      },
    ),
  ],
);
