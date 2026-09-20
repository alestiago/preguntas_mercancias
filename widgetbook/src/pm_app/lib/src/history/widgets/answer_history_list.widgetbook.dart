import 'package:flutter/material.dart';
import 'package:pm_app/component_library.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../../../support/callback_notification.dart';
import '../../../../../support/fixture_factory.dart';
import '../../../../../support/use_case_frame.dart';

final answerHistoryListComponent = WidgetbookComponent(
  name: 'AnswerHistoryList',
  useCases: [
    WidgetbookUseCase(
      name: 'Interactive',
      builder: (context) {
        final rowCount = context.knobs.int.slider(
          label: 'Row count',
          initialValue: 6,
          min: 0,
          max: 20,
        );
        final hasMore = context.knobs.boolean(
          label: 'Has more',
          initialValue: true,
        );
        final isLoadingMore = context.knobs.boolean(
          label: 'Loading more',
          initialValue: false,
        );
        final includeMissingQuestion = context.knobs.boolean(
          label: 'Include missing question',
          initialValue: true,
        );
        final sections = rowCount == 0
            ? <AnswerHistorySection>[]
            : [
                WidgetbookFixtures.historySection(
                  date: DateTime.now(),
                  entryCount: rowCount,
                  includeMissingQuestion: includeMissingQuestion,
                ),
              ];

        return UseCaseFrame(
          padding: EdgeInsets.zero,
          scrollable: false,
          builder: (context) => AnswerHistoryList(
            sections: sections,
            hasMore: hasMore,
            isLoadingMore: hasMore && isLoadingMore,
            onLoadMore: () => showCallbackNotification(context, 'onLoadMore'),
            onQuestionSelected: (question) => showCallbackNotification(
              context,
              'onQuestionSelected',
              question.code,
            ),
          ),
        );
      },
    ),
    WidgetbookUseCase(
      name: 'Empty',
      builder: (_) => UseCaseFrame(
        padding: EdgeInsets.zero,
        scrollable: false,
        builder: (context) => AnswerHistoryList(
          sections: const [],
          hasMore: false,
          isLoadingMore: false,
          onLoadMore: () => showCallbackNotification(context, 'onLoadMore'),
          onQuestionSelected: (question) => showCallbackNotification(
            context,
            'onQuestionSelected',
            question.code,
          ),
        ),
      ),
    ),
  ],
);
