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
  String get answerHistoryTitle => 'Historial';

  @override
  String get answerHistoryEmpty =>
      'Todavía no has respondido ninguna pregunta.';

  @override
  String answerHistorySelection(String answerText) {
    return 'Elegida: $answerText';
  }

  @override
  String get answerHistoryUnknownQuestion => 'Pregunta no disponible';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get appVersion => 'Versión';

  @override
  String get shuffleAnswersTitle => 'Aleatorización inteligente de respuestas';

  @override
  String get shuffleAnswersSubtitle =>
      'Cambia el orden de las opciones al mostrar cada pregunta. Las preguntas cuyas respuestas hacen referencia a otras opciones (por ejemplo, \"todas las anteriores\") nunca se aleatorizan.';

  @override
  String get resetProgress => 'Reiniciar progreso';

  @override
  String get resetProgressConfirmationTitle => 'Reiniciar progreso';

  @override
  String get resetProgressConfirmationMessage =>
      'Se borrarán tus respuestas y estadísticas. Esta acción no se puede deshacer.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get progressReset => 'Progreso reiniciado';

  @override
  String get startSimulacro => 'Simulacro';

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
  String get nextQuestion => 'Siguiente';

  @override
  String get previousQuestion => 'Anterior';

  @override
  String get restartPractice => 'Reiniciar';

  @override
  String get finishPractice => 'Finalizar';

  @override
  String scorePill(
    int correctCount,
    int answeredQuestionCount,
    int scorePercentage,
  ) {
    return '$correctCount/$answeredQuestionCount ($scorePercentage%)';
  }

  @override
  String get noQuestionsAvailable => 'No hay preguntas disponibles.';
}
