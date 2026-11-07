# widgetbook: agent notes

See [README.md](README.md) and [the original plan](../plans/archive/WIDGETBOOK_PLAN.md).

- Use cases mirror production paths:
  `pm_app/lib/src/home/widgets/foo.dart` maps to
  `src/pm_app/lib/src/home/widgets/foo.widgetbook.dart`.
- Import real widgets through `package:pm_app/component_library.dart`. Never
  copy widget code here.
- Callbacks show a SnackBar naming the callback and its value. Reuse the
  helpers in `src/support/`.
- Add knobs only for inputs that change how the widget looks or behaves.
- Widgets that load `pm_app` assets (SVGs, images) need `PmAppAssets`
  (`src/support/pm_app_assets.dart`) around them, or the assets fail to load
  here even though they work in the app.
- Register new use cases in `src/widgetbook_directories.dart`.
  `test/widgetbook_app_test.dart` checks that the catalog builds.

Check: `fvm exec ../tool/verify.sh --only widgetbook`.
