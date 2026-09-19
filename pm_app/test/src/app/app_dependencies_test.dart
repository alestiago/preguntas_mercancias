import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/app.dart';
import 'package:pm_app/src/app/app_dependencies_owner.dart';

import '../../helpers/fake_question_progress_store.dart';
import '../../helpers/fake_settings_store.dart';

void main() {
  test('closes every owned dependency exactly once', () async {
    final progressStore = FakeQuestionProgressStore();
    final settingsStore = FakeSettingsStore();
    final dependencies = AppDependencies(
      questionProgressStore: progressStore,
      settingsStore: settingsStore,
    );

    await dependencies.close();
    await dependencies.close();

    expect(progressStore.closeCallCount, 1);
    expect(settingsStore.closeCallCount, 1);
  });

  testWidgets('the app does not close injected dependencies', (tester) async {
    final progressStore = FakeQuestionProgressStore();
    final settingsStore = FakeSettingsStore();
    addTearDown(progressStore.close);
    addTearDown(settingsStore.close);

    await tester.pumpWidget(
      PreguntasMercanciasApp(
        dependencies: AppDependencies(
          questionProgressStore: progressStore,
          settingsStore: settingsStore,
        ),
        loadQuestions: (_) async => [],
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(progressStore.closeCallCount, 0);
    expect(settingsStore.closeCallCount, 0);
  });

  testWidgets('reports asynchronous dependency close failures', (tester) async {
    final progressStore = _FailingQuestionProgressStore();
    final settingsStore = FakeSettingsStore();
    final errors = <Object>[];

    await tester.pumpWidget(
      AppDependenciesOwner(
        dependencies: AppDependencies(
          questionProgressStore: progressStore,
          settingsStore: settingsStore,
        ),
        onCloseError: (error, _) => errors.add(error),
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(errors, [isA<StateError>()]);
    expect(progressStore.closeCallCount, 1);
    expect(settingsStore.closeCallCount, 1);
  });
}

final class _FailingQuestionProgressStore extends FakeQuestionProgressStore {
  @override
  Future<void> close() async {
    closeCallCount += 1;
    throw StateError('Could not close progress storage.');
  }
}
