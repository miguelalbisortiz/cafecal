import '../models/categories.dart';
import '../models/crop.dart';
import '../models/harvest.dart';
import '../models/transaction.dart';
import '../models/units.dart';
import 'derived_harvests.dart';

/// Fecha de la primera cosecha del cultivo, o `null` si todavía no dio nada.
///
/// Es el corte de C9: antes de esa fecha el cultivo se estaba estableciendo.
DateTime? firstHarvestDateOf(Iterable<Harvest> harvests, String? cropId) {
  if (cropId == null) return null;
  DateTime? first;
  for (final h in harvests) {
    if (h.cropId != cropId) continue;
    if (first == null || h.date.isBefore(first)) first = h.date;
  }
  return first;
}

/// Corte de C9 para una fila del desglose de Reportes.
///
/// - **fila de cultivo** → la primera cosecha de ese cultivo;
/// - **fila de lote** (gasto de un terreno que no se pudo repartir) → la
///   primera cosecha **más temprana entre los cultivos del lote**. Si el lote
///   ya sirve a un cultivo que produce, sus cercas son mantenimiento: no se
///   puede decir «este lote se está estableciendo» mientras adentro hay un
///   cafetal cosechando;
/// - **sin cultivo ni lote** («Costos comunes») → `null`, que deja las cercas
///   como inversión (no hay contra qué cortar).
DateTime? establishmentCutForRow({
  required String? cropId,
  required String? terrenoId,
  required List<Crop> crops,
  required Iterable<Harvest> harvests,
}) {
  if (cropId != null) return firstHarvestDateOf(harvests, cropId);
  if (terrenoId == null) return null;
  DateTime? first;
  for (final c in crops) {
    if (c.terrenoId != terrenoId) continue;
    final d = firstHarvestDateOf(harvests, c.id);
    if (d != null && (first == null || d.isBefore(first))) first = d;
  }
  return first;
}

/// ¿Este gasto entra a los ratios de operación (costo por kilo y por
/// hectárea)?
///
/// Todo menos el bloque de **inversión en equipo**: comprar una despulpadora
/// no encarece el kilo de este mes. Sigue contando en el total de gastos y en
/// su bloque; solo queda fuera del ratio, que es de operación.
bool isOperationExpense(Transaction t) =>
    expenseGroupOf(t.category) != ExpenseGroup.inversion;

/// Suma de los gastos de operación (sin el bloque de inversión en equipo).
///
/// Es lo que va al numerador del costo por kilo del estado de resultados.
/// Los borrados no cuentan y los ingresos tampoco.
double operationExpenseTotal(Iterable<Transaction> txs) {
  double total = 0;
  for (final t in txs) {
    if (t.deleted || !t.type.isExpense) continue;
    if (!isOperationExpense(t)) continue;
    total += t.amount;
  }
  return total;
}

/// ¿Este gasto es inversión de establecimiento del cultivo?
///
/// Dos caminos:
/// - **siembra**, por categoría ([kExpenseCategorySowing]) o por traer
///   `sowingId` anotado;
/// - **cercas y preparación antes de la primera cosecha** (C9). Después de la
///   primera cosecha, arreglar una cerca es mantenimiento y va a operación:
///   el mismo gasto no significa lo mismo en un cafetal que se está armando
///   que en uno que ya produce. Sin primera cosecha conocida, todas las cercas
///   siguen siendo de establecimiento.
bool isEstablishmentExpense(Transaction t,
    {DateTime? firstHarvestDate}) {
  if (t.category == kExpenseCategorySowing || t.sowingId != null) return true;
  if (t.category != kExpenseCategoryFences) return false;
  return firstHarvestDate == null || !t.date.isAfter(firstHarvestDate);
}

/// Kilos de una cosecha, o 0 si falta el peso convertible.
///
/// Extraída de `ReportHarvestMetrics._kgOf` para que el stock sin vender use
/// **exactamente** la misma conversión que la tarjeta «Cosechas»: un racimo o
/// un cajón sin peso no suma (nunca 1 kg por unidad).
double harvestKg(Harvest h, {double sacoKg = kSacoKgPorDefecto}) =>
    kgFromUnit(h.amount, h.unit, h.equivalentKg, sacoKg: sacoKg) ?? 0;

/// Métricas de cosecha para la sección "Cosechas" del reporte.
/// Funciones puras sobre datos locales (testables sin UI).
class ReportHarvestMetrics {
  /// [sacoKg] · peso real del saco en kg (A2). La norma dice 70, en la finca
  /// puede ser 60, y de aquí sale el kg de cada cosecha. Ver
  /// `FarmSettings.sacoKg`.
  const ReportHarvestMetrics({this.sacoKg = kSacoKgPorDefecto});

  final double sacoKg;

  /// Kilos de una cosecha, o 0 si falta el peso.
  ///
  /// Un racimo o un cajón sin peso **no suma** (D2): la lista de «sin peso»
  /// los cuenta aparte para completarlos. Nunca 1 kg por unidad.
  double _kgOf(Harvest h) => harvestKg(h, sacoKg: sacoKg);

  /// Total cosechado por cultivo, en su unidad original y normalizado a kg.
  /// [harvests] ya debe estar filtrado al rango de fechas del reporte.
  List<CropHarvestTotal> totalsByCrop(List<Harvest> harvests,
      List<Crop> crops) {
    final nameById = {for (final c in crops) c.id: c.name};
    final acc = <String, _Acc>{};
    for (final h in harvests) {
      final key = h.cropId ?? '';
      final a = acc.putIfAbsent(
          key,
          () => _Acc(
              name: h.cropId == null
                  ? 'Sin cultivo'
                  : (nameById[h.cropId] ?? h.cropId!),
              unit: h.unit));
      a.amount += h.amount;
      a.kg += _kgOf(h);
    }
    final out = acc.entries
        .map((e) => CropHarvestTotal(
              cropId: e.key == '' ? null : e.key,
              name: e.value.name,
              unit: e.value.unit,
              amount: e.value.amount,
              kg: e.value.kg,
            ))
        .toList();
    out.sort((a, b) => b.kg.compareTo(a.kg));
    return out;
  }

  Map<HarvestDestination, double> totalsByDestination(List<Harvest> harvests) {
    final acc = <HarvestDestination, double>{};
    for (final h in harvests) {
      acc[h.destination] = (acc[h.destination] ?? 0) + h.amount;
    }
    return acc;
  }

  /// Costo de recogida por kg: lo que costó recoger ÷ kg cosechados.
  ///
  /// El numerador son los gastos con lazo a una cosecha (`harvestId`) **más**
  /// la mano de obra de «Cosechar» con kilos medidos: en la finca se cosecha
  /// con jornaleros, y ese jornal es costo de recogida aunque no traiga el
  /// lazo. Cada movimiento cuenta una sola vez.
  ///
  /// Devuelve **null** si no hay ningún gasto de recogida (nunca un 0 que se
  /// lea como «cosechar fue gratis») y si los gastos que lo componen están en
  /// más de una moneda: dividir pesos y dólares entre los mismos kilos daría
  /// un costo por kilo falso. Llama a [pickupCostCurrencies] para saber si
  /// toca mostrar un guion en vez de omitir la fila.
  double? pickupCostPerKg(
      List<Transaction> transactions, List<Harvest> harvests) {
    double kg = 0;
    for (final h in harvests) {
      kg += _kgOf(h);
    }
    if (kg <= 0) return null;

    double pickup = 0;
    var hay = false;
    for (final t in _pickupCosts(transactions)) {
      pickup += t.amount;
      hay = true;
    }
    if (!hay) return null;
    if (pickupCostCurrencies(transactions).length > 1) return null;
    return pickup / kg;
  }

  /// Los gastos que forman el costo de recogida, sin repetir ninguno.
  ///
  /// Un gasto con `harvestId` y que además cumpla el predicado del jornal
  /// medido entra una sola vez: el id es la clave.
  Iterable<Transaction> _pickupCosts(List<Transaction> transactions) sync* {
    final vistos = <String>{};
    for (final t in transactions) {
      if (t.deleted || !t.type.isExpense) continue;
      if (t.harvestId == null && !isMeasuredHarvestJornal(t)) continue;
      if (!vistos.add(t.id)) continue;
      yield t;
    }
  }

  /// Monedas de los gastos de recogida (los que forman el costo por kg).
  Set<String> pickupCostCurrencies(List<Transaction> transactions) {
    final out = <String>{};
    for (final t in _pickupCosts(transactions)) {
      out.add(t.currency);
    }
    return out;
  }

  /// Monedas de los montos que suman [totalCostPerKg] y
  /// [accumulatedInvestment] de un cultivo.
  Set<String> cropAmountCurrencies(List<Transaction> cropRecords) {
    final out = <String>{};
    for (final t in cropRecords) {
      if (t.deleted) continue;
      out.add(t.currency);
    }
    return out;
  }

  /// Costo total por kg: gastos del cultivo ÷ kg cosechados (solo producción).
  /// Para establecimiento devuelve null (se muestra la inversión acumulada).
  ///
  /// También devuelve null si los montos del cultivo mezclan monedas: el
  /// costo por kilo solo es válido cuando todos los montos que lo componen
  /// son de una sola moneda.
  double? totalCostPerKg(Crop crop, List<Transaction> cropExpenses,
      List<Harvest> cropHarvests) {
    if (crop.cycle == CropCycle.anual ||
        crop.phase == CropPhase.produccion) {
      double kg = 0;
      for (final h in cropHarvests) {
        kg += _kgOf(h);
      }
      if (kg <= 0) return null;
      // Monedas del ratio: solo las de los gastos que suman. Un equipo
      // comprado en otra moneda no lo vuelve incomparable (C10).
      final operationExpenses =
          cropExpenses.where(isOperationExpense).toList();
      if (cropAmountCurrencies(operationExpenses).length > 1) return null;
      double cost = 0;
      for (final t in operationExpenses) {
        cost += t.amount;
      }
      return cost / kg;
    }
    return null;
  }

  /// Inversión acumulada del cultivo (para fase establecimiento/renovación).
  ///
  /// Es una suma simple de los montos: si [cropRecords] mezcla monedas el
  /// número cruza monedas distintas y **no se puede imprimir**. Usa
  /// [cropAmountCurrencies] para decidirlo y, con mezcla, lista los montos
  /// moneda por moneda en vez de esta cifra.
  double accumulatedInvestment(List<Transaction> cropExpenses) {
    double cost = 0;
    for (final t in cropExpenses) {
      cost += t.amount;
    }
    return cost;
  }

  /// Separa los gastos de un cultivo en **inversión inicial** y **operación
  /// del período** (la separación estándar de Cenicafé: costos de
  /// establecimiento vs costos de operación).
  ///
  /// Tres cestas, sin solaparse:
  /// - **inversión inicial** ([isEstablishmentExpense]): siembra, o
  ///   cercas/preparación de **antes de la primera cosecha**
  ///   ([firstHarvestDate]; sin cosecha, todo cuenta);
  /// - **operación del período** ([isOperationExpense]): lo que cuesta
  ///   producir este período;
  /// - **inversión en equipo**: lo que no es ninguna de las dos, es decir el
  ///   bloque de capital (comprar una despulpadora no encarece el kilo).
  ///
  /// Los borrados (`t.deleted`) no cuentan. Es una partición exacta: las tres
  /// cestas siempre suman el total de gastos, sin duplicar ni perder montos.
  CropExpenseSplit splitInvestmentAndOperation(
      List<Transaction> cropExpenses,
      {DateTime? firstHarvestDate}) {
    double investment = 0;
    double equipment = 0;
    double operation = 0;
    for (final t in cropExpenses) {
      if (t.deleted) continue;
      if (isEstablishmentExpense(t, firstHarvestDate: firstHarvestDate)) {
        investment += t.amount;
      } else if (isOperationExpense(t)) {
        operation += t.amount;
      } else {
        // Ni establecimiento ni operación: el bloque de inversión en equipo.
        equipment += t.amount;
      }
    }
    return CropExpenseSplit(
        investment: investment, equipment: equipment, operation: operation);
  }

  /// Reparto de una fila del desglose con el corte de C9 que le toca
  /// ([establishmentCutForRow]): el mismo en pantalla, PDF y Excel.
  CropExpenseSplit splitForRow({
    required List<Transaction> expenseTxs,
    required String? cropId,
    required String? terrenoId,
    required List<Crop> crops,
    required Iterable<Harvest> harvests,
  }) {
    return splitInvestmentAndOperation(
      expenseTxs,
      firstHarvestDate: establishmentCutForRow(
        cropId: cropId,
        terrenoId: terrenoId,
        crops: crops,
        harvests: harvests,
      ),
    );
  }

  /// Costo por kilo cosechado en el período: gastos ÷ kg cosechados.
  ///
  /// Es el mismo criterio que [totalCostPerKg], pero sin pedir cultivo ni fase,
  /// porque la línea del estado de resultados mira el período entero. Devuelve
  /// null si no se cosechó nada: un 0 fabricado invitaría a compararlo con un
  /// precio que no significa nada.
  double? periodCostPerKg(double expenses, List<Harvest> harvests) {
    double kg = 0;
    for (final h in harvests) {
      kg += _kgOf(h);
    }
    return kg > 0 ? expenses / kg : null;
  }

  /// Precio promedio de venta por kilo: ingresos ÷ kilos vendidos.
  ///
  /// Solo cuenta las ventas que **anotaron cantidad**. Si nadie anotó kilos,
  /// devuelve null: un precio promedio inventado es peor que no mostrar ninguno
  /// (es el mismo hueco que ya detecta la regla de alertas por precio bajo).
  double? avgSalePricePerKg(List<Transaction> records) {
    double kg = 0;
    double money = 0;
    for (final t in records) {
      if (t.deleted || t.type.isExpense) continue;
      final qty = t.quantity ?? 0;
      if (qty <= 0) continue;
      final qtKg = kgFromUnit(qty, t.unit, t.equivalentKg, sacoKg: sacoKg);
      // Un racimo o un cajón sin peso no entra al promedio: no hay kilos.
      if (qtKg == null) continue;
      kg += qtKg;
      money += t.amount;
    }
    return kg > 0 ? money / kg : null;
  }

  /// Rendimiento básico por área y por planta (schema parity con la Regla).
  /// [hasResiembra] marca los valores como "aproximado".
  double? yieldPerArea(List<Harvest> harvests, double? areaHa) {
    if (areaHa == null || areaHa <= 0) return null;
    double kg = 0;
    for (final h in harvests) {
      kg += _kgOf(h);
    }
    return kg > 0 ? kg / areaHa : null;
  }

  double? yieldPerPlant(List<Harvest> harvests, int? livePlants) {
    if (livePlants == null || livePlants <= 0) return null;
    double kg = 0;
    for (final h in harvests) {
      kg += _kgOf(h);
    }
    return kg > 0 ? kg / livePlants : null;
  }

  /// E4 · **su propia tierra**: el rendimiento anual promedio de este cultivo.
  ///
  /// La referencia de E4 no es una tabla de Cenicafé — es la finca del
  /// productor. Sirve a cualquier agricultor de cualquier región porque sale
  /// de sus propias cosechas: no hay que adivinar la especie, ni la altitud,
  /// ni la lluvia, ni el país.
  ///
  /// Reglas que hacen que no mienta:
  ///
  ///  * Solo cuentan años calendario **completos** (anteriores al año en
  ///    curso). Promediar un mes contra un año sería comparar peras con
  ///    manzanas, y el período del reporte puede ser semana, mes o año.
  ///  * [minYears] = 2 por defecto: con un solo año no hay "promedio", hay
  ///    ese año. Y como los años completos excluyen al actual, esto pide
  ///    **dos temporadas cerradas** antes de enseñar nada.
  ///  * El área y las plantas que se usan son las actuales. Si creció o
  ///    redujo, el histórico es aproximado — y por eso el copy lo dice.
  ///  * Todo lo que no se pueda calcular sale `null`. La UI lo oculta, nunca
  ///    pinta un 0 inventado.
  ///
  /// Devuelve [years] junto con las cifras para que la línea pueda decir
  /// "Tu promedio anual (3 años)" y el productor sepa sobre cuánto pesa.
  ({double? kgPerHa, double? kgPerPlant, int years}) historicalYield({
    required List<Harvest> harvests,
    required double? areaHa,
    required int? livePlants,
    int minYears = 2,
  }) {
    final anioEnCurso = DateTime.now().year;
    final kgPorAnio = <int, double>{};
    for (final h in harvests) {
      // El año en curso va incompleto: entraría a medias contra años
      // cerrados y bajaría el promedio solo por haber sido tarde.
      if (h.date.year >= anioEnCurso) continue;
      kgPorAnio[h.date.year] =
          (kgPorAnio[h.date.year] ?? 0) + _kgOf(h);
    }

    final cerrados = kgPorAnio.keys.where((y) => kgPorAnio[y]! > 0).toList();
    if (cerrados.length < minYears) {
      return (kgPerHa: null, kgPerPlant: null, years: 0);
    }

    final promedioKg =
        cerrados.fold<double>(0, (a, y) => a + kgPorAnio[y]!) / cerrados.length;
    return (
      kgPerHa: (areaHa != null && areaHa > 0) ? promedioKg / areaHa : null,
      kgPerPlant: (livePlants != null && livePlants > 0)
          ? promedioKg / livePlants
          : null,
      years: cerrados.length,
    );
  }

  /// Ingresos del cultivo por hectárea. Solo si [areaHa] > 0 y hay ingresos
  /// no eliminados; si no, null (la UI oculta, nunca muestra 0).
  ///
  /// Si los ingresos mezclan monedas también devuelve null: sumar pesos con
  /// dólares daría un ingreso falso por hectárea.
  double? revenuePerHa(List<Transaction> txs, double? areaHa) {
    if (areaHa == null || areaHa <= 0) return null;
    double total = 0;
    final currencies = <String>{};
    for (final t in txs) {
      if (t.deleted || t.type.isExpense) continue;
      total += t.amount;
      currencies.add(t.currency);
    }
    if (currencies.length > 1) return null;
    return total > 0 ? total / areaHa : null;
  }

  /// Gastos del cultivo por hectárea. Mismas reglas que [revenuePerHa].
  double? costPerHa(List<Transaction> txs, double? areaHa) {
    if (areaHa == null || areaHa <= 0) return null;
    double total = 0;
    final currencies = <String>{};
    for (final t in txs) {
      if (t.deleted || !t.type.isExpense) continue;
      // La inversión en equipo no es costo de la hectárea de este período:
      // ni suma ni cuenta para el chequeo de monedas. Un equipo comprado en
      // otra moneda dejaba el ratio en «—» sin motivo.
      if (!isOperationExpense(t)) continue;
      total += t.amount;
      currencies.add(t.currency);
    }
    if (currencies.length > 1) return null;
    return total > 0 ? total / areaHa : null;
  }

  /// Margen por ha (ingresos − gastos), null si no hay ningún dato.
  double? marginPerHa(double? revenue, double? cost) {
    if (revenue == null && cost == null) return null;
    return (revenue ?? 0) - (cost ?? 0);
  }

  /// % de la inversión del establecimiento ya recuperada (margen ÷ inversión).
  /// Solo si [establishmentCost] > 0 y hay margen; si no, null.
  double? recoveryRate(double? establishmentCost, double? margin) {
    if (establishmentCost == null || establishmentCost <= 0) return null;
    if (margin == null) return null;
    return margin / establishmentCost;
  }

  /// Años estimados para pagar la inversión: inversión ÷ margen anual promedio
  /// MEDIDO. No es predicción de producción: es una división de datos medidos,
  /// por eso se presenta siempre como "aprox.".
  double? breakevenYears(double? establishmentCost, double avgAnnualMargin) {
    if (establishmentCost == null || establishmentCost <= 0) return null;
    if (avgAnnualMargin <= 0) return null;
    return establishmentCost / avgAnnualMargin;
  }

  /// Venta vs cosecha por cultivo en kg (últimos 12 meses, para coherencia
  /// con la Regla de conciliación). Devuelve solo cultivos con al menos una
  /// venta o cosecha en el período.
  ///
  /// **Antes de mostrar esto, pasá por `hasIndependentHarvest`**
  /// (`derived_harvests.dart`). Si todas las cosechas del período salieron de
  /// la venta, `harvestedKg` *es* `soldKg` y la comparación no dice nada — D5.
  /// Los tres pintadores (pantalla, PDF, Excel) tienen esa misma puerta; si
  /// alguien agrega un cuarto, es la regla a copiar.
  List<SoldVsHarvested> soldVsHarvested(List<Transaction> transactions,
      List<Harvest> harvests, List<Crop> crops, DateTime now) {
    final cutoff = DateTime(now.year, now.month - 11, 1);
    final nameById = {for (final c in crops) c.id: c.name};
    final acc = <String, _SvH>{
      '': _SvH(name: 'Sin cultivo', cropId: null),
    };
    for (final c in crops) {
      acc.putIfAbsent(c.id, () => _SvH(name: c.name, cropId: c.id));
    }
    for (final t in transactions) {
      if (t.deleted || t.type.isExpense || !t.date.isAfter(cutoff)) continue;
      final a = acc.putIfAbsent(
          t.cropId ?? '',
          () => _SvH(
              name: t.cropId == null
                  ? 'Sin cultivo'
                  : (nameById[t.cropId] ?? t.cropId!),
              cropId: t.cropId));
      final kg = kgFromUnit(t.quantity ?? 0, t.unit, t.equivalentKg, sacoKg: sacoKg);
      if (kg != null) a.soldKg += kg;
    }
    for (final h in harvests) {
      if (!h.date.isAfter(cutoff)) continue;
      final a = acc.putIfAbsent(
          h.cropId ?? '',
          () => _SvH(
              name: h.cropId == null
                  ? 'Sin cultivo'
                  : (nameById[h.cropId] ?? h.cropId!),
              cropId: h.cropId));
      a.harvestedKg += _kgOf(h);
    }
    return acc.entries
        .map((e) => SoldVsHarvested(
              cropId: e.value.cropId,
              name: e.value.name,
              soldKg: e.value.soldKg,
              harvestedKg: e.value.harvestedKg,
            ))
        .where((s) => s.soldKg > 0 || s.harvestedKg > 0)
        .toList()
      ..sort((a, b) => b.harvestedKg.compareTo(a.harvestedKg));
  }
}

/// Reparto de los gastos de un cultivo en inversión inicial vs operación.
/// `total` es exactamente la suma de ambos: la UI lo usa para comprobar que
/// el desglose no pierde ni duplica montos.
/// Reparto de los gastos de una fila del desglose.
///
/// - [investment] · inversión inicial (siembra y cercas de antes de la primera
///   cosecha);
/// - [equipment] · inversión en equipo (compra de capital, C10);
/// - [operation] · operación del período.
///
/// Partición exacta: los tres suman el total de gastos.
class CropExpenseSplit {
  final double investment;
  final double equipment;
  final double operation;

  const CropExpenseSplit({
    required this.investment,
    required this.equipment,
    required this.operation,
  });

  double get total => investment + equipment + operation;
}

class _Acc {
  final String name;
  final String unit;
  double amount = 0;
  double kg = 0;
  _Acc({required this.name, required this.unit});
}

class _SvH {
  final String name;
  final String? cropId;
  double soldKg = 0;
  double harvestedKg = 0;
  _SvH({required this.name, this.cropId});
}

class CropHarvestTotal {
  final String? cropId;
  final String name;
  final String unit;
  final double amount;
  final double kg;

  const CropHarvestTotal({
    this.cropId,
    required this.name,
    required this.unit,
    required this.amount,
    required this.kg,
  });
}

class SoldVsHarvested {
  final String? cropId;
  final String name;
  final double soldKg;
  final double harvestedKg;

  const SoldVsHarvested({
    this.cropId,
    required this.name,
    required this.soldKg,
    required this.harvestedKg,
  });
}

/// Cosechas que no suman kilos porque su unidad necesita peso y no lo tiene.
///
/// No es un error del productor ni una cifra que se rellene: es una lista para
/// completar. Mientras falte el peso, la cosecha cuenta su cantidad (12
/// racimos) pero no sus kilos.
List<Harvest> pendingWeightHarvests(Iterable<Harvest> harvests) => harvests
    .where((h) =>
        unitNeedsWeight(h.unit) &&
        (h.equivalentKg == null || h.equivalentKg! <= 0))
    .toList();

/// Ventas que no suman kilos porque su unidad necesita peso y no lo tiene.
///
/// Solo ventas vivas con cantidad: un gasto o una fila borrada no entra a los
/// totales, así que tampoco tiene nada que completar.
List<Transaction> pendingWeightSales(Iterable<Transaction> transactions) =>
    transactions
        .where((t) =>
            !t.deleted &&
            !t.type.isExpense &&
            isSaleCategory(t.category) &&
            unitNeedsWeight(t.unit) &&
            (t.quantity ?? 0) > 0 &&
            (t.equivalentKg == null || t.equivalentKg! <= 0))
        .toList();
