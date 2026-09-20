import 'package:flutter/material.dart';
import 'package:pm_app/component_library.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../../../support/callback_notification.dart';
import '../../../../../support/use_case_frame.dart';

final exitPracticeIconButtonComponent = WidgetbookComponent(
  name: 'ExitPracticeIconButton',
  useCases: [
    WidgetbookUseCase(
      name: 'Confirmation flow',
      builder: (_) => UseCaseFrame(
        builder: (context) => Center(
          child: ExitPracticeIconButton(
            onPressed: () async {
              final confirmed = await showExitPracticeConfirmationDialog(
                context,
              );
              if (context.mounted && confirmed) {
                showCallbackNotification(context, 'onPressed');
              }
            },
          ),
        ),
      ),
    ),
  ],
);
