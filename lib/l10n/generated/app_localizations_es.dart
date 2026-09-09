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
  String get nextStepTitle => 'Tu próximo paso';

  @override
  String get nextStepAction => 'Ir';

  @override
  String get nextStepCropTitle => 'Crea tu primer cultivo';

  @override
  String get nextStepCropSubtitle => 'Empieza registrando el cultivo que manejarás (Café, Plátano…).';

  @override
  String get nextStepCropSetupTitle => 'Configura tu primer cultivo';

  @override
  String get nextStepCropSetupSubtitle => 'Revisa Café, Plátano u Otro, o crea el tuyo, y ajusta fase y área.';

  @override
  String nextStepSowingTitle(String crop) {
    return 'Registra la siembra de $crop';
  }

  @override
  String get nextStepSowingSubtitle => 'Un plantío en establecimiento necesita su siembra inicial registrada.';

  @override
  String get nextStepExpensesTitle => 'Registra tus primeros gastos';

  @override
  String get nextStepExpensesSubtitle => 'Lleva el control de lo que inviertes cada mes.';

  @override
  String get nextStepHarvestTitle => 'Registra tu primera cosecha';

  @override
  String get nextStepHarvestSubtitle => 'Anota cuánto recogiste y su destino.';

  @override
  String get nextStepSaleTitle => 'Registra la venta de tu cosecha';

  @override
  String get nextStepSaleSubtitle => 'Vincula la venta a la cosecha para ver tu ganancia real.';

  @override
  String get nextStepGuideLink => 'Ver guía completa';

  @override
  String get welcomeTitle => 'Bienvenido';

  @override
  String get welcomeSubtitle => 'Elegí cómo querés empezar a usar la app:';

  @override
  String get welcomeExistingTitle => 'Registrar cultivo';

  @override
  String get welcomeExistingBadge => 'Situación: ya está plantado';

  @override
  String get welcomeExistingSubtitle => 'Las plantas ya están en mi finca; quiero llevar sus cuentas.';

  @override
  String get welcomeExistingAction => 'Registrar cultivo';

  @override
  String get welcomeNewTitle => 'Registrar siembra';

  @override
  String get welcomeNewBadge => 'Situación: vas a plantar ahora';

  @override
  String get welcomeNewSubtitle => 'Todavía no sembré; voy a sembrar hoy o en estos días.';

  @override
  String get welcomeNewAction => 'Registrar siembra';

  @override
  String get welcomeHint => 'No importa cuál elijas primero: ambas te guían bien y la app crea todo lo necesario automáticamente.';

  @override
  String get onboardingCropAddedTitle => 'Cultivo agregado';

  @override
  String get onboardingAnother => 'Agregar otro';

  @override
  String get onboardingAnotherPrompt => 'Cultivo agregado. ¿Registrar otro cultivo que ya tienes sembrado en tu finca?';

  @override
  String get onboardingDone => 'Entrar, terminé';

  @override
  String get sowingNewCropOption => '+ Crear nuevo cultivo…';

  @override
  String get sowingNewCropTitle => 'Nuevo cultivo';

  @override
  String get helpTitle => 'Ayuda';

  @override
  String get helpSectionGuide => 'Guía para empezar';

  @override
  String get helpIntro => 'Mi Cafetal te dice si tu finca está ganando o perdiendo dinero. Tú le dices cuánto gastas y cuánto vendes. La app hace las cuentas y te avisa si algo va mal.';

  @override
  String get helpIntroPromesa => 'La app no inventa números: todo sale de lo que tú registras. Si le das pocos datos, te da poca información. Si le das más, te da más.';

  @override
  String get helpWhereTitle => '¿Dónde entro cada dato?';

  @override
  String get helpRowOverview => 'Ver el panorama: cuánto ganaste, cuánto gastaste, si estás en positivo o negativo';

  @override
  String get helpRowCrops => 'Decirle a la app qué cosechas manejas (café, plátano, etc.)';

  @override
  String get helpRowSowings => 'Registrar cuántas plantas sembraste o reemplazaste';

  @override
  String get helpRowHarvests => 'Registrar cuánto recogiste y qué hiciste con ello';

  @override
  String get helpRowExpenses => 'Anotar gastos: fertilizante, pago de trabajadores, semillas, etc.';

  @override
  String get helpRowIncome => 'Registrar cuánto te pagaron por lo que vendiste';

  @override
  String get helpCaseTitle => '¿Por dónde empiezo? Depende de tu situación';

  @override
  String get helpCaseATitle => 'Ya tengo la finca funcionando, solo quiero controlar las cuentas';

  @override
  String get helpCaseA1 => 'Entra a Cultivos (menú ⋮). Edita Café y Plátano y ponles fase Producción (ya están dando frutos). Si sabes hectáreas y plantas, ponlo.';

  @override
  String get helpCaseA2 => 'En Registrar, anota tus gastos del mes: fertilizante, pago de trabajadores, etc.';

  @override
  String get helpCaseA3 => 'Cuando coseches, entra a Cosechas y registra cuánto recogiste y si lo vendiste, lo guardaste o se perdió.';

  @override
  String get helpCaseA4 => 'Cuando vendas, vuelve a Registrar y pon un Ingreso con el dinero que te pagaron.';

  @override
  String get helpCaseAEnd => 'Mira el Resumen: ahí ves si estás ganando o perdiendo. Las alertas te avisan si algo necesita atención.';

  @override
  String get helpCaseBTitle => 'Estoy empezando un cultivo nuevo desde cero';

  @override
  String get helpCaseB1 => 'En Cultivos, crea tu cultivo (o edita el que está) y ponle fase Establecimiento. Elige si es Anual o Perenne.';

  @override
  String get helpCaseB2 => 'En Siembras, registra cuántas plantas pusiste, en qué área, y si quieres el costo.';

  @override
  String get helpCaseB3 => 'Mientras esté en Establecimiento, la app no dice que estás perdiendo dinero: es una inversión, como construir un local antes de abrir.';

  @override
  String get helpCaseB4 => 'Cuando empiece a dar fruto y pases a Producción, sigue el flujo del caso anterior: cosechas y ventas.';

  @override
  String get helpUnitsTitle => '¿Qué unidad uso?';

  @override
  String get helpUnitsBody => 'Puedes usar kilogramos (kg), arrobas (1 arroba = 12.5 kg, común para café en Colombia) o sacos (1 saco = 70 kg). La app convierte todo a kg para comparar. Usa la unidad con la que trabajes normalmente.';

  @override
  String get helpUnitsTableTitle => 'Equivalencias';

  @override
  String get helpUnitsKgRow => 'Kilogramo (kg)';

  @override
  String get helpUnitsKgRowDesc => 'Unidad base. Todo se convierte a kg.';

  @override
  String get helpUnitsArrobaRow => 'Arroba';

  @override
  String get helpUnitsArrobaRowDesc => '12.5 kg. Común para café en Colombia.';

  @override
  String get helpUnitsSacoRow => 'Saco';

  @override
  String get helpUnitsSacoRowDesc => '70 kg. Para café en sacos.';

  @override
  String get helpUnitsRacimoRow => 'Racimo';

  @override
  String get helpUnitsRacimoRowDesc => 'Para plátano. No se pesa.';

  @override
  String get helpUnitsCajonRow => 'Cajón';

  @override
  String get helpUnitsCajonRowDesc => 'Para frutas y verduras. Su peso varía.';

  @override
  String get helpExampleTitle => '¿Cómo se ve en la práctica? Ejemplos con números';

  @override
  String get helpCaseAExampleTitle => 'Caso A — café en producción (2 ha, 3000 plantas)';

  @override
  String get helpCaseAEx1 => 'Café, Producción, Perenne, 2 ha, 3000 plantas';

  @override
  String get helpCaseAEx2 => 'Gasto de \$500,000 en Fertilizante';

  @override
  String get helpCaseAEx3 => '4 arrobas (50 kg), Vendido';

  @override
  String get helpCaseAEx4 => 'Ingreso de \$750,000 por la venta';

  @override
  String get helpCaseAEx5 => 'Balance +\$250,000 · Margen 33% · ROI 50%';

  @override
  String get helpCaseBExampleTitle => 'Caso B — plátano nuevo (500 plantas en 0.5 ha)';

  @override
  String get helpCaseBEx1 => 'Plátano, Establecimiento, Perenne, 0.5 ha, 500 plantas';

  @override
  String get helpCaseBEx2 => 'Siembra inicial, 500 plantas, 0.5 ha, costo \$200,000';

  @override
  String get helpCaseBEx3 => '\$100,000 de mano de obra y \$150,000 de fertilizante';

  @override
  String get helpCaseBEx4 => 'Inversión \$450,000. No dice pérdida: es inversión hasta que produzca.';

  @override
  String get helpGlossaryTitle => 'Glosario';

  @override
  String get helpGlossaryBody => 'Plantines: plantas jóvenes que aún no producen. Área: cuánto terreno ocupa el cultivo (en hectáreas). Plantas vivas: las que siguen activas (sembradas − muertas + resiembras). Destino: vendido, almacenado o pérdida. Sincronizar: guardar en la nube para tenerlo en cualquier dispositivo. Alerta: aviso automático cuando algo necesita tu atención.';

  @override
  String get helpGlossaryFinance => 'Ver glosario financiero';

  @override
  String get helpPerHaTitle => '¿Qué es el panel \"Por hectárea\"?';

  @override
  String get helpPerHaIntro => 'Si registras cuántas hectáreas tiene tu cultivo, la app puede calcular cuánto produce cada hectárea. Esto es útil para comparar parcelas de diferente tamaño con la misma regla.';

  @override
  String get helpPerHaTitleYield => 'Rendimiento (kg/ha)';

  @override
  String get helpPerHaYield => 'Cuántos kilos produce cada hectárea. Es el mismo dato que piden tus compradores.';

  @override
  String get helpPerHaTitleVentas => 'Ventas por ha';

  @override
  String get helpPerHaRevenue => 'Cuánto dinero genera cada hectárea. Divide tus ingresos entre las hectáreas.';

  @override
  String get helpPerHaTitleGastos => 'Gastos por ha';

  @override
  String get helpPerHaCost => 'Cuánto cuesta producir en cada hectárea. Divide tus gastos entre las hectáreas.';

  @override
  String get helpPerHaTitleMargen => 'Margen por ha';

  @override
  String get helpPerHaMargin => 'Si cada hectárea deja ganancia. Positivo = la hectárea produce más de lo que cuesta.';

  @override
  String get helpPerHaWhy => '¿Para qué sirve? Imagina dos parcelas: una de 3 ha que vende \$9M y otra de 1 ha que vende \$5M. Por hectárea, la segunda gana más (\$5M vs \$3M). Este panel te muestra esa comparación justa.';

  @override
  String get helpPaybackTitle => '¿Cómo sé cuándo recupero lo invertido?';

  @override
  String get helpPaybackIntro => 'Cuando editas un cultivo puedes poner el Costo del establecimiento: todo lo que invertiste para empezar (plantines, mano de obra, abono inicial). La app calcula cuánto ya recuperaste.';

  @override
  String get helpPaybackTitlePercent => '% recuperado';

  @override
  String get helpPaybackPercent => 'Divide lo que ya ganaste con ventas menos gastos, entre lo que invertiste. 100% = ya lo pagaste completamente.';

  @override
  String get helpPaybackTitleYears => 'Se pagaría en N años (aprox.)';

  @override
  String get helpPaybackYears => 'Un estimado basado en tu margen promedio real. No es una promesa — es un cálculo con tus datos.';

  @override
  String get helpPaybackTitleNotLoss => 'No es una pérdida, es una inversión';

  @override
  String get helpPaybackNotLoss => 'Si inviertes \$1,000,000 en plantar café y aún no vendes, no perdiste \$1,000,000. Invertiste \$1,000,000. Cuando empieces a vender, el porcentaje de recuperación empieza a subir.';

  @override
  String get helpFlowTitle => 'El orden de la app';

  @override
  String get helpFlowIntro => 'Piensa en esto como una cadena: primero le dices qué cultivas, luego cuánto sembraste, luego cuánto gastaste, luego qué recogiste, y por último cuánto vendiste.';

  @override
  String get helpFlowStep1Title => 'Definir el cultivo';

  @override
  String get helpFlowStep1Body => 'Qué manejas (café, plátano…).';

  @override
  String get helpFlowStep2Title => 'Registrar la siembra';

  @override
  String get helpFlowStep2Body => 'Cuántas plantas pusiste.';

  @override
  String get helpFlowStep3Title => 'Anotar gastos';

  @override
  String get helpFlowStep3Body => 'Qué invertiste.';

  @override
  String get helpFlowStep4Title => 'Registrar cosecha';

  @override
  String get helpFlowStep4Body => 'Qué recogiste.';

  @override
  String get helpFlowStep5Title => 'Registrar venta';

  @override
  String get helpFlowStep5Body => 'A quién vendiste y cuánto.';

  @override
  String get helpFlowHint => 'La tarjeta \"Tu próximo paso\" en el Resumen te dice exactamente cuál es el siguiente registro que necesitas. Cuando ya hiciste todo, la tarjeta desaparece sola.';

  @override
  String get helpCommonTitle => 'Errores comunes (y cómo corregirlos)';

  @override
  String get helpCommonAmount => 'Puse un monto incorrecto';

  @override
  String get helpCommonAmountFix => 'Ve a Historial, busca el registro, edítalo o elimínalo';

  @override
  String get helpCommonAssigned => 'No le asigné cultivo a un gasto';

  @override
  String get helpCommonAssignedFix => 'En Historial aparece \"X registros sin cultivo\". Pulsa \"Asignar cultivo ahora\" y elige a qué cultivo pertenece';

  @override
  String get helpCommonType => 'Confundí gasto con ingreso';

  @override
  String get helpCommonTypeFix => 'Abre el registro y cambia el tipo de Gasto a Ingreso (o al revés)';

  @override
  String get helpCommonCurrency => 'Quiero cambiar la moneda';

  @override
  String get helpCommonCurrencyFix => 'Ve a Configuración y selecciona la moneda (COP, USD, EUR). Los montos se convierten automáticamente';

  @override
  String get helpCommonArea => 'No veo el panel \"Por hectárea\"';

  @override
  String get helpCommonAreaFix => 'Registra el área del cultivo: en Cultivos edita el cultivo y pon las hectáreas';

  @override
  String get syncTooltip => 'Sincronizar';

  @override
  String get menuReport => 'Reporte';

  @override
  String get menuSettings => 'Configuración';

  @override
  String get menuLogout => 'Cerrar sesión';

  @override
  String get menuSowings => 'Siembras';

  @override
  String get menuHarvests => 'Cosechas';

  @override
  String get menuHelp => 'Ayuda';

  @override
  String get unitRacimo => 'Racimos';

  @override
  String get unitCajon => 'Cajones';

  @override
  String get defaultUnitLabel => 'Unidad preferida';

  @override
  String get defaultUnitNone => 'Sin preferencia';

  @override
  String get cycleLabel => 'Ciclo';

  @override
  String get cyclePerenne => 'Perenne';

  @override
  String get cycleAnual => 'Anual';

  @override
  String get phaseLabel => 'Fase de vida';

  @override
  String get phaseEstablecimiento => 'Establecimiento';

  @override
  String get phaseProduccion => 'Producción';

  @override
  String get phaseRenovacion => 'Renovación';

  @override
  String get phaseHelp => 'Establecimiento = plantío joven que aún no produce (plantines). La app no te marcará pérdidas en esta etapa.';

  @override
  String get areaHaLabel => 'Área (hectáreas)';

  @override
  String get livePlantsLabel => 'Plantas vivas';

  @override
  String get establishmentCostLabel => 'Costo del establecimiento (\$)';

  @override
  String get editCropTitle => 'Editar cultivo';

  @override
  String get sowingTitle => 'Siembras';

  @override
  String get sowingEmpty => 'Aún no hay siembras registradas.';

  @override
  String get sowingAdd => 'Nueva siembra';

  @override
  String get sowingKindLabel => 'Tipo';

  @override
  String get sowingKindSiembra => 'Siembra inicial';

  @override
  String get sowingKindResiembra => 'Resiembra';

  @override
  String get sowingPlantsLabel => 'Número de plantas';

  @override
  String get sowingLostPlantsLabel => 'Plantas perdidas (bajas)';

  @override
  String get sowingReasonLabel => 'Motivo (opcional)';

  @override
  String get sowingAreaLabel => 'Área (hectáreas, opcional)';

  @override
  String get sowingCostLabel => 'Costo (opcional)';

  @override
  String get sowingCostHint => 'Si registras un costo, se crea un gasto vinculado a esta siembra.';

  @override
  String get plantsInvalid => 'Ingresa un número de plantas válido';

  @override
  String get sowingRecordSaved => 'Siembra guardada';

  @override
  String get sowingRecordUpdated => 'Siembra actualizada';

  @override
  String get sowingRecordDeleted => 'Siembra eliminada';

  @override
  String get sowingConfirmDelete => '¿Eliminar esta siembra?';

  @override
  String get harvestTitle => 'Cosechas';

  @override
  String get harvestEmpty => 'Aún no hay cosechas registradas.';

  @override
  String get harvestAdd => 'Nueva cosecha';

  @override
  String get harvestAmountLabel => 'Cantidad';

  @override
  String get harvestUnitLabel => 'Unidad';

  @override
  String get harvestDestinationLabel => 'Destino';

  @override
  String get harvestDstVendido => 'Vendido';

  @override
  String get harvestDstAlmacenado => 'Almacenado';

  @override
  String get harvestDstPerdida => 'Pérdida';

  @override
  String get harvestAmountInvalid => 'Ingresa una cantidad mayor a 0';

  @override
  String get harvestRecordSaved => 'Cosecha guardada';

  @override
  String get harvestRecordUpdated => 'Cosecha actualizada';

  @override
  String get harvestRecordDeleted => 'Cosecha eliminada';

  @override
  String get harvestConfirmDelete => '¿Eliminar esta cosecha?';

  @override
  String get expenseLinkHarvestLabel => 'Vincular a cosecha (opcional)';

  @override
  String get expenseLinkHarvestNone => 'Sin vincular';

  @override
  String get unitPreferenceHint => 'Se usa tu unidad preferida si aún no eliges una.';

  @override
  String get reportHarvestSection => 'Cosechas del período';

  @override
  String get reportHarvestedTotal => 'Total cosechado por cultivo';

  @override
  String get reportHarvestKg => 'Kg (normalizado)';

  @override
  String get reportHarvestDestinations => 'Por destino';

  @override
  String get reportPickupCostPerKg => 'Costo de recogida por kg';

  @override
  String get reportTotalCostPerKg => 'Costo total por kg';

  @override
  String get reportInvestmentEstablecimiento => 'Inversión acumulada (establecimiento)';

  @override
  String get reportYieldPerArea => 'Rendimiento por área (kg/ha)';

  @override
  String get reportYieldPerPlant => 'Rendimiento por planta (kg/planta)';

  @override
  String get reportApprox => '(aproximado)';

  @override
  String get reportSoldVsHarvested => 'Vendido vs cosechado';

  @override
  String get reportSoldKg => 'Vendido (kg)';

  @override
  String get reportHarvestedKg => 'Cosechado (kg)';

  @override
  String get reportWhatsNext => 'Qué hacer';

  @override
  String get reportNoRecommendations => 'No hay recomendaciones para este período.';

  @override
  String get reportNoHarvestData => 'Sin datos de cosechas en el período.';

  @override
  String get perHaSection => 'Por hectárea';

  @override
  String get perHaNoAreaHint => 'Registra el área de tus cultivos (edita el cultivo) para ver su desempeño por hectárea: rendimiento, ingresos y gastos normalizados.';

  @override
  String get perHaYieldLabel => 'Rendimiento';

  @override
  String get perHaRevenueLabel => 'Ventas por ha';

  @override
  String get perHaCostLabel => 'Gastos por ha';

  @override
  String get perHaMarginLabel => 'Margen por ha';

  @override
  String get perHaInvestmentLabel => 'Inversión del establecimiento';

  @override
  String get perHaRecoveredLabel => 'Recuperado';

  @override
  String get perHaRecoveryPending => 'Pendiente de recuperarse';

  @override
  String get perHaPaybackLabel => 'Se pagaría en';

  @override
  String perHaPaybackYears(String years) {
    return '$years años (aprox.)';
  }

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
  String get prodSectionTitle => 'Datos de producción';

  @override
  String get quantityFieldLabel => 'Cantidad vendida';

  @override
  String get unitFieldLabel => 'Unidad';

  @override
  String get unitKg => 'Kilogramos (kg)';

  @override
  String get unitArroba => 'Arrobas (12.5 kg)';

  @override
  String get unitSaco => 'Sacos (70 kg)';

  @override
  String get clientFieldLabel => 'Cliente / comprador (opcional)';

  @override
  String get providerFieldLabel => 'Proveedor / vendedor (opcional)';

  @override
  String get pricePerUnitLabel => 'Precio por';

  @override
  String get pricePerUnitHint => 'Se calcula automáticamente: monto ÷ cantidad';

  @override
  String get lowPriceThresholdLabel => 'Precio mínimo de venta por kg';

  @override
  String get lowPriceThresholdHelper => 'Opcional. Si vendes café por debajo de este precio (por kg), se mostrará una alerta. Déjalo vacío para usar solo tu historial.';

  @override
  String get excelColQty => 'Cantidad';

  @override
  String get excelColUnit => 'Unidad';

  @override
  String get excelColPricePerUnit => 'Precio por unidad';

  @override
  String get excelColClient => 'Cliente';

  @override
  String get excelColProvider => 'Proveedor';

  @override
  String get topClientsTitle => 'Principales compradores';

  @override
  String get topProvidersTitle => 'Principales proveedores';

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
  String get menuCrops => 'Cultivos';

  @override
  String get cropsEmpty => 'Aún no hay cultivos. Agrega el primero.';

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
  String get alertLowPriceManualTitle => 'Vendiste café por debajo de tu precio mínimo';

  @override
  String alertLowPriceManualMessage(String price, String threshold, String date) {
    return 'El $date vendiste a $price por kg, por debajo de tu precio mínimo de $threshold. Considera negociar un mejor precio o esperar.';
  }

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
  String get excelSheetHarvests => 'Cosechas';

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

  @override
  String alertCropEstablishmentTitle(String crop) {
    return '$crop está en establecimiento: es inversión, no pérdida';
  }

  @override
  String alertCropEstablishmentMessage(String investment, String crop) {
    return 'El problema: llevas $investment invertidos en $crop y aún no hay ingresos. Es normal en esta etapa: el plantío está creciendo y la primera cosecha llega al pasar a producción.';
  }

  @override
  String alertCropEstablishmentSuggestion(String crop) {
    return 'Sigue registrando los gastos de $crop. Cuando el cultivo entre en producción, la app evaluará su rentabilidad normal.';
  }

  @override
  String alertHarvestVsSalesTitle(String crop) {
    return 'Vendiste más de lo que cosechaste en $crop';
  }

  @override
  String alertHarvestVsSalesMessage(String soldKg, String harvestedKg, String crop) {
    return 'El problema: en los últimos 12 meses vendiste $soldKg de $crop, pero solo registraste $harvestedKg de cosecha. Revisa si hay inventario almacenado o un error de registro.';
  }

  @override
  String alertHarvestVsSalesSuggestion(String crop) {
    return 'Compara tus registros de $crop: asegúrate de registrar cada cosecha y cada venta con la misma unidad para evitar desfases.';
  }

  @override
  String get alertRecentlyPlantedTitle => 'Registraste una siembra reciente';

  @override
  String alertRecentlyPlantedMessage(String crop, String date) {
    return 'Registraste una siembra o resiembra de $crop el $date. Verifica que el número de plantas vivas actualizado del cultivo coincida con el conteo real.';
  }

  @override
  String get alertRecentlyPlantedSuggestion => 'Edita el cultivo para ajustar sus plantas vivas si el conteo cambió después de la siembra.';

  @override
  String get alertMissingQtyTitle => 'Tienes ventas sin kilos registrados';

  @override
  String alertMissingQtyMessage(int count) {
    return 'El problema: en los últimos 90 días registraste $count ventas sin la cantidad vendida. Sin ese dato, la app no puede calcular tu precio por kilo ni tu rentabilidad.';
  }

  @override
  String get alertMissingQtySuggestion => 'Edita esas ventas e ingresa los kilos vendidos. Así tus informes de precio y rentabilidad serán confiables.';
}
