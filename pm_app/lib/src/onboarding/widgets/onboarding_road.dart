import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/app_theme.dart';

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
class OnboardingRoad extends StatelessWidget {
  const OnboardingRoad({super.key, required this.page, required this.pageCount})
    : assert(pageCount > 0);

  static const aspectRatio = 4 / 3;

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
    final geometry = OnboardingRoadGeometry(page);
    final bounce = disableAnimations ? 0.0 : geometry.bodyBounce;

    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppLayout.cardRadius * 2),
          child: ColoredBox(
            color: colorScheme.primaryContainer,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale =
                    constraints.maxWidth / OnboardingRoadGeometry.viewWidth;
                Offset toLocal(double x, double y) => Offset(
                  (x - OnboardingRoadGeometry.viewLeft) * scale,
                  (y - OnboardingRoadGeometry.viewTop) * scale,
                );

                final bodyOrigin = toLocal(0, 0);
                const wheelSize = OnboardingRoadGeometry.wheelRadius * 2;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        key: const ValueKey('onboarding-road-ground'),
                        painter: OnboardingRoadPainter(
                          distance: geometry.distance,
                          highlightedMilestone: geometry.highlightedMilestone,
                          milestoneCount: pageCount,
                          scale: scale,
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
                        left:
                            toLocal(centre.dx, centre.dy).dx -
                            wheelSize / 2 * scale,
                        top:
                            toLocal(centre.dx, centre.dy).dy -
                            wheelSize / 2 * scale,
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
          ),
        ),
      ),
    );
  }
}

/// Where everything sits for a given page, in the truck SVG's own units.
///
/// The truck body SVG is 844 x 398 units with the wheels resting on y ≈ 396.
/// The visible window adds a margin around it and keeps the 4:3 ratio. One
/// page of travel is one window width.
@immutable
final class OnboardingRoadGeometry {
  const OnboardingRoadGeometry(this.page);

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
  static const viewLeft = -50.0;
  static const viewWidth = 1000.0;
  static const viewHeight = viewWidth / OnboardingRoad.aspectRatio;

  /// Ground line at 80 % of the height leaves room for the road markings.
  static const viewTop = groundY - viewHeight * 0.8;

  static const pageLength = viewWidth;

  /// The first milestone stands just past the cab's nose (x = 844), inside
  /// the right edge of the window.
  static const firstMilestoneX = 900.0;

  final double page;

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

  /// Milestone [index]'s x position in the window, before scrolling.
  static double milestoneX(int index) => firstMilestoneX + index * pageLength;
}

/// Paints the road line, its dashed markings and the milestones, shifted left
/// by [distance].
@visibleForTesting
final class OnboardingRoadPainter extends CustomPainter {
  const OnboardingRoadPainter({
    required this.distance,
    required this.highlightedMilestone,
    required this.milestoneCount,
    required this.scale,
    required this.roadColor,
    required this.passedColor,
    required this.tickColor,
    required this.highlightColor,
  });

  static const _milestoneWidth = 36.0;
  static const _milestoneHeight = 70.0;
  static const _dashLength = 22.0;
  static const _dashGap = 24.0;

  final double distance;
  final int highlightedMilestone;
  final int milestoneCount;
  final double scale;
  final Color roadColor;
  final Color passedColor;
  final Color tickColor;
  final Color highlightColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(scale)
      ..translate(
        -OnboardingRoadGeometry.viewLeft - distance,
        -OnboardingRoadGeometry.viewTop,
      );

    const groundY = OnboardingRoadGeometry.groundY;
    final visibleLeft = OnboardingRoadGeometry.viewLeft + distance;
    final visibleRight = visibleLeft + OnboardingRoadGeometry.viewWidth;

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

    for (var index = 0; index < milestoneCount; index++) {
      final x = OnboardingRoadGeometry.milestoneX(index);
      if (x + _milestoneWidth < visibleLeft ||
          x - _milestoneWidth > visibleRight) {
        continue;
      }
      _paintMilestone(canvas, x, groundY, index);
    }

    canvas.restore();
  }

  void _paintMilestone(Canvas canvas, double x, double groundY, int index) {
    const half = _milestoneWidth / 2;
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
    return distance != oldDelegate.distance ||
        highlightedMilestone != oldDelegate.highlightedMilestone ||
        milestoneCount != oldDelegate.milestoneCount ||
        scale != oldDelegate.scale ||
        roadColor != oldDelegate.roadColor ||
        passedColor != oldDelegate.passedColor ||
        tickColor != oldDelegate.tickColor ||
        highlightColor != oldDelegate.highlightColor;
  }
}
