import 'package:flutter/material.dart';
import 'package:pm_app/component_library.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../../../support/callback_notification.dart';
import '../../../../../support/pm_app_assets.dart';

final onboardingViewComponent = WidgetbookComponent(
  name: 'OnboardingView',
  useCases: [
    WidgetbookUseCase(
      name: 'First launch',
      builder: (_) => PmAppAssets(
        child: Builder(
          builder: (context) => OnboardingView(
            steps: onboardingSteps(AppLocalizations.of(context)),
            onFinished: () => showCallbackNotification(context, 'onFinished'),
          ),
        ),
      ),
    ),
  ],
);
