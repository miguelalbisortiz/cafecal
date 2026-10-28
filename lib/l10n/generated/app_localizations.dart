import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Balance'**
  String get appTitle;

  /// No description provided for @appTitleFull.
  ///
  /// In es, this message translates to:
  /// **'Balance'**
  String get appTitleFull;

  /// No description provided for @tabOverview.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get tabOverview;

  /// No description provided for @tabRegister.
  ///
  /// In es, this message translates to:
  /// **'Registrar'**
  String get tabRegister;

  /// No description provided for @tabHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get tabHistory;

  /// No description provided for @nextStepTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu próximo paso'**
  String get nextStepTitle;

  /// No description provided for @nextStepAction.
  ///
  /// In es, this message translates to:
  /// **'Ir'**
  String get nextStepAction;

  /// No description provided for @nextStepCropTitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primer cultivo'**
  String get nextStepCropTitle;

  /// No description provided for @nextStepCropSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Empieza registrando el cultivo que manejarás (Café, Plátano…).'**
  String get nextStepCropSubtitle;

  /// No description provided for @nextStepCropSetupTitle.
  ///
  /// In es, this message translates to:
  /// **'Configura tu primer cultivo'**
  String get nextStepCropSetupTitle;

  /// No description provided for @nextStepCropSetupSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Revisa Café, Plátano u Otro, o crea el tuyo, y ajusta fase y área.'**
  String get nextStepCropSetupSubtitle;

  /// No description provided for @nextStepSowingTitle.
  ///
  /// In es, this message translates to:
  /// **'Registra la siembra de {crop}'**
  String nextStepSowingTitle(String crop);

  /// No description provided for @nextStepSowingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Este cultivo todavía no tiene registrada su siembra inicial.'**
  String get nextStepSowingSubtitle;

  /// No description provided for @nextStepExpensesTitle.
  ///
  /// In es, this message translates to:
  /// **'Registra tus primeros gastos'**
  String get nextStepExpensesTitle;

  /// No description provided for @nextStepExpensesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lleva el control de lo que inviertes cada mes.'**
  String get nextStepExpensesSubtitle;

  /// No description provided for @nextStepSaleTitle.
  ///
  /// In es, this message translates to:
  /// **'Registra la venta de tu cosecha'**
  String get nextStepSaleTitle;

  /// No description provided for @nextStepSaleSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Al registrarla se anotan solos los kilos cosechados de ese cultivo.'**
  String get nextStepSaleSubtitle;

  /// No description provided for @nextStepGuideLink.
  ///
  /// In es, this message translates to:
  /// **'Ver guía completa'**
  String get nextStepGuideLink;

  /// No description provided for @welcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué cultivas?'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Empieza por el que más tienes. Los demás los agregas después.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeEmptyList.
  ///
  /// In es, this message translates to:
  /// **'Sin cultivos todavía'**
  String get welcomeEmptyList;

  /// No description provided for @welcomeAddFirst.
  ///
  /// In es, this message translates to:
  /// **'Agregar el primero'**
  String get welcomeAddFirst;

  /// No description provided for @welcomeAddMore.
  ///
  /// In es, this message translates to:
  /// **'Agregar otro'**
  String get welcomeAddMore;

  /// No description provided for @welcomeEnter.
  ///
  /// In es, this message translates to:
  /// **'Entrar a la app'**
  String get welcomeEnter;

  /// No description provided for @welcomeIconLabel.
  ///
  /// In es, this message translates to:
  /// **'Icono'**
  String get welcomeIconLabel;

  /// No description provided for @welcomeDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get welcomeDone;

  /// No description provided for @welcomeComplete.
  ///
  /// In es, this message translates to:
  /// **'Completar datos…'**
  String get welcomeComplete;

  /// No description provided for @onboardingCropAddedTitle.
  ///
  /// In es, this message translates to:
  /// **'Cultivo agregado'**
  String get onboardingCropAddedTitle;

  /// No description provided for @onboardingAnother.
  ///
  /// In es, this message translates to:
  /// **'Agregar otro'**
  String get onboardingAnother;

  /// No description provided for @onboardingAnotherPrompt.
  ///
  /// In es, this message translates to:
  /// **'Cultivo agregado. ¿Registrar otro cultivo que ya tienes sembrado en tu finca?'**
  String get onboardingAnotherPrompt;

  /// No description provided for @onboardingDone.
  ///
  /// In es, this message translates to:
  /// **'Entrar, terminé'**
  String get onboardingDone;

  /// No description provided for @sowingNewCropOption.
  ///
  /// In es, this message translates to:
  /// **'+ Crear nuevo cultivo…'**
  String get sowingNewCropOption;

  /// No description provided for @sowingNewCropTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo cultivo'**
  String get sowingNewCropTitle;

  /// No description provided for @helpStartTitle.
  ///
  /// In es, this message translates to:
  /// **'Aprende a operar Balance'**
  String get helpStartTitle;

  /// No description provided for @helpTabStart.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get helpTabStart;

  /// No description provided for @helpTabRoutine.
  ///
  /// In es, this message translates to:
  /// **'Rutina'**
  String get helpTabRoutine;

  /// No description provided for @helpTabUnderstand.
  ///
  /// In es, this message translates to:
  /// **'Entender'**
  String get helpTabUnderstand;

  /// No description provided for @helpStartSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige cómo está tu finca hoy. En cinco minutos haces el primer registro.'**
  String get helpStartSubtitle;

  /// No description provided for @helpStartQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo está tu finca hoy?'**
  String get helpStartQuestion;

  /// No description provided for @helpStartNote.
  ///
  /// In es, this message translates to:
  /// **'Los ejemplos usan números redondos y «tu moneda». Sirven igual para cualquier país y cualquier cultivo.'**
  String get helpStartNote;

  /// No description provided for @helpCaseSellingTitle.
  ///
  /// In es, this message translates to:
  /// **'Ya vendo lo que cosecho'**
  String get helpCaseSellingTitle;

  /// No description provided for @helpCaseSellingDesc.
  ///
  /// In es, this message translates to:
  /// **'Tienes cultivos dando fruto y quieres saber si ganas.'**
  String get helpCaseSellingDesc;

  /// No description provided for @helpCaseStartingTitle.
  ///
  /// In es, this message translates to:
  /// **'Voy a empezar'**
  String get helpCaseStartingTitle;

  /// No description provided for @helpCaseStartingDesc.
  ///
  /// In es, this message translates to:
  /// **'Vas a sembrar y quieres ver cuánto inviertes antes de cosechar.'**
  String get helpCaseStartingDesc;

  /// No description provided for @helpCaseRenewTitle.
  ///
  /// In es, this message translates to:
  /// **'Voy a renovar o ampliar'**
  String get helpCaseRenewTitle;

  /// No description provided for @helpCaseRenewDesc.
  ///
  /// In es, this message translates to:
  /// **'Vas a reemplazar matas o sumar área a un cultivo.'**
  String get helpCaseRenewDesc;

  /// No description provided for @helpCaseWorkersTitle.
  ///
  /// In es, this message translates to:
  /// **'Tengo trabajadores'**
  String get helpCaseWorkersTitle;

  /// No description provided for @helpCaseWorkersDesc.
  ///
  /// In es, this message translates to:
  /// **'Pagas jornales y quieres que el costo quede en el cultivo correcto.'**
  String get helpCaseWorkersDesc;

  /// No description provided for @helpSellingIntro.
  ///
  /// In es, this message translates to:
  /// **'No anotes lo que ya pasó. Empieza desde hoy: lo que gastes y lo que vendas.'**
  String get helpSellingIntro;

  /// No description provided for @helpSellingStep1.
  ///
  /// In es, this message translates to:
  /// **'Revisa tus cultivos: Cultivos › tu cultivo. Que la fase sea «Dando» y, si los sabes, el área y las matas. Si no los sabes, déjalos vacíos: la app no inventa.'**
  String get helpSellingStep1;

  /// No description provided for @helpSellingStep2.
  ///
  /// In es, this message translates to:
  /// **'Anota el primer gasto: Registrar › Gasto. Elige el cultivo y la categoría: fertilizante, mano de obra, transporte. Si el gasto es de varios cultivos, repártelo por área o por porcentaje.'**
  String get helpSellingStep2;

  /// No description provided for @helpSellingStep3.
  ///
  /// In es, this message translates to:
  /// **'Anota la primera venta: Registrar › Ingreso. Escribe los kilos y lo que te pagaron. Con esos kilos, la cosecha de ese cultivo queda registrada sola. No la anotes dos veces.'**
  String get helpSellingStep3;

  /// No description provided for @helpSellingStep4.
  ///
  /// In es, this message translates to:
  /// **'Mira el mes: Resumen o Reporte. Ahí ves ingresos, gastos, balance y costo por kilo. El reporte sale en PDF o Excel.'**
  String get helpSellingStep4;

  /// No description provided for @helpSellingExampleTitle.
  ///
  /// In es, this message translates to:
  /// **'Ejemplo con café, 2 ha y 3.000 matas'**
  String get helpSellingExampleTitle;

  /// No description provided for @helpSellingExample1.
  ///
  /// In es, this message translates to:
  /// **'Gasto: 500 en fertilizante, asignado a café.'**
  String get helpSellingExample1;

  /// No description provided for @helpSellingExample2.
  ///
  /// In es, this message translates to:
  /// **'Venta: 50 kg por 750.'**
  String get helpSellingExample2;

  /// No description provided for @helpSellingExample3.
  ///
  /// In es, this message translates to:
  /// **'Resultado: ingresos 750 · gastos 500 · balance 250 · costo por kilo 10.'**
  String get helpSellingExample3;

  /// No description provided for @helpSellingClosing.
  ///
  /// In es, this message translates to:
  /// **'Lo que vendiste antes de usar la app no hace falta: el reporte empieza con lo que anotes.'**
  String get helpSellingClosing;

  /// No description provided for @helpSellingMulti.
  ///
  /// In es, this message translates to:
  /// **'Si tienes varios cultivos en el mismo terreno, asígnalos al registrar el gasto; la app reparte por área o por porcentaje.'**
  String get helpSellingMulti;

  /// No description provided for @helpStartingIntro.
  ///
  /// In es, this message translates to:
  /// **'Mientras el cultivo no da fruto, la app no te dice que pierdes: te muestra cuánto llevas invertido. Es una inversión, no un mal mes.'**
  String get helpStartingIntro;

  /// No description provided for @helpStartingStep1.
  ///
  /// In es, this message translates to:
  /// **'Crea el cultivo: Cultivos › Nueva variedad. Nombre, fase «Sin dar» y si es perenne o transitorio. El área y las matas pueden quedar vacías.'**
  String get helpStartingStep1;

  /// No description provided for @helpStartingStep2.
  ///
  /// In es, this message translates to:
  /// **'Anota la siembra: Siembras › Nueva siembra. Cuántas matas, en qué área y la fecha. Si anotas el costo, la app crea el gasto vinculado sola: no lo repitas en Registrar.'**
  String get helpStartingStep2;

  /// No description provided for @helpStartingStep3.
  ///
  /// In es, this message translates to:
  /// **'Anota lo que inviertes: Registrar › Gasto, con el cultivo. Fertilizante, mano de obra, herramientas. Todo lo de antes de la primera cosecha se ve como inversión.'**
  String get helpStartingStep3;

  /// No description provided for @helpStartingStep4.
  ///
  /// In es, this message translates to:
  /// **'Cuando coseches, cambia la fase: Cultivos › tu cultivo › fase «Dando». Desde ahí, la venta registra la cosecha.'**
  String get helpStartingStep4;

  /// No description provided for @helpStartingExampleTitle.
  ///
  /// In es, this message translates to:
  /// **'Ejemplo con maíz, 1 ha y 20.000 matas'**
  String get helpStartingExampleTitle;

  /// No description provided for @helpStartingExample1.
  ///
  /// In es, this message translates to:
  /// **'Siembra: 20.000 matas en 1 ha.'**
  String get helpStartingExample1;

  /// No description provided for @helpStartingExample2.
  ///
  /// In es, this message translates to:
  /// **'Inversión: 300 en semilla + 200 en preparación = 500.'**
  String get helpStartingExample2;

  /// No description provided for @helpStartingExample3.
  ///
  /// In es, this message translates to:
  /// **'Antes de cosechar: inversión 500, sin pérdida.'**
  String get helpStartingExample3;

  /// No description provided for @helpStartingExample4.
  ///
  /// In es, this message translates to:
  /// **'Primera venta: 1.000 kg por 800. La cosecha queda registrada.'**
  String get helpStartingExample4;

  /// No description provided for @helpRenewIntro.
  ///
  /// In es, this message translates to:
  /// **'No borres el cultivo viejo. La app guarda su historia y suma la parte nueva.'**
  String get helpRenewIntro;

  /// No description provided for @helpRenewStep1.
  ///
  /// In es, this message translates to:
  /// **'Elige qué pasa con las matas viejas: Siembras › Nueva siembra. Si reemplazas una parte, elige «Renuevo una parte» y el lote que renuevas. Las matas viejas bajan y las nuevas suman: el total no se infla.'**
  String get helpRenewStep1;

  /// No description provided for @helpRenewStep2.
  ///
  /// In es, this message translates to:
  /// **'Si amplías, no reemplaces: elige «Amplío el cultivo». Sumas área y matas sin tocar lo que ya estaba.'**
  String get helpRenewStep2;

  /// No description provided for @helpRenewStep3.
  ///
  /// In es, this message translates to:
  /// **'Mira la edad nueva: el lote renovado arranca su propia edad. Las cosechas viejas siguen en el historial y en el reporte.'**
  String get helpRenewStep3;

  /// No description provided for @helpRenewExampleTitle.
  ///
  /// In es, this message translates to:
  /// **'Ejemplo con café de 3.000 matas; renuevas 1.000'**
  String get helpRenewExampleTitle;

  /// No description provided for @helpRenewExample1.
  ///
  /// In es, this message translates to:
  /// **'Siembra: 1.000 matas nuevas, «Renuevo una parte», lote viejo.'**
  String get helpRenewExample1;

  /// No description provided for @helpRenewExample2.
  ///
  /// In es, this message translates to:
  /// **'Total: sigue en 3.000, no en 4.000.'**
  String get helpRenewExample2;

  /// No description provided for @helpRenewExample3.
  ///
  /// In es, this message translates to:
  /// **'El lote nuevo tiene su fecha; el viejo conserva la suya.'**
  String get helpRenewExample3;

  /// No description provided for @helpWorkersCaseIntro.
  ///
  /// In es, this message translates to:
  /// **'El jornal no es un gasto suelto: va al cultivo donde trabajaron. Así el costo por kilo dice la verdad.'**
  String get helpWorkersCaseIntro;

  /// No description provided for @helpWorkersStep1.
  ///
  /// In es, this message translates to:
  /// **'Guarda al trabajador: Trabajadores › Nuevo trabajador. Nombre y pago por día. Si cambia el jornal, lo actualizas ahí.'**
  String get helpWorkersStep1;

  /// No description provided for @helpWorkersStep2.
  ///
  /// In es, this message translates to:
  /// **'Anota el pago: Registrar › Gasto › Mano de obra. Elige el trabajador, los días y el cultivo. La app calcula el monto; si pagaste otra cosa, lo ajustas.'**
  String get helpWorkersStep2;

  /// No description provided for @helpWorkersStep3.
  ///
  /// In es, this message translates to:
  /// **'Si fue cosecha, márcalo: en la labor elige «Cosechar», anota los kilos y el lote. Con eso sale el costo de recogida por kilo.'**
  String get helpWorkersStep3;

  /// No description provided for @helpWorkersStep4.
  ///
  /// In es, this message translates to:
  /// **'Mira la nómina: Reporte › Nómina del período. Ahí está cuántos días y cuánto pagaste a cada uno.'**
  String get helpWorkersStep4;

  /// No description provided for @helpWorkersExampleTitle.
  ///
  /// In es, this message translates to:
  /// **'Ejemplo con dos trabajadores a 20 por día'**
  String get helpWorkersExampleTitle;

  /// No description provided for @helpWorkersExample1.
  ///
  /// In es, this message translates to:
  /// **'Juan: 3 días en café = 60.'**
  String get helpWorkersExample1;

  /// No description provided for @helpWorkersExample2.
  ///
  /// In es, this message translates to:
  /// **'Pedro: 2 días en café = 40.'**
  String get helpWorkersExample2;

  /// No description provided for @helpWorkersExample3.
  ///
  /// In es, this message translates to:
  /// **'Nómina: 5 días y 100. Si fue cosecha, los kilos van al lote.'**
  String get helpWorkersExample3;

  /// No description provided for @helpExampleNote.
  ///
  /// In es, this message translates to:
  /// **'Números de ejemplo, en tu moneda.'**
  String get helpExampleNote;

  /// No description provided for @helpRoutineTitle.
  ///
  /// In es, this message translates to:
  /// **'La rutina que hace que la app sirva'**
  String get helpRoutineTitle;

  /// No description provided for @helpRoutineIntro.
  ///
  /// In es, this message translates to:
  /// **'No necesitas llenar todo. Con estos cuatro momentos, el reporte se arma solo.'**
  String get helpRoutineIntro;

  /// No description provided for @helpRoutineWhen.
  ///
  /// In es, this message translates to:
  /// **'Cuándo'**
  String get helpRoutineWhen;

  /// No description provided for @helpRoutineWhat.
  ///
  /// In es, this message translates to:
  /// **'Qué anotas'**
  String get helpRoutineWhat;

  /// No description provided for @helpRoutineWhere.
  ///
  /// In es, this message translates to:
  /// **'Dónde'**
  String get helpRoutineWhere;

  /// No description provided for @helpRoutineRow1When.
  ///
  /// In es, this message translates to:
  /// **'Cada gasto'**
  String get helpRoutineRow1When;

  /// No description provided for @helpRoutineRow1What.
  ///
  /// In es, this message translates to:
  /// **'Lo que pagaste, con su cultivo'**
  String get helpRoutineRow1What;

  /// No description provided for @helpRoutineRow1Where.
  ///
  /// In es, this message translates to:
  /// **'Registrar › Gasto'**
  String get helpRoutineRow1Where;

  /// No description provided for @helpRoutineRow2When.
  ///
  /// In es, this message translates to:
  /// **'Cada venta'**
  String get helpRoutineRow2When;

  /// No description provided for @helpRoutineRow2What.
  ///
  /// In es, this message translates to:
  /// **'Kilos y lo que te pagaron'**
  String get helpRoutineRow2What;

  /// No description provided for @helpRoutineRow2Where.
  ///
  /// In es, this message translates to:
  /// **'Registrar › Ingreso'**
  String get helpRoutineRow2Where;

  /// No description provided for @helpRoutineRow3When.
  ///
  /// In es, this message translates to:
  /// **'Cada pago'**
  String get helpRoutineRow3When;

  /// No description provided for @helpRoutineRow3What.
  ///
  /// In es, this message translates to:
  /// **'Trabajador, días y labor'**
  String get helpRoutineRow3What;

  /// No description provided for @helpRoutineRow3Where.
  ///
  /// In es, this message translates to:
  /// **'Registrar › Gasto › Mano de obra'**
  String get helpRoutineRow3Where;

  /// No description provided for @helpRoutineRow4When.
  ///
  /// In es, this message translates to:
  /// **'Fin de mes'**
  String get helpRoutineRow4When;

  /// No description provided for @helpRoutineRow4What.
  ///
  /// In es, this message translates to:
  /// **'Revisas el balance y guardas el respaldo'**
  String get helpRoutineRow4What;

  /// No description provided for @helpRoutineRow4Where.
  ///
  /// In es, this message translates to:
  /// **'Reporte · Configuración › Respaldo'**
  String get helpRoutineRow4Where;

  /// No description provided for @helpRoutineGoldenTitle.
  ///
  /// In es, this message translates to:
  /// **'La regla de oro:'**
  String get helpRoutineGoldenTitle;

  /// No description provided for @helpRoutineGolden.
  ///
  /// In es, this message translates to:
  /// **'si no lo anotas, la app no lo sabe. No inventa cifras: lo que falta, lo dice.'**
  String get helpRoutineGolden;

  /// No description provided for @helpRoutineTwiceTitle.
  ///
  /// In es, this message translates to:
  /// **'Tres cosas que no se anotan dos veces'**
  String get helpRoutineTwiceTitle;

  /// No description provided for @helpRoutineTwice1.
  ///
  /// In es, this message translates to:
  /// **'La cosecha: se registra con la venta (kilos) o con el jornal de cosecha, no en los dos.'**
  String get helpRoutineTwice1;

  /// No description provided for @helpRoutineTwice2.
  ///
  /// In es, this message translates to:
  /// **'El pago del trabajador: va en Mano de obra, no en la categoría de la labor.'**
  String get helpRoutineTwice2;

  /// No description provided for @helpRoutineTwice3.
  ///
  /// In es, this message translates to:
  /// **'El costo de la siembra: va en la siembra y crea su gasto vinculado; no se repite en Registrar.'**
  String get helpRoutineTwice3;

  /// No description provided for @helpDictTitle.
  ///
  /// In es, this message translates to:
  /// **'Lo que significan tus números'**
  String get helpDictTitle;

  /// No description provided for @helpDictIntro.
  ///
  /// In es, this message translates to:
  /// **'Los términos que más vas a ver. Toca «Ver todos los términos» para el glosario completo.'**
  String get helpDictIntro;

  /// No description provided for @helpDictSeeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todos los términos'**
  String get helpDictSeeAll;

  /// No description provided for @helpDictCurrencyTitle.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get helpDictCurrencyTitle;

  /// No description provided for @helpDictCurrencyBody.
  ///
  /// In es, this message translates to:
  /// **'La app muestra siempre el código de la moneda, nunca un símbolo. No suma monedas distintas: cada una sale por separado, con su código. La moneda de la cuenta se elige al empezar y no se cambia.'**
  String get helpDictCurrencyBody;

  /// No description provided for @helpTroubleTitle.
  ///
  /// In es, this message translates to:
  /// **'Si algo no cuadra'**
  String get helpTroubleTitle;

  /// No description provided for @helpTrouble1Title.
  ///
  /// In es, this message translates to:
  /// **'El gasto no aparece en el cultivo'**
  String get helpTrouble1Title;

  /// No description provided for @helpTrouble1Body.
  ///
  /// In es, this message translates to:
  /// **'Revisa que lo hayas asignado. Si quedó «Sin especificar», cae en «Costos comunes».'**
  String get helpTrouble1Body;

  /// No description provided for @helpTrouble2Title.
  ///
  /// In es, this message translates to:
  /// **'La venta no coincide con la cosecha'**
  String get helpTrouble2Title;

  /// No description provided for @helpTrouble2Body.
  ///
  /// In es, this message translates to:
  /// **'La venta registra la cosecha con los kilos que anotes. Si ya la anotaste en el jornal, no la repitas.'**
  String get helpTrouble2Body;

  /// No description provided for @helpTrouble3Title.
  ///
  /// In es, this message translates to:
  /// **'Hay dos monedas y no veo un total'**
  String get helpTrouble3Title;

  /// No description provided for @helpTrouble3Body.
  ///
  /// In es, this message translates to:
  /// **'Es a propósito: no se suman monedas distintas. Cada una sale con su código.'**
  String get helpTrouble3Body;

  /// No description provided for @helpTrouble4Title.
  ///
  /// In es, this message translates to:
  /// **'El área no cuadra'**
  String get helpTrouble4Title;

  /// No description provided for @helpTrouble4Body.
  ///
  /// In es, this message translates to:
  /// **'La suma de cultivos puede superar el área del terreno. La app avisa, no bloquea. Corrige el área o el reparto.'**
  String get helpTrouble4Body;

  /// No description provided for @helpTrouble5Title.
  ///
  /// In es, this message translates to:
  /// **'No subió a la nube'**
  String get helpTrouble5Title;

  /// No description provided for @helpTrouble5Body.
  ///
  /// In es, this message translates to:
  /// **'La app guarda primero en tu equipo. Sin señal queda pendiente y sube al reconectar. Puedes reintentar.'**
  String get helpTrouble5Body;

  /// No description provided for @helpTrouble6Title.
  ///
  /// In es, this message translates to:
  /// **'Borré sin querer'**
  String get helpTrouble6Title;

  /// No description provided for @helpTrouble6Body.
  ///
  /// In es, this message translates to:
  /// **'Mira Historial. Si no está, restaura el respaldo: lo que ya tenías se conserva y lo del archivo se suma.'**
  String get helpTrouble6Body;

  /// No description provided for @helpTroubleFooter.
  ///
  /// In es, this message translates to:
  /// **'¿No encuentras tu caso? Anota lo que pasó y el reporte se ajusta. La app no inventa cifras: si falta un dato, lo dice.'**
  String get helpTroubleFooter;

  /// No description provided for @helpTitle.
  ///
  /// In es, this message translates to:
  /// **'Ayuda'**
  String get helpTitle;

  /// No description provided for @helpUnitsTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué unidad uso?'**
  String get helpUnitsTitle;

  /// No description provided for @helpUnitsBody.
  ///
  /// In es, this message translates to:
  /// **'Puedes usar kilogramos (kg), libras (lb), arrobas (1 arroba = 12,5 kg), sacos o cargas (1 carga = 60 lb = 27,2 kg). La app convierte todo a kg para comparar, con el peso del saco que defines en Configuración. Usa la unidad con la que trabajas normalmente.'**
  String get helpUnitsBody;

  /// No description provided for @syncTooltip.
  ///
  /// In es, this message translates to:
  /// **'Sincronizar'**
  String get syncTooltip;

  /// No description provided for @syncFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo sincronizar'**
  String get syncFailed;

  /// No description provided for @syncRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get syncRetry;

  /// No description provided for @syncErrorTooltip.
  ///
  /// In es, this message translates to:
  /// **'Hay datos sin sincronizar. Toca para ver el detalle'**
  String get syncErrorTooltip;

  /// No description provided for @menuReport.
  ///
  /// In es, this message translates to:
  /// **'Reporte'**
  String get menuReport;

  /// No description provided for @menuSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get menuSettings;

  /// No description provided for @menuLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get menuLogout;

  /// No description provided for @menuSowings.
  ///
  /// In es, this message translates to:
  /// **'Siembras'**
  String get menuSowings;

  /// No description provided for @menuHarvests.
  ///
  /// In es, this message translates to:
  /// **'Cosechas'**
  String get menuHarvests;

  /// No description provided for @menuHelp.
  ///
  /// In es, this message translates to:
  /// **'Ayuda'**
  String get menuHelp;

  /// No description provided for @unitRacimo.
  ///
  /// In es, this message translates to:
  /// **'Racimos'**
  String get unitRacimo;

  /// No description provided for @unitCajon.
  ///
  /// In es, this message translates to:
  /// **'Cajones'**
  String get unitCajon;

  /// No description provided for @defaultUnitLabel.
  ///
  /// In es, this message translates to:
  /// **'Unidad preferida'**
  String get defaultUnitLabel;

  /// No description provided for @defaultUnitNone.
  ///
  /// In es, this message translates to:
  /// **'Sin preferencia'**
  String get defaultUnitNone;

  /// No description provided for @cycleLabel.
  ///
  /// In es, this message translates to:
  /// **'Ciclo'**
  String get cycleLabel;

  /// No description provided for @cyclePerenne.
  ///
  /// In es, this message translates to:
  /// **'Perenne'**
  String get cyclePerenne;

  /// No description provided for @cycleAnual.
  ///
  /// In es, this message translates to:
  /// **'Anual'**
  String get cycleAnual;

  /// No description provided for @phaseLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo va?'**
  String get phaseLabel;

  /// No description provided for @phaseEstablecimiento.
  ///
  /// In es, this message translates to:
  /// **'Sin dar'**
  String get phaseEstablecimiento;

  /// No description provided for @phaseProduccion.
  ///
  /// In es, this message translates to:
  /// **'Dando'**
  String get phaseProduccion;

  /// No description provided for @phaseRenovacion.
  ///
  /// In es, this message translates to:
  /// **'Para renovar'**
  String get phaseRenovacion;

  /// No description provided for @phaseHelp.
  ///
  /// In es, this message translates to:
  /// **'Sin dar = plantío ya sembrado que todavía no produce. La app no te marcará pérdidas en esta etapa.'**
  String get phaseHelp;

  /// No description provided for @helpUnit.
  ///
  /// In es, this message translates to:
  /// **'En qué unidad vendés tu cosecha: kg, lb, arroba (≈12.5 kg), saco, carga (≈27.2 kg), racimo (plátano) o cajón.'**
  String get helpUnit;

  /// No description provided for @helpCycle.
  ///
  /// In es, this message translates to:
  /// **'Perenne = vive muchos años (café, plátano). Anual = se siembra y cosecha en el mismo año (tomate, maíz).'**
  String get helpCycle;

  /// No description provided for @helpArea.
  ///
  /// In es, this message translates to:
  /// **'1 hectárea = 10.000 metros² (≈ 1 campo de fútbol). Si no sabes, déjalo en blanco.'**
  String get helpArea;

  /// No description provided for @helpPlants.
  ///
  /// In es, this message translates to:
  /// **'Cuántas plantas tienes de este cultivo. Si no sabes exacto, aproxima.'**
  String get helpPlants;

  /// No description provided for @helpEstablishment.
  ///
  /// In es, this message translates to:
  /// **'Lo que invertiste en dejar este cultivo listo. Sirve para saber cuándo se paga. Si lo dejas vacío, la app lo suma de tus gastos de siembra inicial (sin resiembras).'**
  String get helpEstablishment;

  /// No description provided for @areaHaLabel.
  ///
  /// In es, this message translates to:
  /// **'Área (hectáreas)'**
  String get areaHaLabel;

  /// No description provided for @livePlantsLabel.
  ///
  /// In es, this message translates to:
  /// **'Plantas vivas'**
  String get livePlantsLabel;

  /// No description provided for @establishmentCostLabel.
  ///
  /// In es, this message translates to:
  /// **'Inversión total'**
  String get establishmentCostLabel;

  /// No description provided for @expectedYieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Meta anual (kg/ha)'**
  String get expectedYieldLabel;

  /// No description provided for @helpExpectedYield.
  ///
  /// In es, this message translates to:
  /// **'Lo que quieres sacar de este lote por año. Es TU número, no una tabla de nadie: la app no mide contra ninguna tabla externa, mide contra lo que tú pusiste. Vacío = no se compara nada.'**
  String get helpExpectedYield;

  /// No description provided for @firstHarvestLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo esperás la primera cosecha?'**
  String get firstHarvestLabel;

  /// No description provided for @firstHarvestEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha estimada'**
  String get firstHarvestEmpty;

  /// Fecha estimada de la primera cosecha y cuánto falta. Solo se muestra si anotó la fecha y todavía no cosechó de verdad.
  ///
  /// In es, this message translates to:
  /// **'primer cosecha est.: {date} · {count, plural, =0{este mes} one{falta {count} mes} other{faltan {count} meses}}'**
  String firstHarvestSoon(String date, int count);

  /// La fecha estimada ya pasó y nunca llegó una cosecha. Se pinta en gris, nunca en rojo ni como alerta: es un dato, no un regaño.
  ///
  /// In es, this message translates to:
  /// **'debería estar rindiendo desde {date}'**
  String firstHarvestOverdue(String date);

  /// No description provided for @cropLockedHint.
  ///
  /// In es, this message translates to:
  /// **'Calculado desde tus siembras'**
  String get cropLockedHint;

  /// No description provided for @cropLossRegister.
  ///
  /// In es, this message translates to:
  /// **'Registrar pérdida'**
  String get cropLossRegister;

  /// Plantas que la app calcula para este cultivo antes de registrar la pérdida
  ///
  /// In es, this message translates to:
  /// **'Hoy la app calcula {count, plural, one{{count} planta} other{{count} plantas}}'**
  String cropLossCurrent(int count);

  /// No description provided for @cropLossRemainingLabel.
  ///
  /// In es, this message translates to:
  /// **'Plantas que quedan'**
  String get cropLossRemainingLabel;

  /// No description provided for @cropLossRemainingHelp.
  ///
  /// In es, this message translates to:
  /// **'Cuenta las que ves en la finca y anota el total.'**
  String get cropLossRemainingHelp;

  /// No description provided for @cropLossInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un número de plantas válido.'**
  String get cropLossInvalid;

  /// No description provided for @cropLossNoChange.
  ///
  /// In es, this message translates to:
  /// **'Ese es el número que ya estaba: no cambia nada.'**
  String get cropLossNoChange;

  /// Plantas muertas que quedan registradas tras el ajuste
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} planta perdida} other{{count} plantas perdidas}}'**
  String cropLossPreviewDied(int count);

  /// Plantas de más en el recuento frente a lo que la app calculaba
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} planta más} other{{count} plantas más}}'**
  String cropLossPreviewAdded(int count);

  /// No description provided for @cropLossSaved.
  ///
  /// In es, this message translates to:
  /// **'Pérdida registrada'**
  String get cropLossSaved;

  /// No description provided for @plantedAtLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Desde cuándo está plantado?'**
  String get plantedAtLabel;

  /// No description provided for @helpPlantedAtShort.
  ///
  /// In es, this message translates to:
  /// **'Opcional. Si no la recuerdas, déjala vacía.'**
  String get helpPlantedAtShort;

  /// No description provided for @plantedAtEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha'**
  String get plantedAtEmpty;

  /// No description provided for @plantedAtClear.
  ///
  /// In es, this message translates to:
  /// **'Borrar la fecha'**
  String get plantedAtClear;

  /// Edad del cultivo, junto a la fase. Se muestra solo si hay datos.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Menos de un año} one{{count} año} other{{count} años}}'**
  String cropAge(int count);

  /// No description provided for @editCropTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar cultivo'**
  String get editCropTitle;

  /// No description provided for @sowingTitle.
  ///
  /// In es, this message translates to:
  /// **'Siembras'**
  String get sowingTitle;

  /// No description provided for @sowingEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay siembras registradas.'**
  String get sowingEmpty;

  /// No description provided for @sowingAdd.
  ///
  /// In es, this message translates to:
  /// **'Nueva siembra'**
  String get sowingAdd;

  /// No description provided for @sowingKindLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get sowingKindLabel;

  /// No description provided for @sowingKindSiembra.
  ///
  /// In es, this message translates to:
  /// **'Siembra inicial'**
  String get sowingKindSiembra;

  /// No description provided for @sowingKindResiembra.
  ///
  /// In es, this message translates to:
  /// **'Resiembra'**
  String get sowingKindResiembra;

  /// No description provided for @helpSowingKind.
  ///
  /// In es, this message translates to:
  /// **'Siembra = plantas por primera vez. Resiembra = reemplazas plantas muertas o dañadas.'**
  String get helpSowingKind;

  /// No description provided for @sowingPlantsLabel.
  ///
  /// In es, this message translates to:
  /// **'Número de plantas'**
  String get sowingPlantsLabel;

  /// No description provided for @helpSowingPlants.
  ///
  /// In es, this message translates to:
  /// **'Cuántas plantas en esta siembra. Si no sabes exacto, aproxima.'**
  String get helpSowingPlants;

  /// No description provided for @sowingLostPlantsLabel.
  ///
  /// In es, this message translates to:
  /// **'Plantas perdidas (bajas)'**
  String get sowingLostPlantsLabel;

  /// No description provided for @sowingMissingLossesTitle.
  ///
  /// In es, this message translates to:
  /// **'Anotaste plantas nuevas sin muertas'**
  String get sowingMissingLossesTitle;

  /// No description provided for @sowingMissingLossesBody.
  ///
  /// In es, this message translates to:
  /// **'En una resiembra conviene anotar cuántas matas se perdieron: es lo que baja el contador del cultivo. Puedes guardar así y completarlo después.'**
  String get sowingMissingLossesBody;

  /// No description provided for @sowingMissingLossesEnter.
  ///
  /// In es, this message translates to:
  /// **'Anotar muertas'**
  String get sowingMissingLossesEnter;

  /// No description provided for @sowingMissingLossesSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar así'**
  String get sowingMissingLossesSave;

  /// No description provided for @helpSowingLostPlants.
  ///
  /// In es, this message translates to:
  /// **'Cuántas plantas se murieron o perdieron (plagas, clima, etc.).'**
  String get helpSowingLostPlants;

  /// No description provided for @sowingReasonLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo (opcional)'**
  String get sowingReasonLabel;

  /// No description provided for @sowingAreaLabel.
  ///
  /// In es, this message translates to:
  /// **'Área (hectáreas, opcional)'**
  String get sowingAreaLabel;

  /// No description provided for @helpSowingArea.
  ///
  /// In es, this message translates to:
  /// **'1 hectárea = 10.000 metros² (≈ 1 campo de fútbol).'**
  String get helpSowingArea;

  /// No description provided for @sowingCostLabel.
  ///
  /// In es, this message translates to:
  /// **'Costo (opcional)'**
  String get sowingCostLabel;

  /// No description provided for @sowingCostHint.
  ///
  /// In es, this message translates to:
  /// **'Si registras un costo, se crea un gasto vinculado a esta siembra o resiembra.'**
  String get sowingCostHint;

  /// No description provided for @sowingCostInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un costo válido (solo números).'**
  String get sowingCostInvalid;

  /// No description provided for @helpUnitShort.
  ///
  /// In es, this message translates to:
  /// **'Unidad con la que cosechás o vendés este cultivo.'**
  String get helpUnitShort;

  /// No description provided for @helpCycleShort.
  ///
  /// In es, this message translates to:
  /// **'Perenne o anual'**
  String get helpCycleShort;

  /// No description provided for @phaseHelpShort.
  ///
  /// In es, this message translates to:
  /// **'Fase del cultivo'**
  String get phaseHelpShort;

  /// No description provided for @helpAreaShort.
  ///
  /// In es, this message translates to:
  /// **'Opcional, en ha'**
  String get helpAreaShort;

  /// No description provided for @helpPlantsShort.
  ///
  /// In es, this message translates to:
  /// **'Aproximado'**
  String get helpPlantsShort;

  /// No description provided for @helpEstablishmentShort.
  ///
  /// In es, this message translates to:
  /// **'Se rellena con tus gastos de siembra'**
  String get helpEstablishmentShort;

  /// No description provided for @helpExpectedYieldShort.
  ///
  /// In es, this message translates to:
  /// **'Opcional, tu propia meta'**
  String get helpExpectedYieldShort;

  /// No description provided for @helpFirstHarvestShort.
  ///
  /// In es, this message translates to:
  /// **'Opcional. Es TU fecha: la app solo hace la cuenta.'**
  String get helpFirstHarvestShort;

  /// No description provided for @helpSowingPlantsShort.
  ///
  /// In es, this message translates to:
  /// **'Aproximado'**
  String get helpSowingPlantsShort;

  /// No description provided for @helpSowingLostPlantsShort.
  ///
  /// In es, this message translates to:
  /// **'Muertas o dañadas'**
  String get helpSowingLostPlantsShort;

  /// No description provided for @helpSowingAreaShort.
  ///
  /// In es, this message translates to:
  /// **'En hectáreas'**
  String get helpSowingAreaShort;

  /// No description provided for @sowingCostHintShort.
  ///
  /// In es, this message translates to:
  /// **'Crea gasto vinculado'**
  String get sowingCostHintShort;

  /// No description provided for @plantsInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un número de plantas válido'**
  String get plantsInvalid;

  /// No description provided for @sowingPlantsOrLost.
  ///
  /// In es, this message translates to:
  /// **'Pon las plantas que sembraste o las que se te murieron.'**
  String get sowingPlantsOrLost;

  /// No description provided for @sowingRecordSaved.
  ///
  /// In es, this message translates to:
  /// **'Siembra guardada'**
  String get sowingRecordSaved;

  /// No description provided for @sowingRecordUpdated.
  ///
  /// In es, this message translates to:
  /// **'Siembra actualizada'**
  String get sowingRecordUpdated;

  /// No description provided for @sowingRecordDeleted.
  ///
  /// In es, this message translates to:
  /// **'Siembra eliminada'**
  String get sowingRecordDeleted;

  /// No description provided for @sowingConfirmDelete.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta siembra?'**
  String get sowingConfirmDelete;

  /// No description provided for @harvestTitle.
  ///
  /// In es, this message translates to:
  /// **'Cosechas'**
  String get harvestTitle;

  /// No description provided for @harvestEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay cosechas registradas.'**
  String get harvestEmpty;

  /// No description provided for @harvestAdd.
  ///
  /// In es, this message translates to:
  /// **'Nueva cosecha'**
  String get harvestAdd;

  /// No description provided for @harvestAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get harvestAmountLabel;

  /// No description provided for @harvestUnitLabel.
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get harvestUnitLabel;

  /// No description provided for @harvestDestinationLabel.
  ///
  /// In es, this message translates to:
  /// **'Destino'**
  String get harvestDestinationLabel;

  /// No description provided for @harvestDstVendido.
  ///
  /// In es, this message translates to:
  /// **'Vendido'**
  String get harvestDstVendido;

  /// No description provided for @harvestDstAlmacenado.
  ///
  /// In es, this message translates to:
  /// **'Almacenado'**
  String get harvestDstAlmacenado;

  /// No description provided for @harvestDstPerdida.
  ///
  /// In es, this message translates to:
  /// **'Pérdida'**
  String get harvestDstPerdida;

  /// No description provided for @harvestAmountInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa una cantidad mayor a 0'**
  String get harvestAmountInvalid;

  /// No description provided for @harvestRecordSaved.
  ///
  /// In es, this message translates to:
  /// **'Cosecha guardada'**
  String get harvestRecordSaved;

  /// No description provided for @harvestRecordUpdated.
  ///
  /// In es, this message translates to:
  /// **'Cosecha actualizada'**
  String get harvestRecordUpdated;

  /// No description provided for @harvestRecordDeleted.
  ///
  /// In es, this message translates to:
  /// **'Cosecha eliminada'**
  String get harvestRecordDeleted;

  /// No description provided for @harvestConfirmDelete.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta cosecha?'**
  String get harvestConfirmDelete;

  /// No description provided for @expenseLinkHarvestLabel.
  ///
  /// In es, this message translates to:
  /// **'Vincular a cosecha (opcional)'**
  String get expenseLinkHarvestLabel;

  /// No description provided for @expenseLinkHarvestNone.
  ///
  /// In es, this message translates to:
  /// **'Sin vincular'**
  String get expenseLinkHarvestNone;

  /// No description provided for @unitPreferenceHint.
  ///
  /// In es, this message translates to:
  /// **'Se usa tu unidad preferida si aún no eliges una.'**
  String get unitPreferenceHint;

  /// No description provided for @reportHarvestSection.
  ///
  /// In es, this message translates to:
  /// **'Cosechas del período'**
  String get reportHarvestSection;

  /// No description provided for @reportHarvestedTotal.
  ///
  /// In es, this message translates to:
  /// **'Total cosechado por cultivo'**
  String get reportHarvestedTotal;

  /// No description provided for @reportHarvestKg.
  ///
  /// In es, this message translates to:
  /// **'Kg (normalizado)'**
  String get reportHarvestKg;

  /// No description provided for @reportHarvestDestinations.
  ///
  /// In es, this message translates to:
  /// **'Por destino'**
  String get reportHarvestDestinations;

  /// Cosechas en racimo o cajón a las que les falta el peso total y por eso no suman kilos.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} cosecha sin peso} other{{count} cosechas sin peso}}'**
  String reportPendingWeightHarvests(int count);

  /// Ventas en racimo o cajón a las que les falta el peso total y por eso no suman kilos.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} venta sin peso} other{{count} ventas sin peso}}'**
  String reportPendingWeightSales(int count);

  /// No description provided for @reportPendingWeightTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin peso (no entran en los kilos)'**
  String get reportPendingWeightTitle;

  /// No description provided for @reportPendingWeightHint.
  ///
  /// In es, this message translates to:
  /// **'Anota el peso total para que sumen kilos.'**
  String get reportPendingWeightHint;

  /// No description provided for @reportPickupCostPerKg.
  ///
  /// In es, this message translates to:
  /// **'Costo de recogida por kg'**
  String get reportPickupCostPerKg;

  /// No description provided for @reportTotalCostPerKg.
  ///
  /// In es, this message translates to:
  /// **'Costo total por kg'**
  String get reportTotalCostPerKg;

  /// No description provided for @reportInvestmentEstablecimiento.
  ///
  /// In es, this message translates to:
  /// **'Inversión acumulada (establecimiento)'**
  String get reportInvestmentEstablecimiento;

  /// No description provided for @reportYieldPerArea.
  ///
  /// In es, this message translates to:
  /// **'Rendimiento por área del período (kg/ha)'**
  String get reportYieldPerArea;

  /// No description provided for @reportYieldPerPlant.
  ///
  /// In es, this message translates to:
  /// **'Rendimiento por planta del período (kg/planta)'**
  String get reportYieldPerPlant;

  /// No description provided for @reportApprox.
  ///
  /// In es, this message translates to:
  /// **'(aproximado)'**
  String get reportApprox;

  /// No description provided for @reportSoldVsHarvested.
  ///
  /// In es, this message translates to:
  /// **'Vendido vs cosechado'**
  String get reportSoldVsHarvested;

  /// No description provided for @reportSoldKg.
  ///
  /// In es, this message translates to:
  /// **'Vendido (kg)'**
  String get reportSoldKg;

  /// No description provided for @reportHarvestedKg.
  ///
  /// In es, this message translates to:
  /// **'Cosechado (kg)'**
  String get reportHarvestedKg;

  /// No description provided for @soldVsHarvestedMismatch.
  ///
  /// In es, this message translates to:
  /// **'Vendiste {pct}% más de lo que cosechaste en este período. Suele ser una cosecha de meses anteriores o una cosecha sin registrar.'**
  String soldVsHarvestedMismatch(Object pct);

  /// No description provided for @soldVsHarvestedNoHarvest.
  ///
  /// In es, this message translates to:
  /// **'No registraste cosecha de este cultivo en el período. Esta venta puede venir de una cosecha de meses anteriores.'**
  String get soldVsHarvestedNoHarvest;

  /// No description provided for @reportSowingsSection.
  ///
  /// In es, this message translates to:
  /// **'Siembras'**
  String get reportSowingsSection;

  /// No description provided for @reportSowingsNow.
  ///
  /// In es, this message translates to:
  /// **'¿Qué tengo plantado hoy?'**
  String get reportSowingsNow;

  /// No description provided for @reportSowingsPlantOne.
  ///
  /// In es, this message translates to:
  /// **'planta'**
  String get reportSowingsPlantOne;

  /// No description provided for @reportSowingsPlantMany.
  ///
  /// In es, this message translates to:
  /// **'plantas'**
  String get reportSowingsPlantMany;

  /// No description provided for @reportSowingsTotal.
  ///
  /// In es, this message translates to:
  /// **'Total plantado'**
  String get reportSowingsTotal;

  /// No description provided for @reportSowingsLosses.
  ///
  /// In es, this message translates to:
  /// **'Pérdidas acumuladas'**
  String get reportSowingsLosses;

  /// No description provided for @reportSowingsInPeriod.
  ///
  /// In es, this message translates to:
  /// **'Siembras en {period}'**
  String reportSowingsInPeriod(Object period);

  /// No description provided for @reportSowingsKindSiembra.
  ///
  /// In es, this message translates to:
  /// **'siembra'**
  String get reportSowingsKindSiembra;

  /// No description provided for @reportSowingsKindResiembra.
  ///
  /// In es, this message translates to:
  /// **'resiembra'**
  String get reportSowingsKindResiembra;

  /// No description provided for @reportSowingsLostLine.
  ///
  /// In es, this message translates to:
  /// **'↳ perdidas {count} · {reason}'**
  String reportSowingsLostLine(Object count, Object reason);

  /// No description provided for @reportSowingsLostOnly.
  ///
  /// In es, this message translates to:
  /// **'↳ perdidas {count}'**
  String reportSowingsLostOnly(Object count);

  /// No description provided for @reportSowingsNoPeriod.
  ///
  /// In es, this message translates to:
  /// **'No registraste siembras en este período.'**
  String get reportSowingsNoPeriod;

  /// No description provided for @reportWhatsNext.
  ///
  /// In es, this message translates to:
  /// **'Qué hacer'**
  String get reportWhatsNext;

  /// No description provided for @reportNoRecommendations.
  ///
  /// In es, this message translates to:
  /// **'No hay recomendaciones para este período.'**
  String get reportNoRecommendations;

  /// No description provided for @reportNoHarvestData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos de cosechas en el período.'**
  String get reportNoHarvestData;

  /// No description provided for @harvestWorkersLabel.
  ///
  /// In es, this message translates to:
  /// **'N° de empleados'**
  String get harvestWorkersLabel;

  /// No description provided for @harvestWorkersHint.
  ///
  /// In es, this message translates to:
  /// **'Opcional. Personas que trabajaron en la cosecha.'**
  String get harvestWorkersHint;

  /// No description provided for @harvestWorkersInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un entero mayor o igual a 0.'**
  String get harvestWorkersInvalid;

  /// Cantidad de trabajadores en una cosecha
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} empleado} other{{count} empleados}}'**
  String harvestWorkersCount(int count);

  /// No description provided for @harvestEquivalentKgLabel.
  ///
  /// In es, this message translates to:
  /// **'Peso total (kg)'**
  String get harvestEquivalentKgLabel;

  /// No description provided for @harvestEquivalentKgHint.
  ///
  /// In es, this message translates to:
  /// **'Obligatorio: lo que pesaron los racimos o cajones juntos.'**
  String get harvestEquivalentKgHint;

  /// No description provided for @harvestEquivalentKgInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un número mayor que 0.'**
  String get harvestEquivalentKgInvalid;

  /// No description provided for @harvestEquivalentKgRequired.
  ///
  /// In es, this message translates to:
  /// **'Anota el peso total para poder contar los kilos.'**
  String get harvestEquivalentKgRequired;

  /// Precio por unidad de la cosecha; la unidad va al final
  ///
  /// In es, this message translates to:
  /// **'Precio por {unit}'**
  String harvestPriceLabel(String unit);

  /// No description provided for @harvestPriceHint.
  ///
  /// In es, this message translates to:
  /// **'Si ya te pagaron, anótalo aquí y la app registra la venta sola. Déjalo vacío si aún no cobras.'**
  String get harvestPriceHint;

  /// No description provided for @harvestPriceInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un precio válido (solo números).'**
  String get harvestPriceInvalid;

  /// Importe que se registrará como venta al guardar la cosecha
  ///
  /// In es, this message translates to:
  /// **'Se registra la venta: {amount}'**
  String harvestSalePreview(String amount);

  /// No description provided for @reportPayrollSection.
  ///
  /// In es, this message translates to:
  /// **'Nómina del período'**
  String get reportPayrollSection;

  /// No description provided for @reportPayrollBudgetNote.
  ///
  /// In es, this message translates to:
  /// **'Esto es lo gastado por tarea; el presupuesto de caja es uno solo.'**
  String get reportPayrollBudgetNote;

  /// No description provided for @reportPayrollWorker.
  ///
  /// In es, this message translates to:
  /// **'Trabajador'**
  String get reportPayrollWorker;

  /// No description provided for @reportPayrollDays.
  ///
  /// In es, this message translates to:
  /// **'Días'**
  String get reportPayrollDays;

  /// No description provided for @reportPayrollSubtotal.
  ///
  /// In es, this message translates to:
  /// **'Subtotal'**
  String get reportPayrollSubtotal;

  /// No description provided for @reportPayrollTotal.
  ///
  /// In es, this message translates to:
  /// **'Total nómina'**
  String get reportPayrollTotal;

  /// Empleados distintos con gasto de mano de obra en el período
  ///
  /// In es, this message translates to:
  /// **'Empleados distintos: {count}'**
  String reportPayrollEmployees(int count);

  /// No description provided for @reportPayrollUnnamed.
  ///
  /// In es, this message translates to:
  /// **'Sin nombre'**
  String get reportPayrollUnnamed;

  /// No description provided for @reportCashBoxBudget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto'**
  String get reportCashBoxBudget;

  /// No description provided for @reportCashBoxBalance.
  ///
  /// In es, this message translates to:
  /// **'Saldo'**
  String get reportCashBoxBalance;

  /// No description provided for @reportHarvestStaff.
  ///
  /// In es, this message translates to:
  /// **'Personal y kilos'**
  String get reportHarvestStaff;

  /// No description provided for @reportEquivalentKg.
  ///
  /// In es, this message translates to:
  /// **'Kilos equivalentes'**
  String get reportEquivalentKg;

  /// No description provided for @perHaSection.
  ///
  /// In es, this message translates to:
  /// **'Por hectárea'**
  String get perHaSection;

  /// No description provided for @perHaNoAreaHint.
  ///
  /// In es, this message translates to:
  /// **'Registra el área de tus cultivos (edita el cultivo) para ver su desempeño por hectárea: rendimiento, ingresos y gastos normalizados.'**
  String get perHaNoAreaHint;

  /// No description provided for @perHaYieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Rendimiento del período'**
  String get perHaYieldLabel;

  /// No description provided for @perHaYieldPlantLabel.
  ///
  /// In es, this message translates to:
  /// **'Rendimiento por planta del período'**
  String get perHaYieldPlantLabel;

  /// No description provided for @perHaPerPlantNote.
  ///
  /// In es, this message translates to:
  /// **'kg/planta es el promedio del cultivo; incluye plantas que aún no producen.'**
  String get perHaPerPlantNote;

  /// Promedio anual del propio productor. No es una tabla externa: sale de sus cosechas de años cerrados
  ///
  /// In es, this message translates to:
  /// **'Tu promedio anual ({years} años)'**
  String yieldAvgHaLabel(int years);

  /// Mismo promedio, medida por planta en vez de por hectárea
  ///
  /// In es, this message translates to:
  /// **'Tu promedio por planta ({years} años)'**
  String yieldAvgPlantLabel(int years);

  /// No description provided for @yieldGoalLabel.
  ///
  /// In es, this message translates to:
  /// **'Meta anual'**
  String get yieldGoalLabel;

  /// No description provided for @perHaRevenueLabel.
  ///
  /// In es, this message translates to:
  /// **'Ventas por ha'**
  String get perHaRevenueLabel;

  /// No description provided for @perHaCostLabel.
  ///
  /// In es, this message translates to:
  /// **'Gastos por ha'**
  String get perHaCostLabel;

  /// No description provided for @perHaLotNotSplit.
  ///
  /// In es, this message translates to:
  /// **'El lote no se reparte: falta el área de un cultivo.'**
  String get perHaLotNotSplit;

  /// No description provided for @perHaMarginLabel.
  ///
  /// In es, this message translates to:
  /// **'Margen por ha'**
  String get perHaMarginLabel;

  /// No description provided for @perHaInvestmentLabel.
  ///
  /// In es, this message translates to:
  /// **'Inversión del establecimiento'**
  String get perHaInvestmentLabel;

  /// No description provided for @perHaRecoveredLabel.
  ///
  /// In es, this message translates to:
  /// **'Recuperado'**
  String get perHaRecoveredLabel;

  /// No description provided for @perHaRecoveryPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de recuperarse'**
  String get perHaRecoveryPending;

  /// No description provided for @perHaPaybackLabel.
  ///
  /// In es, this message translates to:
  /// **'Se pagaría en'**
  String get perHaPaybackLabel;

  /// Tiempo estimado para recuperar la inversión del establecimiento
  ///
  /// In es, this message translates to:
  /// **'{years} años (aprox.)'**
  String perHaPaybackYears(String years);

  /// No description provided for @monthJan.
  ///
  /// In es, this message translates to:
  /// **'Enero'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In es, this message translates to:
  /// **'Febrero'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In es, this message translates to:
  /// **'Marzo'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In es, this message translates to:
  /// **'Abril'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In es, this message translates to:
  /// **'Mayo'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In es, this message translates to:
  /// **'Junio'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In es, this message translates to:
  /// **'Julio'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In es, this message translates to:
  /// **'Agosto'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In es, this message translates to:
  /// **'Septiembre'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In es, this message translates to:
  /// **'Octubre'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In es, this message translates to:
  /// **'Noviembre'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In es, this message translates to:
  /// **'Diciembre'**
  String get monthDec;

  /// No description provided for @conjAnd.
  ///
  /// In es, this message translates to:
  /// **'y'**
  String get conjAnd;

  /// No description provided for @sectionThisMonth.
  ///
  /// In es, this message translates to:
  /// **'Este mes'**
  String get sectionThisMonth;

  /// Encabezado del resumen anual
  ///
  /// In es, this message translates to:
  /// **'En el año {year}'**
  String sectionInYear(int year);

  /// No description provided for @incomeLabel.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get incomeLabel;

  /// No description provided for @expensesLabel.
  ///
  /// In es, this message translates to:
  /// **'Gastos'**
  String get expensesLabel;

  /// No description provided for @resultLabel.
  ///
  /// In es, this message translates to:
  /// **'Resultado'**
  String get resultLabel;

  /// Bajo el delta de cada tarjeta del Resumen: contra qué mes se compara
  ///
  /// In es, this message translates to:
  /// **'vs. {month}'**
  String summaryVsPrev(String month);

  /// Pie de la fila de tarjetas: aclara que la comparación usa el mismo tramo de días (B1)
  ///
  /// In es, this message translates to:
  /// **'Comparado con los mismos días de {month}.'**
  String summaryVsPrevNote(String month);

  /// Delta del Resultado en monto, nunca en % (puede ser negativo o cruzar de cero)
  ///
  /// In es, this message translates to:
  /// **'mejoró {amount}'**
  String summaryResultBetter(String amount);

  /// Delta del Resultado en monto, nunca en % (puede ser negativo o cruzar de cero)
  ///
  /// In es, this message translates to:
  /// **'empeoró {amount}'**
  String summaryResultWorse(String amount);

  /// No description provided for @summaryEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no registraste movimientos'**
  String get summaryEmptyTitle;

  /// No description provided for @summaryEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Cuando anotes un gasto o una venta, acá vas a ver cuánto ganaste, cuánto gastaste y qué te quedó.'**
  String get summaryEmptyBody;

  /// No description provided for @alertsTitle.
  ///
  /// In es, this message translates to:
  /// **'Alertas'**
  String get alertsTitle;

  /// No description provided for @alertsTooltip.
  ///
  /// In es, this message translates to:
  /// **'¿Qué significan estas alertas?'**
  String get alertsTooltip;

  /// No description provided for @glossaryTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué significan estos términos?'**
  String get glossaryTitle;

  /// No description provided for @glossaryGotIt.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get glossaryGotIt;

  /// No description provided for @glossaryIncomeTerm.
  ///
  /// In es, this message translates to:
  /// **'Ingreso'**
  String get glossaryIncomeTerm;

  /// No description provided for @glossaryIncomeDef.
  ///
  /// In es, this message translates to:
  /// **'Lo que te pagaron por lo que vendiste. No es lo mismo que cosechar: puedes cosechar y no vender.'**
  String get glossaryIncomeDef;

  /// No description provided for @glossaryExpenseTerm.
  ///
  /// In es, this message translates to:
  /// **'Gasto'**
  String get glossaryExpenseTerm;

  /// No description provided for @glossaryExpenseDef.
  ///
  /// In es, this message translates to:
  /// **'Lo que pagaste para producir o mantener la finca. Si es de un cultivo, asígnalo.'**
  String get glossaryExpenseDef;

  /// No description provided for @glossaryBalanceTerm.
  ///
  /// In es, this message translates to:
  /// **'Balance / Resultado'**
  String get glossaryBalanceTerm;

  /// No description provided for @glossaryBalanceDef.
  ///
  /// In es, this message translates to:
  /// **'Es la resta de Ingresos menos Gastos en un período. Si el resultado es positivo tienes ganancia; si es negativo, pérdida.'**
  String get glossaryBalanceDef;

  /// No description provided for @glossaryMarginTerm.
  ///
  /// In es, this message translates to:
  /// **'Margen'**
  String get glossaryMarginTerm;

  /// No description provided for @glossaryMarginDef.
  ///
  /// In es, this message translates to:
  /// **'De cada 100 que vendes, cuánto queda después de cubrir los gastos. Se calcula como (Ingresos - Gastos) ÷ Ingresos: si vendes 100 y gastas 40, el margen es 60%. Un margen negativo significa que gastas más de lo que vendes.'**
  String get glossaryMarginDef;

  /// No description provided for @glossaryRatioTerm.
  ///
  /// In es, this message translates to:
  /// **'Gastos vs ingresos'**
  String get glossaryRatioTerm;

  /// No description provided for @glossaryRatioDef.
  ///
  /// In es, this message translates to:
  /// **'Qué porcentaje de tus ingresos se va en gastos. Por ejemplo, 80% quiere decir que por cada 100 que entran, 80 se gastan y quedan 20.'**
  String get glossaryRatioDef;

  /// No description provided for @glossaryAvgTerm.
  ///
  /// In es, this message translates to:
  /// **'Promedio histórico mensual'**
  String get glossaryAvgTerm;

  /// No description provided for @glossaryAvgDef.
  ///
  /// In es, this message translates to:
  /// **'El promedio de lo que gastas al mes en una categoría (por ejemplo, mano de obra). Sirve como referencia para detectar aumentos inusuales en tus gastos.'**
  String get glossaryAvgDef;

  /// No description provided for @glossaryYieldAreaTerm.
  ///
  /// In es, this message translates to:
  /// **'Rendimiento por área (kg/ha)'**
  String get glossaryYieldAreaTerm;

  /// No description provided for @glossaryYieldAreaDef.
  ///
  /// In es, this message translates to:
  /// **'Cuántos kilos sacas de una hectárea. Sirve para comparar lotes de tamaños distintos: si uno da 1.200 kg/ha y otro 800 kg/ha, el primero rinde más con la misma tierra.'**
  String get glossaryYieldAreaDef;

  /// No description provided for @glossaryYieldPlantTerm.
  ///
  /// In es, this message translates to:
  /// **'Rendimiento por planta (kg/planta)'**
  String get glossaryYieldPlantTerm;

  /// No description provided for @glossaryYieldPlantDef.
  ///
  /// In es, this message translates to:
  /// **'Cuántos kilos produce cada planta. Te ayuda a ver si el problema es la cantidad de plantas o el cuidado del cultivo.'**
  String get glossaryYieldPlantDef;

  /// No description provided for @glossaryCostPerKgTerm.
  ///
  /// In es, this message translates to:
  /// **'Costo total por kg'**
  String get glossaryCostPerKgTerm;

  /// No description provided for @glossaryCostPerKgDef.
  ///
  /// In es, this message translates to:
  /// **'Todo lo que te costó producir cada kilo (establecimiento, mano de obra y gastos del período) dividido entre los kilos cosechados. Si vendes por debajo de este número, pierdes dinero.'**
  String get glossaryCostPerKgDef;

  /// No description provided for @glossaryPickupCostTerm.
  ///
  /// In es, this message translates to:
  /// **'Costo de recogida por kg'**
  String get glossaryPickupCostTerm;

  /// No description provided for @glossaryPickupCostDef.
  ///
  /// In es, this message translates to:
  /// **'Lo que pagas por recoger un kilo: jornales y recolección, sin contar lo invertido en plantar. Es el costo inmediato de cada cosecha.'**
  String get glossaryPickupCostDef;

  /// No description provided for @glossaryEstablishmentTerm.
  ///
  /// In es, this message translates to:
  /// **'Inversión de establecimiento'**
  String get glossaryEstablishmentTerm;

  /// No description provided for @glossaryEstablishmentDef.
  ///
  /// In es, this message translates to:
  /// **'Lo que invertiste para empezar el cultivo: plantines, abono inicial y la mano de obra de plantar. No es una pérdida, es una inversión que se recupera con las ventas.'**
  String get glossaryEstablishmentDef;

  /// No description provided for @glossaryPaybackTerm.
  ///
  /// In es, this message translates to:
  /// **'Payback (recuperación)'**
  String get glossaryPaybackTerm;

  /// No description provided for @glossaryPaybackDef.
  ///
  /// In es, this message translates to:
  /// **'Cuánto te lleva recuperar lo invertido en establecimiento. 100% significa que ya lo pagaste por completo con lo que vendiste.'**
  String get glossaryPaybackDef;

  /// No description provided for @glossarySubtotalTerm.
  ///
  /// In es, this message translates to:
  /// **'Subtotal'**
  String get glossarySubtotalTerm;

  /// No description provided for @glossarySubtotalDef.
  ///
  /// In es, this message translates to:
  /// **'Suma parcial de un grupo de filas antes del total general. En la nómina es lo que se le paga a cada trabajador antes del total del período.'**
  String get glossarySubtotalDef;

  /// No description provided for @glossaryYtdTerm.
  ///
  /// In es, this message translates to:
  /// **'Año a la fecha (YTD)'**
  String get glossaryYtdTerm;

  /// No description provided for @glossaryYtdDef.
  ///
  /// In es, this message translates to:
  /// **'Lo que va acumulado desde el 1 de enero de este año hasta hoy, sin importar en qué mes estés mirando.'**
  String get glossaryYtdDef;

  /// No description provided for @glossaryPayrollTerm.
  ///
  /// In es, this message translates to:
  /// **'Nómina del período'**
  String get glossaryPayrollTerm;

  /// No description provided for @glossaryPayrollDef.
  ///
  /// In es, this message translates to:
  /// **'Lo que se pagó por mano de obra en el período: personas, días trabajados y jornales. No incluye lo que inviertes en plantar.'**
  String get glossaryPayrollDef;

  /// No description provided for @glossaryCashBoxTerm.
  ///
  /// In es, this message translates to:
  /// **'Caja menor'**
  String get glossaryCashBoxTerm;

  /// No description provided for @glossaryCashBoxDef.
  ///
  /// In es, this message translates to:
  /// **'Dinero disponible para gastos pequeños del mes: transporte, herramientas e imprevistos. Se compara con el presupuesto que definiste para no pasarte.'**
  String get glossaryCashBoxDef;

  /// No description provided for @glossarySoldVsHarvestedTerm.
  ///
  /// In es, this message translates to:
  /// **'Vendido vs cosechado'**
  String get glossarySoldVsHarvestedTerm;

  /// No description provided for @glossarySoldVsHarvestedDef.
  ///
  /// In es, this message translates to:
  /// **'Compara los kilos que vendiste con los que cosechaste en el mismo período. Si vendiste más, suele ser una cosecha de meses anteriores o una cosecha sin registrar.'**
  String get glossarySoldVsHarvestedDef;

  /// No description provided for @glossaryMarginTooltip.
  ///
  /// In es, this message translates to:
  /// **'¿Qué significa margen?'**
  String get glossaryMarginTooltip;

  /// No description provided for @authSubtitleSignup.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta para llevar tus finanzas'**
  String get authSubtitleSignup;

  /// No description provided for @authSubtitleWelcome.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido de vuelta'**
  String get authSubtitleWelcome;

  /// No description provided for @authEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authPasswordLabel;

  /// No description provided for @authInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo válido'**
  String get authInvalidEmail;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get authPasswordTooShort;

  /// No description provided for @authCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get authCreateAccount;

  /// No description provided for @authSignIn.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get authSignIn;

  /// No description provided for @authHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Entra'**
  String get authHaveAccount;

  /// No description provided for @authNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get authNoAccount;

  /// No description provided for @authCreatedMsg.
  ///
  /// In es, this message translates to:
  /// **'Cuenta creada. Revisa tu correo (incluye spam) para confirmar y luego inicia sesión.'**
  String get authCreatedMsg;

  /// No description provided for @authCreateError.
  ///
  /// In es, this message translates to:
  /// **'Error al crear la cuenta'**
  String get authCreateError;

  /// No description provided for @authSignInError.
  ///
  /// In es, this message translates to:
  /// **'Error al iniciar sesión'**
  String get authSignInError;

  /// No description provided for @authForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get authForgotPassword;

  /// No description provided for @authResetSent.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un enlace para restablecer tu contraseña. Revisa tu correo (incluye spam).'**
  String get authResetSent;

  /// No description provided for @registerEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar movimiento'**
  String get registerEditTitle;

  /// No description provided for @expenseTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Gasto'**
  String get expenseTypeLabel;

  /// No description provided for @incomeTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Ingreso'**
  String get incomeTypeLabel;

  /// No description provided for @cropFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Cultivo o lote (opcional)'**
  String get cropFieldLabel;

  /// No description provided for @cropUnspecified.
  ///
  /// In es, this message translates to:
  /// **'Sin especificar'**
  String get cropUnspecified;

  /// No description provided for @cropNewOption.
  ///
  /// In es, this message translates to:
  /// **'+ Nueva variedad…'**
  String get cropNewOption;

  /// No description provided for @cropGroupHint.
  ///
  /// In es, this message translates to:
  /// **'Toca «+ Nueva variedad…» para crear un cultivo nuevo; los que ya tienes están en la lista. Los movimientos del mismo cultivo se suman juntos en el reporte.'**
  String get cropGroupHint;

  /// No description provided for @commonCosts.
  ///
  /// In es, this message translates to:
  /// **'Costos comunes'**
  String get commonCosts;

  /// No description provided for @commonCostsHint.
  ///
  /// In es, this message translates to:
  /// **'Es un gasto de toda la finca (cerca, camino, luz). No afecta el costo/kg de ningún cultivo, pero sí el resultado total.'**
  String get commonCostsHint;

  /// No description provided for @expenseSplitTitle.
  ///
  /// In es, this message translates to:
  /// **'Repartir entre cultivos'**
  String get expenseSplitTitle;

  /// No description provided for @expenseSplitBody.
  ///
  /// In es, this message translates to:
  /// **'El gasto sirve a varios cultivos. Se guardan gastos separados, uno por cultivo, que suman el total.'**
  String get expenseSplitBody;

  /// No description provided for @expenseSplitHint.
  ///
  /// In es, this message translates to:
  /// **'El gasto se reparte entre cultivos: se guardan gastos separados que suman el total.'**
  String get expenseSplitHint;

  /// No description provided for @expenseSplitUseAreas.
  ///
  /// In es, this message translates to:
  /// **'Usar áreas'**
  String get expenseSplitUseAreas;

  /// Suma de los porcentajes del reparto de un gasto
  ///
  /// In es, this message translates to:
  /// **'Suma: {percent} %'**
  String expenseSplitSum(String percent);

  /// No description provided for @expenseSplitMustSum.
  ///
  /// In es, this message translates to:
  /// **'Los porcentajes tienen que sumar 100 %.'**
  String get expenseSplitMustSum;

  /// No description provided for @expenseSplitZero.
  ///
  /// In es, this message translates to:
  /// **'Cada cultivo elegido necesita un porcentaje mayor que 0.'**
  String get expenseSplitZero;

  /// No description provided for @expenseSplitFew.
  ///
  /// In es, this message translates to:
  /// **'Elige al menos dos cultivos.'**
  String get expenseSplitFew;

  /// No description provided for @expenseSplitNoAreas.
  ///
  /// In es, this message translates to:
  /// **'Para usar las áreas, al menos dos cultivos tienen que tener su hectáreaje anotado.'**
  String get expenseSplitNoAreas;

  /// Resumen del reparto ya elegido
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Repartido entre {count} cultivo} other{Repartido entre {count} cultivos}}'**
  String expenseSplitChosen(int count);

  /// No description provided for @expenseSplitChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get expenseSplitChange;

  /// No description provided for @expenseSplitClear.
  ///
  /// In es, this message translates to:
  /// **'Quitar reparto'**
  String get expenseSplitClear;

  /// No description provided for @expenseSplitNeedAmount.
  ///
  /// In es, this message translates to:
  /// **'Primero escribe el monto del gasto.'**
  String get expenseSplitNeedAmount;

  /// Porcentaje de un cultivo en el reparto
  ///
  /// In es, this message translates to:
  /// **'{percent} %'**
  String expenseSplitPercent(String percent);

  /// No description provided for @noCropLabel.
  ///
  /// In es, this message translates to:
  /// **'Sin cultivo'**
  String get noCropLabel;

  /// No description provided for @noCropHint.
  ///
  /// In es, this message translates to:
  /// **'No pertenece a ningún cultivo. Se queda en el resultado general de la finca.'**
  String get noCropHint;

  /// Fila del desglose por cultivo: gasto de un lote con varios cultivos que no se pudo repartir porque a alguno le falta la hectárea
  ///
  /// In es, this message translates to:
  /// **'{name} · sin repartir'**
  String loteNoRepartido(String name);

  /// No description provided for @sowingCategoryHint.
  ///
  /// In es, this message translates to:
  /// **'Si esto es para un cultivo, elige su nombre abajo: el gasto pasará a contar como su inversión y a salir en su costo/kg. Si el cultivo no existe, toca «+ Nueva variedad…».'**
  String get sowingCategoryHint;

  /// No description provided for @harvestCategoryHint.
  ///
  /// In es, this message translates to:
  /// **'Lo que cuesta la cosecha en sí: bolsas, insumos y mover el café. Si le pagaste a alguien por recoger, ese pago va en Mano de obra, no acá.'**
  String get harvestCategoryHint;

  /// No description provided for @laborCategoryHint.
  ///
  /// In es, this message translates to:
  /// **'Lo que pagas a las personas, aunque sea por cosechar, abonar o deshierbar. Aquí anotas quién trabajó y cuántos días.'**
  String get laborCategoryHint;

  /// No description provided for @seedsCategoryHint.
  ///
  /// In es, this message translates to:
  /// **'Lo que se gasta durante la temporada: semillas, bolsas y demás insumos. Si son colinos o plantas para un cultivo, cámbiate a Siembra: ahí cuenta como inversión y sale en su costo/kg.'**
  String get seedsCategoryHint;

  /// No description provided for @irrigationCategoryHint.
  ///
  /// In es, this message translates to:
  /// **'El sistema que lleva agua al cultivo: bomba, goteo, tanque. La factura del agua va en Agua y la de la luz en Energía.'**
  String get irrigationCategoryHint;

  /// No description provided for @waterCategoryHint.
  ///
  /// In es, this message translates to:
  /// **'El servicio de agua de la finca, igual que la luz. La factura es de acá; el sistema de riego —bomba, goteo, tanque— va en Riego.'**
  String get waterCategoryHint;

  /// No description provided for @deductionSwitchLabel.
  ///
  /// In es, this message translates to:
  /// **'El comprador me descontó'**
  String get deductionSwitchLabel;

  /// No description provided for @deductionHint.
  ///
  /// In es, this message translates to:
  /// **'En café no siempre se paga lo que se entrega: impureza, humedad o piedras.'**
  String get deductionHint;

  /// No description provided for @deductionQtyLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantidad descontada'**
  String get deductionQtyLabel;

  /// No description provided for @deductionQtyInvalid.
  ///
  /// In es, this message translates to:
  /// **'Pon la cantidad que te descontaron'**
  String get deductionQtyInvalid;

  /// No description provided for @deductionReasonLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo del descuento'**
  String get deductionReasonLabel;

  /// No description provided for @deductionReasonHint.
  ///
  /// In es, this message translates to:
  /// **'impureza, humedad, piedras…'**
  String get deductionReasonHint;

  /// No description provided for @deductionRegisteredLabel.
  ///
  /// In es, this message translates to:
  /// **'Entregado'**
  String get deductionRegisteredLabel;

  /// No description provided for @deductionDeductedLabel.
  ///
  /// In es, this message translates to:
  /// **'Descontado'**
  String get deductionDeductedLabel;

  /// No description provided for @deductionPaidLabel.
  ///
  /// In es, this message translates to:
  /// **'Pagado'**
  String get deductionPaidLabel;

  /// No description provided for @deductionOverQuantity.
  ///
  /// In es, this message translates to:
  /// **'Te descontaron más de lo que entregaste: revisa la cantidad.'**
  String get deductionOverQuantity;

  /// No description provided for @paidStatusTitle.
  ///
  /// In es, this message translates to:
  /// **'Estado de pago'**
  String get paidStatusTitle;

  /// No description provided for @paidStatusPaid.
  ///
  /// In es, this message translates to:
  /// **'Pagado'**
  String get paidStatusPaid;

  /// No description provided for @paidStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Por cobrar'**
  String get paidStatusPending;

  /// No description provided for @categoryFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get categoryFieldLabel;

  /// No description provided for @amountFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get amountFieldLabel;

  /// No description provided for @amountInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un monto válido'**
  String get amountInvalid;

  /// No description provided for @dateFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get dateFieldLabel;

  /// No description provided for @datePickerHelp.
  ///
  /// In es, this message translates to:
  /// **'Fecha del registro'**
  String get datePickerHelp;

  /// No description provided for @descriptionFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get descriptionFieldLabel;

  /// No description provided for @saveRecord.
  ///
  /// In es, this message translates to:
  /// **'Guardar registro'**
  String get saveRecord;

  /// No description provided for @saveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get saveChanges;

  /// No description provided for @expenseFootnote.
  ///
  /// In es, this message translates to:
  /// **'Vas a registrar un GASTO. El monto se usará en tu resumen del mes.'**
  String get expenseFootnote;

  /// No description provided for @incomeFootnote.
  ///
  /// In es, this message translates to:
  /// **'Vas a registrar un INGRESO. El monto se usará en tu resumen del mes.'**
  String get incomeFootnote;

  /// No description provided for @prodSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos de producción'**
  String get prodSectionTitle;

  /// No description provided for @quantityFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantidad vendida'**
  String get quantityFieldLabel;

  /// No description provided for @unitFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get unitFieldLabel;

  /// No description provided for @unitKg.
  ///
  /// In es, this message translates to:
  /// **'Kilogramos (kg)'**
  String get unitKg;

  /// No description provided for @unitArroba.
  ///
  /// In es, this message translates to:
  /// **'Arrobas (12.5 kg)'**
  String get unitArroba;

  /// No description provided for @unitSaco.
  ///
  /// In es, this message translates to:
  /// **'Sacos'**
  String get unitSaco;

  /// No description provided for @unitLb.
  ///
  /// In es, this message translates to:
  /// **'Libras (lb)'**
  String get unitLb;

  /// No description provided for @unitCarga.
  ///
  /// In es, this message translates to:
  /// **'Cargas (27.2 kg)'**
  String get unitCarga;

  /// No description provided for @clientFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Cliente / comprador (opcional)'**
  String get clientFieldLabel;

  /// No description provided for @providerFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Proveedor / vendedor (opcional)'**
  String get providerFieldLabel;

  /// No description provided for @pricePerUnitLabel.
  ///
  /// In es, this message translates to:
  /// **'Precio por'**
  String get pricePerUnitLabel;

  /// No description provided for @pricePerUnitHint.
  ///
  /// In es, this message translates to:
  /// **'Se calcula automáticamente: monto ÷ cantidad'**
  String get pricePerUnitHint;

  /// No description provided for @lowPriceThresholdLabel.
  ///
  /// In es, this message translates to:
  /// **'Precio mínimo de venta por kg'**
  String get lowPriceThresholdLabel;

  /// No description provided for @lowPriceThresholdHelper.
  ///
  /// In es, this message translates to:
  /// **'Opcional. Si vendes café por debajo de este precio (por kg), se mostrará una alerta. Déjalo vacío para usar solo tu historial.'**
  String get lowPriceThresholdHelper;

  /// No description provided for @sacoKgLabel.
  ///
  /// In es, this message translates to:
  /// **'Peso de un saco (kg)'**
  String get sacoKgLabel;

  /// No description provided for @sacoKgHelper.
  ///
  /// In es, this message translates to:
  /// **'Pasa los sacos a kilogramos en reportes, PDF y alertas. El estándar del café es 70.'**
  String get sacoKgHelper;

  /// No description provided for @excelColQty.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get excelColQty;

  /// No description provided for @excelColUnit.
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get excelColUnit;

  /// No description provided for @excelColPricePerUnit.
  ///
  /// In es, this message translates to:
  /// **'Precio por unidad'**
  String get excelColPricePerUnit;

  /// No description provided for @excelColClient.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get excelColClient;

  /// No description provided for @excelColProvider.
  ///
  /// In es, this message translates to:
  /// **'Proveedor'**
  String get excelColProvider;

  /// No description provided for @excelColCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get excelColCurrency;

  /// No description provided for @excelColBalance.
  ///
  /// In es, this message translates to:
  /// **'Balance'**
  String get excelColBalance;

  /// No description provided for @excelMonthlyTitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresos y gastos por mes'**
  String get excelMonthlyTitle;

  /// No description provided for @excelCrossExpensesTitle.
  ///
  /// In es, this message translates to:
  /// **'Gastos por categoría y cultivo'**
  String get excelCrossExpensesTitle;

  /// No description provided for @topClientsTitle.
  ///
  /// In es, this message translates to:
  /// **'Principales compradores'**
  String get topClientsTitle;

  /// No description provided for @topProvidersTitle.
  ///
  /// In es, this message translates to:
  /// **'Principales proveedores'**
  String get topProvidersTitle;

  /// No description provided for @recordSaved.
  ///
  /// In es, this message translates to:
  /// **'Registro guardado'**
  String get recordSaved;

  /// No description provided for @recordUpdated.
  ///
  /// In es, this message translates to:
  /// **'Movimiento actualizado'**
  String get recordUpdated;

  /// No description provided for @recordDeleted.
  ///
  /// In es, this message translates to:
  /// **'Movimiento eliminado'**
  String get recordDeleted;

  /// No description provided for @deleteDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar movimiento'**
  String get deleteDialogTitle;

  /// No description provided for @deleteDialogBody.
  ///
  /// In es, this message translates to:
  /// **'Esta acción borra el registro. ¿Confirmas?'**
  String get deleteDialogBody;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get add;

  /// No description provided for @newCropDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva variedad'**
  String get newCropDialogTitle;

  /// No description provided for @welcomeCompleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Completar cultivo'**
  String get welcomeCompleteTitle;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @cropNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del cultivo'**
  String get cropNameLabel;

  /// No description provided for @cropNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre del cultivo.'**
  String get cropNameRequired;

  /// No description provided for @cropNameTaken.
  ///
  /// In es, this message translates to:
  /// **'Ya hay un cultivo con ese nombre. Escribe otro.'**
  String get cropNameTaken;

  /// No description provided for @newCropDuplicateTitle.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes un cultivo con ese nombre'**
  String get newCropDuplicateTitle;

  /// Segunda pregunta del diálogo de cultivo nuevo: el nombre escrito ya existe y hay que decidir si se usa el existente o se crea otro igual.
  ///
  /// In es, this message translates to:
  /// **'«{name}» ya está en tu lista de cultivos. ¿Qué prefieres hacer?'**
  String newCropDuplicateBody(String name);

  /// No description provided for @newCropUseExisting.
  ///
  /// In es, this message translates to:
  /// **'Usar el que ya tienes'**
  String get newCropUseExisting;

  /// No description provided for @newCropCreateAnother.
  ///
  /// In es, this message translates to:
  /// **'Crear otro igual'**
  String get newCropCreateAnother;

  /// Subtítulo que distingue cultivos con el mismo nombre cuando no tienen área cargada
  ///
  /// In es, this message translates to:
  /// **'lote {n}'**
  String cropLotTag(int n);

  /// No description provided for @cropPhaseNoYield.
  ///
  /// In es, this message translates to:
  /// **'aún no rinde · primera cosecha pendiente'**
  String get cropPhaseNoYield;

  /// No description provided for @sowingRenovacionCheckbox.
  ///
  /// In es, this message translates to:
  /// **'Esta resiembra renovó el cultivo — cambiar su fase a renovación'**
  String get sowingRenovacionCheckbox;

  /// No description provided for @sowingRestartCheckbox.
  ///
  /// In es, this message translates to:
  /// **'Esta siembra arrancó el cultivo de nuevo — volver a «Sin dar» y borrar la fecha de la primera cosecha'**
  String get sowingRestartCheckbox;

  /// No description provided for @sowingWhatHappensOldPlants.
  ///
  /// In es, this message translates to:
  /// **'¿Qué pasa con las matas que ya tienes?'**
  String get sowingWhatHappensOldPlants;

  /// No description provided for @sowingExpandOption.
  ///
  /// In es, this message translates to:
  /// **'Amplío el cultivo: no reemplazo nada'**
  String get sowingExpandOption;

  /// No description provided for @sowingRenewOption.
  ///
  /// In es, this message translates to:
  /// **'Renuevo una parte'**
  String get sowingRenewOption;

  /// No description provided for @sowingRenewHint.
  ///
  /// In es, this message translates to:
  /// **'Las matas del lote viejo bajan y las nuevas suman. El total no se infla.'**
  String get sowingRenewHint;

  /// No description provided for @sowingReplaceCohortLabel.
  ///
  /// In es, this message translates to:
  /// **'Lote que renuevo'**
  String get sowingReplaceCohortLabel;

  /// No description provided for @sowingReplacePlantsLabel.
  ///
  /// In es, this message translates to:
  /// **'Matas que reemplaza'**
  String get sowingReplacePlantsLabel;

  /// No description provided for @sowingReplacePlantsRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe cuántas matas reemplazas.'**
  String get sowingReplacePlantsRequired;

  /// No description provided for @sowingReplacePlantsPrefill.
  ///
  /// In es, this message translates to:
  /// **'Calculado por área: {plants} de {live}'**
  String sowingReplacePlantsPrefill(int plants, int live);

  /// No description provided for @sowingReplaceNoArea.
  ///
  /// In es, this message translates to:
  /// **'El lote viejo no tiene área: dime cuántas matas reemplazas.'**
  String get sowingReplaceNoArea;

  /// No description provided for @sowingReplaceAll.
  ///
  /// In es, this message translates to:
  /// **'Todas ({live})'**
  String sowingReplaceAll(int live);

  /// No description provided for @sowingReplaceTooMany.
  ///
  /// In es, this message translates to:
  /// **'Ese lote tiene {live} matas vivas: no puedes reemplazar más.'**
  String sowingReplaceTooMany(int live);

  /// No description provided for @sowingReplaceAreaLabel.
  ///
  /// In es, this message translates to:
  /// **'Área que reemplaza (ha)'**
  String get sowingReplaceAreaLabel;

  /// No description provided for @sowingCohortOption.
  ///
  /// In es, this message translates to:
  /// **'{date} · {plants} matas'**
  String sowingCohortOption(String date, int plants);

  /// Un lote cerrado: solo la fecha, sin matas vivas
  ///
  /// In es, this message translates to:
  /// **'{date}'**
  String sowingCohortDateOnly(String date);

  /// No description provided for @sowingCohortLabel.
  ///
  /// In es, this message translates to:
  /// **'Lote'**
  String get sowingCohortLabel;

  /// No description provided for @sowingCohortNoneTitle.
  ///
  /// In es, this message translates to:
  /// **'No hay un lote vivo'**
  String get sowingCohortNoneTitle;

  /// No description provided for @sowingCohortNoneBody.
  ///
  /// In es, this message translates to:
  /// **'Este cultivo no tiene matas vivas donde reponer. Si estás arrancando de nuevo, anotalo como siembra.'**
  String get sowingCohortNoneBody;

  /// No description provided for @sowingCohortNoneSaveAs.
  ///
  /// In es, this message translates to:
  /// **'Anotar como siembra'**
  String get sowingCohortNoneSaveAs;

  /// No description provided for @sowingNoCohortTag.
  ///
  /// In es, this message translates to:
  /// **'Sin lote'**
  String get sowingNoCohortTag;

  /// No description provided for @sowingDeleteCohortBody.
  ///
  /// In es, this message translates to:
  /// **'Otra siembra le resta matas a este lote. Si lo borras, esos reemplazos dejan de aplicar y el total del cultivo queda en {total} matas.'**
  String sowingDeleteCohortBody(int total);

  /// No description provided for @cohortsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} edades'**
  String cohortsCount(int count);

  /// No description provided for @cohortOpen.
  ///
  /// In es, this message translates to:
  /// **'Abierta'**
  String get cohortOpen;

  /// No description provided for @cohortRenewed.
  ///
  /// In es, this message translates to:
  /// **'Renovada'**
  String get cohortRenewed;

  /// No description provided for @cohortRenewedOn.
  ///
  /// In es, this message translates to:
  /// **'Renovada en {date}'**
  String cohortRenewedOn(String date);

  /// No description provided for @cohortsHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Lotes renovados'**
  String get cohortsHistoryTitle;

  /// No description provided for @cohortsAreaFallback.
  ///
  /// In es, this message translates to:
  /// **'No todos los lotes tienen área: el área del cultivo es la que escribiste.'**
  String get cohortsAreaFallback;

  /// No description provided for @cohortsAreaMismatch.
  ///
  /// In es, this message translates to:
  /// **'Los lotes con área suman {sum} ha; el cultivo dice {manual} ha.'**
  String cohortsAreaMismatch(String sum, String manual);

  /// No description provided for @cohortsNoLivingPlants.
  ///
  /// In es, this message translates to:
  /// **'Este cultivo no tiene matas vivas.'**
  String get cohortsNoLivingPlants;

  /// No description provided for @perHaAgesAverage.
  ///
  /// In es, this message translates to:
  /// **'promedio de {count} edades'**
  String perHaAgesAverage(int count);

  /// No description provided for @sowingAreaMissingWarning.
  ///
  /// In es, this message translates to:
  /// **'Sin área no se pueden ver los costos por hectárea. Puedes guardar igual.'**
  String get sowingAreaMissingWarning;

  /// No description provided for @cropSetupPrompt.
  ///
  /// In es, this message translates to:
  /// **'Tu cultivo está listo para usar. ¿Quieres completar sus datos (fase, área, plantas, unidad)?'**
  String get cropSetupPrompt;

  /// No description provided for @cropSetupComplete.
  ///
  /// In es, this message translates to:
  /// **'Completar'**
  String get cropSetupComplete;

  /// No description provided for @cropSetupLater.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get cropSetupLater;

  /// No description provided for @deleteCropTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar cultivo?'**
  String get deleteCropTitle;

  /// El orden de los 'placeholders' es el orden de los argumentos, como se lee en la frase. Sin declararlos, el generador los ordena alfabéticamente y las cifras caen en la casilla equivocada.
  ///
  /// In es, this message translates to:
  /// **'Se eliminarán las siembras ({sowings}) y las cosechas ({harvests}) de «{name}». Los gastos y ventas se quedarán sin cultivo.'**
  String deleteCropBody(int sowings, int harvests, String name);

  /// No description provided for @deleteCropBodyEmpty.
  ///
  /// In es, this message translates to:
  /// **'«{name}» todavía no tiene siembras ni cosechas. Los gastos y ventas se quedarán sin cultivo.'**
  String deleteCropBodyEmpty(Object name);

  /// No description provided for @expenseGroupProduccion.
  ///
  /// In es, this message translates to:
  /// **'Gastos de producción'**
  String get expenseGroupProduccion;

  /// No description provided for @expenseGroupVenta.
  ///
  /// In es, this message translates to:
  /// **'Gastos de venta'**
  String get expenseGroupVenta;

  /// No description provided for @expenseGroupFijos.
  ///
  /// In es, this message translates to:
  /// **'Gastos fijos'**
  String get expenseGroupFijos;

  /// No description provided for @expenseGroupOtros.
  ///
  /// In es, this message translates to:
  /// **'Otros gastos'**
  String get expenseGroupOtros;

  /// No description provided for @menuCrops.
  ///
  /// In es, this message translates to:
  /// **'Cultivos'**
  String get menuCrops;

  /// No description provided for @cropsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay cultivos. Agrega el primero.'**
  String get cropsEmpty;

  /// No description provided for @menuWorkers.
  ///
  /// In es, this message translates to:
  /// **'Trabajadores'**
  String get menuWorkers;

  /// No description provided for @workersEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay trabajadores. Agrega el primero.'**
  String get workersEmpty;

  /// No description provided for @workerNewOption.
  ///
  /// In es, this message translates to:
  /// **'+ Nuevo trabajador…'**
  String get workerNewOption;

  /// No description provided for @newWorkerDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo trabajador'**
  String get newWorkerDialogTitle;

  /// No description provided for @editWorkerTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar trabajador'**
  String get editWorkerTitle;

  /// No description provided for @workerNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get workerNameLabel;

  /// No description provided for @workerNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre del trabajador.'**
  String get workerNameRequired;

  /// No description provided for @workerDayRateLabel.
  ///
  /// In es, this message translates to:
  /// **'Valor por día (opcional)'**
  String get workerDayRateLabel;

  /// No description provided for @workerDayRateShort.
  ///
  /// In es, this message translates to:
  /// **'Valor por día'**
  String get workerDayRateShort;

  /// No description provided for @helpWorkerDayRate.
  ///
  /// In es, this message translates to:
  /// **'Se autocompleta al registrar un jornal. Déjalo vacío si prefieres escribirlo cada vez.'**
  String get helpWorkerDayRate;

  /// No description provided for @workerConfirmDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar trabajador'**
  String get workerConfirmDelete;

  /// No description provided for @workerDeleted.
  ///
  /// In es, this message translates to:
  /// **'Trabajador eliminado'**
  String get workerDeleted;

  /// No description provided for @workerWorkedIn.
  ///
  /// In es, this message translates to:
  /// **'Trabajó en'**
  String get workerWorkedIn;

  /// No description provided for @workerNoJornales.
  ///
  /// In es, this message translates to:
  /// **'Sin jornales registrados'**
  String get workerNoJornales;

  /// No description provided for @workerNoRate.
  ///
  /// In es, this message translates to:
  /// **'Sin valor por día'**
  String get workerNoRate;

  /// No description provided for @jornalSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Jornal'**
  String get jornalSectionTitle;

  /// No description provided for @jornalWorkerLabel.
  ///
  /// In es, this message translates to:
  /// **'Trabajador'**
  String get jornalWorkerLabel;

  /// No description provided for @jornalWorkerHint.
  ///
  /// In es, this message translates to:
  /// **'Crea tus trabajadores en el menú ⋮ o elige «Otro nombre».'**
  String get jornalWorkerHint;

  /// No description provided for @jornalWorkerRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige el trabajador.'**
  String get jornalWorkerRequired;

  /// No description provided for @jornalOtherNameOption.
  ///
  /// In es, this message translates to:
  /// **'Otro nombre…'**
  String get jornalOtherNameOption;

  /// No description provided for @jornalCreateOption.
  ///
  /// In es, this message translates to:
  /// **'Crear trabajador…'**
  String get jornalCreateOption;

  /// No description provided for @jornalDaysLabel.
  ///
  /// In es, this message translates to:
  /// **'Días trabajados'**
  String get jornalDaysLabel;

  /// No description provided for @jornalDaysRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa los días (entero mayor que 0).'**
  String get jornalDaysRequired;

  /// No description provided for @jornalRateRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el valor por día.'**
  String get jornalRateRequired;

  /// No description provided for @jornalTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get jornalTotalLabel;

  /// No description provided for @jornalTotalHint.
  ///
  /// In es, this message translates to:
  /// **'Se calcula: días × valor por día.'**
  String get jornalTotalHint;

  /// No description provided for @jornalHarvestedKgLabel.
  ///
  /// In es, this message translates to:
  /// **'Kilos recolectados (opcional)'**
  String get jornalHarvestedKgLabel;

  /// No description provided for @jornalHarvestedKgHelp.
  ///
  /// In es, this message translates to:
  /// **'Para comparar lo cosechado con lo vendido.'**
  String get jornalHarvestedKgHelp;

  /// No description provided for @jornalHarvestedKgNoCrop.
  ///
  /// In es, this message translates to:
  /// **'Elige el cultivo para anotar los kilos.'**
  String get jornalHarvestedKgNoCrop;

  /// No description provided for @jornalHarvestedKgInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa los kilos recolectados (mayor que 0).'**
  String get jornalHarvestedKgInvalid;

  /// No description provided for @jornalHarvestedKgLotLabel.
  ///
  /// In es, this message translates to:
  /// **'Lote de la cosecha (opcional)'**
  String get jornalHarvestedKgLotLabel;

  /// No description provided for @jornalHarvestedKgLotNone.
  ///
  /// In es, this message translates to:
  /// **'Sin lote'**
  String get jornalHarvestedKgLotNone;

  /// No description provided for @jornalHarvestedKgLotRenewed.
  ///
  /// In es, this message translates to:
  /// **'{date} · {plants} matas · renovado'**
  String jornalHarvestedKgLotRenewed(String date, int plants);

  /// No description provided for @jornalHarvestedKgLotMissing.
  ///
  /// In es, this message translates to:
  /// **'No elegiste lote: estos kilos quedan del cultivo y no se ven por lote. Puedes guardar así.'**
  String get jornalHarvestedKgLotMissing;

  /// No description provided for @cohortKgLabel.
  ///
  /// In es, this message translates to:
  /// **'{kg} kg'**
  String cohortKgLabel(String kg);

  /// No description provided for @cohortKgPerPlantLabel.
  ///
  /// In es, this message translates to:
  /// **'{value} kg/planta'**
  String cohortKgPerPlantLabel(String value);

  /// No description provided for @cashBoxLabel.
  ///
  /// In es, this message translates to:
  /// **'Aporte mensual de caja'**
  String get cashBoxLabel;

  /// No description provided for @cashBoxHelp.
  ///
  /// In es, this message translates to:
  /// **'Lo que sacas cada mes para la finca: cubre los jornales y los gastos chicos. Lo que no se gasta no se pierde, se arrastra al mes siguiente. El aporte rige desde este mes: los meses anteriores no se recalculan.'**
  String get cashBoxHelp;

  /// No description provided for @cashBoxCarry.
  ///
  /// In es, this message translates to:
  /// **'Lo arrastrado de meses anteriores'**
  String get cashBoxCarry;

  /// No description provided for @cashBoxMonthly.
  ///
  /// In es, this message translates to:
  /// **'Aporte del mes'**
  String get cashBoxMonthly;

  /// No description provided for @cashBoxTitle.
  ///
  /// In es, this message translates to:
  /// **'Caja menor'**
  String get cashBoxTitle;

  /// No description provided for @cashBoxOf.
  ///
  /// In es, this message translates to:
  /// **'{used} de {total}'**
  String cashBoxOf(String used, String total);

  /// No description provided for @cashBoxRemaining.
  ///
  /// In es, this message translates to:
  /// **'Restante'**
  String get cashBoxRemaining;

  /// No description provided for @cashBoxLabor.
  ///
  /// In es, this message translates to:
  /// **'Jornales'**
  String get cashBoxLabor;

  /// No description provided for @cashBoxExtras.
  ///
  /// In es, this message translates to:
  /// **'Extras'**
  String get cashBoxExtras;

  /// No description provided for @workBudgetTitle.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto de obra'**
  String get workBudgetTitle;

  /// No description provided for @workBudgetOf.
  ///
  /// In es, this message translates to:
  /// **'{used} de {total}'**
  String workBudgetOf(String used, String total);

  /// No description provided for @workBudgetRemaining.
  ///
  /// In es, this message translates to:
  /// **'Restante'**
  String get workBudgetRemaining;

  /// No description provided for @workBudgetBalance.
  ///
  /// In es, this message translates to:
  /// **'Saldo de obra'**
  String get workBudgetBalance;

  /// No description provided for @taskFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Qué labor'**
  String get taskFieldLabel;

  /// No description provided for @taskFieldHint.
  ///
  /// In es, this message translates to:
  /// **'¿Qué se hizo?'**
  String get taskFieldHint;

  /// No description provided for @taskOtherOption.
  ///
  /// In es, this message translates to:
  /// **'✏️ Otra…'**
  String get taskOtherOption;

  /// No description provided for @taskOtherLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la labor'**
  String get taskOtherLabel;

  /// No description provided for @taskOtherHint.
  ///
  /// In es, this message translates to:
  /// **'Escríbela como la digas'**
  String get taskOtherHint;

  /// No description provided for @workSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Planilla del mes'**
  String get workSheetTitle;

  /// No description provided for @workSheetWorkers.
  ///
  /// In es, this message translates to:
  /// **'personas'**
  String get workSheetWorkers;

  /// No description provided for @workSheetDayPlural.
  ///
  /// In es, this message translates to:
  /// **'día'**
  String get workSheetDayPlural;

  /// No description provided for @workSheetDayOther.
  ///
  /// In es, this message translates to:
  /// **'días'**
  String get workSheetDayOther;

  /// No description provided for @workSheetUnlabeled.
  ///
  /// In es, this message translates to:
  /// **'Sin labor'**
  String get workSheetUnlabeled;

  /// No description provided for @workSheetNoTasks.
  ///
  /// In es, this message translates to:
  /// **'Todavía no anotaste labores en un jornal. Cuando registres uno, elige «Qué labor» y va a salir aquí.'**
  String get workSheetNoTasks;

  /// No description provided for @segMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get segMonth;

  /// No description provided for @segYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get segYear;

  /// No description provided for @segAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get segAll;

  /// No description provided for @segYearToDate.
  ///
  /// In es, this message translates to:
  /// **'A la fecha'**
  String get segYearToDate;

  /// No description provided for @yearLabel.
  ///
  /// In es, this message translates to:
  /// **'Año {year}'**
  String yearLabel(int year);

  /// No description provided for @allMovementsLabel.
  ///
  /// In es, this message translates to:
  /// **'Todos los movimientos'**
  String get allMovementsLabel;

  /// No description provided for @noMovements.
  ///
  /// In es, this message translates to:
  /// **'Sin movimientos en este período.'**
  String get noMovements;

  /// No description provided for @confirmDeleteExpense.
  ///
  /// In es, this message translates to:
  /// **'Gasto de {amount} — ¿confirmas?'**
  String confirmDeleteExpense(String amount);

  /// No description provided for @confirmDeleteIncome.
  ///
  /// In es, this message translates to:
  /// **'Ingreso de {amount} — ¿confirmas?'**
  String confirmDeleteIncome(String amount);

  /// No description provided for @reportPeriodMonth.
  ///
  /// In es, this message translates to:
  /// **'{monthName} de {year}'**
  String reportPeriodMonth(String monthName, int year);

  /// No description provided for @reportChipMonth.
  ///
  /// In es, this message translates to:
  /// **'{monthName} {year}'**
  String reportChipMonth(String monthName, int year);

  /// No description provided for @reportPeriodYtd.
  ///
  /// In es, this message translates to:
  /// **'{year} a la fecha'**
  String reportPeriodYtd(int year);

  /// No description provided for @reportChipYtd.
  ///
  /// In es, this message translates to:
  /// **'{year} · a la fecha'**
  String reportChipYtd(int year);

  /// No description provided for @segWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get segWeek;

  /// No description provided for @reportPeriodWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana {week}, {year}'**
  String reportPeriodWeek(int week, int year);

  /// No description provided for @reportChipWeek.
  ///
  /// In es, this message translates to:
  /// **'Sem {week}'**
  String reportChipWeek(int week);

  /// No description provided for @harvestCargasLabel.
  ///
  /// In es, this message translates to:
  /// **'cargas'**
  String get harvestCargasLabel;

  /// No description provided for @harvestCargasNote.
  ///
  /// In es, this message translates to:
  /// **'1 carga ≈ 60 lbs ≈ 27.2 kg'**
  String get harvestCargasNote;

  /// No description provided for @incomeStatementTitle.
  ///
  /// In es, this message translates to:
  /// **'Estado de resultados'**
  String get incomeStatementTitle;

  /// No description provided for @noIncomePeriod.
  ///
  /// In es, this message translates to:
  /// **'Sin ingresos en este período'**
  String get noIncomePeriod;

  /// No description provided for @operatingExpensesLabel.
  ///
  /// In es, this message translates to:
  /// **'Gastos operacionales'**
  String get operatingExpensesLabel;

  /// No description provided for @noExpensesPeriod.
  ///
  /// In es, this message translates to:
  /// **'Sin gastos en este período.'**
  String get noExpensesPeriod;

  /// No description provided for @resultPeriodLabel.
  ///
  /// In es, this message translates to:
  /// **'RESULTADO DEL PERÍODO'**
  String get resultPeriodLabel;

  /// No description provided for @marginLabel.
  ///
  /// In es, this message translates to:
  /// **'Margen sobre ventas'**
  String get marginLabel;

  /// No description provided for @ratioLabel.
  ///
  /// In es, this message translates to:
  /// **'Gastos vs ingresos'**
  String get ratioLabel;

  /// No description provided for @comparisonTitle.
  ///
  /// In es, this message translates to:
  /// **'Comparado con {previous}'**
  String comparisonTitle(String previous);

  /// No description provided for @comparisonFromTo.
  ///
  /// In es, this message translates to:
  /// **'de {before} a {after}'**
  String comparisonFromTo(String before, String after);

  /// No description provided for @comparisonPreviousWeek.
  ///
  /// In es, this message translates to:
  /// **'la semana anterior'**
  String get comparisonPreviousWeek;

  /// No description provided for @comparisonPreviousMonth.
  ///
  /// In es, this message translates to:
  /// **'el mes anterior'**
  String get comparisonPreviousMonth;

  /// No description provided for @comparisonPreviousYear.
  ///
  /// In es, this message translates to:
  /// **'el año anterior'**
  String get comparisonPreviousYear;

  /// No description provided for @comparisonPreviousSameStretch.
  ///
  /// In es, this message translates to:
  /// **'el mismo tramo del año anterior'**
  String get comparisonPreviousSameStretch;

  /// No description provided for @comparisonPreviousColumn.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get comparisonPreviousColumn;

  /// No description provided for @comparisonCurrentColumn.
  ///
  /// In es, this message translates to:
  /// **'Actual'**
  String get comparisonCurrentColumn;

  /// No description provided for @comparisonChangeColumn.
  ///
  /// In es, this message translates to:
  /// **'Cambio'**
  String get comparisonChangeColumn;

  /// No description provided for @metricMarginGood.
  ///
  /// In es, this message translates to:
  /// **'Buen margen: te quedan \$20 o más de cada \$100 vendidos.'**
  String get metricMarginGood;

  /// No description provided for @metricMarginFair.
  ///
  /// In es, this message translates to:
  /// **'Margen justo: te quedan entre \$10 y \$20 de cada \$100 vendidos.'**
  String get metricMarginFair;

  /// No description provided for @metricMarginLow.
  ///
  /// In es, this message translates to:
  /// **'Margen bajo: te quedan menos de \$10 de cada \$100 vendidos.'**
  String get metricMarginLow;

  /// No description provided for @metricMarginLoss.
  ///
  /// In es, this message translates to:
  /// **'Pérdida: los gastos son mayores a lo que vendiste.'**
  String get metricMarginLoss;

  /// No description provided for @metricMarginBreakEven.
  ///
  /// In es, this message translates to:
  /// **'Sin ganancia ni pérdida: los gastos cubren justo lo vendido.'**
  String get metricMarginBreakEven;

  /// No description provided for @metricNoSales.
  ///
  /// In es, this message translates to:
  /// **'Sin ventas en el período: no se puede calcular.'**
  String get metricNoSales;

  /// No description provided for @metricRatioHealthy.
  ///
  /// In es, this message translates to:
  /// **'Buen control: de cada \$100 que entran, hasta \$70 se van en gastos.'**
  String get metricRatioHealthy;

  /// No description provided for @metricRatioHigh.
  ///
  /// In es, this message translates to:
  /// **'Gastas bastante: de cada \$100 que entran, entre \$70 y \$90 se van en gastos.'**
  String get metricRatioHigh;

  /// No description provided for @metricRatioCritical.
  ///
  /// In es, this message translates to:
  /// **'Gastas casi todo lo que entra: más de \$90 de cada \$100 se van en gastos.'**
  String get metricRatioCritical;

  /// No description provided for @metricCostPriceLabel.
  ///
  /// In es, this message translates to:
  /// **'Precio de venta por kilo'**
  String get metricCostPriceLabel;

  /// No description provided for @metricMarginPerKgLabel.
  ///
  /// In es, this message translates to:
  /// **'Margen por kilo'**
  String get metricMarginPerKgLabel;

  /// No description provided for @metricMarginPerKgGood.
  ///
  /// In es, this message translates to:
  /// **'Vendes por encima de lo que te costó producirlo.'**
  String get metricMarginPerKgGood;

  /// No description provided for @metricMarginPerKgBad.
  ///
  /// In es, this message translates to:
  /// **'Vendes por debajo de lo que te costó producirlo: cada kilo vendido resta.'**
  String get metricMarginPerKgBad;

  /// No description provided for @metricMarginPerKgZero.
  ///
  /// In es, this message translates to:
  /// **'Vendes a costo: ni ganas ni pierdes por kilo.'**
  String get metricMarginPerKgZero;

  /// No description provided for @metricReceivablesLabel.
  ///
  /// In es, this message translates to:
  /// **'Ventas por cobrar'**
  String get metricReceivablesLabel;

  /// No description provided for @metricReceivablesNote.
  ///
  /// In es, this message translates to:
  /// **'Todavía no te lo han pagado: ese dinero no está en la caja.'**
  String get metricReceivablesNote;

  /// No description provided for @metricLaborShareLabel.
  ///
  /// In es, this message translates to:
  /// **'Mano de obra sobre el gasto'**
  String get metricLaborShareLabel;

  /// No description provided for @metricLaborShareNote.
  ///
  /// In es, this message translates to:
  /// **'Es la parte de todo lo que gastaste en el periodo que se fue en mano de obra.'**
  String get metricLaborShareNote;

  /// Veredicto de la línea precio/kg vs costo/kg cuando se vende por encima del costo
  ///
  /// In es, this message translates to:
  /// **'Te cuesta {cost} por kilo. Vendes por encima de tu costo.'**
  String metricCostPriceAbove(String cost);

  /// Veredicto de la línea precio/kg vs costo/kg cuando se vende por debajo del costo
  ///
  /// In es, this message translates to:
  /// **'Te cuesta {cost} por kilo. Vendes por debajo de tu costo: cada kilo vendido resta.'**
  String metricCostPriceBelow(String cost);

  /// Veredicto de la línea precio/kg vs costo/kg cuando coinciden
  ///
  /// In es, this message translates to:
  /// **'Te cuesta {cost} por kilo y vendes a ese mismo precio: ni ganas ni pierdes.'**
  String metricCostPriceEqual(String cost);

  /// No description provided for @metricCostPriceNoCost.
  ///
  /// In es, this message translates to:
  /// **'No cosechaste en el período: todavía no hay costo por kilo que comparar.'**
  String get metricCostPriceNoCost;

  /// Hay costo por kilo pero las ventas no registran cantidad
  ///
  /// In es, this message translates to:
  /// **'Te cuesta {cost} por kilo, pero tus ventas no anotan kilos: no se puede comparar.'**
  String metricCostPriceNoQty(String cost);

  /// No description provided for @cropBreakdownTitle.
  ///
  /// In es, this message translates to:
  /// **'Desglose por cultivo — {period}'**
  String cropBreakdownTitle(String period);

  /// No description provided for @cropBreakdownSummaryG.
  ///
  /// In es, this message translates to:
  /// **'Gastos'**
  String get cropBreakdownSummaryG;

  /// Parte de los gastos de un cultivo que viene de la siembra (costo de establecer el lote)
  ///
  /// In es, this message translates to:
  /// **'Inversión inicial'**
  String get cropBreakdownInvestment;

  /// Parte de los gastos de un cultivo que es trabajo del campo en el período
  ///
  /// In es, this message translates to:
  /// **'Operación del período'**
  String get cropBreakdownOperation;

  /// No description provided for @cropBreakdownSummaryI.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get cropBreakdownSummaryI;

  /// No description provided for @cropBreakdownSummaryR.
  ///
  /// In es, this message translates to:
  /// **'Resultado'**
  String get cropBreakdownSummaryR;

  /// Cifra del margen de un cultivo: porcentaje de lo vendido que queda tras los gastos.
  ///
  /// In es, this message translates to:
  /// **'Margen {value}'**
  String cropMarginBadge(String value);

  /// No description provided for @cropBreakdownMarginHint.
  ///
  /// In es, this message translates to:
  /// **'Cómo leer el margen: es el porcentaje de lo que vendes que te queda después de cubrir los gastos. Ej.: si vendes 100 y gastas 40, el margen es 60%.'**
  String get cropBreakdownMarginHint;

  /// No description provided for @noCropData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos de cultivos en el período.'**
  String get noCropData;

  /// No description provided for @exportPdf.
  ///
  /// In es, this message translates to:
  /// **'Exportar PDF y compartir'**
  String get exportPdf;

  /// No description provided for @generating.
  ///
  /// In es, this message translates to:
  /// **'Generando…'**
  String get generating;

  /// No description provided for @exportExcel.
  ///
  /// In es, this message translates to:
  /// **'Exportar a Excel y compartir'**
  String get exportExcel;

  /// No description provided for @exportBalance.
  ///
  /// In es, this message translates to:
  /// **'Plantilla de balance (Excel)'**
  String get exportBalance;

  /// Contador de movimientos
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} movimiento} other{{count} movimientos}}'**
  String movementsCount(int count);

  /// No description provided for @reportGeneratedSnack.
  ///
  /// In es, this message translates to:
  /// **'Reporte generado.'**
  String get reportGeneratedSnack;

  /// No description provided for @exportError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo exportar: {error}'**
  String exportError(String error);

  /// Primera exportación sin conexión: el trozo de PDF/Excel todavía no está en el dispositivo
  ///
  /// In es, this message translates to:
  /// **'La primera vez hay que estar conectado para preparar la exportación. Revisa la conexión y reintenta.'**
  String get exportNeedsNetworkOnce;

  /// No description provided for @pdfShareSubject.
  ///
  /// In es, this message translates to:
  /// **'Balance - Reporte {year}'**
  String pdfShareSubject(int year);

  /// No description provided for @farmNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la finca'**
  String get farmNameLabel;

  /// No description provided for @currencyLabel.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get currencyLabel;

  /// No description provided for @currencyDisplayLabel.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get currencyDisplayLabel;

  /// Helper text for the display currency setting
  ///
  /// In es, this message translates to:
  /// **'Única moneda de tu cuenta y de todos tus registros.'**
  String get currencyDisplayHelper;

  /// No description provided for @currencyLockedHelper.
  ///
  /// In es, this message translates to:
  /// **'Elegiste esta moneda al empezar y no puede cambiarse, para que todos tus montos coincidan siempre.'**
  String get currencyLockedHelper;

  /// No description provided for @currencyGateTitle.
  ///
  /// In es, this message translates to:
  /// **'¿En qué moneda manejas tus cuentas?'**
  String get currencyGateTitle;

  /// No description provided for @currencyGateBody.
  ///
  /// In es, this message translates to:
  /// **'Esta será la única moneda de tu cuenta y no podrá cambiarse después.'**
  String get currencyGateBody;

  /// Botón de la pregunta inicial de moneda
  ///
  /// In es, this message translates to:
  /// **'Empezar con {currency}'**
  String currencyGateCta(String currency);

  /// No description provided for @currencyGateRequired.
  ///
  /// In es, this message translates to:
  /// **'Necesitas elegir una moneda para poder registrar tus primeros datos.'**
  String get currencyGateRequired;

  /// Texto bajo el campo Monto: dice en qué moneda queda el registro
  ///
  /// In es, this message translates to:
  /// **'Se registra en {currency}.'**
  String currencyRegisterHint(String currency);

  /// Hint when transactions have mixed currencies
  ///
  /// In es, this message translates to:
  /// **'Se muestra en {count} monedas'**
  String currencyMixedHint(int count);

  /// Aviso en el desglose por cultivo cuando un cultivo tiene movimientos en más de una moneda
  ///
  /// In es, this message translates to:
  /// **'Este cultivo está en {count} monedas: cada moneda va por separado y no se calcula el margen.'**
  String cropMixedCurrencyNote(int count);

  /// Aviso genérico cuando hay moneda mixta y cada cifra se lista por moneda (caja, planilla, exportaciones)
  ///
  /// In es, this message translates to:
  /// **'En {count} monedas: cada monto sale con su moneda; no se suman ni se comparan entre sí.'**
  String currencyMixedByCurrencyNote(int count);

  /// Total converted to display currency
  ///
  /// In es, this message translates to:
  /// **'Total en {currency}: {amount}'**
  String currencyConvertedTotal(String currency, String amount);

  /// No description provided for @languageLabel.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languageLabel;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @saveButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get saveButton;

  /// No description provided for @converting.
  ///
  /// In es, this message translates to:
  /// **'Convirtiendo…'**
  String get converting;

  /// No description provided for @rateErrorMsg.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener la tasa de cambio. Verifica tu conexión e inténtalo de nuevo.'**
  String get rateErrorMsg;

  /// Se muestra al cambiar la moneda de reportes en Ajustes
  ///
  /// In es, this message translates to:
  /// **'Moneda de reportes cambiada a {currency}. Los montos que ya registraste siguen guardados en la moneda en que los anotaste; ahora los totales se muestran en {currency}.'**
  String currencyChangedMsg(String currency);

  /// Aviso bajo un total convertido con la tasa de hoy
  ///
  /// In es, this message translates to:
  /// **'Total al cambio de hoy. Cada movimiento sigue guardado en su propia moneda.'**
  String get currencyRateNote;

  /// No description provided for @settingsSavedMsg.
  ///
  /// In es, this message translates to:
  /// **'Configuración guardada'**
  String get settingsSavedMsg;

  /// No description provided for @noIncomesPeriod.
  ///
  /// In es, this message translates to:
  /// **'Sin ingresos en este período.'**
  String get noIncomesPeriod;

  /// No description provided for @recordExpense.
  ///
  /// In es, this message translates to:
  /// **'Registrar gasto'**
  String get recordExpense;

  /// No description provided for @recordIncome.
  ///
  /// In es, this message translates to:
  /// **'Registrar ingreso'**
  String get recordIncome;

  /// No description provided for @expensesByCategory.
  ///
  /// In es, this message translates to:
  /// **'Gastos por categoría'**
  String get expensesByCategory;

  /// No description provided for @incomesByCategory.
  ///
  /// In es, this message translates to:
  /// **'Ingresos por categoría'**
  String get incomesByCategory;

  /// No description provided for @categoryBreakdownTotal.
  ///
  /// In es, this message translates to:
  /// **'Total del período: {total}'**
  String categoryBreakdownTotal(Object total);

  /// No description provided for @categoryBreakdownShowMore.
  ///
  /// In es, this message translates to:
  /// **'Ver {count} más'**
  String categoryBreakdownShowMore(Object count);

  /// No description provided for @categoryBreakdownShowLess.
  ///
  /// In es, this message translates to:
  /// **'Ver menos'**
  String get categoryBreakdownShowLess;

  /// No description provided for @assignCropsTitle.
  ///
  /// In es, this message translates to:
  /// **'Asignar cultivo'**
  String get assignCropsTitle;

  /// No description provided for @assignCropsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige un cultivo para cada registro. Todos los cambios se guardan juntos.'**
  String get assignCropsSubtitle;

  /// No description provided for @assignCropsUnassigned.
  ///
  /// In es, this message translates to:
  /// **'Sin cultivo'**
  String get assignCropsUnassigned;

  /// No description provided for @assignCropsNewCrop.
  ///
  /// In es, this message translates to:
  /// **'Nuevo cultivo…'**
  String get assignCropsNewCrop;

  /// No description provided for @assignCropsSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get assignCropsSave;

  /// No description provided for @assignCropsSaved.
  ///
  /// In es, this message translates to:
  /// **'{count} registros actualizados'**
  String assignCropsSaved(Object count);

  /// No description provided for @assignCropsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Ya no hay registros sin cultivo. ¡Todo asignado!'**
  String get assignCropsEmpty;

  /// No description provided for @assignCropsBanner.
  ///
  /// In es, this message translates to:
  /// **'{count} registros sin cultivo asignado'**
  String assignCropsBanner(Object count);

  /// No description provided for @assignCropsNow.
  ///
  /// In es, this message translates to:
  /// **'Asignar cultivo ahora'**
  String get assignCropsNow;

  /// No description provided for @insightsTitle.
  ///
  /// In es, this message translates to:
  /// **'Conclusión del período'**
  String get insightsTitle;

  /// No description provided for @insightNoActivity.
  ///
  /// In es, this message translates to:
  /// **'No hay movimientos registrados en este período.'**
  String get insightNoActivity;

  /// No description provided for @insightBalanceNoIncome.
  ///
  /// In es, this message translates to:
  /// **'Resultado del período: {spent} en gastos y ninguna venta en este período.'**
  String insightBalanceNoIncome(Object spent);

  /// No description provided for @insightBalancePositive.
  ///
  /// In es, this message translates to:
  /// **'Resultado del período: ganancia de {balance} con {margin} de margen sobre las ventas.'**
  String insightBalancePositive(Object balance, Object margin);

  /// No description provided for @insightBalanceNegative.
  ///
  /// In es, this message translates to:
  /// **'Resultado del período: pérdida de {loss} con margen de {margin} sobre las ventas.'**
  String insightBalanceNegative(Object loss, Object margin);

  /// No description provided for @insightVsPrev.
  ///
  /// In es, this message translates to:
  /// **'Frente a {month}: ventas {incChange} y gastos {expChange}.'**
  String insightVsPrev(String month, String incChange, String expChange);

  /// B1: cuando el mes que se mira es el mes en curso, el mes anterior se recorta al mismo tramo de días
  ///
  /// In es, this message translates to:
  /// **'Frente a {month} (mismos días): ventas {incChange} y gastos {expChange}.'**
  String insightVsPrevPartial(String month, String incChange, String expChange);

  /// No description provided for @insightChangeUp.
  ///
  /// In es, this message translates to:
  /// **'subieron {pct}'**
  String insightChangeUp(Object pct);

  /// No description provided for @insightChangeDown.
  ///
  /// In es, this message translates to:
  /// **'bajaron {pct}'**
  String insightChangeDown(Object pct);

  /// No description provided for @insightChangeFlat.
  ///
  /// In es, this message translates to:
  /// **'sin cambios'**
  String get insightChangeFlat;

  /// No description provided for @insightTopExpense.
  ///
  /// In es, this message translates to:
  /// **'Tu mayor gasto fue {category} ({amount}, el {pct} del total).'**
  String insightTopExpense(String category, String amount, String pct);

  /// No description provided for @insightTopExpenseDependency.
  ///
  /// In es, this message translates to:
  /// **'Concentras más de la mitad de tus gastos en {category}: revisa ese costo recurrente antes de que siga creciendo.'**
  String insightTopExpenseDependency(Object category);

  /// No description provided for @insightTopIncome.
  ///
  /// In es, this message translates to:
  /// **'Tu mejor ingreso fue {category} ({amount}, el {pct} del total).'**
  String insightTopIncome(String category, String amount, String pct);

  /// No description provided for @insightLowPrice.
  ///
  /// In es, this message translates to:
  /// **'Vendes más barato que tu histórico: promedio reciente {recent} vs {history} por kilo. Revisa precio, presentación o canal de venta.'**
  String insightLowPrice(String recent, String history);

  /// No description provided for @insightBestMonth.
  ///
  /// In es, this message translates to:
  /// **'Tu mejor mes de ventas fue {salesMonth} ({salesAmount}); tu menor gasto mensual fue {costMonth} ({costAmount}).'**
  String insightBestMonth(String salesMonth, String salesAmount, String costMonth, String costAmount);

  /// No description provided for @chartTitle.
  ///
  /// In es, this message translates to:
  /// **'Gastos vs ingresos — {year}'**
  String chartTitle(int year);

  /// No description provided for @chartCumulativeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu dinero en {year} — acumulado'**
  String chartCumulativeTitle(int year);

  /// No description provided for @chartCumulativeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresos menos gastos, mes a mes. Toca un punto para ver cuánto llevabas.'**
  String get chartCumulativeSubtitle;

  /// No description provided for @chartStartLabel.
  ///
  /// In es, this message translates to:
  /// **'como empezaste'**
  String get chartStartLabel;

  /// No description provided for @chartAccumDelta.
  ///
  /// In es, this message translates to:
  /// **'{amount} desde el 1 de enero'**
  String chartAccumDelta(String amount);

  /// No description provided for @chartCumulativeEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay movimientos en {year}.'**
  String chartCumulativeEmpty(int year);

  /// No description provided for @alertExcessTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu gasto en {category} casi se duplicó'**
  String alertExcessTitle(String category);

  /// No description provided for @alertExcessMessage.
  ///
  /// In es, this message translates to:
  /// **'El problema: este mes llevas {current} en {category} frente a un promedio de {avg} por mes.'**
  String alertExcessMessage(String current, String category, String avg);

  /// No description provided for @alertExcessSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Revisa qué generó ese aumento. Si fue un gasto grande y puntual, regístralo por partes para que no distorsione tus promedios.'**
  String get alertExcessSuggestion;

  /// No description provided for @alertNoIncomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Hay gastos registrados, pero cero ventas'**
  String get alertNoIncomeTitle;

  /// No description provided for @alertNoIncomeMessage.
  ///
  /// In es, this message translates to:
  /// **'El problema: hay {spent} en gastos y ninguna venta, así que el balance está en pérdida.'**
  String alertNoIncomeMessage(String spent);

  /// No description provided for @alertNoIncomeSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Cuando vendas tu cosecha, regístrala como ingreso para que el balance muestre tu ganancia real.'**
  String get alertNoIncomeSuggestion;

  /// No description provided for @alertNoSalesTitle.
  ///
  /// In es, this message translates to:
  /// **'Hace {days} días que no registras ventas'**
  String alertNoSalesTitle(int days);

  /// No description provided for @alertNoSalesMessage.
  ///
  /// In es, this message translates to:
  /// **'El problema: no vendes desde el {date}. Tus ingresos están estancados desde esa fecha.'**
  String alertNoSalesMessage(String date);

  /// No description provided for @alertNoSalesSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Registra la última cosecha vendida o la venta más reciente para mantener el estado de resultados al día.'**
  String get alertNoSalesSuggestion;

  /// No description provided for @alertLossesTitle.
  ///
  /// In es, this message translates to:
  /// **'{count} meses seguidos con pérdidas (gastos > ingresos)'**
  String alertLossesTitle(int count);

  /// No description provided for @alertLossesMessage.
  ///
  /// In es, this message translates to:
  /// **'El problema: {months} gastaste más de lo que ganaste.'**
  String alertLossesMessage(String months);

  /// No description provided for @alertLossesSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Revisa tus costos fijos (mano de obra, fertilizante, transporte) y busca reducir gastos o mejorar el precio de venta.'**
  String get alertLossesSuggestion;

  /// No description provided for @alertLowPriceTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus ventas recientes rinden menos que tu promedio'**
  String get alertLowPriceTitle;

  /// No description provided for @alertLowPriceMessage.
  ///
  /// In es, this message translates to:
  /// **'El problema: en los últimos 30 días vendes a {recentAvg} por kilo, por debajo de tu promedio histórico de {histAvg} por kilo.'**
  String alertLowPriceMessage(String recentAvg, String histAvg);

  /// No description provided for @alertLowPriceSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Compara precios con otros compradores y evalúa esperar un mejor momento para vender parte de la cosecha.'**
  String get alertLowPriceSuggestion;

  /// No description provided for @alertLowPriceManualTitle.
  ///
  /// In es, this message translates to:
  /// **'Vendiste café por debajo de tu precio mínimo'**
  String get alertLowPriceManualTitle;

  /// No description provided for @alertLowPriceManualMessage.
  ///
  /// In es, this message translates to:
  /// **'El {date} vendiste a {price} por kg, por debajo de tu precio mínimo de {threshold}. Considera negociar un mejor precio o esperar.'**
  String alertLowPriceManualMessage(String date, String price, String threshold);

  /// No description provided for @alertDeficitNoCropTitle.
  ///
  /// In es, this message translates to:
  /// **'Gastos sin cultivo asignado no se recuperan'**
  String get alertDeficitNoCropTitle;

  /// El orden de los 'placeholders' es el orden de los argumentos; 'count' va primero porque así aparece en el texto. Sin declararlo, el generador lo manda al final y las cifras caen en la casilla equivocada.
  ///
  /// In es, this message translates to:
  /// **'El problema: tienes {count} registros sin cultivo asignado que suman {spent} en gastos y {sold} en ventas (solo has recuperado el {recovery} de lo invertido).'**
  String alertDeficitNoCropMessage(String count, String spent, String sold, String recovery);

  /// No description provided for @alertDeficitNoCropSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Edita esos {count} registros y asígnales su cultivo (Café, Plátano…) para que su costo cuente en el cultivo correcto, y esta alerta desaparecerá.'**
  String alertDeficitNoCropSuggestion(Object count);

  /// No description provided for @alertDeficitTitle.
  ///
  /// In es, this message translates to:
  /// **'{crop} está perdiendo dinero'**
  String alertDeficitTitle(String crop);

  /// No description provided for @alertDeficitMessage.
  ///
  /// In es, this message translates to:
  /// **'El problema: invertiste {spent} en {crop} y solo has recuperado {sold} (el {recovery} de lo invertido).'**
  String alertDeficitMessage(String spent, String crop, String sold, String recovery);

  /// No description provided for @alertDeficitSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Evalúa bajar los costos de {crop}, mejorar el precio de venta o decidir si conviene seguir invirtiendo en ese cultivo.'**
  String alertDeficitSuggestion(String crop);

  /// No description provided for @pdfIncomeStatement.
  ///
  /// In es, this message translates to:
  /// **'Estado de Resultados — {period}'**
  String pdfIncomeStatement(String period);

  /// No description provided for @pdfGeneratedOn.
  ///
  /// In es, this message translates to:
  /// **'Generado el {date} · Moneda: {currency}'**
  String pdfGeneratedOn(String date, String currency);

  /// No description provided for @pdfIncomesHeader.
  ///
  /// In es, this message translates to:
  /// **'INGRESOS'**
  String get pdfIncomesHeader;

  /// No description provided for @pdfNoIncomeSub.
  ///
  /// In es, this message translates to:
  /// **'    Sin ingresos en el período'**
  String get pdfNoIncomeSub;

  /// No description provided for @pdfExpensesHeader.
  ///
  /// In es, this message translates to:
  /// **'GASTOS OPERACIONALES'**
  String get pdfExpensesHeader;

  /// No description provided for @pdfNoExpensesSub.
  ///
  /// In es, this message translates to:
  /// **'    Sin gastos en el período'**
  String get pdfNoExpensesSub;

  /// No description provided for @pdfCropBreakdown.
  ///
  /// In es, this message translates to:
  /// **'Desglose por cultivo — {period}'**
  String pdfCropBreakdown(String period);

  /// No description provided for @pdfYearAnnex.
  ///
  /// In es, this message translates to:
  /// **'Anexo — Acumulado del año {year}'**
  String pdfYearAnnex(int year);

  /// No description provided for @pdfMarginFootnote.
  ///
  /// In es, this message translates to:
  /// **'Margen = (Ingresos − Gastos) / Ingresos. Un margen negativo sugiere revisar el cultivo.'**
  String get pdfMarginFootnote;

  /// No description provided for @pdfColCrop.
  ///
  /// In es, this message translates to:
  /// **'Cultivo'**
  String get pdfColCrop;

  /// No description provided for @pdfColMov.
  ///
  /// In es, this message translates to:
  /// **'Mov.'**
  String get pdfColMov;

  /// No description provided for @pdfColExpenses.
  ///
  /// In es, this message translates to:
  /// **'Gastos'**
  String get pdfColExpenses;

  /// No description provided for @pdfColIncomes.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get pdfColIncomes;

  /// No description provided for @pdfColResult.
  ///
  /// In es, this message translates to:
  /// **'Resultado'**
  String get pdfColResult;

  /// No description provided for @pdfColMargin.
  ///
  /// In es, this message translates to:
  /// **'Margen'**
  String get pdfColMargin;

  /// No description provided for @pdfFileNamePrefix.
  ///
  /// In es, this message translates to:
  /// **'reporte'**
  String get pdfFileNamePrefix;

  /// No description provided for @excelSheetSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get excelSheetSummary;

  /// No description provided for @excelSheetCrops.
  ///
  /// In es, this message translates to:
  /// **'Por cultivo'**
  String get excelSheetCrops;

  /// No description provided for @excelSheetMovements.
  ///
  /// In es, this message translates to:
  /// **'Movimientos'**
  String get excelSheetMovements;

  /// No description provided for @excelSheetHarvests.
  ///
  /// In es, this message translates to:
  /// **'Cosechas'**
  String get excelSheetHarvests;

  /// No description provided for @excelSheetPayrollCash.
  ///
  /// In es, this message translates to:
  /// **'Nómina y caja'**
  String get excelSheetPayrollCash;

  /// No description provided for @excelTotalIncomes.
  ///
  /// In es, this message translates to:
  /// **'Total ingresos'**
  String get excelTotalIncomes;

  /// No description provided for @excelTotalExpenses.
  ///
  /// In es, this message translates to:
  /// **'Total gastos'**
  String get excelTotalExpenses;

  /// No description provided for @excelTotalResult.
  ///
  /// In es, this message translates to:
  /// **'Resultado'**
  String get excelTotalResult;

  /// No description provided for @pdfColDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get pdfColDate;

  /// No description provided for @pdfColType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get pdfColType;

  /// No description provided for @pdfColCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get pdfColCategory;

  /// No description provided for @pdfColDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get pdfColDescription;

  /// No description provided for @pdfColAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get pdfColAmount;

  /// No description provided for @balanceTemplateTitle.
  ///
  /// In es, this message translates to:
  /// **'PLANTILLA DE BALANCE — {period}'**
  String balanceTemplateTitle(String period);

  /// No description provided for @balanceTemplateFarm.
  ///
  /// In es, this message translates to:
  /// **'{farm} — Generado el {date}'**
  String balanceTemplateFarm(String farm, String date);

  /// No description provided for @balanceAssetsTitle.
  ///
  /// In es, this message translates to:
  /// **'ACTIVOS'**
  String get balanceAssetsTitle;

  /// No description provided for @balanceRowCash.
  ///
  /// In es, this message translates to:
  /// **'Caja / bancos'**
  String get balanceRowCash;

  /// No description provided for @balanceRowReceivables.
  ///
  /// In es, this message translates to:
  /// **'Cuentas por cobrar'**
  String get balanceRowReceivables;

  /// No description provided for @balanceRowInventory.
  ///
  /// In es, this message translates to:
  /// **'Inventario de café'**
  String get balanceRowInventory;

  /// No description provided for @balanceRowMachinery.
  ///
  /// In es, this message translates to:
  /// **'Maquinaria y equipos'**
  String get balanceRowMachinery;

  /// No description provided for @balanceRowLand.
  ///
  /// In es, this message translates to:
  /// **'Terrenos / plantaciones'**
  String get balanceRowLand;

  /// No description provided for @balanceRowOtherAssets.
  ///
  /// In es, this message translates to:
  /// **'Otros activos'**
  String get balanceRowOtherAssets;

  /// No description provided for @balanceTotalAssets.
  ///
  /// In es, this message translates to:
  /// **'TOTAL ACTIVOS'**
  String get balanceTotalAssets;

  /// No description provided for @balanceLiabilitiesTitle.
  ///
  /// In es, this message translates to:
  /// **'PASIVOS'**
  String get balanceLiabilitiesTitle;

  /// No description provided for @balanceRowLoans.
  ///
  /// In es, this message translates to:
  /// **'Préstamos / deudas'**
  String get balanceRowLoans;

  /// No description provided for @balanceRowPayables.
  ///
  /// In es, this message translates to:
  /// **'Cuentas por pagar'**
  String get balanceRowPayables;

  /// No description provided for @balanceRowTaxes.
  ///
  /// In es, this message translates to:
  /// **'Impuestos por pagar'**
  String get balanceRowTaxes;

  /// No description provided for @balanceTotalLiabilities.
  ///
  /// In es, this message translates to:
  /// **'TOTAL PASIVOS'**
  String get balanceTotalLiabilities;

  /// No description provided for @balanceEquityTitle.
  ///
  /// In es, this message translates to:
  /// **'PATRIMONIO'**
  String get balanceEquityTitle;

  /// No description provided for @balanceRowCapital.
  ///
  /// In es, this message translates to:
  /// **'Capital inicial'**
  String get balanceRowCapital;

  /// No description provided for @balanceRowAccumulated.
  ///
  /// In es, this message translates to:
  /// **'Utilidades acumuladas'**
  String get balanceRowAccumulated;

  /// No description provided for @balanceRowNetIncome.
  ///
  /// In es, this message translates to:
  /// **'Utilidad del ejercicio ({year})'**
  String balanceRowNetIncome(int year);

  /// No description provided for @balanceTotalEquity.
  ///
  /// In es, this message translates to:
  /// **'TOTAL PATRIMONIO'**
  String get balanceTotalEquity;

  /// No description provided for @balanceCheckLabel.
  ///
  /// In es, this message translates to:
  /// **'VERIFICACIÓN — Activo = Pasivo + Patrimonio (0 = balanceado)'**
  String get balanceCheckLabel;

  /// No description provided for @balanceCheckFormula.
  ///
  /// In es, this message translates to:
  /// **'=B11-B17-B23'**
  String get balanceCheckFormula;

  /// No description provided for @balanceNote.
  ///
  /// In es, this message translates to:
  /// **'Completa los montos de cada rubro en Excel. La celda de verificación usa fórmulas: debe dar 0 cuando el balance cuadra.'**
  String get balanceNote;

  /// Plantilla de balance cuando el año mezcla monedas: no se emite ninguna fórmula de total y la utilidad sale moneda por moneda
  ///
  /// In es, this message translates to:
  /// **'Este año tienes movimientos en {count} monedas: la utilidad va moneda por moneda y no se calculan los totales del balance, porque sumar monedas distintas daría una cifra falsa.'**
  String balanceMixedCurrencyNote(int count);

  /// No description provided for @catSiembra.
  ///
  /// In es, this message translates to:
  /// **'Siembra'**
  String get catSiembra;

  /// No description provided for @catCercasPreparacion.
  ///
  /// In es, this message translates to:
  /// **'Cercas y preparación'**
  String get catCercasPreparacion;

  /// No description provided for @catSemillasInsumos.
  ///
  /// In es, this message translates to:
  /// **'Semillas e insumos'**
  String get catSemillasInsumos;

  /// No description provided for @catFertilizante.
  ///
  /// In es, this message translates to:
  /// **'Fertilizante'**
  String get catFertilizante;

  /// No description provided for @catManoObra.
  ///
  /// In es, this message translates to:
  /// **'Mano de obra'**
  String get catManoObra;

  /// No description provided for @catCosecha.
  ///
  /// In es, this message translates to:
  /// **'Cosecha y recolección'**
  String get catCosecha;

  /// No description provided for @catPlagas.
  ///
  /// In es, this message translates to:
  /// **'Control plagas'**
  String get catPlagas;

  /// No description provided for @catRiego.
  ///
  /// In es, this message translates to:
  /// **'Riego'**
  String get catRiego;

  /// No description provided for @catEnergia.
  ///
  /// In es, this message translates to:
  /// **'Energía'**
  String get catEnergia;

  /// No description provided for @catAgua.
  ///
  /// In es, this message translates to:
  /// **'Agua'**
  String get catAgua;

  /// No description provided for @catEmpaque.
  ///
  /// In es, this message translates to:
  /// **'Empacado y comercialización'**
  String get catEmpaque;

  /// No description provided for @catTransporte.
  ///
  /// In es, this message translates to:
  /// **'Transporte'**
  String get catTransporte;

  /// No description provided for @catEquipo.
  ///
  /// In es, this message translates to:
  /// **'Equipo'**
  String get catEquipo;

  /// No description provided for @catMantenimiento.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento'**
  String get catMantenimiento;

  /// No description provided for @catArriendo.
  ///
  /// In es, this message translates to:
  /// **'Arriendo de tierras'**
  String get catArriendo;

  /// No description provided for @catImpuestos.
  ///
  /// In es, this message translates to:
  /// **'Impuestos y tasas'**
  String get catImpuestos;

  /// No description provided for @catCreditoIntereses.
  ///
  /// In es, this message translates to:
  /// **'Crédito e intereses'**
  String get catCreditoIntereses;

  /// No description provided for @catSeguros.
  ///
  /// In es, this message translates to:
  /// **'Seguros'**
  String get catSeguros;

  /// No description provided for @catOtro.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get catOtro;

  /// No description provided for @catVentaCafe.
  ///
  /// In es, this message translates to:
  /// **'Venta café'**
  String get catVentaCafe;

  /// No description provided for @catVentaPlatano.
  ///
  /// In es, this message translates to:
  /// **'Venta plátano'**
  String get catVentaPlatano;

  /// No description provided for @catSubvenciones.
  ///
  /// In es, this message translates to:
  /// **'Subvenciones y apoyos'**
  String get catSubvenciones;

  /// No description provided for @catVentaOtro.
  ///
  /// In es, this message translates to:
  /// **'Venta otros'**
  String get catVentaOtro;

  /// No description provided for @catVenta.
  ///
  /// In es, this message translates to:
  /// **'Venta'**
  String get catVenta;

  /// No description provided for @catVentaCrop.
  ///
  /// In es, this message translates to:
  /// **'Venta {crop}'**
  String catVentaCrop(String crop);

  /// No description provided for @alertCropEstablishmentTitle.
  ///
  /// In es, this message translates to:
  /// **'{crop} todavía no da: es inversión, no pérdida'**
  String alertCropEstablishmentTitle(String crop);

  /// No description provided for @alertCropEstablishmentMessage.
  ///
  /// In es, this message translates to:
  /// **'El problema: llevas {investment} invertidos en {crop} y aún no hay ingresos. Es normal en esta etapa: el plantío está creciendo y la primera cosecha llega al pasar a Dando.'**
  String alertCropEstablishmentMessage(String investment, String crop);

  /// No description provided for @alertCropEstablishmentSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Sigue registrando los gastos de {crop}. Cuando el cultivo pase a Dando, la app evaluará su rentabilidad normal.'**
  String alertCropEstablishmentSuggestion(String crop);

  /// No description provided for @alertHarvestVsSalesTitle.
  ///
  /// In es, this message translates to:
  /// **'Vendiste más de lo que cosechaste en {crop}'**
  String alertHarvestVsSalesTitle(String crop);

  /// No description provided for @alertHarvestVsSalesMessage.
  ///
  /// In es, this message translates to:
  /// **'El problema: en los últimos 12 meses vendiste {soldKg} de {crop}, pero solo registraste {harvestedKg} de cosecha. Revisa si te faltó registrar alguna cosecha o si usaste la misma unidad en la cosecha y en la venta.'**
  String alertHarvestVsSalesMessage(String soldKg, String crop, String harvestedKg);

  /// No description provided for @alertHarvestVsSalesSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Compara tus registros de {crop}: asegúrate de registrar cada cosecha y cada venta con la misma unidad para evitar desfases.'**
  String alertHarvestVsSalesSuggestion(String crop);

  /// No description provided for @alertRecentlyPlantedTitle.
  ///
  /// In es, this message translates to:
  /// **'Registraste una siembra reciente'**
  String get alertRecentlyPlantedTitle;

  /// No description provided for @alertRecentlyPlantedMessage.
  ///
  /// In es, this message translates to:
  /// **'Registraste una siembra o resiembra de {crop} el {date}. Verifica que el número de plantas vivas actualizado del cultivo coincida con el conteo real.'**
  String alertRecentlyPlantedMessage(String crop, String date);

  /// No description provided for @alertRecentlyPlantedSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Edita el cultivo para ajustar sus plantas vivas si el conteo cambió después de la siembra.'**
  String get alertRecentlyPlantedSuggestion;

  /// No description provided for @alertFirstHarvestTitle.
  ///
  /// In es, this message translates to:
  /// **'{crop} ya debería estar rindiendo'**
  String alertFirstHarvestTitle(String crop);

  /// No description provided for @alertFirstHarvestMessage.
  ///
  /// In es, this message translates to:
  /// **'Estimaste la primera cosecha de {crop} para el {date} y hasta ahora no registraste ninguna cosecha.'**
  String alertFirstHarvestMessage(String crop, String date);

  /// No description provided for @alertFirstHarvestSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Revisa el cultivo: si cambió algo o la fecha ya no va, edítala. Si ya vendiste, anota esa venta con los kilos y el dinero que te pagaron: con esos kilos la app ya sabe que cosechaste y este aviso desaparece.'**
  String get alertFirstHarvestSuggestion;

  /// No description provided for @alertMissingQtyTitle.
  ///
  /// In es, this message translates to:
  /// **'Tienes ventas sin kilos registrados'**
  String get alertMissingQtyTitle;

  /// No description provided for @alertMissingQtyMessage.
  ///
  /// In es, this message translates to:
  /// **'El problema: en los últimos 90 días registraste {count} ventas sin la cantidad vendida. Sin ese dato, la app no puede calcular tu precio por kilo ni tu rentabilidad.'**
  String alertMissingQtyMessage(int count);

  /// No description provided for @alertMissingQtySuggestion.
  ///
  /// In es, this message translates to:
  /// **'Edita esas ventas e ingresa los kilos vendidos. Así tus informes de precio y rentabilidad serán confiables.'**
  String get alertMissingQtySuggestion;

  /// No description provided for @alertUnpaidTitle.
  ///
  /// In es, this message translates to:
  /// **'Hay ventas por cobrar'**
  String get alertUnpaidTitle;

  /// No description provided for @alertUnpaidMessage.
  ///
  /// In es, this message translates to:
  /// **'El problema: {count} ventas suman {amount} que todavía no te pagaron, la más vieja con {days} días.'**
  String alertUnpaidMessage(int count, String amount, int days);

  /// No description provided for @alertUnpaidSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Cobra antes de que se pase: cuando el dinero entre, edita la venta y cambia su estado a «Pagado».'**
  String get alertUnpaidSuggestion;

  /// No description provided for @alertCashBoxWarningTitle.
  ///
  /// In es, this message translates to:
  /// **'La caja menor de {month} está al {percent}'**
  String alertCashBoxWarningTitle(String month, String percent);

  /// No description provided for @alertCashBoxWarningMessage.
  ///
  /// In es, this message translates to:
  /// **'El problema: este mes llevas {used} de {total} en jornales y extras. Te quedan {remaining} antes de agotarla.'**
  String alertCashBoxWarningMessage(String used, String total, String remaining);

  /// No description provided for @alertCashBoxWarningSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Revisa los gastos extras y deja solo lo necesario hasta cerrar el mes.'**
  String get alertCashBoxWarningSuggestion;

  /// No description provided for @alertCashBoxDangerTitle.
  ///
  /// In es, this message translates to:
  /// **'Caja menor agotada en {month}'**
  String alertCashBoxDangerTitle(String month);

  /// No description provided for @alertCashBoxDangerMessage.
  ///
  /// In es, this message translates to:
  /// **'El problema: este mes llevas {used} de {total} en jornales y extras ({percent}). Ya no queda presupuesto disponible.'**
  String alertCashBoxDangerMessage(String used, String total, String percent);

  /// No description provided for @alertCashBoxDangerSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Revisa los gastos extras y considera reducir trabajadores este mes.'**
  String get alertCashBoxDangerSuggestion;

  /// El orden de los 'placeholders' es el orden de los argumentos, como se lee en la frase: primero lo gastado y después el arrastre.
  ///
  /// In es, this message translates to:
  /// **'El problema: este mes llevas {used} en jornales y extras, y la caja cerró los meses anteriores en números rojos: el arrastre está en {carry}.'**
  String alertCashBoxDebtMessage(String used, String carry);

  /// No description provided for @backupSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Respaldo'**
  String get backupSectionTitle;

  /// No description provided for @backupSectionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Guarda todos los datos de tu finca en un archivo y vuelve a cargarlos cuando quieras.'**
  String get backupSectionSubtitle;

  /// No description provided for @backupExport.
  ///
  /// In es, this message translates to:
  /// **'Exportar respaldo'**
  String get backupExport;

  /// No description provided for @backupRestore.
  ///
  /// In es, this message translates to:
  /// **'Restaurar respaldo'**
  String get backupRestore;

  /// No description provided for @backupShareSubject.
  ///
  /// In es, this message translates to:
  /// **'Balance - Respaldo de datos'**
  String get backupShareSubject;

  /// No description provided for @backupExportDoneMsg.
  ///
  /// In es, this message translates to:
  /// **'Respaldo listo para compartir.'**
  String get backupExportDoneMsg;

  /// No description provided for @backupConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Restaurar este respaldo?'**
  String get backupConfirmTitle;

  /// Qué hará la restauración, con el detalle de lo que trae el archivo
  ///
  /// In es, this message translates to:
  /// **'Se añadirá: {counts}. Lo que ya tengas se conserva tal cual; nada se borra.'**
  String backupConfirmMessage(String counts);

  /// No description provided for @backupConfirmAccept.
  ///
  /// In es, this message translates to:
  /// **'Restaurar'**
  String get backupConfirmAccept;

  /// Aviso de que el archivo de respaldo salió de otra cuenta
  ///
  /// In es, this message translates to:
  /// **'Aviso: este respaldo viene de otra cuenta. Sus datos se sumarán a los que ya tienes aquí.'**
  String get backupAccountDiffers;

  /// Conteo de cultivos dentro del respaldo
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} cultivo} other{{count} cultivos}}'**
  String backupCountCrops(int count);

  /// Conteo de siembras dentro del respaldo
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} siembra} other{{count} siembras}}'**
  String backupCountSowings(int count);

  /// Conteo de cosechas dentro del respaldo
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} cosecha} other{{count} cosechas}}'**
  String backupCountHarvests(int count);

  /// Conteo de trabajadores dentro del respaldo
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} trabajador} other{{count} trabajadores}}'**
  String backupCountEmployees(int count);

  /// Resultado de la restauración: cuántos datos entraron y cuántos ya estaban
  ///
  /// In es, this message translates to:
  /// **'Respaldo restaurado: {added} añadidos y {existing} que ya tenías.'**
  String backupSummary(int added, int existing);

  /// Aviso de datos importados sin enlace a su cultivo o cosecha
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} dato quedó sin enlazar con su cultivo o cosecha} other{{count} datos quedaron sin enlazar con su cultivo o cosecha}}'**
  String backupOrphans(int count);

  /// No description provided for @backupInvalidFile.
  ///
  /// In es, this message translates to:
  /// **'Ese archivo no es un respaldo válido.'**
  String get backupInvalidFile;

  /// No description provided for @backupUnknownFormat.
  ///
  /// In es, this message translates to:
  /// **'Ese archivo no es un respaldo de Balance.'**
  String get backupUnknownFormat;

  /// No description provided for @backupUnsupportedVersion.
  ///
  /// In es, this message translates to:
  /// **'Este respaldo se hizo con una versión más nueva de la app. Actualiza la app para restaurarlo.'**
  String get backupUnsupportedVersion;

  /// No description provided for @backupRestoreError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo restaurar el respaldo. Inténtalo de nuevo.'**
  String get backupRestoreError;

  /// No description provided for @terrenosSection.
  ///
  /// In es, this message translates to:
  /// **'Tus terrenos'**
  String get terrenosSection;

  /// No description provided for @terrenoNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo terreno'**
  String get terrenoNew;

  /// No description provided for @terrenoEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar terreno'**
  String get terrenoEdit;

  /// No description provided for @terrenoDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar terreno'**
  String get terrenoDelete;

  /// No description provided for @terrenoNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del terreno'**
  String get terrenoNameLabel;

  /// No description provided for @terrenoAreaLabel.
  ///
  /// In es, this message translates to:
  /// **'Hectáreas del terreno'**
  String get terrenoAreaLabel;

  /// El área del terreno es opcional: se pregunta, pero no se exige
  ///
  /// In es, this message translates to:
  /// **'Opcional. Solo si las has medido; si no, déjalo vacío.'**
  String get helpTerrenoArea;

  /// No description provided for @terrenoCropsLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Qué cultivos van aquí?'**
  String get terrenoCropsLabel;

  /// Explica que las casillas no borran nada: solo mueven el cultivo de sitio
  ///
  /// In es, this message translates to:
  /// **'Marca los que quieras poner en este terreno. Un mismo terreno puede tener café, plátano y sombra a la vez.'**
  String get helpTerrenoCrops;

  /// Cuando aún no existe ningún cultivo, el diálogo se queda sin casillas
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes cultivos. Puedes crear el terreno y asignarlos después.'**
  String get terrenoCropsEmpty;

  /// No description provided for @terrenoNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ponle nombre al terreno.'**
  String get terrenoNameRequired;

  /// No description provided for @terrenoNameTaken.
  ///
  /// In es, this message translates to:
  /// **'Ya hay un terreno con ese nombre.'**
  String get terrenoNameTaken;

  /// No description provided for @terrenoAreaInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ese número de hectáreas no se puede leer.'**
  String get terrenoAreaInvalid;

  /// No description provided for @terrenoLocationSection.
  ///
  /// In es, this message translates to:
  /// **'Ubicación del lote'**
  String get terrenoLocationSection;

  /// No description provided for @terrenoLocationButton.
  ///
  /// In es, this message translates to:
  /// **'Tomar mi ubicación'**
  String get terrenoLocationButton;

  /// No description provided for @terrenoLocationHelper.
  ///
  /// In es, this message translates to:
  /// **'El punto donde está el lote. Tómalo desde el celular o escríbelo a mano. La app no lo vuelve a medir sola: mover la tierra sin avisar sería inventar datos.'**
  String get terrenoLocationHelper;

  /// No description provided for @terrenoLatLabel.
  ///
  /// In es, this message translates to:
  /// **'Latitud'**
  String get terrenoLatLabel;

  /// No description provided for @terrenoLngLabel.
  ///
  /// In es, this message translates to:
  /// **'Longitud'**
  String get terrenoLngLabel;

  /// No description provided for @terrenoLocationDate.
  ///
  /// In es, this message translates to:
  /// **'Registrado el {date}'**
  String terrenoLocationDate(Object date);

  /// No description provided for @terrenoLocationInvalid.
  ///
  /// In es, this message translates to:
  /// **'La latitud va de -90 a 90 y la longitud de -180 a 180.'**
  String get terrenoLocationInvalid;

  /// No description provided for @terrenoLocationHalf.
  ///
  /// In es, this message translates to:
  /// **'Las dos coordenadas deben ir juntas: una sola no dice dónde está nada.'**
  String get terrenoLocationHalf;

  /// No description provided for @terrenoLocationFailed.
  ///
  /// In es, this message translates to:
  /// **'No pude tomar la ubicación. Escríbela a mano o inténtalo de nuevo.'**
  String get terrenoLocationFailed;

  /// No description provided for @reportTerrenosTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus terrenos · ubicación'**
  String get reportTerrenosTitle;

  /// No description provided for @reportTerrenosHint.
  ///
  /// In es, this message translates to:
  /// **'La coordenada de cada lote, tal como la registraste. No se vuelve a medir sola.'**
  String get reportTerrenosHint;

  /// No description provided for @associatedCropsCostTitle.
  ///
  /// In es, this message translates to:
  /// **'Costos entre cultivos asociados'**
  String get associatedCropsCostTitle;

  /// No description provided for @associatedCropsCostNote.
  ///
  /// In es, this message translates to:
  /// **'Varios cultivos comparten el mismo terreno: un mismo jornal o la misma bolsa de abono pueden servir a varios. Ese gasto se reparte entre ellos por hectáreas; si a alguno le falta la superficie, sale aparte. Por eso el costo de cada cultivo es una aproximación. El total de la finca sí cuadra.'**
  String get associatedCropsCostNote;

  /// Cuántos cultivos hay dentro de un terreno
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} cultivo} other{{count} cultivos}}'**
  String terrenoCropCount(int count);

  /// Área de los cultivos asignada a un terreno, comparada con la del terreno
  ///
  /// In es, this message translates to:
  /// **'{assigned} de {total} ha asignadas'**
  String terrenoAreaAssigned(String assigned, String total);

  /// Aviso en ámbar: las áreas de los cultivos superan el área del terreno. No bloquea el guardado.
  ///
  /// In es, this message translates to:
  /// **'Las áreas suman {assigned} ha y el terreno tiene {total}'**
  String terrenoAreaOver(String assigned, String total);

  /// Cultivos del terreno que todavía no tienen área anotada
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} cultivo sin área} other{{count} cultivos sin área}}'**
  String terrenoAreaWithoutArea(int count);

  /// Ayuda en el editor de cultivo: cuánto del terreno ya está asignado entre sus cultivos
  ///
  /// In es, this message translates to:
  /// **'En {terreno}: {assigned} de {total} ha asignadas'**
  String cropAreaShareHelp(String terreno, String assigned, String total);

  /// Título del aviso previo a borrar un terreno
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar el terreno?'**
  String get deleteTerrenoTitle;

  /// El aviso tiene que dejar claro que borrar el terreno no borra ningún cultivo
  ///
  /// In es, this message translates to:
  /// **'Se eliminará «{name}». Tus cultivos no se borran: solo quedan sin terreno.'**
  String deleteTerrenoBody(String name);

  /// No description provided for @cropTerrenoLabel.
  ///
  /// In es, this message translates to:
  /// **'¿En qué terreno está?'**
  String get cropTerrenoLabel;

  /// No description provided for @cropTerrenoNone.
  ///
  /// In es, this message translates to:
  /// **'Sin terreno'**
  String get cropTerrenoNone;

  /// Ayuda corta bajo el desplegable de terreno del editor de cultivo
  ///
  /// In es, this message translates to:
  /// **'El terreno donde está plantado. Puedes dejarlo vacío.'**
  String get helpCropTerreno;

  /// No description provided for @terrenoGroupLabel.
  ///
  /// In es, this message translates to:
  /// **'Lotes'**
  String get terrenoGroupLabel;

  /// No description provided for @terrenoGroupHint.
  ///
  /// In es, this message translates to:
  /// **'El gasto sirve a varios cultivos del mismo lote, como una limpieza compartida. Se reparte entre ellos por hectáreas; si a alguno le falta la superficie, sale aparte.'**
  String get terrenoGroupHint;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
