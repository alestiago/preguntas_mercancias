import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/theme/app_theme.dart';
import '../onboarding_steps.dart';
import '../widgets/onboarding_page_indicator.dart';
import '../widgets/onboarding_step_view.dart';

/// Swipeable onboarding pages with skip, next and start controls.
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

  bool get _isLastPage => _currentIndex == widget.steps.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    _pageController.nextPage(duration: _pageTransition, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
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
                  child: PageView(
                    key: const ValueKey('onboarding-page-view'),
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    children: [
                      for (final step in widget.steps)
                        OnboardingStepView(step: step),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OnboardingPageIndicator(
                  pageCount: widget.steps.length,
                  currentIndex: _currentIndex,
                ),
                Padding(
                  padding: const EdgeInsets.all(AppLayout.pageHorizontalInset),
                  child: SizedBox(
                    width: double.infinity,
                    child: _isLastPage
                        ? FilledButton(
                            key: const ValueKey('onboarding-start-button'),
                            onPressed: widget.onFinished,
                            child: Text(l10n.onboardingStart),
                          )
                        : FilledButton.tonal(
                            key: const ValueKey('onboarding-next-button'),
                            onPressed: _goToNextPage,
                            child: Text(l10n.onboardingNext),
                          ),
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
