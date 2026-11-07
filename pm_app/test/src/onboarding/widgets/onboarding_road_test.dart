import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/onboarding/widgets/onboarding_road.dart';

import '../../../helpers/pump_app.dart';

const _phoneBand = Size(360, 380);
const _tabletBand = Size(1200, 420);

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
    OnboardingRoadGeometry at(double page, [Size size = _phoneBand]) =>
        OnboardingRoadGeometry(page: page, size: size);

    test('one page travels one window width', () {
      expect(at(0).distance, 0);
      expect(at(1).distance, at(1).viewWidth);
      expect(at(2.5).distance, at(2.5).viewWidth * 2.5);
    });

    test('wheels roll without slipping', () {
      final geometry = at(1.25);

      expect(
        geometry.wheelAngle * OnboardingRoadGeometry.wheelRadius,
        closeTo(geometry.distance, 1e-9),
      );
    });

    test('going back turns the wheels back', () {
      expect(at(0.5).wheelAngle, lessThan(at(1).wheelAngle));
    });

    test('the body only bobs between pages', () {
      expect(at(0).bodyBounce, 0);
      expect(at(2).bodyBounce, 0);
      expect(at(0.5).bodyBounce, isNot(0));
      expect(at(0.5).bodyBounce.abs(), lessThanOrEqualTo(1.6));
    });

    test('highlights the milestone of the nearest page', () {
      expect(at(0.4).highlightedMilestone, 0);
      expect(at(0.6).highlightedMilestone, 1);
    });

    for (final (name, size) in [
      ('phone', _phoneBand),
      ('tablet', _tabletBand),
    ]) {
      test('fits the truck and its milestone inside a $name band', () {
        final geometry = at(0, size);
        final truckLeft = geometry.toLocal(Offset.zero);
        final truckBottomRight = geometry.toLocal(
          const Offset(
            OnboardingRoadGeometry.bodyWidth,
            OnboardingRoadGeometry.bodyHeight,
          ),
        );
        final milestoneRight = geometry
            .toLocal(
              Offset(
                geometry.milestoneX(0) +
                    OnboardingRoadGeometry.milestoneHalfWidth,
                0,
              ),
            )
            .dx;

        expect(truckLeft.dx, greaterThan(0));
        expect(truckLeft.dy, greaterThan(0));
        expect(truckBottomRight.dy, lessThan(size.height));
        expect(milestoneRight, lessThan(size.width));
        // Centred: the same margin on both sides.
        expect(truckLeft.dx, closeTo(size.width - milestoneRight, 0.01));
      });
    }

    test('the current milestone stands ahead of the cab on every page', () {
      for (var page = 0; page < 4; page++) {
        final geometry = at(page.toDouble());
        final visibleX =
            geometry.milestoneX(page) - geometry.viewLeft - geometry.distance;

        expect(
          visibleX,
          greaterThan(OnboardingRoadGeometry.bodyWidth - geometry.viewLeft),
        );
        expect(visibleX, lessThan(geometry.viewWidth));
      }
    });
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
            child: SizedBox.fromSize(
              size: _phoneBand,
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
    });

    testWidgets('turns every wheel by the distance travelled', (tester) async {
      await pumpRoad(tester, page: 1.5);
      const geometry = OnboardingRoadGeometry(page: 1.5, size: _phoneBand);

      for (var index = 0; index < 3; index++) {
        final (cos, sin) = rotationOf(
          tester,
          find.byKey(ValueKey('onboarding-road-wheel-$index')),
        );
        expect(cos, closeTo(math.cos(geometry.wheelAngle), 1e-6));
        expect(sin, closeTo(math.sin(geometry.wheelAngle), 1e-6));
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
      expect(
        painter.distance,
        const OnboardingRoadGeometry(page: 1.5, size: _phoneBand).distance,
      );
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
