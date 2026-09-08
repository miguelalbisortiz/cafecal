import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/crop.dart';
import '../models/farm_alert.dart';
import '../models/harvest.dart';
import '../models/sowing.dart';
import '../models/transaction.dart';
import '../models/units.dart';

/// Motor de alertas — 5 reglas del PRD + 3 reglas Nivel 2.
/// Funciones puras sobre datos locales; evaluar en cada registro y apertura.
/// Los avisos usan lenguaje claro, sin siglas financieras (ROI, EBITDA…),
/// incluyen los números que los disparan y una acción sugerida.
/// Recibe [l10n] para los mensajes en el idioma activo.
class AlertService {
  const AlertService({DateTime? now}) : _now = now;

  final DateTime? _now;

  List<FarmAlert> evaluate(
    List<Transaction> transactions,
    List<Crop> crops,
    AppLocalizations l10n, {
    double? manualThresholdPerKg,
    List<Harvest> harvests = const [],
    List<Sowing> sowings = const [],
  }) {
    final now = _now ?? DateTime.now();
    final alerts = <FarmAlert>[];
    final active = transactions.where((t) => !t.deleted).toList();

    _checkExcessiveSpending(active, now, l10n, alerts);
    _checkNoIncome(active, now, l10n, alerts);
    _checkConsecutiveLosses(active, now, l10n, alerts);
    _checkLowPrice(active, now, l10n, alerts,
        manualThresholdPerKg: manualThresholdPerKg);
    _checkDeficitCrop(active, crops, l10n, alerts);
    _checkHarvestVsSales(active, crops, harvests, now, l10n, alerts);
    _checkRecentlyPlanted(sowings, now, crops, l10n, alerts);
    _checkMissingQuantity(active, now, l10n, alerts);

    return alerts;
  }

  // ---- Regla 1: categoría de gasto > 2× promedio histórico mensual ----

  void _checkExcessiveSpending(List<Transaction> txns, DateTime now,
      AppLocalizations l10n, List<FarmAlert> out) {
    final currentMonth = now.month;
    final expenses = txns
        .where((t) =>
            t.type.isExpense &&
            t.date.month == currentMonth &&
            t.date.year == now.year)
        .toList();
    if (expenses.isEmpty) return;

    // Baseline estacional (Nivel 3): comparar contra el mismo mes calendario de
    // años anteriores, para no marcar como "exceso" el pico recurrente de una
    // campaña (fertilización, mano de obra). Si ese baseline no alcanza 2
    // meses-dato con datos, se cae al promedio global histórico (original).
    final globalHistory = txns
        .where((t) => t.type.isExpense && t.date.month != currentMonth)
        .toList();
    final sameMonthHistory = txns
        .where((t) =>
            t.type.isExpense &&
            t.date.month == currentMonth &&
            t.date.year != now.year)
        .toList();

    for (final category in expenses.map((t) => t.category).toSet()) {
      final current =
          expenses.where((t) => t.category == category).fold<double>(0, (a, t) => a + t.amount);
      if (current <= 0) continue;

      final sameMonthForCat =
          sameMonthHistory.where((t) => t.category == category).toList();

      // Promedio histórico del MISMO mes calendario: sumar el total de cada
      // (año,mes) igual, luego dividir entre esos meses-dato. Si el baseline
      // estacional no alcanza 2 meses-dato, se usa el promedio global
      // (promediar por transacción distorsiona si un mes tuvo picos).
      final catHistory = sameMonthForCat.length >= 2
          ? sameMonthForCat
          : globalHistory.where((t) => t.category == category).toList();
      if (catHistory.length < 2) continue;

      final months = <int>{};
      for (final t in catHistory) {
        months.add(DateTime(t.date.year, t.date.month).millisecondsSinceEpoch);
      }
      if (months.length < 2) continue;
      final avg = catHistory.fold<double>(0, (a, t) => a + t.amount) /
          months.length;

      if (current > 2 * avg && avg > 0) {
        final label = l10n.expenseCategory(category);
        out.add(FarmAlert(
          id: 'excess_$category',
          rule: AlertRule.excessiveSpending,
          severity: AlertSeverity.warning,
          title: l10n.alertExcessTitle(label),
          message: l10n.alertExcessMessage(
            _money(current),
            label,
            _money(avg),
          ),
          suggestion: l10n.alertExcessSuggestion,
        ));
      }
    }
  }

  // ---- Regla 2: sin ingresos en 60 días ----

  void _checkNoIncome(List<Transaction> txns, DateTime now,
      AppLocalizations l10n, List<FarmAlert> out) {
    final incomes = txns.where((t) => !t.type.isExpense).toList();
    if (incomes.isEmpty) {
      if (txns.any((t) => t.type.isExpense)) {
        final spent = txns
            .where((t) => t.type.isExpense)
            .fold<double>(0, (a, t) => a + t.amount);
        out.add(FarmAlert(
          id: 'no_income',
          rule: AlertRule.noIncome,
          severity: AlertSeverity.warning,
          title: l10n.alertNoIncomeTitle,
          message: l10n.alertNoIncomeMessage(_money(spent)),
          suggestion: l10n.alertNoIncomeSuggestion,
        ));
      }
      return;
    }

    final lastIncome = incomes
        .map((t) => t.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final days = now.difference(lastIncome).inDays;
    if (days >= 60) {
      out.add(FarmAlert(
        id: 'no_income',
        rule: AlertRule.noIncome,
        severity: AlertSeverity.warning,
        title: l10n.alertNoSalesTitle(days),
        message: l10n.alertNoSalesMessage(
          DateFormat('dd/MM/yyyy').format(lastIncome),
        ),
        suggestion: l10n.alertNoSalesSuggestion,
      ));
    }
  }

  // ---- Regla 3: gastos > ingresos por 3+ meses consecutivos ----

  void _checkConsecutiveLosses(List<Transaction> txns, DateTime now,
      AppLocalizations l10n, List<FarmAlert> out) {
    int consecutive = 0;
    for (var i = 0; i < 6; i++) {
      final month = DateTime(now.year, now.month - i);
      final expenses = txns
          .where((t) =>
              !t.deleted &&
              t.type.isExpense &&
              t.date.year == month.year &&
              t.date.month == month.month)
          .fold<double>(0, (a, t) => a + t.amount);
      final incomes = txns
          .where((t) =>
              !t.deleted &&
              !t.type.isExpense &&
              t.date.year == month.year &&
              t.date.month == month.month)
          .fold<double>(0, (a, t) => a + t.amount);

      if (expenses > incomes) {
        consecutive++;
      } else if (expenses == 0 && incomes == 0) {
        continue;
      } else {
        break;
      }
    }

    if (consecutive >= 3) {
      final months = <String>[];
      for (var i = 0; i < consecutive; i++) {
        final month = DateTime(now.year, now.month - i);
        months.add(l10n.monthFull[month.month - 1]);
      }
      out.add(FarmAlert(
        id: 'consecutive_losses',
        rule: AlertRule.consecutiveLosses,
        severity: AlertSeverity.danger,
        title: l10n.alertLossesTitle(consecutive),
        message: l10n.alertLossesMessage(l10n.listMonthsWithAnd(months)),
        suggestion: l10n.alertLossesSuggestion,
      ));
    }
  }

  // ---- Regla 4: precio de venta bajo ----

  void _checkLowPrice(List<Transaction> txns, DateTime now,
      AppLocalizations l10n, List<FarmAlert> out,
      {double? manualThresholdPerKg}) {
    final sales = txns
        .where((t) =>
            !t.type.isExpense &&
            t.category.startsWith('venta_') &&
            t.quantity != null &&
            t.quantity! > 0)
        .toList();
    if (sales.isEmpty) return;

    double pricePerKg(Transaction t) =>
        t.amount / (t.quantity! * unitToKg(t.unit));

    if (manualThresholdPerKg != null && manualThresholdPerKg > 0) {
      final below = sales
          .where((t) => pricePerKg(t) < manualThresholdPerKg)
          .toList();
      if (below.isNotEmpty) {
        final latest = below.reduce(
            (a, b) => a.date.isAfter(b.date) ? a : b);
        out.add(FarmAlert(
          id: 'low_price_manual',
          rule: AlertRule.lowPrice,
          severity: AlertSeverity.warning,
          title: l10n.alertLowPriceManualTitle,
          message: l10n.alertLowPriceManualMessage(
            _money(pricePerKg(latest)),
            _money(manualThresholdPerKg),
            DateFormat('dd/MM/yyyy').format(latest.date),
          ),
          suggestion: l10n.alertLowPriceSuggestion,
        ));
      }
    }

    if (sales.length < 3) return;
    final histAvg =
        sales.fold<double>(0, (a, t) => a + pricePerKg(t)) / sales.length;
    if (histAvg <= 0) return;

    final threshold = DateTime(now.year, now.month, now.day - 30);
    final recent = sales
        .where((t) => t.date.isAfter(threshold))
        .toList();
    if (recent.length < 2) return;

    final recentAvg =
        recent.fold<double>(0, (a, t) => a + pricePerKg(t)) / recent.length;
    if (recentAvg < histAvg) {
      out.add(FarmAlert(
        id: 'low_price',
        rule: AlertRule.lowPrice,
        severity: AlertSeverity.info,
        title: l10n.alertLowPriceTitle,
        message: l10n.alertLowPriceMessage(
          _money(recentAvg),
          _money(histAvg),
        ),
        suggestion: l10n.alertLowPriceSuggestion,
      ));
    }
  }

  // ---- Regla 5: cultivo con pérdidas superiores al 30% de lo invertido ----
  // Modificada para Nivel 2: en establecimiento/renovación → info, no danger.

  void _checkDeficitCrop(List<Transaction> txns, List<Crop> crops,
      AppLocalizations l10n, List<FarmAlert> out) {
    final cropMap = {for (final c in crops) c.id: c};
    final totals = <String?, _CropTotals>{};
    for (final t in txns) {
      final row = totals.putIfAbsent(t.cropId, _CropTotals.new);
      if (t.type.isExpense) {
        row.expenses += t.amount;
      } else {
        row.incomes += t.amount;
      }
    }

    totals.forEach((cropId, row) {
      if (row.expenses <= 0) return;
      final ratio = (row.incomes - row.expenses) / row.expenses;
      if (ratio < -0.30) {
        final crop = cropId != null ? cropMap[cropId] : null;
        final phase = crop?.phase ?? CropPhase.produccion;

        if (phase == CropPhase.establecimiento || phase == CropPhase.renovacion) {
          if (cropId == null) return;
          final label = crop?.name ?? cropId;
          out.add(FarmAlert(
            id: 'crop_establishment_$cropId',
            rule: AlertRule.cropEstablishment,
            severity: AlertSeverity.info,
            title: l10n.alertCropEstablishmentTitle(label),
            message: l10n.alertCropEstablishmentMessage(
              _money(row.expenses),
              label,
            ),
            suggestion: l10n.alertCropEstablishmentSuggestion(label),
          ));
          return;
        }

        final label = cropId == null
            ? l10n.cropUnspecified
            : (crop?.name ?? cropId);
        final recovery = row.incomes / row.expenses * 100;
        final String title;
        final String message;
        final String suggestion;
        if (cropId == null) {
          final unassigned = txns.where((t) => t.cropId == null).length;
          title = l10n.alertDeficitNoCropTitle(_percentage(ratio * 100));
          message = l10n.alertDeficitNoCropMessage(
            '$unassigned',
            _money(row.expenses),
            _money(row.incomes),
            _percentage(recovery),
          );
          suggestion =
              l10n.alertDeficitNoCropSuggestion('$unassigned');
        } else {
          title = l10n.alertDeficitTitle(label, _percentage(ratio * 100));
          message = l10n.alertDeficitMessage(
            _money(row.expenses),
            label,
            _money(row.incomes),
            _percentage(recovery),
          );
          suggestion = l10n.alertDeficitSuggestion(label);
        }
        out.add(FarmAlert(
          id: 'deficit_$cropId',
          rule: AlertRule.deficitCrop,
          severity: AlertSeverity.danger,
          title: title,
          message: message,
          suggestion: suggestion,
        ));
      }
    });
  }

  // ---- Regla 6: vendido más de lo cosechado (>10% margen, últimos 12 meses) ----

  void _checkHarvestVsSales(
    List<Transaction> txns,
    List<Crop> crops,
    List<Harvest> harvests,
    DateTime now,
    AppLocalizations l10n,
    List<FarmAlert> out,
  ) {
    final cutoff = DateTime(now.year - 1, now.month, now.day);
    final cropMap = {for (final c in crops) c.id: c};

    final salesByCrop = <String, double>{};
    for (final t in txns) {
      if (t.type.isExpense || !t.category.startsWith('venta_')) continue;
      if (t.date.isBefore(cutoff)) continue;
      final cid = t.cropId ?? '_none_';
      final qty = (t.quantity ?? 0);
      salesByCrop[cid] = (salesByCrop[cid] ?? 0) + qty * unitToKg(t.unit);
    }

    final harvestedByCrop = <String, double>{};
    for (final h in harvests) {
      if (h.date.isBefore(cutoff)) continue;
      // Solo lo vendido y lo almacenado respaldan ventas; la pérdida no
      // justifica vender más de lo cosechado.
      if (h.destination == HarvestDestination.perdida) continue;
      final cid = h.cropId ?? '_none_';
      harvestedByCrop[cid] =
          (harvestedByCrop[cid] ?? 0) + h.amount * unitToKg(h.unit);
    }

    final allCropIds = {...salesByCrop.keys, ...harvestedByCrop.keys};
    for (final cid in allCropIds) {
      final soldKg = salesByCrop[cid] ?? 0;
      final harvestedKg = harvestedByCrop[cid] ?? 0;
      if (soldKg <= 0 || harvestedKg <= 0) continue;
      if (soldKg > harvestedKg * 1.1) {
        final label = cid == '_none_'
            ? l10n.cropUnspecified
            : (cropMap[cid]?.name ?? cid);
        out.add(FarmAlert(
          id: 'harvest_vs_sales_$cid',
          rule: AlertRule.harvestVsSales,
          severity: AlertSeverity.warning,
          title: l10n.alertHarvestVsSalesTitle(label),
          message: l10n.alertHarvestVsSalesMessage(
            _kg(soldKg),
            _kg(harvestedKg),
            label,
          ),
          suggestion: l10n.alertHarvestVsSalesSuggestion(label),
        ));
      }
    }
  }

  // ---- Regla 7: siembra/resiembra en últimos 15 días ----

  void _checkRecentlyPlanted(
    List<Sowing> sowings,
    DateTime now,
    List<Crop> crops,
    AppLocalizations l10n,
    List<FarmAlert> out,
  ) {
    final cutoff = now.subtract(const Duration(days: 15));
    final cropMap = {for (final c in crops) c.id: c};

    final recent = sowings.where((s) => s.date.isAfter(cutoff)).toList();
    for (final s in recent) {
      final label = s.cropId == null
          ? l10n.cropUnspecified
          : (cropMap[s.cropId]?.name ?? s.cropId!);
      out.add(FarmAlert(
        id: 'recently_planted_${s.id}',
        rule: AlertRule.cropRecentlyPlanted,
        severity: AlertSeverity.info,
        title: l10n.alertRecentlyPlantedTitle,
        message: l10n.alertRecentlyPlantedMessage(
          label,
          DateFormat('dd/MM/yyyy').format(s.date),
        ),
        suggestion: l10n.alertRecentlyPlantedSuggestion,
      ));
    }
  }

  // ---- Regla 9: ventas sin cantidad registrada (últimos 90 días) ----

  void _checkMissingQuantity(List<Transaction> txns, DateTime now,
      AppLocalizations l10n, List<FarmAlert> out) {
    final cutoff = now.subtract(const Duration(days: 90));
    var count = 0;
    for (final t in txns) {
      if (t.type.isExpense || !t.category.startsWith('venta_')) continue;
      if (t.date.isBefore(cutoff)) continue;
      final qty = t.quantity ?? 0;
      if (qty > 0) continue;
      count++;
    }
    if (count >= 3) {
      out.add(FarmAlert(
        id: 'missing_quantity',
        rule: AlertRule.missingQuantity,
        severity: AlertSeverity.info,
        title: l10n.alertMissingQtyTitle,
        message: l10n.alertMissingQtyMessage(count),
        suggestion: l10n.alertMissingQtySuggestion,
      ));
    }
  }
}

String _money(double value) {
  final digits = NumberFormat('#,##0', 'es_CO').format(value.abs());
  return value < 0 ? '-\$$digits' : '\$$digits';
}

String _kg(double kg) {
  return '${NumberFormat('#,##0.0', 'es_CO').format(kg)} kg';
}

String _percentage(double value) {
  return '${value.toStringAsFixed(0)}%';
}

class _CropTotals {
  double expenses = 0;
  double incomes = 0;
}
