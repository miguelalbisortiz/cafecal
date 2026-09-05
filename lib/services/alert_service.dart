import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/crop.dart';
import '../models/farm_alert.dart';
import '../models/transaction.dart';

/// Motor de alertas — 5 reglas del PRD.
/// Funciones puras sobre datos locales; evaluar en cada registro y apertura.
/// Los avisos usan lenguaje claro, sin siglas financieras (ROI, EBITDA…),
/// incluyen los números que los disparan y una acción sugerida.
/// Recibe [l10n] para los mensajes en el idioma activo.
class AlertService {
  const AlertService({DateTime? now}) : _now = now;

  final DateTime? _now;

  List<FarmAlert> evaluate(
      List<Transaction> transactions, List<Crop> crops, AppLocalizations l10n) {
    final now = _now ?? DateTime.now();
    final alerts = <FarmAlert>[];
    final active = transactions.where((t) => !t.deleted).toList();

    _checkExcessiveSpending(active, now, l10n, alerts);
    _checkNoIncome(active, now, l10n, alerts);
    _checkConsecutiveLosses(active, now, l10n, alerts);
    _checkLowPrice(active, now, l10n, alerts);
    _checkDeficitCrop(active, crops, l10n, alerts);

    return alerts;
  }

  // ---- Regla 1: categoría de gasto > 2× promedio histórico mensual ----

  void _checkExcessiveSpending(List<Transaction> txns, DateTime now,
      AppLocalizations l10n, List<FarmAlert> out) {
    final currentMonth = now.month;
    final expenses = txns
        .where((t) => t.type.isExpense && t.date.month == currentMonth)
        .toList();
    if (expenses.isEmpty) return;

    final history = txns
        .where((t) => t.type.isExpense && t.date.month != currentMonth)
        .toList();

    for (final category in expenses.map((t) => t.category).toSet()) {
      final current =
          expenses.where((t) => t.category == category).fold<double>(0, (a, t) => a + t.amount);
      if (current <= 0) continue;

final catHistory =
        history.where((t) => t.category == category).toList();
    if (catHistory.length < 2) continue;

    // Promedio histórico MENSUAL: sumar el total de cada mes, luego
    // dividir entre los meses con datos. Promediar por transacción
    // distorsiona el umbral si un mes tuvo muchos movimientos puntuales.
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

  // ---- Regla 4: precio de venta < promedio histórico ----

  void _checkLowPrice(List<Transaction> txns, DateTime now,
      AppLocalizations l10n, List<FarmAlert> out) {
    // Solo ventas reales: subvenciones y apoyos no son precio de venta y
    // distorsionarían el promedio del ticket por venta.
    final sales = txns
        .where((t) => !t.type.isExpense && t.category.startsWith('venta_'))
        .toList();
    if (sales.length < 3) return;

    final histAvg = sales.fold<double>(0, (a, t) => a + t.amount) / sales.length;
    final threshold = DateTime(now.year, now.month, now.day - 30);
    final recent = sales.where((t) => t.date.isAfter(threshold)).toList();
    if (recent.length < 2) return;

    final recentAvg =
        recent.fold<double>(0, (a, t) => a + t.amount) / recent.length;
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
  // Se mide (Ingresos − Gastos) / Gastos. Si es < −30 %, el cultivo no
  // recupera ni el 70 % de lo que se ha invertido en él.

  void _checkDeficitCrop(List<Transaction> txns, List<Crop> crops,
      AppLocalizations l10n, List<FarmAlert> out) {
    final cropName = {for (final c in crops) c.id: c.name};
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
        final label = cropId == null
            ? l10n.cropUnspecified
            : (cropName[cropId] ?? cropId);
        final recovery = row.incomes / row.expenses * 100;
        final String title;
        final String message;
        final String suggestion;
        if (cropId == null) {
          title = l10n.alertDeficitNoCropTitle(_percentage(ratio * 100));
          message = l10n.alertDeficitNoCropMessage(
            _money(row.expenses),
            _money(row.incomes),
            _percentage(recovery),
          );
          suggestion = l10n.alertDeficitNoCropSuggestion;
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
}

String _money(double value) {
  final digits = NumberFormat('#,##0', 'es_CO').format(value.abs());
  return value < 0 ? '-\$$digits' : '\$$digits';
}

String _percentage(double value) {
  return '${value.toStringAsFixed(0)}%';
}

class _CropTotals {
  double expenses = 0;
  double incomes = 0;
}