import 'package:pm_app/component_library.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../../../support/callback_notification.dart';
import '../../../../../support/use_case_frame.dart';

final practiceSessionFooterComponent = WidgetbookComponent(
  name: 'PracticeSessionFooter',
  useCases: [
    WidgetbookUseCase(
      name: 'Interactive',
      builder: (context) {
        final primaryAction = context.knobs.object.segmented(
          label: 'Primary action',
          options: PracticePrimaryAction.values,
          initialOption: PracticePrimaryAction.next,
          labelBuilder: (action) => action.name,
        );
        final primaryEnabled = context.knobs.boolean(
          label: 'Primary enabled',
          initialValue: true,
        );
        final previousEnabled = context.knobs.boolean(
          label: 'Previous enabled',
          initialValue: true,
        );

        return UseCaseFrame(
          builder: (context) => PracticeSessionFooter(
            primaryAction: primaryAction,
            isPrimaryActionEnabled: primaryEnabled,
            isPreviousActionEnabled: previousEnabled,
            onPrimaryAction: () => showCallbackNotification(
              context,
              'onPrimaryAction',
              primaryAction.name,
            ),
            onPreviousQuestion: () =>
                showCallbackNotification(context, 'onPreviousQuestion'),
          ),
        );
      },
    ),
    WidgetbookUseCase(
      name: 'Disabled',
      builder: (_) => UseCaseFrame(
        builder: (context) => PracticeSessionFooter(
          primaryAction: PracticePrimaryAction.next,
          isPrimaryActionEnabled: false,
          isPreviousActionEnabled: false,
          onPrimaryAction: () =>
              showCallbackNotification(context, 'onPrimaryAction'),
          onPreviousQuestion: () =>
              showCallbackNotification(context, 'onPreviousQuestion'),
        ),
      ),
    ),
  ],
);
