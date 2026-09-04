import '../models/crop.dart';
import '../models/farm_alert.dart';
import '../models/transaction.dart';

/// Motor de alertas — 5 reglas del PRD.
/// Funciones puras sobre datos locales; evaluar en cada registro y apertura.
class AlertService {
  const AlertService({DateTime? now}) : _now = now;

  final DateTime? _now;

  List<FarmAlert> evaluate(
      List<Transaction> transactions, List<Crop> crops) {
    final now = _now ?? DateTime.now();
    final alerts = <FarmAlert>[];
    final active = transactions.where((t) => !t.deleted).toList();

    _checkExcessiveSpending(active, now, alerts);
    _checkNoIncome(active, now, alerts);
    _checkConsecutiveLosses(active, now, alerts);
    _checkLowPrice(active, now, alerts);
    _checkDeficitCrop(active, crops, alerts);

    return alerts;
  }

  // ---- Regla 1: categoría de gasto > 2× promedio histórico mensual ----

  void _checkExcessiveSpending(
      List<Transaction> txns, DateTime now, List<FarmAlert> out) {
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

      final avg = catHistory
              .fold<double>(0, (a, t) => a + t.amount) /
          catHistory.length;

      if (current > 2 * avg && avg > 0) {
        out.add(FarmAlert(
          id: 'excess_$category',
          rule: AlertRule.excessiveSpending,
          severity: AlertSeverity.warning,
          title: 'Gasto excesivo en $category',
          message:
              'El gasto en $category supera 2× el promedio histórico. Revisar gasto en $category.',
        ));
      }
    }
  }

  // ---- Regla 2: sin ingresos en 60 días ----

  void _checkNoIncome(
      List<Transaction> txns, DateTime now, List<FarmAlert> out) {
    final incomes = txns.where((t) => !t.type.isExpense).toList();
    if (incomes.isEmpty) {
      if (txns.any((t) => t.type.isExpense)) {
        out.add(const FarmAlert(
          id: 'no_income',
          rule: AlertRule.noIncome,
          severity: AlertSeverity.warning,
          title: 'Sin ingresos registrados',
          message: 'Tienes gastos pero aún no hay ventas. Registrar última cosecha.',
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
        title: 'Hace $days días sin ventas',
        message: 'Registrar última cosecha.',
      ));
    }
  }

  // ---- Regla 3: gastos > ingresos por 3+ meses consecutivos ----

  void _checkConsecutiveLosses(
      List<Transaction> txns, DateTime now, List<FarmAlert> out) {
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
      out.add(FarmAlert(
        id: 'consecutive_losses',
        rule: AlertRule.consecutiveLosses,
        severity: AlertSeverity.danger,
        title: '$consecutive meses con balance negativo',
        message: 'Revisar costos operativos.',
      ));
    }
  }

  // ---- Regla 4: precio de venta < promedio histórico ----

  void _checkLowPrice(
      List<Transaction> txns, DateTime now, List<FarmAlert> out) {
final sales = txns.where((t) => !t.type.isExpense).toList();
    if (sales.length < 3) return;

    final histAvg = sales.fold<double>(0, (a, t) => a + t.amount) / sales.length;
    final threshold = DateTime(now.year, now.month, now.day - 30);
    final recent = sales.where((t) => t.date.isAfter(threshold)).toList();
    if (recent.length < 2) return;

    final recentAvg =
        recent.fold<double>(0, (a, t) => a + t.amount) / recent.length;
    if (recentAvg < histAvg) {
      out.add(const FarmAlert(
        id: 'low_price',
        rule: AlertRule.lowPrice,
        severity: AlertSeverity.info,
        title: 'Precio de venta bajo',
        message: 'Considerar vender después.',
      ));
    }
  }

  // ---- Regla 5: cultivo con ROI < -30% ----

  void _checkDeficitCrop(
      List<Transaction> txns, List<Crop> crops, List<FarmAlert> out) {
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
      final roi = (row.incomes - row.expenses) / row.expenses;
      if (roi < -0.30) {
        final label = cropId == null ? 'Sin especificar' : (cropName[cropId] ?? cropId);
        out.add(FarmAlert(
          id: 'deficit_$cropId',
          rule: AlertRule.deficitCrop,
          severity: AlertSeverity.danger,
          title: 'ROI negativo en $label',
          message: 'Evaluar continuar con $label.',
        ));
      }
    });
  }
}

class _CropTotals {
  double expenses = 0;
  double incomes = 0;
}