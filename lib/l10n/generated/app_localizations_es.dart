import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Mi Cafetal';

  @override
  String get appTitleFull => 'Mi Cafetal App';

  @override
  String get tabOverview => 'Resumen';

  @override
  String get tabRegister => 'Registrar';

  @override
  String get tabHistory => 'Historial';

  @override
  String get syncTooltip => 'Sincronizar';

  @override
  String get menuReport => 'Reporte';

  @override
  String get menuSettings => 'Configuración';

  @override
  String get menuLogout => 'Cerrar sesión';

  @override
  String get monthJan => 'Enero';

  @override
  String get monthFeb => 'Febrero';

  @override
  String get monthMar => 'Marzo';

  @override
  String get monthApr => 'Abril';

  @override
  String get monthMay => 'Mayo';

  @override
  String get monthJun => 'Junio';

  @override
  String get monthJul => 'Julio';

  @override
  String get monthAug => 'Agosto';

  @override
  String get monthSep => 'Septiembre';

  @override
  String get monthOct => 'Octubre';

  @override
  String get monthNov => 'Noviembre';

  @override
  String get monthDec => 'Diciembre';

  @override
  String get conjAnd => 'y';

  @override
  String get sectionThisMonth => 'Este mes';

  @override
  String sectionInYear(int year) {
    return 'En el año $year';
  }

  @override
  String get incomeLabel => 'Ingresos';

  @override
  String get expensesLabel => 'Gastos';

  @override
  String get resultLabel => 'Resultado';

  @override
  String get alertsTitle => 'Alertas';

  @override
  String get alertsTooltip => '¿Qué significan estas alertas?';

  @override
  String get glossaryTitle => '¿Qué significan estos términos?';

  @override
  String get glossaryGotIt => 'Entendido';

  @override
  String get glossaryRoiTerm => 'ROI (Retorno de la Inversión)';

  @override
  String get glossaryRoiDef => 'Mide cuánto recuperas por cada peso invertido en un cultivo. Se calcula como (Ingresos − Gastos) ÷ Gastos. Un ROI negativo significa que el cultivo gasta más de lo que recupera: por ejemplo, ROI −70% quiere decir que por cada \$100 invertidos solo vuelven \$30.';

  @override
  String get glossaryBalanceTerm => 'Balance / Resultado';

  @override
  String get glossaryBalanceDef => 'Es la resta de Ingresos menos Gastos en un período. Si el resultado es positivo tienes ganancia; si es negativo, pérdida.';

  @override
  String get glossaryMarginTerm => 'Margen sobre ventas';

  @override
  String get glossaryMarginDef => 'De cada \$100 que vendes, cuánto queda como ganancia después de cubrir los gastos. Un margen del 20% significa que por cada \$100 vendidos quedan \$20.';

  @override
  String get glossaryRatioTerm => 'Gastos vs ingresos';

  @override
  String get glossaryRatioDef => 'Qué porcentaje de tus ingresos se va en gastos. Por ejemplo, 80% quiere decir que por cada \$100 que entran, \$80 se gastan y quedan \$20.';

  @override
  String get glossaryAvgTerm => 'Promedio histórico mensual';

  @override
  String get glossaryAvgDef => 'El promedio de lo que gastas al mes en una categoría (por ejemplo, mano de obra). Sirve como referencia para detectar aumentos inusuales en tus gastos.';

  @override
  String get glossaryRoiTooltip => '¿Qué significa ROI?';

  @override
  String get authSubtitleSignup => 'Crea tu cuenta para llevar tus finanzas';

  @override
  String get authSubtitleWelcome => 'Bienvenido de vuelta';

  @override
  String get authEmailLabel => 'Correo';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authInvalidEmail => 'Ingresa un correo válido';

  @override
  String get authPasswordTooShort => 'Mínimo 6 caracteres';

  @override
  String get authCreateAccount => 'Crear cuenta';

  @override
  String get authSignIn => 'Entrar';

  @override
  String get authHaveAccount => '¿Ya tienes cuenta? Entra';

  @override
  String get authNoAccount => '¿No tienes cuenta? Regístrate';

  @override
  String get authGuest => 'Explorar la app sin cuenta';

  @override
  String get authGuestHint => 'Modo visita: los datos de ejemplo quedan solo en este dispositivo y no se sincronizan.';

  @override
  String get authCreatedMsg => 'Cuenta creada. Revisa tu correo (incluye spam) para confirmar y luego inicia sesión.';

  @override
  String get authCreateError => 'Error al crear la cuenta';

  @override
  String get authSignInError => 'Error al iniciar sesión';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authResetSent => 'Te enviamos un enlace para restablecer tu contraseña. Revisa tu correo (incluye spam).';

  @override
  String get registerEditTitle => 'Editar movimiento';

  @override
  String get expenseTypeLabel => 'Gasto';

  @override
  String get incomeTypeLabel => 'Ingreso';

  @override
  String get cropFieldLabel => 'Cultivo (opcional)';

  @override
  String get cropUnspecified => 'Sin especificar';

  @override
  String get cropNewOption => '+ Nueva variedad…';

  @override
  String get cropGroupHint => 'Los movimientos del mismo cultivo se suman juntos en el reporte.';

  @override
  String get categoryFieldLabel => 'Categoría';

  @override
  String get amountFieldLabel => 'Monto';

  @override
  String get amountInvalid => 'Ingresa un monto válido';

  @override
  String get dateFieldLabel => 'Fecha';

  @override
  String get datePickerHelp => 'Fecha del registro';

  @override
  String get descriptionFieldLabel => 'Descripción (opcional)';

  @override
  String get saveRecord => 'Guardar registro';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get expenseFootnote => 'Vas a registrar un GASTO. El monto se usará en tu resumen del mes.';

  @override
  String get incomeFootnote => 'Vas a registrar un INGRESO. El monto se usará en tu resumen del mes.';

  @override
  String get recordSaved => 'Registro guardado';

  @override
  String get recordUpdated => 'Movimiento actualizado';

  @override
  String get recordDeleted => 'Movimiento eliminado';

  @override
  String get deleteDialogTitle => 'Eliminar movimiento';

  @override
  String get deleteDialogBody => 'Esta acción borra el registro. ¿Confirmas?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get add => 'Agregar';

  @override
  String get newCropDialogTitle => 'Nueva variedad';

  @override
  String get cropNameLabel => 'Nombre del cultivo';

  @override
  String get cropNameRequired => 'Escribe el nombre del cultivo.';

  @override
  String get segMonth => 'Mes';

  @override
  String get segYear => 'Año';

  @override
  String get segAll => 'Todo';

  @override
  String get segYearToDate => 'A la fecha';

  @override
  String yearLabel(int year) {
    return 'Año $year';
  }

  @override
  String get allMovementsLabel => 'Todos los movimientos';

  @override
  String get noMovements => 'Sin movimientos en este período.';

  @override
  String confirmDeleteExpense(String amount) {
    return 'Gasto de $amount — ¿confirmas?';
  }

  @override
  String confirmDeleteIncome(String amount) {
    return 'Ingreso de $amount — ¿confirmas?';
  }

  @override
  String reportPeriodMonth(String monthName, int year) {
    return '$monthName de $year';
  }

  @override
  String reportChipMonth(String monthName, int year) {
    return '$monthName $year';
  }

  @override
  String reportPeriodYtd(int year) {
    return '$year a la fecha';
  }

  @override
  String reportChipYtd(int year) {
    return '$year · a la fecha';
  }

  @override
  String get incomeStatementTitle => 'Estado de resultados';

  @override
  String get noIncomePeriod => 'Sin ingresos en este período';

  @override
  String get operatingExpensesLabel => 'Gastos operacionales';

  @override
  String get noExpensesPeriod => 'Sin gastos en este período.';

  @override
  String get resultPeriodLabel => 'RESULTADO DEL PERÍODO';

  @override
  String get marginLabel => 'Margen sobre ventas';

  @override
  String get ratioLabel => 'Gastos vs ingresos';

  @override
  String cropBreakdownTitle(String period) {
    return 'Desglose por cultivo — $period';
  }

  @override
  String get cropBreakdownSummaryG => 'Gastos';

  @override
  String get cropBreakdownSummaryI => 'Ingresos';

  @override
  String get cropBreakdownSummaryR => 'Resultado';

  @override
  String get cropBreakdownRoiHint => 'Cómo leer el ROI: por cada \$1 invertido recuperas la ganancia más el capital. Ej.: ROI 516% → por cada \$1 vuelven \$6,16 (5,16 de ganancia + 1 del capital).';

  @override
  String get noCropData => 'Sin datos de cultivos en el período.';

  @override
  String get exportPdf => 'Exportar PDF y compartir';

  @override
  String get generating => 'Generando…';

  @override
  String get exportExcel => 'Exportar a Excel y compartir';

  @override
  String get exportBalance => 'Plantilla de balance (Excel)';

  @override
  String movementsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimientos',
      one: '$count movimiento',
    );
    return '$_temp0';
  }

  @override
  String get reportGeneratedSnack => 'Reporte generado.';

  @override
  String exportError(String error) {
    return 'No se pudo exportar: $error';
  }

  @override
  String pdfShareSubject(int year) {
    return 'Mi Cafetal — Reporte $year';
  }

  @override
  String get farmNameLabel => 'Nombre de la finca';

  @override
  String get currencyLabel => 'Moneda';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get saveButton => 'Guardar';

  @override
  String get converting => 'Convirtiendo…';

  @override
  String get rateErrorMsg => 'No se pudo obtener la tasa de cambio. Verifica tu conexión e inténtalo de nuevo.';

  @override
  String currencyChangedMsg(String currency) {
    return 'Moneda cambiada a $currency. Montos convertidos al cambio actual.';
  }

  @override
  String get settingsSavedMsg => 'Configuración guardada';

  @override
  String get noIncomesPeriod => 'Sin ingresos en este período.';

  @override
  String get recordExpense => 'Registrar gasto';

  @override
  String get recordIncome => 'Registrar ingreso';

  @override
  String get expensesByCategory => 'Gastos por categoría';

  @override
  String get incomesByCategory => 'Ingresos por categoría';

  @override
  String categoryBreakdownTotal(Object total) {
    return 'Total del período: $total';
  }

  @override
  String categoryBreakdownShowMore(Object count) {
    return 'Ver $count más';
  }

  @override
  String get categoryBreakdownShowLess => 'Ver menos';

  @override
  String get assignCropsTitle => 'Asignar cultivo';

  @override
  String get assignCropsSubtitle => 'Elige un cultivo para cada registro. Todos los cambios se guardan juntos.';

  @override
  String get assignCropsUnassigned => 'Sin cultivo';

  @override
  String get assignCropsNewCrop => 'Nuevo cultivo…';

  @override
  String get assignCropsSave => 'Guardar cambios';

  @override
  String assignCropsSaved(Object count) {
    return '$count registros actualizados';
  }

  @override
  String get assignCropsEmpty => 'Ya no hay registros sin cultivo. ¡Todo asignado!';

  @override
  String assignCropsBanner(Object count) {
    return '$count registros sin cultivo asignado';
  }

  @override
  String get assignCropsNow => 'Asignar cultivo ahora';

  @override
  String get insightsTitle => 'Conclusión del período';

  @override
  String get insightNoActivity => 'No hay movimientos registrados en este período.';

  @override
  String insightBalanceNoIncome(Object spent) {
    return 'Registraste $spent en gastos y no hay ventas en este período.';
  }

  @override
  String insightBalancePositive(Object balance, Object margin) {
    return 'Resultado positivo: $balance con $margin de margen sobre las ventas.';
  }

  @override
  String insightBalanceNegative(Object loss, Object margin) {
    return 'Resultado negativo: $loss con margen de $margin sobre las ventas.';
  }

  @override
  String insightVsPrev(Object expChange, Object incChange, Object month) {
    return 'Frente a $month: ventas $incChange y gastos $expChange.';
  }

  @override
  String insightChangeUp(Object pct) {
    return 'subieron $pct';
  }

  @override
  String insightChangeDown(Object pct) {
    return 'bajaron $pct';
  }

  @override
  String get insightChangeFlat => 'sin cambios';

  @override
  String insightTopExpense(Object amount, Object category, Object pct) {
    return 'Tu mayor gasto fue $category ($amount, el $pct del total).';
  }

  @override
  String insightTopExpenseDependency(Object category) {
    return 'Concentras más de la mitad de tus gastos en $category: revisa ese costo recurrente antes de que siga creciendo.';
  }

  @override
  String insightTopIncome(Object amount, Object category, Object pct) {
    return 'Tu mejor ingreso fue $category ($amount, el $pct del total).';
  }

  @override
  String insightLowPrice(Object history, Object recent) {
    return 'Vendes por montos menores que tu histórico: promedio reciente $recent vs $history por venta. Revisa precio, presentación o canal de venta.';
  }

  @override
  String insightBestMonth(Object costAmount, Object costMonth, Object salesAmount, Object salesMonth) {
    return 'Tu mejor mes de ventas fue $salesMonth ($salesAmount); tu menor gasto mensual fue $costMonth ($costAmount).';
  }

  @override
  String chartTitle(int year) {
    return 'Gastos vs ingresos — $year';
  }

  @override
  String alertExcessTitle(String category) {
    return 'Tu gasto en $category casi se duplicó';
  }

  @override
  String alertExcessMessage(String current, String category, String avg) {
    return 'El problema: este mes llevas $current en $category frente a un promedio de $avg por mes.';
  }

  @override
  String get alertExcessSuggestion => 'Revisa qué generó ese aumento. Si fue un gasto grande y puntual, regístralo por partes para que no distorsione tus promedios.';

  @override
  String get alertNoIncomeTitle => 'Hay gastos registrados, pero cero ventas';

  @override
  String alertNoIncomeMessage(String spent) {
    return 'El problema: hay $spent en gastos y \$0 en ventas, así que el balance está en pérdida.';
  }

  @override
  String get alertNoIncomeSuggestion => 'Cuando vendas tu cosecha, regístrala como ingreso para que el balance muestre tu ganancia real.';

  @override
  String alertNoSalesTitle(int days) {
    return 'Hace $days días que no registras ventas';
  }

  @override
  String alertNoSalesMessage(String date) {
    return 'El problema: no vendes desde el $date. Tus ingresos están estancados desde esa fecha.';
  }

  @override
  String get alertNoSalesSuggestion => 'Registra la última cosecha vendida o la venta más reciente para mantener el estado de resultados al día.';

  @override
  String alertLossesTitle(int count) {
    return '$count meses seguidos con pérdidas (gastos > ingresos)';
  }

  @override
  String alertLossesMessage(String months) {
    return 'El problema: $months gastaste más de lo que ganaste.';
  }

  @override
  String get alertLossesSuggestion => 'Revisa tus costos fijos (mano de obra, fertilizante, transporte) y busca reducir gastos o mejorar el precio de venta.';

  @override
  String get alertLowPriceTitle => 'Tus ventas recientes rinden menos que tu promedio';

  @override
  String alertLowPriceMessage(String recentAvg, String histAvg) {
    return 'El problema: en los últimos 30 días cada venta te rinde en promedio $recentAvg, por debajo de tu promedio histórico por venta ($histAvg).';
  }

  @override
  String get alertLowPriceSuggestion => 'Compara precios con otros compradores y evalúa esperar un mejor momento para vender parte de la cosecha.';

  @override
  String alertDeficitNoCropTitle(String roi) {
    return 'Gastos sin cultivo asignado no se recuperan (ROI $roi)';
  }

  @override
  String alertDeficitNoCropMessage(String spent, String sold, String recovery, Object count) {
    return 'El problema: tienes $count registros sin cultivo asignado que suman $spent en gastos y $sold en ventas (solo has recuperado el $recovery de lo invertido).';
  }

  @override
  String alertDeficitNoCropSuggestion(Object count) {
    return 'Edita esos $count registros y asígnales su cultivo (Café, Plátano…) para que su costo cuente en el cultivo correcto, y esta alerta desaparecerá.';
  }

  @override
  String alertDeficitTitle(String crop, String roi) {
    return '$crop está perdiendo dinero (ROI $roi)';
  }

  @override
  String alertDeficitMessage(String spent, String crop, String sold, String recovery) {
    return 'El problema: invertiste $spent en $crop y solo has recuperado $sold (el $recovery de lo invertido).';
  }

  @override
  String alertDeficitSuggestion(String crop) {
    return 'Evalúa bajar los costos de $crop, mejorar el precio de venta o decidir si conviene seguir invirtiendo en ese cultivo.';
  }

  @override
  String pdfIncomeStatement(String period) {
    return 'Estado de Resultados — $period';
  }

  @override
  String pdfGeneratedOn(String date, String currency) {
    return 'Generado el $date · Moneda: $currency';
  }

  @override
  String get pdfIncomesHeader => 'INGRESOS';

  @override
  String get pdfNoIncomeSub => '    Sin ingresos en el período';

  @override
  String get pdfExpensesHeader => 'GASTOS OPERACIONALES';

  @override
  String get pdfNoExpensesSub => '    Sin gastos en el período';

  @override
  String pdfCropBreakdown(String period) {
    return 'Desglose por cultivo — $period';
  }

  @override
  String pdfYearAnnex(int year) {
    return 'Anexo — Acumulado del año $year';
  }

  @override
  String get pdfRoiFootnote => 'ROI = (Ingresos − Gastos) / Gastos. Negativo > 30% sugiere revisar el cultivo.';

  @override
  String get pdfColCrop => 'Cultivo';

  @override
  String get pdfColMov => 'Mov.';

  @override
  String get pdfColExpenses => 'Gastos';

  @override
  String get pdfColIncomes => 'Ingresos';

  @override
  String get pdfColResult => 'Resultado';

  @override
  String get pdfColRoi => 'ROI';

  @override
  String get pdfFileNamePrefix => 'reporte';

  @override
  String get excelSheetSummary => 'Resumen';

  @override
  String get excelSheetCrops => 'Por cultivo';

  @override
  String get excelSheetMovements => 'Movimientos';

  @override
  String get pdfColDate => 'Fecha';

  @override
  String get pdfColType => 'Tipo';

  @override
  String get pdfColCategory => 'Categoría';

  @override
  String get pdfColDescription => 'Descripción';

  @override
  String get pdfColAmount => 'Monto';

  @override
  String balanceTemplateTitle(String period) {
    return 'PLANTILLA DE BALANCE — $period';
  }

  @override
  String balanceTemplateFarm(String farm, String date) {
    return '$farm — Generado el $date';
  }

  @override
  String get balanceAssetsTitle => 'ACTIVOS';

  @override
  String get balanceRowCash => 'Caja / bancos';

  @override
  String get balanceRowReceivables => 'Cuentas por cobrar';

  @override
  String get balanceRowInventory => 'Inventario de café';

  @override
  String get balanceRowMachinery => 'Maquinaria y equipos';

  @override
  String get balanceRowLand => 'Terrenos / plantaciones';

  @override
  String get balanceRowOtherAssets => 'Otros activos';

  @override
  String get balanceTotalAssets => 'TOTAL ACTIVOS';

  @override
  String get balanceLiabilitiesTitle => 'PASIVOS';

  @override
  String get balanceRowLoans => 'Préstamos / deudas';

  @override
  String get balanceRowPayables => 'Cuentas por pagar';

  @override
  String get balanceRowTaxes => 'Impuestos por pagar';

  @override
  String get balanceTotalLiabilities => 'TOTAL PASIVOS';

  @override
  String get balanceEquityTitle => 'PATRIMONIO';

  @override
  String get balanceRowCapital => 'Capital inicial';

  @override
  String get balanceRowAccumulated => 'Utilidades acumuladas';

  @override
  String balanceRowNetIncome(int year) {
    return 'Utilidad del ejercicio ($year)';
  }

  @override
  String get balanceTotalEquity => 'TOTAL PATRIMONIO';

  @override
  String get balanceCheckLabel => 'VERIFICACIÓN — Activo = Pasivo + Patrimonio (0 = balanceado)';

  @override
  String get balanceCheckFormula => '=B11-B17-B23';

  @override
  String get balanceNote => 'Completa los montos de cada rubro en Excel. La celda de verificación usa fórmulas: debe dar 0 cuando el balance cuadra.';

  @override
  String get catSiembra => 'Siembra';

  @override
  String get catSemillasInsumos => 'Semillas e insumos';

  @override
  String get catFertilizante => 'Fertilizante';

  @override
  String get catManoObra => 'Mano de obra';

  @override
  String get catCosecha => 'Cosecha y recolección';

  @override
  String get catPlagas => 'Control plagas';

  @override
  String get catRiego => 'Riego';

  @override
  String get catEmpaque => 'Empacado y comercialización';

  @override
  String get catTransporte => 'Transporte';

  @override
  String get catEquipo => 'Equipo';

  @override
  String get catMantenimiento => 'Mantenimiento';

  @override
  String get catArriendo => 'Arriendo de tierras';

  @override
  String get catImpuestos => 'Impuestos y tasas';

  @override
  String get catOtro => 'Otro';

  @override
  String get catVentaCafe => 'Venta café';

  @override
  String get catVentaPlatano => 'Venta plátano';

  @override
  String get catSubvenciones => 'Subvenciones y apoyos';

  @override
  String get catVentaOtro => 'Venta otros';
}
