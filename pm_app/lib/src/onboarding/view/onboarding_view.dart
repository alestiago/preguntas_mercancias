import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/theme/app_theme.dart';
import '../onboarding_steps.dart';
import '../widgets/onboarding_page_indicator.dart';
import '../widgets/onboarding_road.dart';
import '../widgets/onboarding_step_view.dart';

/// Swipeable onboarding pages with back, skip, next and start controls.
///
/// All pages share one illustration ([OnboardingRoad]): a truck that drives
/// from page to page, following the swipe.
///
/// Pages can be changed with the buttons, by swiping (touch, mouse or
/// trackpad), or with the system back button, which goes to the previous page
/// before leaving onboarding.
///
/// [onFinished] runs when the user skips or starts. The caller decides what
/// finishing means (persist the flag, or just pop).
class OnboardingView extends StatefulWidget {
  const OnboardingView({
    super.key,
    required this.steps,
    required this.onFinished,
  }) : assert(steps.length > 0);

  final List<OnboardingStep> steps;
  final VoidCallback onFinished;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  static const _pageTransition = Duration(milliseconds: 300);

  final _pageController = PageController();
  var _currentIndex = 0;

  static const _illustrationTopInset = 24.0;
  static const _illustrationMaxWidth = 360.0;

  /// Most of the height the illustration may take, so the text keeps room on
  /// short screens (landscape phones, large text).
  static const _illustrationMaxHeightFraction = 0.45;

  bool get _isFirstPage => _currentIndex == 0;
  bool get _isLastPage => _currentIndex == widget.steps.length - 1;

  /// The fractional page while swiping, for the illustration.
  double get _page {
    final position = _pageController.hasClients
        ? _pageController.position
        : null;
    if (position == null || !position.hasContentDimensions) {
      return _currentIndex.toDouble();
    }
    return _pageController.page ?? _currentIndex.toDouble();
  }

  static double _illustrationWidth(BoxConstraints constraints) {
    final byWidth = constraints.maxWidth - AppLayout.pageHorizontalInset * 2;
    final byHeight =
        constraints.maxHeight *
        _illustrationMaxHeightFraction *
        OnboardingRoad.aspectRatio;
    return math.max(
      0.0,
      math.min(_illustrationMaxWidth, math.min(byWidth, byHeight)),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    _pageController.nextPage(duration: _pageTransition, curve: Curves.easeOut);
  }

  void _goToPreviousPage() {
    _pageController.previousPage(
      duration: _pageTransition,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: _isFirstPage,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _goToPreviousPage();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxContentWidth,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Visibility(
                        visible: !_isLastPage,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: TextButton(
                          key: const ValueKey('onboarding-skip-button'),
                          onPressed: _isLastPage ? null : widget.onFinished,
                          child: Text(l10n.onboardingSkip),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final illustrationWidth = _illustrationWidth(
                          constraints,
                        );
                        final illustrationSpace =
                            _illustrationTopInset +
                            illustrationWidth / OnboardingRoad.aspectRatio;

                        return Stack(
                          children: [
                            PageView(
                              key: const ValueKey('onboarding-page-view'),
                              controller: _pageController,
                              // Flutter only drags scrollables with touch by
                              // default. Allow mouse and trackpad too, so
                              // swiping works on web.
                              scrollBehavior: ScrollConfiguration.of(context)
                                  .copyWith(
                                    dragDevices: PointerDeviceKind.values
                                        .toSet(),
                                  ),
                              onPageChanged: (index) =>
                                  setState(() => _currentIndex = index),
                              children: [
                                for (final step in widget.steps)
                                  OnboardingStepView(
                                    step: step,
                                    illustrationSpace: illustrationSpace,
                                  ),
                              ],
                            ),
                            // One shared scene over the pages, so the truck
                            // stays put while they slide. It ignores pointers:
                            // drags fall through to the PageView.
                            Positioned(
                              top: _illustrationTopInset,
                              left: 0,
                              right: 0,
                              child: IgnorePointer(
                                child: Center(
                                  child: SizedBox(
                                    width: illustrationWidth,
                                    child: AnimatedBuilder(
                                      animation: _pageController,
                                      builder: (context, _) => OnboardingRoad(
                                        page: _page,
                                        pageCount: widget.steps.length,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  OnboardingPageIndicator(
                    pageCount: widget.steps.length,
                    currentIndex: _currentIndex,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(
                      AppLayout.pageHorizontalInset,
                    ),
                    child: Row(
                      children: [
                        Visibility(
                          visible: !_isFirstPage,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: TextButton(
                            key: const ValueKey('onboarding-back-button'),
                            onPressed: _isFirstPage ? null : _goToPreviousPage,
                            child: Text(l10n.onboardingBack),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _isLastPage
                              ? FilledButton(
                                  key: const ValueKey(
                                    'onboarding-start-button',
                                  ),
                                  onPressed: widget.onFinished,
                                  child: Text(l10n.onboardingStart),
                                )
                              : FilledButton.tonal(
                                  key: const ValueKey('onboarding-next-button'),
                                  onPressed: _goToNextPage,
                                  child: Text(l10n.onboardingNext),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
