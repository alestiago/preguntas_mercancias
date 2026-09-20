import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import '../src/widgetbook_app.dart';
import '../src/widgetbook_directories.dart';

void main() {
  testWidgets('builds the Widgetbook application', (tester) async {
    await tester.pumpWidget(const PmWidgetbookApp());
    await tester.pump();

    expect(find.byType(Widgetbook), findsOneWidget);
  });

  test('registers the mirrored pm_app directory tree', () {
    expect(widgetbookDirectories, hasLength(1));
    expect(widgetbookDirectories.single.name, 'pm_app');
    expect(widgetbookDirectories.single.children!.single.name, 'lib');
  });
}
