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

        // The road fills its box and paints no background; in the app it sits
        // in the onboarding band, so mimic that here.
        return PmAppAssets(
          child: UseCaseFrame(
            builder: (context) => ColoredBox(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: SizedBox(
                width: 360,
                height: 380,
                child: OnboardingRoad(page: page, pageCount: pageCount),
              ),
            ),
          ),
        );
      },
    ),
  ],
);
