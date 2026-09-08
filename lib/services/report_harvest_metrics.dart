import '../models/crop.dart';
import '../models/harvest.dart';
import '../models/transaction.dart';
import '../models/units.dart';

/// Métricas de cosecha para la sección "Cosechas" del reporte.
/// Funciones puras sobre datos locales (testables sin UI).
class ReportHarvestMetrics {
  const ReportHarvestMetrics();

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
      a.kg += h.amount * unitToKg(h.unit);
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

  /// Costo de recogida por kg: gastos vinculados a una cosecha ÷ kg cosechados.
  double? pickupCostPerKg(
      List<Transaction> transactions, List<Harvest> harvests) {
    double kg = 0;
    double pickup = 0;
    for (final h in harvests) {
      kg += h.amount * unitToKg(h.unit);
    }
    for (final t in transactions) {
      if (t.deleted || !t.type.isExpense || t.harvestId == null) continue;
      pickup += t.amount;
    }
    return kg > 0 ? pickup / kg : null;
  }

  /// Costo total por kg: gastos del cultivo ÷ kg cosechados (solo producción).
  /// Para establecimiento devuelve null (se muestra la inversión acumulada).
  double? totalCostPerKg(Crop crop, List<Transaction> cropExpenses,
      List<Harvest> cropHarvests) {
    if (crop.cycle == CropCycle.anual ||
        crop.phase == CropPhase.produccion) {
      double kg = 0;
      for (final h in cropHarvests) {
        kg += h.amount * unitToKg(h.unit);
      }
      if (kg <= 0) return null;
      double cost = 0;
      for (final t in cropExpenses) {
        cost += t.amount;
      }
      return cost / kg;
    }
    return null;
  }

  /// Inversión acumulada del cultivo (para fase establecimiento/renovación).
  double accumulatedInvestment(List<Transaction> cropExpenses) {
    double cost = 0;
    for (final t in cropExpenses) {
      cost += t.amount;
    }
    return cost;
  }

  /// Rendimiento básico por área y por planta (schema parity con la Regla).
  /// [hasResiembra] marca los valores como "aproximado".
  double? yieldPerArea(List<Harvest> harvests, double? areaHa) {
    if (areaHa == null || areaHa <= 0) return null;
    double kg = 0;
    for (final h in harvests) {
      kg += h.amount * unitToKg(h.unit);
    }
    return kg > 0 ? kg / areaHa : null;
  }

  double? yieldPerPlant(List<Harvest> harvests, int? livePlants) {
    if (livePlants == null || livePlants <= 0) return null;
    double kg = 0;
    for (final h in harvests) {
      kg += h.amount * unitToKg(h.unit);
    }
    return kg > 0 ? kg / livePlants : null;
  }

  /// Ingresos del cultivo por hectárea. Solo si [areaHa] > 0 y hay ingresos
  /// no eliminados; si no, null (la UI oculta, nunca muestra 0).
  double? revenuePerHa(List<Transaction> txs, double? areaHa) {
    if (areaHa == null || areaHa <= 0) return null;
    double total = 0;
    for (final t in txs) {
      if (t.deleted || t.type.isExpense) continue;
      total += t.amount;
    }
    return total > 0 ? total / areaHa : null;
  }

  /// Gastos del cultivo por hectárea. Mismas reglas que [revenuePerHa].
  double? costPerHa(List<Transaction> txs, double? areaHa) {
    if (areaHa == null || areaHa <= 0) return null;
    double total = 0;
    for (final t in txs) {
      if (t.deleted || !t.type.isExpense) continue;
      total += t.amount;
    }
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
      a.soldKg += (t.quantity ?? 0) * unitToKg(t.unit);
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
      a.harvestedKg += h.amount * unitToKg(h.unit);
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
