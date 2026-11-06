import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/onboarding/widgets/onboarding_road.dart';

import '../../../helpers/pump_app.dart';

/// The rotation a `Transform.rotate` applies, as (cos, sin).
(double, double) rotationOf(WidgetTester tester, Finder finder) {
  final storage = tester.widget<Transform>(finder).transform.storage;
  return (storage[0], storage[1]);
}

Finder svgAsset(String asset) => find.byWidgetPredicate(
  (widget) =>
      widget is SvgPicture &&
      widget.bytesLoader is SvgAssetLoader &&
      (widget.bytesLoader as SvgAssetLoader).assetName == asset,
);

void main() {
  group('OnboardingRoadGeometry', () {
    test('one page travels one window width', () {
      expect(const OnboardingRoadGeometry(0).distance, 0);
      expect(
        const OnboardingRoadGeometry(1).distance,
        OnboardingRoadGeometry.viewWidth,
      );
      expect(
        const OnboardingRoadGeometry(2.5).distance,
        OnboardingRoadGeometry.viewWidth * 2.5,
      );
    });

    test('wheels roll without slipping', () {
      const geometry = OnboardingRoadGeometry(1.25);

      expect(
        geometry.wheelAngle * OnboardingRoadGeometry.wheelRadius,
        closeTo(geometry.distance, 1e-9),
      );
    });

    test('going back turns the wheels back', () {
      expect(
        const OnboardingRoadGeometry(0.5).wheelAngle,
        lessThan(const OnboardingRoadGeometry(1).wheelAngle),
      );
    });

    test('the body only bobs between pages', () {
      expect(const OnboardingRoadGeometry(0).bodyBounce, 0);
      expect(const OnboardingRoadGeometry(2).bodyBounce, 0);
      expect(const OnboardingRoadGeometry(0.5).bodyBounce, isNot(0));
      expect(
        const OnboardingRoadGeometry(0.5).bodyBounce.abs(),
        lessThanOrEqualTo(1.6),
      );
    });

    test('highlights the milestone of the nearest page', () {
      expect(const OnboardingRoadGeometry(0.4).highlightedMilestone, 0);
      expect(const OnboardingRoadGeometry(0.6).highlightedMilestone, 1);
    });

    test(
      'the current milestone stands ahead of the cab, inside the window',
      () {
        for (var page = 0; page < 4; page++) {
          final visibleX =
              OnboardingRoadGeometry.milestoneX(page) -
              OnboardingRoadGeometry.viewLeft -
              OnboardingRoadGeometry(page.toDouble()).distance;

          expect(
            visibleX,
            greaterThan(
              OnboardingRoadGeometry.bodyWidth -
                  OnboardingRoadGeometry.viewLeft,
            ),
          );
          expect(visibleX, lessThan(OnboardingRoadGeometry.viewWidth));
        }
      },
    );
  });

  group('OnboardingRoad', () {
    Future<void> pumpRoad(
      WidgetTester tester, {
      required double page,
      bool disableAnimations = false,
    }) async {
      await tester.pumpLocalizedPage(
        MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Center(
            child: SizedBox(
              width: 360,
              child: OnboardingRoad(page: page, pageCount: 4),
            ),
          ),
        ),
      );
    }

    testWidgets('draws the body and three wheels', (tester) async {
      await pumpRoad(tester, page: 0);

      expect(svgAsset(OnboardingRoad.bodyAsset), findsOneWidget);
      expect(svgAsset(OnboardingRoad.wheelAsset), findsNWidgets(3));
      expect(tester.getSize(find.byType(OnboardingRoad)), const Size(360, 270));
    });

    testWidgets('turns every wheel by the distance travelled', (tester) async {
      await pumpRoad(tester, page: 1.5);
      const angle = OnboardingRoadGeometry(1.5);

      for (var index = 0; index < 3; index++) {
        final (cos, sin) = rotationOf(
          tester,
          find.byKey(ValueKey('onboarding-road-wheel-$index')),
        );
        expect(cos, closeTo(math.cos(angle.wheelAngle), 1e-6));
        expect(sin, closeTo(math.sin(angle.wheelAngle), 1e-6));
      }
    });

    testWidgets('scrolls the ground with the page', (tester) async {
      await pumpRoad(tester, page: 1.5);

      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('onboarding-road-ground')),
                  )
                  .painter!
              as OnboardingRoadPainter;
      expect(painter.distance, OnboardingRoadGeometry.viewWidth * 1.5);
      expect(painter.highlightedMilestone, 2);
      expect(painter.milestoneCount, 4);
    });

    testWidgets('keeps the body still when animations are disabled', (
      tester,
    ) async {
      await pumpRoad(tester, page: 0);
      final restingTop = tester
          .getTopLeft(svgAsset(OnboardingRoad.bodyAsset))
          .dy;

      await pumpRoad(tester, page: 0.5, disableAnimations: true);

      expect(
        tester.getTopLeft(svgAsset(OnboardingRoad.bodyAsset)).dy,
        restingTop,
      );
    });

    testWidgets('bobs the body between pages', (tester) async {
      await pumpRoad(tester, page: 0);
      final restingTop = tester
          .getTopLeft(svgAsset(OnboardingRoad.bodyAsset))
          .dy;

      await pumpRoad(tester, page: 0.5);

      expect(
        tester.getTopLeft(svgAsset(OnboardingRoad.bodyAsset)).dy,
        isNot(restingTop),
      );
    });
  });
}
