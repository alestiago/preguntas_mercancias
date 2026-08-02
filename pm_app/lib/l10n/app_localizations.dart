import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Preguntas Mercancias'**
  String get appTitle;

  /// No description provided for @allSections.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get allSections;

  /// No description provided for @homeProgressTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu progreso'**
  String get homeProgressTitle;

  /// No description provided for @questionsInBank.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{0 preguntas en el banco} =1{1 pregunta en el banco} other{{count} preguntas en el banco}}'**
  String questionsInBank(int count);

  /// No description provided for @startPractice.
  ///
  /// In es, this message translates to:
  /// **'Practicar'**
  String get startPractice;

  /// No description provided for @correctQuestions.
  ///
  /// In es, this message translates to:
  /// **'Correctas'**
  String get correctQuestions;

  /// No description provided for @questionsToReview.
  ///
  /// In es, this message translates to:
  /// **'Por repasar'**
  String get questionsToReview;

  /// No description provided for @pendingQuestions.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get pendingQuestions;

  /// No description provided for @homeLoadFailure.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el progreso.'**
  String get homeLoadFailure;

  /// No description provided for @practiceLoadFailure.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las preguntas.'**
  String get practiceLoadFailure;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @questionProgress.
  ///
  /// In es, this message translates to:
  /// **'Pregunta {currentQuestionNumber} de {questionCount}'**
  String questionProgress(int currentQuestionNumber, int questionCount);

  /// No description provided for @correctAnswerFeedbackTitle.
  ///
  /// In es, this message translates to:
  /// **'Correcta'**
  String get correctAnswerFeedbackTitle;

  /// No description provided for @incorrectAnswerFeedbackTitle.
  ///
  /// In es, this message translates to:
  /// **'Incorrecta'**
  String get incorrectAnswerFeedbackTitle;

  /// No description provided for @correctAnswer.
  ///
  /// In es, this message translates to:
  /// **'Respuesta correcta: {optionCode}. {answerText}'**
  String correctAnswer(String optionCode, String answerText);

  /// No description provided for @normReference.
  ///
  /// In es, this message translates to:
  /// **'Norma: {norma}'**
  String normReference(String norma);

  /// No description provided for @sessionScore.
  ///
  /// In es, this message translates to:
  /// **'Aciertos {correctCount} · Fallos {incorrectCount}'**
  String sessionScore(int correctCount, int incorrectCount);

  /// No description provided for @nextQuestion.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get nextQuestion;

  /// No description provided for @restartPractice.
  ///
  /// In es, this message translates to:
  /// **'Reiniciar'**
  String get restartPractice;

  /// No description provided for @scorePill.
  ///
  /// In es, this message translates to:
  /// **'{correctCount} / {incorrectCount} · {answeredQuestionCount}'**
  String scorePill(
    int correctCount,
    int incorrectCount,
    int answeredQuestionCount,
  );

  /// No description provided for @noQuestionsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay preguntas disponibles.'**
  String get noQuestionsAvailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
