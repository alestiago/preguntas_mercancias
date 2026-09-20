// The requested mirror contains a literal `pm_app/lib/src` subtree inside
// this application's `src` directory. Those files are not package libraries.
// ignore_for_file: avoid_relative_lib_imports

import 'package:widgetbook/widgetbook.dart';

import 'pm_app/lib/src/app/widgets/app_message_panel.widgetbook.dart';
import 'pm_app/lib/src/history/widgets/answer_history_date_header.widgetbook.dart';
import 'pm_app/lib/src/history/widgets/answer_history_list.widgetbook.dart';
import 'pm_app/lib/src/home/widgets/home_progress_summary.widgetbook.dart';
import 'pm_app/lib/src/practice/widgets/answer_feedback.widgetbook.dart';
import 'pm_app/lib/src/practice/widgets/exit_practice_button.widgetbook.dart';
import 'pm_app/lib/src/practice/widgets/practice_progress_divider.widgetbook.dart';
import 'pm_app/lib/src/practice/widgets/practice_question_header.widgetbook.dart';
import 'pm_app/lib/src/practice/widgets/practice_question_panel.widgetbook.dart';
import 'pm_app/lib/src/practice/widgets/practice_section_selector.widgetbook.dart';
import 'pm_app/lib/src/practice/widgets/practice_session_footer.widgetbook.dart';
import 'pm_app/lib/src/practice/widgets/session_question_status_badge.widgetbook.dart';

final widgetbookDirectories = <WidgetbookNode>[
  WidgetbookCategory(
    name: 'pm_app',
    children: [
      WidgetbookFolder(
        name: 'lib',
        children: [
          WidgetbookFolder(
            name: 'src',
            children: [
              WidgetbookFolder(
                name: 'app',
                children: [
                  WidgetbookFolder(
                    name: 'widgets',
                    children: [appMessagePanelComponent],
                  ),
                ],
              ),
              WidgetbookFolder(
                name: 'home',
                children: [
                  WidgetbookFolder(
                    name: 'widgets',
                    children: [homeProgressSummaryComponent],
                  ),
                ],
              ),
              WidgetbookFolder(
                name: 'history',
                children: [
                  WidgetbookFolder(
                    name: 'widgets',
                    children: [
                      answerHistoryDateHeaderComponent,
                      answerHistoryListComponent,
                    ],
                  ),
                ],
              ),
              WidgetbookFolder(
                name: 'practice',
                children: [
                  WidgetbookFolder(
                    name: 'widgets',
                    children: [
                      answerFeedbackSwitcherComponent,
                      exitPracticeIconButtonComponent,
                      practiceProgressDividerComponent,
                      practiceQuestionHeaderComponent,
                      practiceQuestionPanelComponent,
                      practiceSectionSelectorComponent,
                      practiceSessionFooterComponent,
                      sessionQuestionStatusBadgeComponent,
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
