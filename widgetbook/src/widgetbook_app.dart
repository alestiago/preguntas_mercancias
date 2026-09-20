import 'package:flutter/material.dart';
import 'package:pm_app/component_library.dart';
import 'package:widgetbook/widgetbook.dart';

import 'widgetbook_directories.dart';

class PmWidgetbookApp extends StatelessWidget {
  const PmWidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: widgetbookDirectories,
      addons: [
        MaterialThemeAddon(
          themes: [WidgetbookTheme(name: 'Light', data: AppTheme.light)],
        ),
        LocalizationAddon(
          locales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          initialLocale: const Locale('es'),
        ),
        ViewportAddon([
          Viewports.none,
          AndroidViewports.samsungGalaxyS20,
          AndroidViewports.mediumTablet,
          MacosViewports.macbookPro,
        ]),
        TextScaleAddon(min: 1, max: 2, divisions: 4),
      ],
    );
  }
}
