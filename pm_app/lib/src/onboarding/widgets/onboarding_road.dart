import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The onboarding illustration: a truck driving between the pages.
///
/// The truck stays still. The road and its milestones scroll with [page], and
/// the wheels turn exactly as far as the road moves, so the truck looks like
/// it drives rather than slides. [page] is the fractional page from the
/// `PageController`, so a half swipe moves the truck half way and swiping back
/// reverses it.
///
/// There is one milestone per page. The one ahead of the truck is
/// highlighted, and the ones already passed show a tick.
///
/// It fills the space it is given and paints no background, so the caller
/// decides the band it sits in. The truck sits near the bottom, centred.
class OnboardingRoad extends StatelessWidget {
  const OnboardingRoad({super.key, required this.page, required this.pageCount})
    : assert(pageCount > 0);

  static const bodyAsset = 'assets/onboarding/truck_body.svg';
  static const wheelAsset = 'assets/onboarding/truck_wheel.svg';

  /// Amber accent shared with the app icon proposals. Only the next milestone
  /// uses it, so it reads as "where you are going".
  static const highlightColor = Color(0xFFF2A900);

  final double page;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final geometry = OnboardingRoadGeometry(
            page: page,
            size: constraints.biggest,
          );
          final scale = geometry.scale;
          final bounce = disableAnimations ? 0.0 : geometry.bodyBounce;
          final bodyOrigin = geometry.toLocal(Offset.zero);
          const wheelSize = OnboardingRoadGeometry.wheelRadius * 2;

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  key: const ValueKey('onboarding-road-ground'),
                  painter: OnboardingRoadPainter(
                    geometry: geometry,
                    milestoneCount: pageCount,
                    roadColor: colorScheme.outline,
                    passedColor: colorScheme.primary,
                    tickColor: colorScheme.primaryContainer,
                    highlightColor: highlightColor,
                  ),
                ),
              ),
              Positioned(
                left: bodyOrigin.dx,
                top: bodyOrigin.dy + bounce * scale,
                width: OnboardingRoadGeometry.bodyWidth * scale,
                height: OnboardingRoadGeometry.bodyHeight * scale,
                child: SvgPicture.asset(bodyAsset),
              ),
              for (final (index, centre)
                  in OnboardingRoadGeometry.wheelCentres.indexed)
                Positioned(
                  left: geometry.toLocal(centre).dx - wheelSize / 2 * scale,
                  top: geometry.toLocal(centre).dy - wheelSize / 2 * scale,
                  width: wheelSize * scale,
                  height: wheelSize * scale,
                  child: Transform.rotate(
                    key: ValueKey('onboarding-road-wheel-$index'),
                    angle: geometry.wheelAngle,
                    child: SvgPicture.asset(wheelAsset),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Where everything sits for a given page and box size.
///
/// Positions are in the truck SVG's own units: the body is 844 x 398 with the
/// wheels resting on y ≈ 396. [scale] converts units to logical pixels. One
/// page of travel is one window width, so each page brings the next milestone
/// into view.
@immutable
final class OnboardingRoadGeometry {
  const OnboardingRoadGeometry({required this.page, required this.size});

  static const bodyWidth = 844.0;
  static const bodyHeight = 398.0;
  static const wheelRadius = 53.6;

  /// Measured from `truck.svg`; `truck_wheel.svg` is centred on its origin.
  static const wheelCentres = [
    Offset(208.5, 342.4),
    Offset(336.1, 342.9),
    Offset(715.6, 342.0),
  ];

  static const groundY = 396.0;

  /// The first milestone stands just past the cab's nose (x = 844).
  static const firstMilestoneX = 900.0;
  static const milestoneHalfWidth = 18.0;

  /// The truck plus the milestone ahead of it, kept centred in the window.
  static const _contentWidth = firstMilestoneX + milestoneHalfWidth;

  /// The truck and its milestone take at most this share of the width...
  static const _maxWidthShare = 0.88;

  /// ...and the truck at most this share of the height, so it fits wide
  /// tablets too.
  static const _maxHeightShare = 0.5;

  /// Room below the ground line for the road markings.
  static const _minGroundMargin = 36.0;
  static const _groundMarginShare = 0.14;

  final double page;
  final Size size;

  /// Logical pixels per truck unit.
  double get scale => math.min(
    size.width * _maxWidthShare / _contentWidth,
    size.height * _maxHeightShare / bodyHeight,
  );

  /// The window, in truck units.
  double get viewWidth => size.width / scale;
  double get viewLeft => -(viewWidth - _contentWidth) / 2;
  double get viewTop {
    final groundMargin = math.max(
      _minGroundMargin,
      size.height * _groundMarginShare,
    );
    return groundY - (size.height - groundMargin) / scale;
  }

  double get pageLength => viewWidth;

  /// A point in truck units, in logical pixels inside the box.
  Offset toLocal(Offset point) =>
      Offset((point.dx - viewLeft) * scale, (point.dy - viewTop) * scale);

  /// How far the truck has travelled, in truck units.
  double get distance => page * pageLength;

  /// Wheel rotation in radians. Rolling without slipping: angle = s / r.
  double get wheelAngle => distance / wheelRadius;

  /// A small vertical bob while between pages, none at rest.
  double get bodyBounce {
    final atRest = (page - page.roundToDouble()).abs() < 0.002;
    return atRest ? 0 : math.sin(distance / 9) * 1.6;
  }

  int get highlightedMilestone => page.round();

  /// Milestone [index]'s x position in truck units, before scrolling.
  double milestoneX(int index) => firstMilestoneX + index * pageLength;
}

/// Paints the road line, its dashed markings and the milestones, scrolled by
/// the geometry's distance.
@visibleForTesting
final class OnboardingRoadPainter extends CustomPainter {
  const OnboardingRoadPainter({
    required this.geometry,
    required this.milestoneCount,
    required this.roadColor,
    required this.passedColor,
    required this.tickColor,
    required this.highlightColor,
  });

  static const _milestoneHeight = 70.0;
  static const _dashLength = 22.0;
  static const _dashGap = 24.0;

  final OnboardingRoadGeometry geometry;
  final int milestoneCount;
  final Color roadColor;
  final Color passedColor;
  final Color tickColor;
  final Color highlightColor;

  double get distance => geometry.distance;
  int get highlightedMilestone => geometry.highlightedMilestone;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(geometry.scale)
      ..translate(-geometry.viewLeft - distance, -geometry.viewTop);

    const groundY = OnboardingRoadGeometry.groundY;
    final visibleLeft = geometry.viewLeft + distance;
    final visibleRight = visibleLeft + geometry.viewWidth;

    final road = Paint()
      ..color = roadColor
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(visibleLeft, groundY + 1.5),
      Offset(visibleRight, groundY + 1.5),
      road,
    );

    final dash = Paint()
      ..color = roadColor.withValues(alpha: 0.55)
      ..strokeWidth = 3;
    const period = _dashLength + _dashGap;
    final firstDash = (visibleLeft / period).floorToDouble() * period;
    for (var x = firstDash; x < visibleRight; x += period) {
      canvas.drawLine(
        Offset(x, groundY + 26),
        Offset(x + _dashLength, groundY + 26),
        dash,
      );
    }

    const half = OnboardingRoadGeometry.milestoneHalfWidth;
    for (var index = 0; index < milestoneCount; index++) {
      final x = geometry.milestoneX(index);
      if (x + half < visibleLeft || x - half > visibleRight) {
        continue;
      }
      _paintMilestone(canvas, x, groundY, index);
    }

    canvas.restore();
  }

  void _paintMilestone(Canvas canvas, double x, double groundY, int index) {
    const half = OnboardingRoadGeometry.milestoneHalfWidth;
    final shape = Path()
      ..moveTo(x - half, groundY)
      ..lineTo(x - half, groundY - _milestoneHeight + half)
      ..arcToPoint(
        Offset(x + half, groundY - _milestoneHeight + half),
        radius: const Radius.circular(half),
      )
      ..lineTo(x + half, groundY)
      ..close();

    final passed = index < highlightedMilestone;
    final highlighted = index == highlightedMilestone;

    if (passed || highlighted) {
      canvas.drawPath(
        shape,
        Paint()..color = highlighted ? highlightColor : passedColor,
      );
    } else {
      canvas.drawPath(
        shape,
        Paint()
          ..color = roadColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    if (passed) {
      final tickTop = groundY - _milestoneHeight + half + 4;
      canvas.drawPath(
        Path()
          ..moveTo(x - 9, tickTop)
          ..relativeLineTo(6, 6)
          ..relativeLineTo(12, -13),
        Paint()
          ..color = tickColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(OnboardingRoadPainter oldDelegate) {
    return geometry.page != oldDelegate.geometry.page ||
        geometry.size != oldDelegate.geometry.size ||
        milestoneCount != oldDelegate.milestoneCount ||
        roadColor != oldDelegate.roadColor ||
        passedColor != oldDelegate.passedColor ||
        tickColor != oldDelegate.tickColor ||
        highlightColor != oldDelegate.highlightColor;
  }
}
