import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/theme/app_theme.dart';
import '../onboarding_steps.dart';
import '../widgets/onboarding_page_indicator.dart';
import '../widgets/onboarding_road.dart';
import '../widgets/onboarding_step_view.dart';

/// Swipeable onboarding pages with back, skip, next and start controls.
///
/// A full-width illustration band fills the top of the screen, behind the
/// status bar and the back and skip buttons. All pages share it
/// ([OnboardingRoad]): a truck that drives from page to page, following the
/// swipe. Each page's text sits below the band.
///
/// Pages can be changed with the buttons, by swiping (touch, mouse or
/// trackpad, including over the band), or with the system back button, which
/// goes to the previous page before leaving onboarding.
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

  static final _primaryActionStyle = FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
  );

  /// The back and skip row: 48 tall buttons with 8 of padding around.
  static const _topBarHeight = 64.0;

  /// The band aims for two thirds of the screen height...
  static const _bandScreenShare = 2 / 3;

  /// ...but always leaves this much for the page text (short phones, large
  /// text), and never gets smaller than this below the top bar.
  static const _minTextSpace = 240.0;
  static const _minSceneHeight = 120.0;

  final _pageController = PageController();
  var _currentIndex = 0;

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

  /// The band's height from the top edge of the screen.
  static double _bandHeight({
    required double screenHeight,
    required double availableHeight,
    required double sceneTop,
  }) {
    final preferred = screenHeight * _bandScreenShare;
    final roomForText = availableHeight - _minTextSpace;
    return math.max(
      sceneTop + _minSceneHeight,
      math.min(preferred, roomForText),
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
    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final sceneTop = mediaQuery.padding.top + _topBarHeight;

    return PopScope(
      canPop: _isFirstPage,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _goToPreviousPage();
        }
      },
      // The band runs behind the status bar, so keep its icons dark.
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bandHeight = _bandHeight(
                      screenHeight: mediaQuery.size.height,
                      availableHeight: constraints.maxHeight,
                      sceneTop: sceneTop,
                    );

                    return Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: bandHeight,
                          child: ColoredBox(
                            key: const ValueKey('onboarding-illustration-band'),
                            color: colorScheme.primaryContainer,
                          ),
                        ),
                        // The pages cover the band too, so swiping over the
                        // illustration changes the page. Each page leaves the
                        // band's height empty at the top.
                        PageView(
                          key: const ValueKey('onboarding-page-view'),
                          controller: _pageController,
                          // Flutter only drags scrollables with touch by
                          // default. Allow mouse and trackpad too, so swiping
                          // works on web.
                          scrollBehavior: ScrollConfiguration.of(context)
                              .copyWith(
                                dragDevices: PointerDeviceKind.values.toSet(),
                              ),
                          onPageChanged: (index) =>
                              setState(() => _currentIndex = index),
                          children: [
                            for (final step in widget.steps)
                              OnboardingStepView(
                                step: step,
                                illustrationSpace: bandHeight,
                              ),
                          ],
                        ),
                        // One shared scene over the pages, so the truck stays
                        // put while they slide. It ignores pointers: drags
                        // fall through to the PageView.
                        Positioned(
                          top: sceneTop,
                          left: 0,
                          right: 0,
                          height: bandHeight - sceneTop,
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, _) => OnboardingRoad(
                                page: _page,
                                pageCount: widget.steps.length,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            bottom: false,
                            child: _buildTopBar(l10n),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.maxContentWidth,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        OnboardingPageIndicator(
                          pageCount: widget.steps.length,
                          currentIndex: _currentIndex,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(
                            AppLayout.pageHorizontalInset,
                          ),
                          // The main action spans the full width at the
                          // bottom, within thumb reach.
                          child: _isLastPage
                              ? FilledButton(
                                  key: const ValueKey(
                                    'onboarding-start-button',
                                  ),
                                  style: _primaryActionStyle,
                                  onPressed: widget.onFinished,
                                  child: Text(l10n.onboardingStart),
                                )
                              : FilledButton.tonal(
                                  key: const ValueKey('onboarding-next-button'),
                                  style: _primaryActionStyle,
                                  onPressed: _goToNextPage,
                                  child: Text(l10n.onboardingNext),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Back sits top left, where people look for it; skip top right. Both keep
  /// their space when hidden so nothing jumps between pages.
  Widget _buildTopBar(AppLocalizations l10n) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
        child: SizedBox(
          height: _topBarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Visibility(
                  visible: !_isFirstPage,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: IconButton(
                    key: const ValueKey('onboarding-back-button'),
                    onPressed: _isFirstPage ? null : _goToPreviousPage,
                    tooltip: l10n.onboardingBack,
                    icon: const BackButtonIcon(),
                  ),
                ),
                Visibility(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
