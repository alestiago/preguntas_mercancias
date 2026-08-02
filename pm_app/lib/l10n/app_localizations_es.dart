// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Preguntas Mercancias';

  @override
  String get allSections => 'Todas';

  @override
  String get homeProgressTitle => 'Tu progreso';

  @override
  String questionsInBank(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count preguntas en el banco',
      one: '1 pregunta en el banco',
      zero: '0 preguntas en el banco',
    );
    return '$_temp0';
  }

  @override
  String get startPractice => 'Practicar';

  @override
  String get correctQuestions => 'Correctas';

  @override
  String get questionsToReview => 'Por repasar';

  @override
  String get pendingQuestions => 'Pendientes';

  @override
  String get homeLoadFailure => 'No se pudo cargar el progreso.';

  @override
  String get practiceLoadFailure => 'No se pudieron cargar las preguntas.';

  @override
  String get retry => 'Reintentar';

  @override
  String questionProgress(int currentQuestionNumber, int questionCount) {
    return 'Pregunta $currentQuestionNumber de $questionCount';
  }

  @override
  String get correctAnswerFeedbackTitle => 'Correcta';

  @override
  String get incorrectAnswerFeedbackTitle => 'Incorrecta';

  @override
  String correctAnswer(String optionCode, String answerText) {
    return 'Respuesta correcta: $optionCode. $answerText';
  }

  @override
  String normReference(String norma) {
    return 'Norma: $norma';
  }

  @override
  String sessionScore(int correctCount, int incorrectCount) {
    return 'Aciertos $correctCount · Fallos $incorrectCount';
  }

  @override
  String get nextQuestion => 'Siguiente';

  @override
  String get restartPractice => 'Reiniciar';

  @override
  String scorePill(
    int correctCount,
    int incorrectCount,
    int answeredQuestionCount,
  ) {
    return '$correctCount / $incorrectCount · $answeredQuestionCount';
  }

  @override
  String get noQuestionsAvailable => 'No hay preguntas disponibles.';
}
