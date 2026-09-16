import 'package:flutter/material.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../../l10n/app_localizations.dart';
import '../bloc/practice_bloc.dart';

class QuestionNavigationDrawer extends StatefulWidget {
  const QuestionNavigationDrawer({
    super.key,
    required this.state,
    required this.onQuestionSelected,
  });

  final PracticeLoaded state;
  final ValueChanged<int> onQuestionSelected;

  @override
  State<QuestionNavigationDrawer> createState() =>
      _QuestionNavigationDrawerState();
}

class _QuestionNavigationDrawerState extends State<QuestionNavigationDrawer> {
  late final ScrollController _scrollController;
  late List<GlobalKey> _tileKeys;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tileKeys = _tileKeysFor(widget.state.questions.length);
    _scheduleCurrentTileScroll();
  }

  @override
  void didUpdateWidget(QuestionNavigationDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.questions.length != widget.state.questions.length) {
      _tileKeys = _tileKeysFor(widget.state.questions.length);
    }

    if (oldWidget.state.currentIndex != widget.state.currentIndex ||
        oldWidget.state.questions.length != widget.state.questions.length) {
      _scheduleCurrentTileScroll();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<GlobalKey> _tileKeysFor(int count) {
    return List<GlobalKey>.generate(count, (_) => GlobalKey());
  }

  void _scheduleCurrentTileScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.state.questions.isEmpty) {
        return;
      }

      final currentTileContext =
          _tileKeys[widget.state.currentIndex].currentContext;
      if (currentTileContext == null) {
        return;
      }

      Scrollable.ensureVisible(currentTileContext, alignment: 0.5);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Drawer(
      width: MediaQuery.sizeOf(context).width.clamp(320, 420).toDouble(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      localizations.questionNavigationTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: localizations.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < widget.state.questions.length;
                      index += 1
                    ) ...[
                      KeyedSubtree(
                        key: _tileKeys[index],
                        child: _QuestionNavigationTile(
                          question: widget.state.questions[index],
                          number: index + 1,
                          status: _statusFor(widget.state.questions[index]),
                          isCurrent: index == widget.state.currentIndex,
                          onTap: () => widget.onQuestionSelected(index),
                        ),
                      ),
                      if (index < widget.state.questions.length - 1)
                        const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _QuestionNavigationStatus _statusFor(Question question) {
    final selectedOption =
        widget.state.selectedOptionsByQuestionCode[question.code];
    if (selectedOption == null) {
      return _QuestionNavigationStatus.pending;
    }

    return question.isCorrect(selectedOption)
        ? _QuestionNavigationStatus.correct
        : _QuestionNavigationStatus.incorrect;
  }
}

enum _QuestionNavigationStatus { pending, correct, incorrect }

class _QuestionNavigationTile extends StatelessWidget {
  const _QuestionNavigationTile({
    required this.question,
    required this.number,
    required this.status,
    required this.isCurrent,
    required this.onTap,
  });

  final Question question;
  final int number;
  final _QuestionNavigationStatus status;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);

    return Material(
      color: isCurrent
          ? colorScheme.primaryContainer.withValues(alpha: 0.45)
          : Colors.transparent,
      child: InkWell(
        key: ValueKey('question-navigation-tile-$number'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuestionStatusIcon(status: status),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${localizations.questionNavigationQuestion(number)} · ${question.code}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      question.prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isCurrent ? Icons.location_on : Icons.chevron_right,
                color: isCurrent ? colorScheme.primary : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionStatusIcon extends StatelessWidget {
  const _QuestionStatusIcon({required this.status});

  final _QuestionNavigationStatus status;

  @override
  Widget build(BuildContext context) {
    final style = _QuestionStatusIconStyle.forStatus(
      Theme.of(context).colorScheme,
      status,
    );

    return CircleAvatar(
      backgroundColor: style.color.withValues(alpha: 0.12),
      foregroundColor: style.color,
      child: Icon(style.icon),
    );
  }
}

final class _QuestionStatusIconStyle {
  const _QuestionStatusIconStyle({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  factory _QuestionStatusIconStyle.forStatus(
    ColorScheme colorScheme,
    _QuestionNavigationStatus status,
  ) {
    return switch (status) {
      _QuestionNavigationStatus.correct => const _QuestionStatusIconStyle(
        color: Color(0xFF2E7D32),
        icon: Icons.check,
      ),
      _QuestionNavigationStatus.incorrect => const _QuestionStatusIconStyle(
        color: Color(0xFFC62828),
        icon: Icons.close,
      ),
      _QuestionNavigationStatus.pending => _QuestionStatusIconStyle(
        color: colorScheme.onSurfaceVariant,
        icon: Icons.radio_button_unchecked,
      ),
    };
  }
}
