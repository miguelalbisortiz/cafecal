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

  /// No description provided for @authGuest.
  ///
  /// In es, this message translates to:
  /// **'Explorar la app sin cuenta'**
  String get authGuest;

  /// No description provided for @authGuestHint.
  ///
  /// In es, this message translates to:
  /// **'Modo visita: los datos de ejemplo quedan solo en este dispositivo y no se sincronizan.'**
  String get authGuestHint;

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
