import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

part 'practice_event.dart';
part 'practice_state.dart';

typedef LoadQuestions = Future<List<Question>> Function(String? section);

Future<List<Question>> loadQuestionsFromBank(String? section) {
  final loader = QuestionBankLoader();
  return section == null ? loader.loadAll() : loader.loadSection(section);
}

class PracticeBloc extends Bloc<PracticeEvent, PracticeState> {
  PracticeBloc({
    this.loadQuestions = loadQuestionsFromBank,
    String? initialSection,
  }) : super(
         PracticeLoading(
           selectedSection: initialSection ?? QuestionBankLoader.sections.first,
         ),
       ) {
    on<PracticeStarted>(_onStarted);
    on<SectionSelected>(_onSectionSelected);
    on<AnswerPressed>(_onAnswerPressed);
    on<NextQuestionPressed>(_onNextQuestionPressed);
    on<RetryPressed>(_onRetryPressed);
  }

  final LoadQuestions loadQuestions;

  Future<void> _onStarted(PracticeStarted event, Emitter<PracticeState> emit) {
    return _load(emit, state.selectedSection);
  }

  Future<void> _onSectionSelected(
    SectionSelected event,
    Emitter<PracticeState> emit,
  ) {
    if (state.selectedSection == event.section) {
      return Future.value();
    }

    return _load(emit, event.section);
  }

  void _onAnswerPressed(AnswerPressed event, Emitter<PracticeState> emit) {
    final currentState = state;
    if (currentState is! PracticeLoaded || currentState.answered) {
      return;
    }

    final isCorrect = currentState.currentQuestion.isCorrect(event.option);
    emit(
      currentState.copyWith(
        selectedOption: event.option,
        correctCount: currentState.correctCount + (isCorrect ? 1 : 0),
        incorrectCount: currentState.incorrectCount + (isCorrect ? 0 : 1),
      ),
    );
  }

  void _onNextQuestionPressed(
    NextQuestionPressed event,
    Emitter<PracticeState> emit,
  ) {
    final currentState = state;
    if (currentState is! PracticeLoaded || !currentState.answered) {
      return;
    }

    if (currentState.isLastQuestion) {
      emit(currentState.restart());
      return;
    }

    emit(
      currentState.copyWith(
        currentIndex: currentState.currentIndex + 1,
        selectedOption: null,
      ),
    );
  }

  Future<void> _onRetryPressed(
    RetryPressed event,
    Emitter<PracticeState> emit,
  ) {
    return _load(emit, state.selectedSection);
  }

  Future<void> _load(
    Emitter<PracticeState> emit,
    String? selectedSection,
  ) async {
    emit(PracticeLoading(selectedSection: selectedSection));

    try {
      final questions = await loadQuestions(selectedSection);
      emit(
        PracticeLoaded(
          selectedSection: selectedSection,
          questions: List<Question>.unmodifiable(questions),
        ),
      );
    } catch (error) {
      emit(PracticeLoadFailure(selectedSection: selectedSection, error: error));
    }
  }
}
