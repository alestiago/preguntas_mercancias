import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../bloc/answer_history_bloc.dart';
import '../history_date_time_format.dart';

class AnswerHistoryDateHeader extends StatelessWidget {
  const AnswerHistoryDateHeader({super.key, required this.section});

  final AnswerHistorySection section;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final formattedDate = HistoryDateTimeFormat.date(context, section.date);

    return DecoratedBox(
      key: ValueKey('answer-history-date-header-$formattedDate'),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                formattedDate,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.strongWeight,
                ),
              ),
              const Spacer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppLayout.pillRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Text(
                    '${section.entries.length}',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: AppTypography.strongWeight,
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
}
