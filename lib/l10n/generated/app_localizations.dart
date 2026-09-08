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
  /// **'Mi Cafetal'**
  String get appTitle;

  /// No description provided for @appTitleFull.
  ///
  /// In es, this message translates to:
  /// **'Mi Cafetal App'**
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
  /// **'Un plantío en establecimiento necesita su siembra inicial registrada.'**
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

  /// No description provided for @nextStepHarvestTitle.
  ///
  /// In es, this message translates to:
  /// **'Registra tu primera cosecha'**
  String get nextStepHarvestTitle;

  /// No description provided for @nextStepHarvestSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Anota cuánto recogiste y su destino.'**
  String get nextStepHarvestSubtitle;

  /// No description provided for @nextStepSaleTitle.
  ///
  /// In es, this message translates to:
  /// **'Registra la venta de tu cosecha'**
  String get nextStepSaleTitle;

  /// No description provided for @nextStepSaleSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Vincula la venta a la cosecha para ver tu ganancia real.'**
  String get nextStepSaleSubtitle;

  /// No description provided for @nextStepGuideLink.
  ///
  /// In es, this message translates to:
  /// **'Ver guía completa'**
  String get nextStepGuideLink;

  /// No description provided for @helpTitle.
  ///
  /// In es, this message translates to:
  /// **'Ayuda'**
  String get helpTitle;

  /// No description provided for @helpSectionGuide.
  ///
  /// In es, this message translates to:
  /// **'Guía para empezar'**
  String get helpSectionGuide;

  /// No description provided for @helpIntro.
  ///
  /// In es, this message translates to:
  /// **'Mi Cafetal te dice si tu finca está ganando o perdiendo dinero. Tú le dices cuánto gastas y cuánto vendes. La app hace las cuentas y te avisa si algo va mal.'**
  String get helpIntro;

  /// No description provided for @helpIntroPromesa.
  ///
  /// In es, this message translates to:
  /// **'La app no inventa números: todo sale de lo que tú registras. Si le das pocos datos, te da poca información. Si le das más, te da más.'**
  String get helpIntroPromesa;

  /// No description provided for @helpWhereTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Dónde entro cada dato?'**
  String get helpWhereTitle;

  /// No description provided for @helpRowOverview.
  ///
  /// In es, this message translates to:
  /// **'Ver el panorama: cuánto ganaste, cuánto gastaste, si estás en positivo o negativo'**
  String get helpRowOverview;

  /// No description provided for @helpRowCrops.
  ///
  /// In es, this message translates to:
  /// **'Decirle a la app qué cosechas manejas (café, plátano, etc.)'**
  String get helpRowCrops;

  /// No description provided for @helpRowSowings.
  ///
  /// In es, this message translates to:
  /// **'Registrar cuántas plantas sembraste o reemplazaste'**
  String get helpRowSowings;

  /// No description provided for @helpRowHarvests.
  ///
  /// In es, this message translates to:
  /// **'Registrar cuánto recogiste y qué hiciste con ello'**
  String get helpRowHarvests;

  /// No description provided for @helpRowExpenses.
  ///
  /// In es, this message translates to:
  /// **'Anotar gastos: fertilizante, pago de trabajadores, semillas, etc.'**
  String get helpRowExpenses;

  /// No description provided for @helpRowIncome.
  ///
  /// In es, this message translates to:
  /// **'Registrar cuánto te pagaron por lo que vendiste'**
  String get helpRowIncome;

  /// No description provided for @helpCaseTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Por dónde empiezo? Depende de tu situación'**
  String get helpCaseTitle;

  /// No description provided for @helpCaseATitle.
  ///
  /// In es, this message translates to:
  /// **'Ya tengo la finca funcionando, solo quiero controlar las cuentas'**
  String get helpCaseATitle;

  /// No description provided for @helpCaseA1.
  ///
  /// In es, this message translates to:
  /// **'Entra a Cultivos (menú ⋮). Edita Café y Plátano y ponles fase Producción (ya están dando frutos). Si sabes hectáreas y plantas, ponlo.'**
  String get helpCaseA1;

  /// No description provided for @helpCaseA2.
  ///
  /// In es, this message translates to:
  /// **'En Registrar, anota tus gastos del mes: fertilizante, pago de trabajadores, etc.'**
  String get helpCaseA2;

  /// No description provided for @helpCaseA3.
  ///
  /// In es, this message translates to:
  /// **'Cuando coseches, entra a Cosechas y registra cuánto recogiste y si lo vendiste, lo guardaste o se perdió.'**
  String get helpCaseA3;

  /// No description provided for @helpCaseA4.
  ///
  /// In es, this message translates to:
  /// **'Cuando vendas, vuelve a Registrar y pon un Ingreso con el dinero que te pagaron.'**
  String get helpCaseA4;

  /// No description provided for @helpCaseAEnd.
  ///
  /// In es, this message translates to:
  /// **'Mira el Resumen: ahí ves si estás ganando o perdiendo. Las alertas te avisan si algo necesita atención.'**
  String get helpCaseAEnd;

  /// No description provided for @helpCaseBTitle.
  ///
  /// In es, this message translates to:
  /// **'Estoy empezando un cultivo nuevo desde cero'**
  String get helpCaseBTitle;

  /// No description provided for @helpCaseB1.
  ///
  /// In es, this message translates to:
  /// **'En Cultivos, crea tu cultivo (o edita el que está) y ponle fase Establecimiento. Elige si es Anual o Perenne.'**
  String get helpCaseB1;

  /// No description provided for @helpCaseB2.
  ///
  /// In es, this message translates to:
  /// **'En Siembras, registra cuántas plantas pusiste, en qué área, y si quieres el costo.'**
  String get helpCaseB2;

  /// No description provided for @helpCaseB3.
  ///
  /// In es, this message translates to:
  /// **'Mientras esté en Establecimiento, la app no dice que estás perdiendo dinero: es una inversión, como construir un local antes de abrir.'**
  String get helpCaseB3;

  /// No description provided for @helpCaseB4.
  ///
  /// In es, this message translates to:
  /// **'Cuando empiece a dar fruto y pases a Producción, sigue el flujo del caso anterior: cosechas y ventas.'**
  String get helpCaseB4;

  /// No description provided for @helpUnitsTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué unidad uso?'**
  String get helpUnitsTitle;

  /// No description provided for @helpUnitsBody.
  ///
  /// In es, this message translates to:
  /// **'Puedes usar kilogramos (kg), arrobas (1 arroba = 12.5 kg, común para café en Colombia) o sacos (1 saco = 70 kg). La app convierte todo a kg para comparar. Usa la unidad con la que trabajes normalmente.'**
  String get helpUnitsBody;

  /// No description provided for @helpGlossaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Glosario'**
  String get helpGlossaryTitle;

  /// No description provided for @helpGlossaryBody.
  ///
  /// In es, this message translates to:
  /// **'Plantines: plantas jóvenes que aún no producen. Área: cuánto terreno ocupa el cultivo (en hectáreas). Plantas vivas: las que siguen activas (sembradas − muertas + resiembras). Destino: vendido, almacenado o pérdida. Sincronizar: guardar en la nube para tenerlo en cualquier dispositivo. Alerta: aviso automático cuando algo necesita tu atención.'**
  String get helpGlossaryBody;

  /// No description provided for @helpGlossaryFinance.
  ///
  /// In es, this message translates to:
  /// **'Ver glosario financiero'**
  String get helpGlossaryFinance;

  /// No description provided for @helpPerHaTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué es el panel \"Por hectárea\"?'**
  String get helpPerHaTitle;

  /// No description provided for @helpPerHaIntro.
  ///
  /// In es, this message translates to:
  /// **'Si registras cuántas hectáreas tiene tu cultivo, la app puede calcular cuánto produce cada hectárea. Esto es útil para comparar parcelas de diferente tamaño con la misma regla.'**
  String get helpPerHaIntro;

  /// No description provided for @helpPerHaTitleYield.
  ///
  /// In es, this message translates to:
  /// **'Rendimiento (kg/ha)'**
  String get helpPerHaTitleYield;

  /// No description provided for @helpPerHaYield.
  ///
  /// In es, this message translates to:
  /// **'Cuántos kilos produce cada hectárea. Es el mismo dato que piden tus compradores.'**
  String get helpPerHaYield;

  /// No description provided for @helpPerHaTitleVentas.
  ///
  /// In es, this message translates to:
  /// **'Ventas por ha'**
  String get helpPerHaTitleVentas;

  /// No description provided for @helpPerHaRevenue.
  ///
  /// In es, this message translates to:
  /// **'Cuánto dinero genera cada hectárea. Divide tus ingresos entre las hectáreas.'**
  String get helpPerHaRevenue;

  /// No description provided for @helpPerHaTitleGastos.
  ///
  /// In es, this message translates to:
  /// **'Gastos por ha'**
  String get helpPerHaTitleGastos;

  /// No description provided for @helpPerHaCost.
  ///
  /// In es, this message translates to:
  /// **'Cuánto cuesta producir en cada hectárea. Divide tus gastos entre las hectáreas.'**
  String get helpPerHaCost;

  /// No description provided for @helpPerHaTitleMargen.
  ///
  /// In es, this message translates to:
  /// **'Margen por ha'**
  String get helpPerHaTitleMargen;

  /// No description provided for @helpPerHaMargin.
  ///
  /// In es, this message translates to:
  /// **'Si cada hectárea deja ganancia. Positivo = la hectárea produce más de lo que cuesta.'**
  String get helpPerHaMargin;

  /// No description provided for @helpPerHaWhy.
  ///
  /// In es, this message translates to:
  /// **'¿Para qué sirve? Imagina dos parcelas: una de 3 ha que vende \$9M y otra de 1 ha que vende \$5M. Por hectárea, la segunda gana más (\$5M vs \$3M). Este panel te muestra esa comparación justa.'**
  String get helpPerHaWhy;

  /// No description provided for @helpPaybackTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo sé cuándo recupero lo invertido?'**
  String get helpPaybackTitle;

  /// No description provided for @helpPaybackIntro.
  ///
  /// In es, this message translates to:
  /// **'Cuando editas un cultivo puedes poner el Costo del establecimiento: todo lo que invertiste para empezar (plantines, mano de obra, abono inicial). La app calcula cuánto ya recuperaste.'**
  String get helpPaybackIntro;

  /// No description provided for @helpPaybackTitlePercent.
  ///
  /// In es, this message translates to:
  /// **'% recuperado'**
  String get helpPaybackTitlePercent;

  /// No description provided for @helpPaybackPercent.
  ///
  /// In es, this message translates to:
  /// **'Divide lo que ya ganaste con ventas menos gastos, entre lo que invertiste. 100% = ya lo pagaste completamente.'**
  String get helpPaybackPercent;

  /// No description provided for @helpPaybackTitleYears.
  ///
  /// In es, this message translates to:
  /// **'Se pagaría en N años (aprox.)'**
  String get helpPaybackTitleYears;

  /// No description provided for @helpPaybackYears.
  ///
  /// In es, this message translates to:
  /// **'Un estimado basado en tu margen promedio real. No es una promesa — es un cálculo con tus datos.'**
  String get helpPaybackYears;

  /// No description provided for @helpPaybackTitleNotLoss.
  ///
  /// In es, this message translates to:
  /// **'No es una pérdida, es una inversión'**
  String get helpPaybackTitleNotLoss;

  /// No description provided for @helpPaybackNotLoss.
  ///
  /// In es, this message translates to:
  /// **'Si inviertes \$1,000,000 en plantar café y aún no vendes, no perdiste \$1,000,000. Invertiste \$1,000,000. Cuando empieces a vender, el porcentaje de recuperación empieza a subir.'**
  String get helpPaybackNotLoss;

  /// No description provided for @helpFlowTitle.
  ///
  /// In es, this message translates to:
  /// **'El orden de la app'**
  String get helpFlowTitle;

  /// No description provided for @helpFlowIntro.
  ///
  /// In es, this message translates to:
  /// **'Piensa en esto como una cadena: primero le dices qué cultivas, luego cuánto sembraste, luego cuánto gastaste, luego qué recogiste, y por último cuánto vendiste.'**
  String get helpFlowIntro;

  /// No description provided for @helpFlowStep1Title.
  ///
  /// In es, this message translates to:
  /// **'Definir el cultivo'**
  String get helpFlowStep1Title;

  /// No description provided for @helpFlowStep1Body.
  ///
  /// In es, this message translates to:
  /// **'Qué manejas (café, plátano…).'**
  String get helpFlowStep1Body;

  /// No description provided for @helpFlowStep2Title.
  ///
  /// In es, this message translates to:
  /// **'Registrar la siembra'**
  String get helpFlowStep2Title;

  /// No description provided for @helpFlowStep2Body.
  ///
  /// In es, this message translates to:
  /// **'Cuántas plantas pusiste.'**
  String get helpFlowStep2Body;

  /// No description provided for @helpFlowStep3Title.
  ///
  /// In es, this message translates to:
  /// **'Anotar gastos'**
  String get helpFlowStep3Title;

  /// No description provided for @helpFlowStep3Body.
  ///
  /// In es, this message translates to:
  /// **'Qué invertiste.'**
  String get helpFlowStep3Body;

  /// No description provided for @helpFlowStep4Title.
  ///
  /// In es, this message translates to:
  /// **'Registrar cosecha'**
  String get helpFlowStep4Title;

  /// No description provided for @helpFlowStep4Body.
  ///
  /// In es, this message translates to:
  /// **'Qué recogiste.'**
  String get helpFlowStep4Body;

  /// No description provided for @helpFlowStep5Title.
  ///
  /// In es, this message translates to:
  /// **'Registrar venta'**
  String get helpFlowStep5Title;

  /// No description provided for @helpFlowStep5Body.
  ///
  /// In es, this message translates to:
  /// **'A quién vendiste y cuánto.'**
  String get helpFlowStep5Body;

  /// No description provided for @helpFlowHint.
  ///
  /// In es, this message translates to:
  /// **'La tarjeta \"Tu próximo paso\" en el Resumen te dice exactamente cuál es el siguiente registro que necesitas. Cuando ya hiciste todo, la tarjeta desaparece sola.'**
  String get helpFlowHint;

  /// No description provided for @helpCommonTitle.
  ///
  /// In es, this message translates to:
  /// **'Errores comunes (y cómo corregirlos)'**
  String get helpCommonTitle;

  /// No description provided for @helpCommonMistake.
  ///
  /// In es, this message translates to:
  /// **'Miseria en el monto'**
  String get helpCommonMistake;

  /// No description provided for @helpCommonFix.
  ///
  /// In es, this message translates to:
  /// **'Puse un monto incorrecto'**
  String get helpCommonFix;

  /// No description provided for @helpCommonFix2.
  ///
  /// In es, this message translates to:
  /// **'Ve a Historial, busca el registro, edítalo o elimínalo'**
  String get helpCommonFix2;

  /// No description provided for @helpCommonAssigned.
  ///
  /// In es, this message translates to:
  /// **'No le asigné cultivo a un gasto'**
  String get helpCommonAssigned;

  /// No description provided for @helpCommonAssignedFix.
  ///
  /// In es, this message translates to:
  /// **'En Historial aparece \"X registros sin cultivo\". Pulsa \"Asignar cultivo ahora\" y elige a qué cultivo pertenece'**
  String get helpCommonAssignedFix;

  /// No description provided for @helpCommonType.
  ///
  /// In es, this message translates to:
  /// **'Confundí gasto con ingreso'**
  String get helpCommonType;

  /// No description provided for @helpCommonTypeFix.
  ///
  /// In es, this message translates to:
  /// **'Abre el registro y cambia el tipo de Gasto a Ingreso (o al revés)'**
  String get helpCommonTypeFix;

  /// No description provided for @helpCommonArea.
  ///
  /// In es, this message translates to:
  /// **'No veo el panel \"Por hectárea\"'**
  String get helpCommonArea;

  /// No description provided for @helpCommonAreaFix.
  ///
  /// In es, this message translates to:
  /// **'Registra el área del cultivo: en Cultivos edita el cultivo y pon las hectáreas'**
  String get helpCommonAreaFix;

  /// No description provided for @syncTooltip.
  ///
  /// In es, this message translates to:
  /// **'Sincronizar'**
  String get syncTooltip;

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
  /// **'Fase de vida'**
  String get phaseLabel;

  /// No description provided for @phaseEstablecimiento.
  ///
  /// In es, this message translates to:
  /// **'Establecimiento'**
  String get phaseEstablecimiento;

  /// No description provided for @phaseProduccion.
  ///
  /// In es, this message translates to:
  /// **'Producción'**
  String get phaseProduccion;

  /// No description provided for @phaseRenovacion.
  ///
  /// In es, this message translates to:
  /// **'Renovación'**
  String get phaseRenovacion;

  /// No description provided for @phaseHelp.
  ///
  /// In es, this message translates to:
  /// **'Establecimiento = plantío joven que aún no produce (plantines). La app no te marcará pérdidas en esta etapa.'**
  String get phaseHelp;

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
  /// **'Costo del establecimiento (\$)'**
  String get establishmentCostLabel;

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

  /// No description provided for @sowingPlantsLabel.
  ///
  /// In es, this message translates to:
  /// **'Número de plantas'**
  String get sowingPlantsLabel;

  /// No description provided for @sowingLostPlantsLabel.
  ///
  /// In es, this message translates to:
  /// **'Plantas perdidas (bajas)'**
  String get sowingLostPlantsLabel;

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

  /// No description provided for @sowingCostLabel.
  ///
  /// In es, this message translates to:
  /// **'Costo (opcional)'**
  String get sowingCostLabel;

  /// No description provided for @sowingCostHint.
  ///
  /// In es, this message translates to:
  /// **'Si registras un costo, se crea un gasto vinculado a esta siembra.'**
  String get sowingCostHint;

  /// No description provided for @plantsInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un número de plantas válido'**
  String get plantsInvalid;

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
  /// **'Rendimiento por área (kg/ha)'**
  String get reportYieldPerArea;

  /// No description provided for @reportYieldPerPlant.
  ///
  /// In es, this message translates to:
  /// **'Rendimiento por planta (kg/planta)'**
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
  /// **'Rendimiento'**
  String get perHaYieldLabel;

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

  /// No description provided for @glossaryRoiTerm.
  ///
  /// In es, this message translates to:
  /// **'ROI (Retorno de la Inversión)'**
  String get glossaryRoiTerm;

  /// No description provided for @glossaryRoiDef.
  ///
  /// In es, this message translates to:
  /// **'Mide cuánto recuperas por cada peso invertido en un cultivo. Se calcula como (Ingresos − Gastos) ÷ Gastos. Un ROI negativo significa que el cultivo gasta más de lo que recupera: por ejemplo, ROI −70% quiere decir que por cada \$100 invertidos solo vuelven \$30.'**
  String get glossaryRoiDef;

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
  /// **'Margen sobre ventas'**
  String get glossaryMarginTerm;

  /// No description provided for @glossaryMarginDef.
  ///
  /// In es, this message translates to:
  /// **'De cada \$100 que vendes, cuánto queda como ganancia después de cubrir los gastos. Un margen del 20% significa que por cada \$100 vendidos quedan \$20.'**
  String get glossaryMarginDef;

  /// No description provided for @glossaryRatioTerm.
  ///
  /// In es, this message translates to:
  /// **'Gastos vs ingresos'**
  String get glossaryRatioTerm;

  /// No description provided for @glossaryRatioDef.
  ///
  /// In es, this message translates to:
  /// **'Qué porcentaje de tus ingresos se va en gastos. Por ejemplo, 80% quiere decir que por cada \$100 que entran, \$80 se gastan y quedan \$20.'**
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

  /// No description provided for @glossaryRoiTooltip.
  ///
  /// In es, this message translates to:
  /// **'¿Qué significa ROI?'**
  String get glossaryRoiTooltip;

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
  /// **'Cultivo (opcional)'**
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
  /// **'Los movimientos del mismo cultivo se suman juntos en el reporte.'**
  String get cropGroupHint;

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
  /// **'Sacos (70 kg)'**
  String get unitSaco;

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

  /// No description provided for @cropBreakdownRoiHint.
  ///
  /// In es, this message translates to:
  /// **'Cómo leer el ROI: por cada \$1 invertido recuperas la ganancia más el capital. Ej.: ROI 516% → por cada \$1 vuelven \$6,16 (5,16 de ganancia + 1 del capital).'**
  String get cropBreakdownRoiHint;

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

  /// No description provided for @pdfShareSubject.
  ///
  /// In es, this message translates to:
  /// **'Mi Cafetal — Reporte {year}'**
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

  /// No description provided for @currencyChangedMsg.
  ///
  /// In es, this message translates to:
  /// **'Moneda cambiada a {currency}. Montos convertidos al cambio actual.'**
  String currencyChangedMsg(String currency);

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
  /// **'Registraste {spent} en gastos y no hay ventas en este período.'**
  String insightBalanceNoIncome(Object spent);

  /// No description provided for @insightBalancePositive.
  ///
  /// In es, this message translates to:
  /// **'Resultado positivo: {balance} con {margin} de margen sobre las ventas.'**
  String insightBalancePositive(Object balance, Object margin);

  /// No description provided for @insightBalanceNegative.
  ///
  /// In es, this message translates to:
  /// **'Resultado negativo: {loss} con margen de {margin} sobre las ventas.'**
  String insightBalanceNegative(Object loss, Object margin);

  /// No description provided for @insightVsPrev.
  ///
  /// In es, this message translates to:
  /// **'Frente a {month}: ventas {incChange} y gastos {expChange}.'**
  String insightVsPrev(Object expChange, Object incChange, Object month);

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
  String insightTopExpense(Object amount, Object category, Object pct);

  /// No description provided for @insightTopExpenseDependency.
  ///
  /// In es, this message translates to:
  /// **'Concentras más de la mitad de tus gastos en {category}: revisa ese costo recurrente antes de que siga creciendo.'**
  String insightTopExpenseDependency(Object category);

  /// No description provided for @insightTopIncome.
  ///
  /// In es, this message translates to:
  /// **'Tu mejor ingreso fue {category} ({amount}, el {pct} del total).'**
  String insightTopIncome(Object amount, Object category, Object pct);

  /// No description provided for @insightLowPrice.
  ///
  /// In es, this message translates to:
  /// **'Vendes por montos menores que tu histórico: promedio reciente {recent} vs {history} por venta. Revisa precio, presentación o canal de venta.'**
  String insightLowPrice(Object history, Object recent);

  /// No description provided for @insightBestMonth.
  ///
  /// In es, this message translates to:
  /// **'Tu mejor mes de ventas fue {salesMonth} ({salesAmount}); tu menor gasto mensual fue {costMonth} ({costAmount}).'**
  String insightBestMonth(Object costAmount, Object costMonth, Object salesAmount, Object salesMonth);

  /// No description provided for @chartTitle.
  ///
  /// In es, this message translates to:
  /// **'Gastos vs ingresos — {year}'**
  String chartTitle(int year);

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
  /// **'El problema: hay {spent} en gastos y \$0 en ventas, así que el balance está en pérdida.'**
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
  /// **'El problema: en los últimos 30 días cada venta te rinde en promedio {recentAvg}, por debajo de tu promedio histórico por venta ({histAvg}).'**
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
  String alertLowPriceManualMessage(String price, String threshold, String date);

  /// No description provided for @alertDeficitNoCropTitle.
  ///
  /// In es, this message translates to:
  /// **'Gastos sin cultivo asignado no se recuperan (ROI {roi})'**
  String alertDeficitNoCropTitle(String roi);

  /// No description provided for @alertDeficitNoCropMessage.
  ///
  /// In es, this message translates to:
  /// **'El problema: tienes {count} registros sin cultivo asignado que suman {spent} en gastos y {sold} en ventas (solo has recuperado el {recovery} de lo invertido).'**
  String alertDeficitNoCropMessage(String spent, String sold, String recovery, Object count);

  /// No description provided for @alertDeficitNoCropSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Edita esos {count} registros y asígnales su cultivo (Café, Plátano…) para que su costo cuente en el cultivo correcto, y esta alerta desaparecerá.'**
  String alertDeficitNoCropSuggestion(Object count);

  /// No description provided for @alertDeficitTitle.
  ///
  /// In es, this message translates to:
  /// **'{crop} está perdiendo dinero (ROI {roi})'**
  String alertDeficitTitle(String crop, String roi);

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

  /// No description provided for @pdfRoiFootnote.
  ///
  /// In es, this message translates to:
  /// **'ROI = (Ingresos − Gastos) / Gastos. Negativo > 30% sugiere revisar el cultivo.'**
  String get pdfRoiFootnote;

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

  /// No description provided for @pdfColRoi.
  ///
  /// In es, this message translates to:
  /// **'ROI'**
  String get pdfColRoi;

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

  /// No description provided for @catSiembra.
  ///
  /// In es, this message translates to:
  /// **'Siembra'**
  String get catSiembra;

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

  /// No description provided for @alertCropEstablishmentTitle.
  ///
  /// In es, this message translates to:
  /// **'{crop} está en establecimiento: es inversión, no pérdida'**
  String alertCropEstablishmentTitle(String crop);

  /// No description provided for @alertCropEstablishmentMessage.
  ///
  /// In es, this message translates to:
  /// **'El problema: llevas {investment} invertidos en {crop} y aún no hay ingresos. Es normal en esta etapa: el plantío está creciendo y la primera cosecha llega al pasar a producción.'**
  String alertCropEstablishmentMessage(String investment, String crop);

  /// No description provided for @alertCropEstablishmentSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Sigue registrando los gastos de {crop}. Cuando el cultivo entre en producción, la app evaluará su rentabilidad normal.'**
  String alertCropEstablishmentSuggestion(String crop);

  /// No description provided for @alertHarvestVsSalesTitle.
  ///
  /// In es, this message translates to:
  /// **'Vendiste más de lo que cosechaste en {crop}'**
  String alertHarvestVsSalesTitle(String crop);

  /// No description provided for @alertHarvestVsSalesMessage.
  ///
  /// In es, this message translates to:
  /// **'El problema: en los últimos 12 meses vendiste {soldKg} de {crop}, pero solo registraste {harvestedKg} de cosecha. Revisa si hay inventario almacenado o un error de registro.'**
  String alertHarvestVsSalesMessage(String soldKg, String harvestedKg, String crop);

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
