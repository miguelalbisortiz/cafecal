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
  String get nextStepSowingSubtitle => 'Este cultivo todavía no tiene registrada su siembra inicial.';

  @override
  String get nextStepExpensesTitle => 'Registra tus primeros gastos';

  @override
  String get nextStepExpensesSubtitle => 'Lleva el control de lo que inviertes cada mes.';

  @override
  String get nextStepSaleTitle => 'Registra la venta de tu cosecha';

  @override
  String get nextStepSaleSubtitle => 'Al registrarla se anotan solos los kilos cosechados de ese cultivo.';

  @override
  String get nextStepGuideLink => 'Ver guía completa';

  @override
  String get welcomeTitle => '¿Qué cultivas?';

  @override
  String get welcomeSubtitle => 'Empieza por el que más tienes. Los demás los agregas después.';

  @override
  String get welcomeEmptyList => 'Sin cultivos todavía';

  @override
  String get welcomeAddFirst => 'Agregar el primero';

  @override
  String get welcomeAddMore => 'Agregar otro';

  @override
  String get welcomeEnter => 'Entrar a la app';

  @override
  String get welcomeIconLabel => 'Icono';

  @override
  String get welcomeDone => 'Listo';

  @override
  String get welcomeComplete => 'Completar datos…';

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
  String get helpStartTitle => 'Aprende a operar Mi Cafetal';

  @override
  String get helpTabStart => 'Empezar';

  @override
  String get helpTabRoutine => 'Rutina';

  @override
  String get helpTabUnderstand => 'Entender';

  @override
  String get helpStartSubtitle => 'Elige cómo está tu finca hoy. En cinco minutos haces el primer registro.';

  @override
  String get helpStartQuestion => '¿Cómo está tu finca hoy?';

  @override
  String get helpStartNote => 'Los ejemplos usan números redondos y «tu moneda». Sirven igual para cualquier país y cualquier cultivo.';

  @override
  String get helpCaseSellingTitle => 'Ya vendo lo que cosecho';

  @override
  String get helpCaseSellingDesc => 'Tienes cultivos dando fruto y quieres saber si ganas.';

  @override
  String get helpCaseStartingTitle => 'Voy a empezar';

  @override
  String get helpCaseStartingDesc => 'Vas a sembrar y quieres ver cuánto inviertes antes de cosechar.';

  @override
  String get helpCaseRenewTitle => 'Voy a renovar o ampliar';

  @override
  String get helpCaseRenewDesc => 'Vas a reemplazar matas o sumar área a un cultivo.';

  @override
  String get helpCaseWorkersTitle => 'Tengo trabajadores';

  @override
  String get helpCaseWorkersDesc => 'Pagas jornales y quieres que el costo quede en el cultivo correcto.';

  @override
  String get helpSellingIntro => 'No anotes lo que ya pasó. Empieza desde hoy: lo que gastes y lo que vendas.';

  @override
  String get helpSellingStep1 => 'Revisa tus cultivos: Cultivos › tu cultivo. Que la fase sea «Dando» y, si los sabes, el área y las matas. Si no los sabes, déjalos vacíos: la app no inventa.';

  @override
  String get helpSellingStep2 => 'Anota el primer gasto: Registrar › Gasto. Elige el cultivo y la categoría: fertilizante, mano de obra, transporte. Si el gasto es de varios cultivos, repártelo por área o por porcentaje.';

  @override
  String get helpSellingStep3 => 'Anota la primera venta: Registrar › Ingreso. Escribe los kilos y lo que te pagaron. Con esos kilos, la cosecha de ese cultivo queda registrada sola. No la anotes dos veces.';

  @override
  String get helpSellingStep4 => 'Mira el mes: Resumen o Reporte. Ahí ves ingresos, gastos, balance y costo por kilo. El reporte sale en PDF o Excel.';

  @override
  String get helpSellingExampleTitle => 'Ejemplo con café, 2 ha y 3.000 matas';

  @override
  String get helpSellingExample1 => 'Gasto: 500 en fertilizante, asignado a café.';

  @override
  String get helpSellingExample2 => 'Venta: 50 kg por 750.';

  @override
  String get helpSellingExample3 => 'Resultado: ingresos 750 · gastos 500 · balance 250 · costo por kilo 10.';

  @override
  String get helpSellingClosing => 'Lo que vendiste antes de usar la app no hace falta: el reporte empieza con lo que anotes.';

  @override
  String get helpSellingMulti => 'Si tienes varios cultivos en el mismo terreno, asígnalos al registrar el gasto; la app reparte por área o por porcentaje.';

  @override
  String get helpStartingIntro => 'Mientras el cultivo no da fruto, la app no te dice que pierdes: te muestra cuánto llevas invertido. Es una inversión, no un mal mes.';

  @override
  String get helpStartingStep1 => 'Crea el cultivo: Cultivos › Nueva variedad. Nombre, fase «Sin dar» y si es perenne o transitorio. El área y las matas pueden quedar vacías.';

  @override
  String get helpStartingStep2 => 'Anota la siembra: Siembras › Nueva siembra. Cuántas matas, en qué área y la fecha. Si anotas el costo, la app crea el gasto vinculado sola: no lo repitas en Registrar.';

  @override
  String get helpStartingStep3 => 'Anota lo que inviertes: Registrar › Gasto, con el cultivo. Fertilizante, mano de obra, herramientas. Todo lo de antes de la primera cosecha se ve como inversión.';

  @override
  String get helpStartingStep4 => 'Cuando coseches, cambia la fase: Cultivos › tu cultivo › fase «Dando». Desde ahí, la venta registra la cosecha.';

  @override
  String get helpStartingExampleTitle => 'Ejemplo con maíz, 1 ha y 20.000 matas';

  @override
  String get helpStartingExample1 => 'Siembra: 20.000 matas en 1 ha.';

  @override
  String get helpStartingExample2 => 'Inversión: 300 en semilla + 200 en preparación = 500.';

  @override
  String get helpStartingExample3 => 'Antes de cosechar: inversión 500, sin pérdida.';

  @override
  String get helpStartingExample4 => 'Primera venta: 1.000 kg por 800. La cosecha queda registrada.';

  @override
  String get helpRenewIntro => 'No borres el cultivo viejo. La app guarda su historia y suma la parte nueva.';

  @override
  String get helpRenewStep1 => 'Elige qué pasa con las matas viejas: Siembras › Nueva siembra. Si reemplazas una parte, elige «Renuevo una parte» y el lote que renuevas. Las matas viejas bajan y las nuevas suman: el total no se infla.';

  @override
  String get helpRenewStep2 => 'Si amplías, no reemplaces: elige «Amplío el cultivo». Sumas área y matas sin tocar lo que ya estaba.';

  @override
  String get helpRenewStep3 => 'Mira la edad nueva: el lote renovado arranca su propia edad. Las cosechas viejas siguen en el historial y en el reporte.';

  @override
  String get helpRenewExampleTitle => 'Ejemplo con café de 3.000 matas; renuevas 1.000';

  @override
  String get helpRenewExample1 => 'Siembra: 1.000 matas nuevas, «Renuevo una parte», lote viejo.';

  @override
  String get helpRenewExample2 => 'Total: sigue en 3.000, no en 4.000.';

  @override
  String get helpRenewExample3 => 'El lote nuevo tiene su fecha; el viejo conserva la suya.';

  @override
  String get helpWorkersCaseIntro => 'El jornal no es un gasto suelto: va al cultivo donde trabajaron. Así el costo por kilo dice la verdad.';

  @override
  String get helpWorkersStep1 => 'Guarda al trabajador: Trabajadores › Nuevo trabajador. Nombre y pago por día. Si cambia el jornal, lo actualizas ahí.';

  @override
  String get helpWorkersStep2 => 'Anota el pago: Registrar › Gasto › Mano de obra. Elige el trabajador, los días y el cultivo. La app calcula el monto; si pagaste otra cosa, lo ajustas.';

  @override
  String get helpWorkersStep3 => 'Si fue cosecha, márcalo: en la labor elige «Cosechar», anota los kilos y el lote. Con eso sale el costo de recogida por kilo.';

  @override
  String get helpWorkersStep4 => 'Mira la nómina: Reporte › Nómina del período. Ahí está cuántos días y cuánto pagaste a cada uno.';

  @override
  String get helpWorkersExampleTitle => 'Ejemplo con dos trabajadores a 20 por día';

  @override
  String get helpWorkersExample1 => 'Juan: 3 días en café = 60.';

  @override
  String get helpWorkersExample2 => 'Pedro: 2 días en café = 40.';

  @override
  String get helpWorkersExample3 => 'Nómina: 5 días y 100. Si fue cosecha, los kilos van al lote.';

  @override
  String get helpExampleNote => 'Números de ejemplo, en tu moneda.';

  @override
  String get helpRoutineTitle => 'La rutina que hace que la app sirva';

  @override
  String get helpRoutineIntro => 'No necesitas llenar todo. Con estos cuatro momentos, el reporte se arma solo.';

  @override
  String get helpRoutineWhen => 'Cuándo';

  @override
  String get helpRoutineWhat => 'Qué anotas';

  @override
  String get helpRoutineWhere => 'Dónde';

  @override
  String get helpRoutineRow1When => 'Cada gasto';

  @override
  String get helpRoutineRow1What => 'Lo que pagaste, con su cultivo';

  @override
  String get helpRoutineRow1Where => 'Registrar › Gasto';

  @override
  String get helpRoutineRow2When => 'Cada venta';

  @override
  String get helpRoutineRow2What => 'Kilos y lo que te pagaron';

  @override
  String get helpRoutineRow2Where => 'Registrar › Ingreso';

  @override
  String get helpRoutineRow3When => 'Cada pago';

  @override
  String get helpRoutineRow3What => 'Trabajador, días y labor';

  @override
  String get helpRoutineRow3Where => 'Registrar › Gasto › Mano de obra';

  @override
  String get helpRoutineRow4When => 'Fin de mes';

  @override
  String get helpRoutineRow4What => 'Revisas el balance y guardas el respaldo';

  @override
  String get helpRoutineRow4Where => 'Reporte · Configuración › Respaldo';

  @override
  String get helpRoutineGoldenTitle => 'La regla de oro:';

  @override
  String get helpRoutineGolden => 'si no lo anotas, la app no lo sabe. No inventa cifras: lo que falta, lo dice.';

  @override
  String get helpRoutineTwiceTitle => 'Tres cosas que no se anotan dos veces';

  @override
  String get helpRoutineTwice1 => 'La cosecha: se registra con la venta (kilos) o con el jornal de cosecha, no en los dos.';

  @override
  String get helpRoutineTwice2 => 'El pago del trabajador: va en Mano de obra, no en la categoría de la labor.';

  @override
  String get helpRoutineTwice3 => 'El costo de la siembra: va en la siembra y crea su gasto vinculado; no se repite en Registrar.';

  @override
  String get helpDictTitle => 'Lo que significan tus números';

  @override
  String get helpDictIntro => 'Los términos que más vas a ver. Toca «Ver todos los términos» para el glosario completo.';

  @override
  String get helpDictSeeAll => 'Ver todos los términos';

  @override
  String get helpDictCurrencyTitle => 'Moneda';

  @override
  String get helpDictCurrencyBody => 'La app muestra siempre el código de la moneda, nunca un símbolo. No suma monedas distintas: cada una sale por separado, con su código. La moneda de la cuenta se elige al empezar y no se cambia.';

  @override
  String get helpTroubleTitle => 'Si algo no cuadra';

  @override
  String get helpTrouble1Title => 'El gasto no aparece en el cultivo';

  @override
  String get helpTrouble1Body => 'Revisa que lo hayas asignado. Si quedó «Sin especificar», cae en «Costos comunes».';

  @override
  String get helpTrouble2Title => 'La venta no coincide con la cosecha';

  @override
  String get helpTrouble2Body => 'La venta registra la cosecha con los kilos que anotes. Si ya la anotaste en el jornal, no la repitas.';

  @override
  String get helpTrouble3Title => 'Hay dos monedas y no veo un total';

  @override
  String get helpTrouble3Body => 'Es a propósito: no se suman monedas distintas. Cada una sale con su código.';

  @override
  String get helpTrouble4Title => 'El área no cuadra';

  @override
  String get helpTrouble4Body => 'La suma de cultivos puede superar el área del terreno. La app avisa, no bloquea. Corrige el área o el reparto.';

  @override
  String get helpTrouble5Title => 'No subió a la nube';

  @override
  String get helpTrouble5Body => 'La app guarda primero en tu equipo. Sin señal queda pendiente y sube al reconectar. Puedes reintentar.';

  @override
  String get helpTrouble6Title => 'Borré sin querer';

  @override
  String get helpTrouble6Body => 'Mira Historial. Si no está, restaura el respaldo: lo que ya tenías se conserva y lo del archivo se suma.';

  @override
  String get helpTroubleFooter => '¿No encuentras tu caso? Anota lo que pasó y el reporte se ajusta. La app no inventa cifras: si falta un dato, lo dice.';

  @override
  String get helpTitle => 'Ayuda';

  @override
  String get helpUnitsTitle => '¿Qué unidad uso?';

  @override
  String get helpUnitsBody => 'Puedes usar kilogramos (kg), libras (lb), arrobas (1 arroba = 12,5 kg), sacos o cargas (1 carga = 60 lb = 27,2 kg). La app convierte todo a kg para comparar, con el peso del saco que defines en Configuración. Usa la unidad con la que trabajas normalmente.';

  @override
  String get syncTooltip => 'Sincronizar';

  @override
  String get syncFailed => 'No se pudo sincronizar';

  @override
  String get syncRetry => 'Reintentar';

  @override
  String get syncErrorTooltip => 'Hay datos sin sincronizar. Toca para ver el detalle';

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
  String get phaseLabel => '¿Cómo va?';

  @override
  String get phaseEstablecimiento => 'Sin dar';

  @override
  String get phaseProduccion => 'Dando';

  @override
  String get phaseRenovacion => 'Para renovar';

  @override
  String get phaseHelp => 'Sin dar = plantío ya sembrado que todavía no produce. La app no te marcará pérdidas en esta etapa.';

  @override
  String get helpUnit => 'En qué unidad vendés tu cosecha: kg, lb, arroba (≈12.5 kg), saco, carga (≈27.2 kg), racimo (plátano) o cajón.';

  @override
  String get helpCycle => 'Perenne = vive muchos años (café, plátano). Anual = se siembra y cosecha en el mismo año (tomate, maíz).';

  @override
  String get helpArea => '1 hectárea = 10.000 metros² (≈ 1 campo de fútbol). Si no sabes, déjalo en blanco.';

  @override
  String get helpPlants => 'Cuántas plantas tienes de este cultivo. Si no sabes exacto, aproxima.';

  @override
  String get helpEstablishment => 'Lo que invertiste en dejar este cultivo listo. Sirve para saber cuándo se paga. Si lo dejas vacío, la app lo suma de tus gastos de siembra inicial (sin resiembras).';

  @override
  String get areaHaLabel => 'Área (hectáreas)';

  @override
  String get livePlantsLabel => 'Plantas vivas';

  @override
  String get establishmentCostLabel => 'Inversión total';

  @override
  String get expectedYieldLabel => 'Meta anual (kg/ha)';

  @override
  String get helpExpectedYield => 'Lo que quieres sacar de este lote por año. Es TU número, no una tabla de nadie: la app no mide contra ninguna tabla externa, mide contra lo que tú pusiste. Vacío = no se compara nada.';

  @override
  String get firstHarvestLabel => '¿Cuándo esperás la primera cosecha?';

  @override
  String get firstHarvestEmpty => 'Sin fecha estimada';

  @override
  String firstHarvestSoon(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'faltan $count meses',
      one: 'falta $count mes',
      zero: 'este mes',
    );
    return 'primer cosecha est.: $date · $_temp0';
  }

  @override
  String firstHarvestOverdue(String date) {
    return 'debería estar rindiendo desde $date';
  }

  @override
  String get cropLockedHint => 'Calculado desde tus siembras';

  @override
  String get cropLossRegister => 'Registrar pérdida';

  @override
  String cropLossCurrent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plantas',
      one: '$count planta',
    );
    return 'Hoy la app calcula $_temp0';
  }

  @override
  String get cropLossRemainingLabel => 'Plantas que quedan';

  @override
  String get cropLossRemainingHelp => 'Cuenta las que ves en la finca y anota el total.';

  @override
  String get cropLossInvalid => 'Ingresa un número de plantas válido.';

  @override
  String get cropLossNoChange => 'Ese es el número que ya estaba: no cambia nada.';

  @override
  String cropLossPreviewDied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plantas perdidas',
      one: '$count planta perdida',
    );
    return '$_temp0';
  }

  @override
  String cropLossPreviewAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plantas más',
      one: '$count planta más',
    );
    return '$_temp0';
  }

  @override
  String get cropLossSaved => 'Pérdida registrada';

  @override
  String get plantedAtLabel => '¿Desde cuándo está plantado?';

  @override
  String get helpPlantedAtShort => 'Opcional. Si no la recuerdas, déjala vacía.';

  @override
  String get plantedAtEmpty => 'Sin fecha';

  @override
  String get plantedAtClear => 'Borrar la fecha';

  @override
  String cropAge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count años',
      one: '$count año',
      zero: 'Menos de un año',
    );
    return '$_temp0';
  }

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
  String get helpSowingKind => 'Siembra = plantas por primera vez. Resiembra = reemplazas plantas muertas o dañadas.';

  @override
  String get sowingPlantsLabel => 'Número de plantas';

  @override
  String get helpSowingPlants => 'Cuántas plantas en esta siembra. Si no sabes exacto, aproxima.';

  @override
  String get sowingLostPlantsLabel => 'Plantas perdidas (bajas)';

  @override
  String get sowingMissingLossesTitle => 'Anotaste plantas nuevas sin muertas';

  @override
  String get sowingMissingLossesBody => 'En una resiembra conviene anotar cuántas matas se perdieron: es lo que baja el contador del cultivo. Puedes guardar así y completarlo después.';

  @override
  String get sowingMissingLossesEnter => 'Anotar muertas';

  @override
  String get sowingMissingLossesSave => 'Guardar así';

  @override
  String get helpSowingLostPlants => 'Cuántas plantas se murieron o perdieron (plagas, clima, etc.).';

  @override
  String get sowingReasonLabel => 'Motivo (opcional)';

  @override
  String get sowingAreaLabel => 'Área (hectáreas, opcional)';

  @override
  String get helpSowingArea => '1 hectárea = 10.000 metros² (≈ 1 campo de fútbol).';

  @override
  String get sowingCostLabel => 'Costo (opcional)';

  @override
  String get sowingCostHint => 'Si registras un costo, se crea un gasto vinculado a esta siembra o resiembra.';

  @override
  String get sowingCostInvalid => 'Ingresa un costo válido (solo números).';

  @override
  String get helpUnitShort => 'Unidad con la que cosechás o vendés este cultivo.';

  @override
  String get helpCycleShort => 'Perenne o anual';

  @override
  String get phaseHelpShort => 'Fase del cultivo';

  @override
  String get helpAreaShort => 'Opcional, en ha';

  @override
  String get helpPlantsShort => 'Aproximado';

  @override
  String get helpEstablishmentShort => 'Se rellena con tus gastos de siembra';

  @override
  String get helpExpectedYieldShort => 'Opcional, tu propia meta';

  @override
  String get helpFirstHarvestShort => 'Opcional. Es TU fecha: la app solo hace la cuenta.';

  @override
  String get helpSowingPlantsShort => 'Aproximado';

  @override
  String get helpSowingLostPlantsShort => 'Muertas o dañadas';

  @override
  String get helpSowingAreaShort => 'En hectáreas';

  @override
  String get sowingCostHintShort => 'Crea gasto vinculado';

  @override
  String get plantsInvalid => 'Ingresa un número de plantas válido';

  @override
  String get sowingPlantsOrLost => 'Pon las plantas que sembraste o las que se te murieron.';

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
  String reportPendingWeightHarvests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cosechas sin peso',
      one: '$count cosecha sin peso',
    );
    return '$_temp0';
  }

  @override
  String reportPendingWeightSales(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ventas sin peso',
      one: '$count venta sin peso',
    );
    return '$_temp0';
  }

  @override
  String get reportPendingWeightTitle => 'Sin peso (no entran en los kilos)';

  @override
  String get reportPendingWeightHint => 'Anota el peso total para que sumen kilos.';

  @override
  String get reportPickupCostPerKg => 'Costo de recogida por kg';

  @override
  String get reportTotalCostPerKg => 'Costo total por kg';

  @override
  String get reportInvestmentEstablecimiento => 'Inversión acumulada (establecimiento)';

  @override
  String get reportYieldPerArea => 'Rendimiento por área del período (kg/ha)';

  @override
  String get reportYieldPerPlant => 'Rendimiento por planta del período (kg/planta)';

  @override
  String get reportApprox => '(aproximado)';

  @override
  String get reportSoldVsHarvested => 'Vendido vs cosechado';

  @override
  String get reportSoldKg => 'Vendido (kg)';

  @override
  String get reportHarvestedKg => 'Cosechado (kg)';

  @override
  String soldVsHarvestedMismatch(Object pct) {
    return 'Vendiste $pct% más de lo que cosechaste en este período. Suele ser una cosecha de meses anteriores o una cosecha sin registrar.';
  }

  @override
  String get soldVsHarvestedNoHarvest => 'No registraste cosecha de este cultivo en el período. Esta venta puede venir de una cosecha de meses anteriores.';

  @override
  String get reportSowingsSection => 'Siembras';

  @override
  String get reportSowingsNow => '¿Qué tengo plantado hoy?';

  @override
  String get reportSowingsPlantOne => 'planta';

  @override
  String get reportSowingsPlantMany => 'plantas';

  @override
  String get reportSowingsTotal => 'Total plantado';

  @override
  String get reportSowingsLosses => 'Pérdidas acumuladas';

  @override
  String reportSowingsInPeriod(Object period) {
    return 'Siembras en $period';
  }

  @override
  String get reportSowingsKindSiembra => 'siembra';

  @override
  String get reportSowingsKindResiembra => 'resiembra';

  @override
  String reportSowingsLostLine(Object count, Object reason) {
    return '↳ perdidas $count · $reason';
  }

  @override
  String reportSowingsLostOnly(Object count) {
    return '↳ perdidas $count';
  }

  @override
  String get reportSowingsNoPeriod => 'No registraste siembras en este período.';

  @override
  String get reportWhatsNext => 'Qué hacer';

  @override
  String get reportNoRecommendations => 'No hay recomendaciones para este período.';

  @override
  String get reportNoHarvestData => 'Sin datos de cosechas en el período.';

  @override
  String get harvestWorkersLabel => 'N° de empleados';

  @override
  String get harvestWorkersHint => 'Opcional. Personas que trabajaron en la cosecha.';

  @override
  String get harvestWorkersInvalid => 'Ingresa un entero mayor o igual a 0.';

  @override
  String harvestWorkersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count empleados',
      one: '$count empleado',
    );
    return '$_temp0';
  }

  @override
  String get harvestEquivalentKgLabel => 'Peso total (kg)';

  @override
  String get harvestEquivalentKgHint => 'Obligatorio: lo que pesaron los racimos o cajones juntos.';

  @override
  String get harvestEquivalentKgInvalid => 'Ingresa un número mayor que 0.';

  @override
  String get harvestEquivalentKgRequired => 'Anota el peso total para poder contar los kilos.';

  @override
  String harvestPriceLabel(String unit) {
    return 'Precio por $unit';
  }

  @override
  String get harvestPriceHint => 'Si ya te pagaron, anótalo aquí y la app registra la venta sola. Déjalo vacío si aún no cobras.';

  @override
  String get harvestPriceInvalid => 'Ingresa un precio válido (solo números).';

  @override
  String harvestSalePreview(String amount) {
    return 'Se registra la venta: $amount';
  }

  @override
  String get reportPayrollSection => 'Nómina del período';

  @override
  String get reportPayrollBudgetNote => 'Esto es lo gastado por tarea; el presupuesto de caja es uno solo.';

  @override
  String get reportPayrollWorker => 'Trabajador';

  @override
  String get reportPayrollDays => 'Días';

  @override
  String get reportPayrollSubtotal => 'Subtotal';

  @override
  String get reportPayrollTotal => 'Total nómina';

  @override
  String reportPayrollEmployees(int count) {
    return 'Empleados distintos: $count';
  }

  @override
  String get reportPayrollUnnamed => 'Sin nombre';

  @override
  String get reportCashBoxBudget => 'Presupuesto';

  @override
  String get reportCashBoxBalance => 'Saldo';

  @override
  String get reportHarvestStaff => 'Personal y kilos';

  @override
  String get reportEquivalentKg => 'Kilos equivalentes';

  @override
  String get perHaSection => 'Por hectárea';

  @override
  String get perHaNoAreaHint => 'Registra el área de tus cultivos (edita el cultivo) para ver su desempeño por hectárea: rendimiento, ingresos y gastos normalizados.';

  @override
  String get perHaYieldLabel => 'Rendimiento del período';

  @override
  String get perHaYieldPlantLabel => 'Rendimiento por planta del período';

  @override
  String get perHaPerPlantNote => 'kg/planta es el promedio del cultivo; incluye plantas que aún no producen.';

  @override
  String yieldAvgHaLabel(int years) {
    return 'Tu promedio anual ($years años)';
  }

  @override
  String yieldAvgPlantLabel(int years) {
    return 'Tu promedio por planta ($years años)';
  }

  @override
  String get yieldGoalLabel => 'Meta anual';

  @override
  String get perHaRevenueLabel => 'Ventas por ha';

  @override
  String get perHaCostLabel => 'Gastos por ha';

  @override
  String get perHaLotNotSplit => 'El lote no se reparte: falta el área de un cultivo.';

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
  String summaryVsPrev(String month) {
    return 'vs. $month';
  }

  @override
  String summaryVsPrevNote(String month) {
    return 'Comparado con los mismos días de $month.';
  }

  @override
  String summaryResultBetter(String amount) {
    return 'mejoró $amount';
  }

  @override
  String summaryResultWorse(String amount) {
    return 'empeoró $amount';
  }

  @override
  String get summaryEmptyTitle => 'Aún no registraste movimientos';

  @override
  String get summaryEmptyBody => 'Cuando anotes un gasto o una venta, acá vas a ver cuánto ganaste, cuánto gastaste y qué te quedó.';

  @override
  String get alertsTitle => 'Alertas';

  @override
  String get alertsTooltip => '¿Qué significan estas alertas?';

  @override
  String get glossaryTitle => '¿Qué significan estos términos?';

  @override
  String get glossaryGotIt => 'Entendido';

  @override
  String get glossaryIncomeTerm => 'Ingreso';

  @override
  String get glossaryIncomeDef => 'Lo que te pagaron por lo que vendiste. No es lo mismo que cosechar: puedes cosechar y no vender.';

  @override
  String get glossaryExpenseTerm => 'Gasto';

  @override
  String get glossaryExpenseDef => 'Lo que pagaste para producir o mantener la finca. Si es de un cultivo, asígnalo.';

  @override
  String get glossaryBalanceTerm => 'Balance / Resultado';

  @override
  String get glossaryBalanceDef => 'Es la resta de Ingresos menos Gastos en un período. Si el resultado es positivo tienes ganancia; si es negativo, pérdida.';

  @override
  String get glossaryMarginTerm => 'Margen';

  @override
  String get glossaryMarginDef => 'De cada 100 que vendes, cuánto queda después de cubrir los gastos. Se calcula como (Ingresos - Gastos) ÷ Ingresos: si vendes 100 y gastas 40, el margen es 60%. Un margen negativo significa que gastas más de lo que vendes.';

  @override
  String get glossaryRatioTerm => 'Gastos vs ingresos';

  @override
  String get glossaryRatioDef => 'Qué porcentaje de tus ingresos se va en gastos. Por ejemplo, 80% quiere decir que por cada 100 que entran, 80 se gastan y quedan 20.';

  @override
  String get glossaryAvgTerm => 'Promedio histórico mensual';

  @override
  String get glossaryAvgDef => 'El promedio de lo que gastas al mes en una categoría (por ejemplo, mano de obra). Sirve como referencia para detectar aumentos inusuales en tus gastos.';

  @override
  String get glossaryYieldAreaTerm => 'Rendimiento por área (kg/ha)';

  @override
  String get glossaryYieldAreaDef => 'Cuántos kilos sacas de una hectárea. Sirve para comparar lotes de tamaños distintos: si uno da 1.200 kg/ha y otro 800 kg/ha, el primero rinde más con la misma tierra.';

  @override
  String get glossaryYieldPlantTerm => 'Rendimiento por planta (kg/planta)';

  @override
  String get glossaryYieldPlantDef => 'Cuántos kilos produce cada planta. Te ayuda a ver si el problema es la cantidad de plantas o el cuidado del cultivo.';

  @override
  String get glossaryCostPerKgTerm => 'Costo total por kg';

  @override
  String get glossaryCostPerKgDef => 'Todo lo que te costó producir cada kilo (establecimiento, mano de obra y gastos del período) dividido entre los kilos cosechados. Si vendes por debajo de este número, pierdes dinero.';

  @override
  String get glossaryPickupCostTerm => 'Costo de recogida por kg';

  @override
  String get glossaryPickupCostDef => 'Lo que pagas por recoger un kilo: jornales y recolección, sin contar lo invertido en plantar. Es el costo inmediato de cada cosecha.';

  @override
  String get glossaryEstablishmentTerm => 'Inversión de establecimiento';

  @override
  String get glossaryEstablishmentDef => 'Lo que invertiste para empezar el cultivo: plantines, abono inicial y la mano de obra de plantar. No es una pérdida, es una inversión que se recupera con las ventas.';

  @override
  String get glossaryPaybackTerm => 'Payback (recuperación)';

  @override
  String get glossaryPaybackDef => 'Cuánto te lleva recuperar lo invertido en establecimiento. 100% significa que ya lo pagaste por completo con lo que vendiste.';

  @override
  String get glossarySubtotalTerm => 'Subtotal';

  @override
  String get glossarySubtotalDef => 'Suma parcial de un grupo de filas antes del total general. En la nómina es lo que se le paga a cada trabajador antes del total del período.';

  @override
  String get glossaryYtdTerm => 'Año a la fecha (YTD)';

  @override
  String get glossaryYtdDef => 'Lo que va acumulado desde el 1 de enero de este año hasta hoy, sin importar en qué mes estés mirando.';

  @override
  String get glossaryPayrollTerm => 'Nómina del período';

  @override
  String get glossaryPayrollDef => 'Lo que se pagó por mano de obra en el período: personas, días trabajados y jornales. No incluye lo que inviertes en plantar.';

  @override
  String get glossaryCashBoxTerm => 'Caja menor';

  @override
  String get glossaryCashBoxDef => 'Dinero disponible para gastos pequeños del mes: transporte, herramientas e imprevistos. Se compara con el presupuesto que definiste para no pasarte.';

  @override
  String get glossarySoldVsHarvestedTerm => 'Vendido vs cosechado';

  @override
  String get glossarySoldVsHarvestedDef => 'Compara los kilos que vendiste con los que cosechaste en el mismo período. Si vendiste más, suele ser una cosecha de meses anteriores o una cosecha sin registrar.';

  @override
  String get glossaryMarginTooltip => '¿Qué significa margen?';

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
  String get cropFieldLabel => 'Cultivo o lote (opcional)';

  @override
  String get cropUnspecified => 'Sin especificar';

  @override
  String get cropNewOption => '+ Nueva variedad…';

  @override
  String get cropGroupHint => 'Toca «+ Nueva variedad…» para crear un cultivo nuevo; los que ya tienes están en la lista. Los movimientos del mismo cultivo se suman juntos en el reporte.';

  @override
  String get commonCosts => 'Costos comunes';

  @override
  String get commonCostsHint => 'Es un gasto de toda la finca (cerca, camino, luz). No afecta el costo/kg de ningún cultivo, pero sí el resultado total.';

  @override
  String get expenseSplitTitle => 'Repartir entre cultivos';

  @override
  String get expenseSplitBody => 'El gasto sirve a varios cultivos. Se guardan gastos separados, uno por cultivo, que suman el total.';

  @override
  String get expenseSplitHint => 'El gasto se reparte entre cultivos: se guardan gastos separados que suman el total.';

  @override
  String get expenseSplitUseAreas => 'Usar áreas';

  @override
  String expenseSplitSum(String percent) {
    return 'Suma: $percent %';
  }

  @override
  String get expenseSplitMustSum => 'Los porcentajes tienen que sumar 100 %.';

  @override
  String get expenseSplitZero => 'Cada cultivo elegido necesita un porcentaje mayor que 0.';

  @override
  String get expenseSplitFew => 'Elige al menos dos cultivos.';

  @override
  String get expenseSplitNoAreas => 'Para usar las áreas, al menos dos cultivos tienen que tener su hectáreaje anotado.';

  @override
  String expenseSplitChosen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Repartido entre $count cultivos',
      one: 'Repartido entre $count cultivo',
    );
    return '$_temp0';
  }

  @override
  String get expenseSplitChange => 'Cambiar';

  @override
  String get expenseSplitClear => 'Quitar reparto';

  @override
  String get expenseSplitNeedAmount => 'Primero escribe el monto del gasto.';

  @override
  String expenseSplitPercent(String percent) {
    return '$percent %';
  }

  @override
  String get noCropLabel => 'Sin cultivo';

  @override
  String get noCropHint => 'No pertenece a ningún cultivo. Se queda en el resultado general de la finca.';

  @override
  String loteNoRepartido(String name) {
    return '$name · sin repartir';
  }

  @override
  String get sowingCategoryHint => 'Si esto es para un cultivo, elige su nombre abajo: el gasto pasará a contar como su inversión y a salir en su costo/kg. Si el cultivo no existe, toca «+ Nueva variedad…».';

  @override
  String get harvestCategoryHint => 'Lo que cuesta la cosecha en sí: bolsas, insumos y mover el café. Si le pagaste a alguien por recoger, ese pago va en Mano de obra, no acá.';

  @override
  String get laborCategoryHint => 'Lo que pagas a las personas, aunque sea por cosechar, abonar o deshierbar. Aquí anotas quién trabajó y cuántos días.';

  @override
  String get seedsCategoryHint => 'Lo que se gasta durante la temporada: semillas, bolsas y demás insumos. Si son colinos o plantas para un cultivo, cámbiate a Siembra: ahí cuenta como inversión y sale en su costo/kg.';

  @override
  String get irrigationCategoryHint => 'El sistema que lleva agua al cultivo: bomba, goteo, tanque. La factura del agua va en Agua y la de la luz en Energía.';

  @override
  String get waterCategoryHint => 'El servicio de agua de la finca, igual que la luz. La factura es de acá; el sistema de riego —bomba, goteo, tanque— va en Riego.';

  @override
  String get deductionSwitchLabel => 'El comprador me descontó';

  @override
  String get deductionHint => 'En café no siempre se paga lo que se entrega: impureza, humedad o piedras.';

  @override
  String get deductionQtyLabel => 'Cantidad descontada';

  @override
  String get deductionQtyInvalid => 'Pon la cantidad que te descontaron';

  @override
  String get deductionReasonLabel => 'Motivo del descuento';

  @override
  String get deductionReasonHint => 'impureza, humedad, piedras…';

  @override
  String get deductionRegisteredLabel => 'Entregado';

  @override
  String get deductionDeductedLabel => 'Descontado';

  @override
  String get deductionPaidLabel => 'Pagado';

  @override
  String get deductionOverQuantity => 'Te descontaron más de lo que entregaste: revisa la cantidad.';

  @override
  String get paidStatusTitle => 'Estado de pago';

  @override
  String get paidStatusPaid => 'Pagado';

  @override
  String get paidStatusPending => 'Por cobrar';

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
  String get unitSaco => 'Sacos';

  @override
  String get unitLb => 'Libras (lb)';

  @override
  String get unitCarga => 'Cargas (27.2 kg)';

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
  String get sacoKgLabel => 'Peso de un saco (kg)';

  @override
  String get sacoKgHelper => 'Pasa los sacos a kilogramos en reportes, PDF y alertas. El estándar del café es 70.';

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
  String get excelColCurrency => 'Moneda';

  @override
  String get excelColBalance => 'Balance';

  @override
  String get excelMonthlyTitle => 'Ingresos y gastos por mes';

  @override
  String get excelCrossExpensesTitle => 'Gastos por categoría y cultivo';

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
  String get edit => 'Editar';

  @override
  String get add => 'Agregar';

  @override
  String get newCropDialogTitle => 'Nueva variedad';

  @override
  String get welcomeCompleteTitle => 'Completar cultivo';

  @override
  String get save => 'Guardar';

  @override
  String get cropNameLabel => 'Nombre del cultivo';

  @override
  String get cropNameRequired => 'Escribe el nombre del cultivo.';

  @override
  String get cropNameTaken => 'Ya hay un cultivo con ese nombre. Escribe otro.';

  @override
  String get newCropDuplicateTitle => 'Ya tienes un cultivo con ese nombre';

  @override
  String newCropDuplicateBody(String name) {
    return '«$name» ya está en tu lista de cultivos. ¿Qué prefieres hacer?';
  }

  @override
  String get newCropUseExisting => 'Usar el que ya tienes';

  @override
  String get newCropCreateAnother => 'Crear otro igual';

  @override
  String cropLotTag(int n) {
    return 'lote $n';
  }

  @override
  String get cropPhaseNoYield => 'aún no rinde · primera cosecha pendiente';

  @override
  String get sowingRenovacionCheckbox => 'Esta resiembra renovó el cultivo — cambiar su fase a renovación';

  @override
  String get sowingRestartCheckbox => 'Esta siembra arrancó el cultivo de nuevo — volver a «Sin dar» y borrar la fecha de la primera cosecha';

  @override
  String get sowingWhatHappensOldPlants => '¿Qué pasa con las matas que ya tienes?';

  @override
  String get sowingExpandOption => 'Amplío el cultivo: no reemplazo nada';

  @override
  String get sowingRenewOption => 'Renuevo una parte';

  @override
  String get sowingRenewHint => 'Las matas del lote viejo bajan y las nuevas suman. El total no se infla.';

  @override
  String get sowingReplaceCohortLabel => 'Lote que renuevo';

  @override
  String get sowingReplacePlantsLabel => 'Matas que reemplaza';

  @override
  String get sowingReplacePlantsRequired => 'Escribe cuántas matas reemplazas.';

  @override
  String sowingReplacePlantsPrefill(int plants, int live) {
    return 'Calculado por área: $plants de $live';
  }

  @override
  String get sowingReplaceNoArea => 'El lote viejo no tiene área: dime cuántas matas reemplazas.';

  @override
  String sowingReplaceAll(int live) {
    return 'Todas ($live)';
  }

  @override
  String sowingReplaceTooMany(int live) {
    return 'Ese lote tiene $live matas vivas: no puedes reemplazar más.';
  }

  @override
  String get sowingReplaceAreaLabel => 'Área que reemplaza (ha)';

  @override
  String sowingCohortOption(String date, int plants) {
    return '$date · $plants matas';
  }

  @override
  String sowingCohortDateOnly(String date) {
    return '$date';
  }

  @override
  String get sowingCohortLabel => 'Lote';

  @override
  String get sowingCohortNoneTitle => 'No hay un lote vivo';

  @override
  String get sowingCohortNoneBody => 'Este cultivo no tiene matas vivas donde reponer. Si estás arrancando de nuevo, anotalo como siembra.';

  @override
  String get sowingCohortNoneSaveAs => 'Anotar como siembra';

  @override
  String get sowingNoCohortTag => 'Sin lote';

  @override
  String sowingDeleteCohortBody(int total) {
    return 'Otra siembra le resta matas a este lote. Si lo borras, esos reemplazos dejan de aplicar y el total del cultivo queda en $total matas.';
  }

  @override
  String cohortsCount(int count) {
    return '$count edades';
  }

  @override
  String get cohortOpen => 'Abierta';

  @override
  String get cohortRenewed => 'Renovada';

  @override
  String cohortRenewedOn(String date) {
    return 'Renovada en $date';
  }

  @override
  String get cohortsHistoryTitle => 'Lotes renovados';

  @override
  String get cohortsAreaFallback => 'No todos los lotes tienen área: el área del cultivo es la que escribiste.';

  @override
  String cohortsAreaMismatch(String sum, String manual) {
    return 'Los lotes con área suman $sum ha; el cultivo dice $manual ha.';
  }

  @override
  String get cohortsNoLivingPlants => 'Este cultivo no tiene matas vivas.';

  @override
  String perHaAgesAverage(int count) {
    return 'promedio de $count edades';
  }

  @override
  String get sowingAreaMissingWarning => 'Sin área no se pueden ver los costos por hectárea. Puedes guardar igual.';

  @override
  String get cropSetupPrompt => 'Tu cultivo está listo para usar. ¿Quieres completar sus datos (fase, área, plantas, unidad)?';

  @override
  String get cropSetupComplete => 'Completar';

  @override
  String get cropSetupLater => 'Ahora no';

  @override
  String get deleteCropTitle => '¿Eliminar cultivo?';

  @override
  String deleteCropBody(int sowings, int harvests, String name) {
    return 'Se eliminarán las siembras ($sowings) y las cosechas ($harvests) de «$name». Los gastos y ventas se quedarán sin cultivo.';
  }

  @override
  String deleteCropBodyEmpty(Object name) {
    return '«$name» todavía no tiene siembras ni cosechas. Los gastos y ventas se quedarán sin cultivo.';
  }

  @override
  String get expenseGroupProduccion => 'Gastos de producción';

  @override
  String get expenseGroupVenta => 'Gastos de venta';

  @override
  String get expenseGroupFijos => 'Gastos fijos';

  @override
  String get expenseGroupOtros => 'Otros gastos';

  @override
  String get menuCrops => 'Cultivos';

  @override
  String get cropsEmpty => 'Aún no hay cultivos. Agrega el primero.';

  @override
  String get menuWorkers => 'Trabajadores';

  @override
  String get workersEmpty => 'Aún no hay trabajadores. Agrega el primero.';

  @override
  String get workerNewOption => '+ Nuevo trabajador…';

  @override
  String get newWorkerDialogTitle => 'Nuevo trabajador';

  @override
  String get editWorkerTitle => 'Editar trabajador';

  @override
  String get workerNameLabel => 'Nombre';

  @override
  String get workerNameRequired => 'Escribe el nombre del trabajador.';

  @override
  String get workerDayRateLabel => 'Valor por día (opcional)';

  @override
  String get workerDayRateShort => 'Valor por día';

  @override
  String get helpWorkerDayRate => 'Se autocompleta al registrar un jornal. Déjalo vacío si prefieres escribirlo cada vez.';

  @override
  String get workerConfirmDelete => 'Eliminar trabajador';

  @override
  String get workerDeleted => 'Trabajador eliminado';

  @override
  String get workerWorkedIn => 'Trabajó en';

  @override
  String get workerNoJornales => 'Sin jornales registrados';

  @override
  String get workerNoRate => 'Sin valor por día';

  @override
  String get jornalSectionTitle => 'Jornal';

  @override
  String get jornalWorkerLabel => 'Trabajador';

  @override
  String get jornalWorkerHint => 'Crea tus trabajadores en el menú ⋮ o elige «Otro nombre».';

  @override
  String get jornalWorkerRequired => 'Elige el trabajador.';

  @override
  String get jornalOtherNameOption => 'Otro nombre…';

  @override
  String get jornalCreateOption => 'Crear trabajador…';

  @override
  String get jornalDaysLabel => 'Días trabajados';

  @override
  String get jornalDaysRequired => 'Ingresa los días (entero mayor que 0).';

  @override
  String get jornalRateRequired => 'Ingresa el valor por día.';

  @override
  String get jornalTotalLabel => 'Total';

  @override
  String get jornalTotalHint => 'Se calcula: días × valor por día.';

  @override
  String get jornalHarvestedKgLabel => 'Kilos recolectados (opcional)';

  @override
  String get jornalHarvestedKgHelp => 'Para comparar lo cosechado con lo vendido.';

  @override
  String get jornalHarvestedKgNoCrop => 'Elige el cultivo para anotar los kilos.';

  @override
  String get jornalHarvestedKgInvalid => 'Ingresa los kilos recolectados (mayor que 0).';

  @override
  String get jornalHarvestedKgLotLabel => 'Lote de la cosecha (opcional)';

  @override
  String get jornalHarvestedKgLotNone => 'Sin lote';

  @override
  String jornalHarvestedKgLotRenewed(String date, int plants) {
    return '$date · $plants matas · renovado';
  }

  @override
  String get jornalHarvestedKgLotMissing => 'No elegiste lote: estos kilos quedan del cultivo y no se ven por lote. Puedes guardar así.';

  @override
  String cohortKgLabel(String kg) {
    return '$kg kg';
  }

  @override
  String cohortKgPerPlantLabel(String value) {
    return '$value kg/planta';
  }

  @override
  String get cashBoxLabel => 'Aporte mensual de caja';

  @override
  String get cashBoxHelp => 'Lo que sacas cada mes para la finca: cubre los jornales y los gastos chicos. Lo que no se gasta no se pierde, se arrastra al mes siguiente. El aporte rige desde este mes: los meses anteriores no se recalculan.';

  @override
  String get cashBoxCarry => 'Lo arrastrado de meses anteriores';

  @override
  String get cashBoxMonthly => 'Aporte del mes';

  @override
  String get cashBoxTitle => 'Caja menor';

  @override
  String cashBoxOf(String used, String total) {
    return '$used de $total';
  }

  @override
  String get cashBoxRemaining => 'Restante';

  @override
  String get cashBoxLabor => 'Jornales';

  @override
  String get cashBoxExtras => 'Extras';

  @override
  String get workBudgetTitle => 'Presupuesto de obra';

  @override
  String workBudgetOf(String used, String total) {
    return '$used de $total';
  }

  @override
  String get workBudgetRemaining => 'Restante';

  @override
  String get workBudgetBalance => 'Saldo de obra';

  @override
  String get taskFieldLabel => 'Qué labor';

  @override
  String get taskFieldHint => '¿Qué se hizo?';

  @override
  String get taskOtherOption => '✏️ Otra…';

  @override
  String get taskOtherLabel => 'Nombre de la labor';

  @override
  String get taskOtherHint => 'Escríbela como la digas';

  @override
  String get workSheetTitle => 'Planilla del mes';

  @override
  String get workSheetWorkers => 'personas';

  @override
  String get workSheetDayPlural => 'día';

  @override
  String get workSheetDayOther => 'días';

  @override
  String get workSheetUnlabeled => 'Sin labor';

  @override
  String get workSheetNoTasks => 'Todavía no anotaste labores en un jornal. Cuando registres uno, elige «Qué labor» y va a salir aquí.';

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
  String get segWeek => 'Semana';

  @override
  String reportPeriodWeek(int week, int year) {
    return 'Semana $week, $year';
  }

  @override
  String reportChipWeek(int week) {
    return 'Sem $week';
  }

  @override
  String get harvestCargasLabel => 'cargas';

  @override
  String get harvestCargasNote => '1 carga ≈ 60 lbs ≈ 27.2 kg';

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
  String comparisonTitle(String previous) {
    return 'Comparado con $previous';
  }

  @override
  String comparisonFromTo(String before, String after) {
    return 'de $before a $after';
  }

  @override
  String get comparisonPreviousWeek => 'la semana anterior';

  @override
  String get comparisonPreviousMonth => 'el mes anterior';

  @override
  String get comparisonPreviousYear => 'el año anterior';

  @override
  String get comparisonPreviousSameStretch => 'el mismo tramo del año anterior';

  @override
  String get comparisonPreviousColumn => 'Anterior';

  @override
  String get comparisonCurrentColumn => 'Actual';

  @override
  String get comparisonChangeColumn => 'Cambio';

  @override
  String get metricMarginGood => 'Buen margen: te quedan \$20 o más de cada \$100 vendidos.';

  @override
  String get metricMarginFair => 'Margen justo: te quedan entre \$10 y \$20 de cada \$100 vendidos.';

  @override
  String get metricMarginLow => 'Margen bajo: te quedan menos de \$10 de cada \$100 vendidos.';

  @override
  String get metricMarginLoss => 'Pérdida: los gastos son mayores a lo que vendiste.';

  @override
  String get metricMarginBreakEven => 'Sin ganancia ni pérdida: los gastos cubren justo lo vendido.';

  @override
  String get metricNoSales => 'Sin ventas en el período: no se puede calcular.';

  @override
  String get metricRatioHealthy => 'Buen control: de cada \$100 que entran, hasta \$70 se van en gastos.';

  @override
  String get metricRatioHigh => 'Gastas bastante: de cada \$100 que entran, entre \$70 y \$90 se van en gastos.';

  @override
  String get metricRatioCritical => 'Gastas casi todo lo que entra: más de \$90 de cada \$100 se van en gastos.';

  @override
  String get metricCostPriceLabel => 'Precio de venta por kilo';

  @override
  String get metricMarginPerKgLabel => 'Margen por kilo';

  @override
  String get metricMarginPerKgGood => 'Vendes por encima de lo que te costó producirlo.';

  @override
  String get metricMarginPerKgBad => 'Vendes por debajo de lo que te costó producirlo: cada kilo vendido resta.';

  @override
  String get metricMarginPerKgZero => 'Vendes a costo: ni ganas ni pierdes por kilo.';

  @override
  String get metricReceivablesLabel => 'Ventas por cobrar';

  @override
  String get metricReceivablesNote => 'Todavía no te lo han pagado: ese dinero no está en la caja.';

  @override
  String get metricLaborShareLabel => 'Mano de obra sobre el gasto';

  @override
  String get metricLaborShareNote => 'Es la parte de todo lo que gastaste en el periodo que se fue en mano de obra.';

  @override
  String metricCostPriceAbove(String cost) {
    return 'Te cuesta $cost por kilo. Vendes por encima de tu costo.';
  }

  @override
  String metricCostPriceBelow(String cost) {
    return 'Te cuesta $cost por kilo. Vendes por debajo de tu costo: cada kilo vendido resta.';
  }

  @override
  String metricCostPriceEqual(String cost) {
    return 'Te cuesta $cost por kilo y vendes a ese mismo precio: ni ganas ni pierdes.';
  }

  @override
  String get metricCostPriceNoCost => 'No cosechaste en el período: todavía no hay costo por kilo que comparar.';

  @override
  String metricCostPriceNoQty(String cost) {
    return 'Te cuesta $cost por kilo, pero tus ventas no anotan kilos: no se puede comparar.';
  }

  @override
  String cropBreakdownTitle(String period) {
    return 'Desglose por cultivo — $period';
  }

  @override
  String get cropBreakdownSummaryG => 'Gastos';

  @override
  String get cropBreakdownInvestment => 'Inversión inicial';

  @override
  String get cropBreakdownOperation => 'Operación del período';

  @override
  String get cropBreakdownSummaryI => 'Ingresos';

  @override
  String get cropBreakdownSummaryR => 'Resultado';

  @override
  String cropMarginBadge(String value) {
    return 'Margen $value';
  }

  @override
  String get cropBreakdownMarginHint => 'Cómo leer el margen: es el porcentaje de lo que vendes que te queda después de cubrir los gastos. Ej.: si vendes 100 y gastas 40, el margen es 60%.';

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
  String get exportNeedsNetworkOnce => 'La primera vez hay que estar conectado para preparar la exportación. Revisa la conexión y reintenta.';

  @override
  String pdfShareSubject(int year) {
    return 'Mi Cafetal — Reporte $year';
  }

  @override
  String get farmNameLabel => 'Nombre de la finca';

  @override
  String get currencyLabel => 'Moneda';

  @override
  String get currencyDisplayLabel => 'Moneda';

  @override
  String get currencyDisplayHelper => 'Única moneda de tu cuenta y de todos tus registros.';

  @override
  String get currencyLockedHelper => 'Elegiste esta moneda al empezar y no puede cambiarse, para que todos tus montos coincidan siempre.';

  @override
  String get currencyGateTitle => '¿En qué moneda manejas tus cuentas?';

  @override
  String get currencyGateBody => 'Esta será la única moneda de tu cuenta y no podrá cambiarse después.';

  @override
  String currencyGateCta(String currency) {
    return 'Empezar con $currency';
  }

  @override
  String get currencyGateRequired => 'Necesitas elegir una moneda para poder registrar tus primeros datos.';

  @override
  String currencyRegisterHint(String currency) {
    return 'Se registra en $currency.';
  }

  @override
  String currencyMixedHint(int count) {
    return 'Se muestra en $count monedas';
  }

  @override
  String cropMixedCurrencyNote(int count) {
    return 'Este cultivo está en $count monedas: cada moneda va por separado y no se calcula el margen.';
  }

  @override
  String currencyMixedByCurrencyNote(int count) {
    return 'En $count monedas: cada monto sale con su moneda; no se suman ni se comparan entre sí.';
  }

  @override
  String currencyConvertedTotal(String currency, String amount) {
    return 'Total en $currency: $amount';
  }

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
    return 'Moneda de reportes cambiada a $currency. Los montos que ya registraste siguen guardados en la moneda en que los anotaste; ahora los totales se muestran en $currency.';
  }

  @override
  String get currencyRateNote => 'Total al cambio de hoy. Cada movimiento sigue guardado en su propia moneda.';

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
    return 'Resultado del período: $spent en gastos y ninguna venta en este período.';
  }

  @override
  String insightBalancePositive(Object balance, Object margin) {
    return 'Resultado del período: ganancia de $balance con $margin de margen sobre las ventas.';
  }

  @override
  String insightBalanceNegative(Object loss, Object margin) {
    return 'Resultado del período: pérdida de $loss con margen de $margin sobre las ventas.';
  }

  @override
  String insightVsPrev(String month, String incChange, String expChange) {
    return 'Frente a $month: ventas $incChange y gastos $expChange.';
  }

  @override
  String insightVsPrevPartial(String month, String incChange, String expChange) {
    return 'Frente a $month (mismos días): ventas $incChange y gastos $expChange.';
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
  String insightTopExpense(String category, String amount, String pct) {
    return 'Tu mayor gasto fue $category ($amount, el $pct del total).';
  }

  @override
  String insightTopExpenseDependency(Object category) {
    return 'Concentras más de la mitad de tus gastos en $category: revisa ese costo recurrente antes de que siga creciendo.';
  }

  @override
  String insightTopIncome(String category, String amount, String pct) {
    return 'Tu mejor ingreso fue $category ($amount, el $pct del total).';
  }

  @override
  String insightLowPrice(String recent, String history) {
    return 'Vendes más barato que tu histórico: promedio reciente $recent vs $history por kilo. Revisa precio, presentación o canal de venta.';
  }

  @override
  String insightBestMonth(String salesMonth, String salesAmount, String costMonth, String costAmount) {
    return 'Tu mejor mes de ventas fue $salesMonth ($salesAmount); tu menor gasto mensual fue $costMonth ($costAmount).';
  }

  @override
  String chartTitle(int year) {
    return 'Gastos vs ingresos — $year';
  }

  @override
  String chartCumulativeTitle(int year) {
    return 'Tu dinero en $year — acumulado';
  }

  @override
  String get chartCumulativeSubtitle => 'Ingresos menos gastos, mes a mes. Toca un punto para ver cuánto llevabas.';

  @override
  String get chartStartLabel => 'como empezaste';

  @override
  String chartAccumDelta(String amount) {
    return '$amount desde el 1 de enero';
  }

  @override
  String chartCumulativeEmpty(int year) {
    return 'Aún no hay movimientos en $year.';
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
    return 'El problema: hay $spent en gastos y ninguna venta, así que el balance está en pérdida.';
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
    return 'El problema: en los últimos 30 días vendes a $recentAvg por kilo, por debajo de tu promedio histórico de $histAvg por kilo.';
  }

  @override
  String get alertLowPriceSuggestion => 'Compara precios con otros compradores y evalúa esperar un mejor momento para vender parte de la cosecha.';

  @override
  String get alertLowPriceManualTitle => 'Vendiste café por debajo de tu precio mínimo';

  @override
  String alertLowPriceManualMessage(String date, String price, String threshold) {
    return 'El $date vendiste a $price por kg, por debajo de tu precio mínimo de $threshold. Considera negociar un mejor precio o esperar.';
  }

  @override
  String get alertDeficitNoCropTitle => 'Gastos sin cultivo asignado no se recuperan';

  @override
  String alertDeficitNoCropMessage(String count, String spent, String sold, String recovery) {
    return 'El problema: tienes $count registros sin cultivo asignado que suman $spent en gastos y $sold en ventas (solo has recuperado el $recovery de lo invertido).';
  }

  @override
  String alertDeficitNoCropSuggestion(Object count) {
    return 'Edita esos $count registros y asígnales su cultivo (Café, Plátano…) para que su costo cuente en el cultivo correcto, y esta alerta desaparecerá.';
  }

  @override
  String alertDeficitTitle(String crop) {
    return '$crop está perdiendo dinero';
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
  String get pdfMarginFootnote => 'Margen = (Ingresos − Gastos) / Ingresos. Un margen negativo sugiere revisar el cultivo.';

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
  String get pdfColMargin => 'Margen';

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
  String get excelSheetPayrollCash => 'Nómina y caja';

  @override
  String get excelTotalIncomes => 'Total ingresos';

  @override
  String get excelTotalExpenses => 'Total gastos';

  @override
  String get excelTotalResult => 'Resultado';

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
  String balanceMixedCurrencyNote(int count) {
    return 'Este año tienes movimientos en $count monedas: la utilidad va moneda por moneda y no se calculan los totales del balance, porque sumar monedas distintas daría una cifra falsa.';
  }

  @override
  String get catSiembra => 'Siembra';

  @override
  String get catCercasPreparacion => 'Cercas y preparación';

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
  String get catEnergia => 'Energía';

  @override
  String get catAgua => 'Agua';

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
  String get catCreditoIntereses => 'Crédito e intereses';

  @override
  String get catSeguros => 'Seguros';

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
  String get catVenta => 'Venta';

  @override
  String catVentaCrop(String crop) {
    return 'Venta $crop';
  }

  @override
  String alertCropEstablishmentTitle(String crop) {
    return '$crop todavía no da: es inversión, no pérdida';
  }

  @override
  String alertCropEstablishmentMessage(String investment, String crop) {
    return 'El problema: llevas $investment invertidos en $crop y aún no hay ingresos. Es normal en esta etapa: el plantío está creciendo y la primera cosecha llega al pasar a Dando.';
  }

  @override
  String alertCropEstablishmentSuggestion(String crop) {
    return 'Sigue registrando los gastos de $crop. Cuando el cultivo pase a Dando, la app evaluará su rentabilidad normal.';
  }

  @override
  String alertHarvestVsSalesTitle(String crop) {
    return 'Vendiste más de lo que cosechaste en $crop';
  }

  @override
  String alertHarvestVsSalesMessage(String soldKg, String crop, String harvestedKg) {
    return 'El problema: en los últimos 12 meses vendiste $soldKg de $crop, pero solo registraste $harvestedKg de cosecha. Revisa si te faltó registrar alguna cosecha o si usaste la misma unidad en la cosecha y en la venta.';
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
  String alertFirstHarvestTitle(String crop) {
    return '$crop ya debería estar rindiendo';
  }

  @override
  String alertFirstHarvestMessage(String crop, String date) {
    return 'Estimaste la primera cosecha de $crop para el $date y hasta ahora no registraste ninguna cosecha.';
  }

  @override
  String get alertFirstHarvestSuggestion => 'Revisa el cultivo: si cambió algo o la fecha ya no va, edítala. Si ya vendiste, anota esa venta con los kilos y el dinero que te pagaron: con esos kilos la app ya sabe que cosechaste y este aviso desaparece.';

  @override
  String get alertMissingQtyTitle => 'Tienes ventas sin kilos registrados';

  @override
  String alertMissingQtyMessage(int count) {
    return 'El problema: en los últimos 90 días registraste $count ventas sin la cantidad vendida. Sin ese dato, la app no puede calcular tu precio por kilo ni tu rentabilidad.';
  }

  @override
  String get alertMissingQtySuggestion => 'Edita esas ventas e ingresa los kilos vendidos. Así tus informes de precio y rentabilidad serán confiables.';

  @override
  String get alertUnpaidTitle => 'Hay ventas por cobrar';

  @override
  String alertUnpaidMessage(int count, String amount, int days) {
    return 'El problema: $count ventas suman $amount que todavía no te pagaron, la más vieja con $days días.';
  }

  @override
  String get alertUnpaidSuggestion => 'Cobra antes de que se pase: cuando el dinero entre, edita la venta y cambia su estado a «Pagado».';

  @override
  String alertCashBoxWarningTitle(String month, String percent) {
    return 'La caja menor de $month está al $percent';
  }

  @override
  String alertCashBoxWarningMessage(String used, String total, String remaining) {
    return 'El problema: este mes llevas $used de $total en jornales y extras. Te quedan $remaining antes de agotarla.';
  }

  @override
  String get alertCashBoxWarningSuggestion => 'Revisa los gastos extras y deja solo lo necesario hasta cerrar el mes.';

  @override
  String alertCashBoxDangerTitle(String month) {
    return 'Caja menor agotada en $month';
  }

  @override
  String alertCashBoxDangerMessage(String used, String total, String percent) {
    return 'El problema: este mes llevas $used de $total en jornales y extras ($percent). Ya no queda presupuesto disponible.';
  }

  @override
  String get alertCashBoxDangerSuggestion => 'Revisa los gastos extras y considera reducir trabajadores este mes.';

  @override
  String alertCashBoxDebtMessage(String used, String carry) {
    return 'El problema: este mes llevas $used en jornales y extras, y la caja cerró los meses anteriores en números rojos: el arrastre está en $carry.';
  }

  @override
  String get backupSectionTitle => 'Respaldo';

  @override
  String get backupSectionSubtitle => 'Guarda todos los datos de tu finca en un archivo y vuelve a cargarlos cuando quieras.';

  @override
  String get backupExport => 'Exportar respaldo';

  @override
  String get backupRestore => 'Restaurar respaldo';

  @override
  String get backupShareSubject => 'Mi Cafetal — Respaldo de datos';

  @override
  String get backupExportDoneMsg => 'Respaldo listo para compartir.';

  @override
  String get backupConfirmTitle => '¿Restaurar este respaldo?';

  @override
  String backupConfirmMessage(String counts) {
    return 'Se añadirá: $counts. Lo que ya tengas se conserva tal cual; nada se borra.';
  }

  @override
  String get backupConfirmAccept => 'Restaurar';

  @override
  String get backupAccountDiffers => 'Aviso: este respaldo viene de otra cuenta. Sus datos se sumarán a los que ya tienes aquí.';

  @override
  String backupCountCrops(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cultivos',
      one: '$count cultivo',
    );
    return '$_temp0';
  }

  @override
  String backupCountSowings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count siembras',
      one: '$count siembra',
    );
    return '$_temp0';
  }

  @override
  String backupCountHarvests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cosechas',
      one: '$count cosecha',
    );
    return '$_temp0';
  }

  @override
  String backupCountEmployees(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trabajadores',
      one: '$count trabajador',
    );
    return '$_temp0';
  }

  @override
  String backupSummary(int added, int existing) {
    return 'Respaldo restaurado: $added añadidos y $existing que ya tenías.';
  }

  @override
  String backupOrphans(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count datos quedaron sin enlazar con su cultivo o cosecha',
      one: '$count dato quedó sin enlazar con su cultivo o cosecha',
    );
    return '$_temp0';
  }

  @override
  String get backupInvalidFile => 'Ese archivo no es un respaldo válido.';

  @override
  String get backupUnknownFormat => 'Ese archivo no es un respaldo de Mi Cafetal.';

  @override
  String get backupUnsupportedVersion => 'Este respaldo se hizo con una versión más nueva de la app. Actualiza la app para restaurarlo.';

  @override
  String get backupRestoreError => 'No se pudo restaurar el respaldo. Inténtalo de nuevo.';

  @override
  String get terrenosSection => 'Tus terrenos';

  @override
  String get terrenoNew => 'Nuevo terreno';

  @override
  String get terrenoEdit => 'Editar terreno';

  @override
  String get terrenoDelete => 'Eliminar terreno';

  @override
  String get terrenoNameLabel => 'Nombre del terreno';

  @override
  String get terrenoAreaLabel => 'Hectáreas del terreno';

  @override
  String get helpTerrenoArea => 'Opcional. Solo si las has medido; si no, déjalo vacío.';

  @override
  String get terrenoCropsLabel => '¿Qué cultivos van aquí?';

  @override
  String get helpTerrenoCrops => 'Marca los que quieras poner en este terreno. Un mismo terreno puede tener café, plátano y sombra a la vez.';

  @override
  String get terrenoCropsEmpty => 'Todavía no tienes cultivos. Puedes crear el terreno y asignarlos después.';

  @override
  String get terrenoNameRequired => 'Ponle nombre al terreno.';

  @override
  String get terrenoNameTaken => 'Ya hay un terreno con ese nombre.';

  @override
  String get terrenoAreaInvalid => 'Ese número de hectáreas no se puede leer.';

  @override
  String get terrenoLocationSection => 'Ubicación del lote';

  @override
  String get terrenoLocationButton => 'Tomar mi ubicación';

  @override
  String get terrenoLocationHelper => 'El punto donde está el lote. Tómalo desde el celular o escríbelo a mano. La app no lo vuelve a medir sola: mover la tierra sin avisar sería inventar datos.';

  @override
  String get terrenoLatLabel => 'Latitud';

  @override
  String get terrenoLngLabel => 'Longitud';

  @override
  String terrenoLocationDate(Object date) {
    return 'Registrado el $date';
  }

  @override
  String get terrenoLocationInvalid => 'La latitud va de -90 a 90 y la longitud de -180 a 180.';

  @override
  String get terrenoLocationHalf => 'Las dos coordenadas deben ir juntas: una sola no dice dónde está nada.';

  @override
  String get terrenoLocationFailed => 'No pude tomar la ubicación. Escríbela a mano o inténtalo de nuevo.';

  @override
  String get reportTerrenosTitle => 'Tus terrenos · ubicación';

  @override
  String get reportTerrenosHint => 'La coordenada de cada lote, tal como la registraste. No se vuelve a medir sola.';

  @override
  String get associatedCropsCostTitle => 'Costos entre cultivos asociados';

  @override
  String get associatedCropsCostNote => 'Varios cultivos comparten el mismo terreno: un mismo jornal o la misma bolsa de abono pueden servir a varios. Ese gasto se reparte entre ellos por hectáreas; si a alguno le falta la superficie, sale aparte. Por eso el costo de cada cultivo es una aproximación. El total de la finca sí cuadra.';

  @override
  String terrenoCropCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cultivos',
      one: '$count cultivo',
    );
    return '$_temp0';
  }

  @override
  String terrenoAreaAssigned(String assigned, String total) {
    return '$assigned de $total ha asignadas';
  }

  @override
  String terrenoAreaOver(String assigned, String total) {
    return 'Las áreas suman $assigned ha y el terreno tiene $total';
  }

  @override
  String terrenoAreaWithoutArea(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cultivos sin área',
      one: '$count cultivo sin área',
    );
    return '$_temp0';
  }

  @override
  String cropAreaShareHelp(String terreno, String assigned, String total) {
    return 'En $terreno: $assigned de $total ha asignadas';
  }

  @override
  String get deleteTerrenoTitle => '¿Eliminar el terreno?';

  @override
  String deleteTerrenoBody(String name) {
    return 'Se eliminará «$name». Tus cultivos no se borran: solo quedan sin terreno.';
  }

  @override
  String get cropTerrenoLabel => '¿En qué terreno está?';

  @override
  String get cropTerrenoNone => 'Sin terreno';

  @override
  String get helpCropTerreno => 'El terreno donde está plantado. Puedes dejarlo vacío.';

  @override
  String get terrenoGroupLabel => 'Lotes';

  @override
  String get terrenoGroupHint => 'El gasto sirve a varios cultivos del mismo lote, como una limpieza compartida. Se reparte entre ellos por hectáreas; si a alguno le falta la superficie, sale aparte.';
}
