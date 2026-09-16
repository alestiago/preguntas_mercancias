import 'package:flutter/material.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../../l10n/app_localizations.dart';
import '../bloc/practice_bloc.dart';

class QuestionNavigationDrawer extends StatelessWidget {
  const QuestionNavigationDrawer({
    super.key,
    required this.state,
    required this.onQuestionSelected,
  });

  final PracticeLoaded state;
  final ValueChanged<int> onQuestionSelected;

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
                  IconButton(
                    tooltip: localizations.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      localizations.questionNavigationTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: state.questions.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final question = state.questions[index];
                  return _QuestionNavigationTile(
                    question: question,
                    number: index + 1,
                    status: _statusFor(question),
                    isCurrent: index == state.currentIndex,
                    onTap: () => onQuestionSelected(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  _QuestionNavigationStatus _statusFor(Question question) {
    final selectedOption = state.selectedOptionsByQuestionCode[question.code];
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

    return ListTile(
      key: ValueKey('question-navigation-tile-$number'),
      selected: isCurrent,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.45),
      tileColor: Colors.transparent,
      onTap: onTap,
      leading: _QuestionStatusIcon(status: status),
      title: Text(
        '${localizations.questionNavigationQuestion(number)} · ${question.code}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          question.prompt,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      trailing: isCurrent
          ? Icon(Icons.location_on, color: colorScheme.primary)
          : const Icon(Icons.chevron_right),
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
