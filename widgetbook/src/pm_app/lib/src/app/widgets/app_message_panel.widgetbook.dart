import 'package:flutter/material.dart';
import 'package:pm_app/component_library.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../../../support/callback_notification.dart';
import '../../../../../support/use_case_frame.dart';

final appMessagePanelComponent = WidgetbookComponent(
  name: 'AppMessagePanel',
  useCases: [
    WidgetbookUseCase(
      name: 'Interactive',
      builder: (context) {
        final message = context.knobs.string(
          label: 'Message',
          initialValue: 'No se pudieron cargar las preguntas.',
        );
        final showAction = context.knobs.boolean(
          label: 'Show action',
          initialValue: true,
        );
        final icon = context.knobs.object.segmented(
          label: 'Icon',
          options: const [Icons.info_outline, Icons.warning_amber, Icons.error],
          initialOption: Icons.warning_amber,
          labelBuilder: (icon) => switch (icon) {
            Icons.info_outline => 'Info',
            Icons.error => 'Error',
            _ => 'Warning',
          },
        );
        final iconColor = context.knobs.color(
          label: 'Icon color',
          initialValue: Colors.orange,
        );

        return UseCaseFrame(
          builder: (context) => AppMessagePanel(
            message: message,
            icon: icon,
            iconColor: iconColor,
            actionLabel: showAction ? 'Reintentar' : null,
            onAction: showAction
                ? () => showCallbackNotification(context, 'onAction')
                : null,
          ),
        );
      },
    ),
    WidgetbookUseCase.child(
      name: 'Long message',
      child: const UseCaseFrame(builder: _buildLongMessagePanel),
    ),
  ],
);

Widget _buildLongMessagePanel(BuildContext context) {
  return const AppMessagePanel(
    message: 'No se pudo completar la operación. Comprueba la conexión y vuelve a intentarlo cuando estés preparado.',
    icon: Icons.cloud_off,
  );
}
