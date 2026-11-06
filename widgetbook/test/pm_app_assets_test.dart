import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/component_library.dart';

import '../src/support/pm_app_assets.dart';

void main() {
  testWidgets('loads pm_app assets by their app-relative path', (tester) async {
    late AssetBundle bundle;
    await tester.pumpWidget(
      PmAppAssets(
        child: Builder(
          builder: (context) {
            bundle = DefaultAssetBundle.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    for (final asset in [OnboardingRoad.bodyAsset, OnboardingRoad.wheelAsset]) {
      final data = await tester.runAsync(() => bundle.load(asset));
      expect(data!.lengthInBytes, greaterThan(0), reason: asset);
    }
  });
}
