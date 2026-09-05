import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/transaction.dart';

/// Tono de cada conclusión para colorearla en la UI.
enum InsightTone {
  positive,
  negative,
  info;

  /// Conveniente que lo use la UI para mantener un solo origen.
  bool get isPositive => this == InsightTone.positive;
  bool get isNegative => this == InsightTone.negative;
}

class ReportInsight {
  final InsightTone tone;
  final String text;

  const ReportInsight({required this.tone, required this.text});
}

/// Conclusión del período, 100% determinista y basada solo en los datos.
/// Genera frases cortas con números reales para que el usuario sepa
/// en qué gastó más, qué vendió mejor y cómo viene la tendencia.
/// No usa IA: es reproducible y nunca inventa cifras.
class ReportInsightsService {
  const ReportInsightsService();

  /// Parámetros:
  /// - [current] registros del período que se reporta.
  /// - [previousMonth] registros del mes anterior (solo para comparación mensual).
  /// - [yearRecords] todos los registros del año (para comparar meses).
  /// - [now] fecha de referencia para la ventana de 30 días.
  /// - [money] formatea un monto según la moneda activa de la app.
  List<ReportInsight> build({
    required DateTime now,
    required List<Transaction> current,
    required List<Transaction> previousMonth,
    required List<Transaction> yearRecords,
    required int year,
    int? month,
    required AppLocalizations l10n,
    required String Function(double) money,
  }) {
    final insights = <ReportInsight>[];
    final currentYear = yearRecords.where((t) => t.date.year == year).toList();

    if (current.isEmpty && previousMonth.isEmpty && currentYear.isEmpty) {
      insights.add(ReportInsight(
        tone: InsightTone.info,
        text: l10n.insightNoActivity,
      ));
      return insights;
    }

    _balance(current, previousMonth, month, l10n, money, insights);
    _topExpense(current, l10n, money, insights);
    _sales(current, currentYear, now, l10n, money, insights);
    _bestMonth(month, currentYear, l10n, money, insights);

    return insights;
  }

  // ---- A. Balance y tendencia ----

  void _balance(List<Transaction> current, List<Transaction> previous,
      int? month, AppLocalizations l10n, String Function(double) money,
      List<ReportInsight> out) {
    final expenses = _sumBy(current, isExpense: true);
    final incomes = _sumBy(current, isExpense: false);
    final balance = incomes - expenses;
    final margin = incomes > 0 ? balance / incomes * 100 : null;

    if (incomes <= 0 && expenses <= 0) return;
    if (incomes <= 0) {
      out.add(ReportInsight(
        tone: InsightTone.negative,
        text: l10n.insightBalanceNoIncome(money(expenses)),
      ));
    } else if (balance >= 0) {
      out.add(ReportInsight(
        tone: InsightTone.positive,
        text: l10n.insightBalancePositive(money(balance), _signed(margin!)),
      ));
    } else {
      out.add(ReportInsight(
        tone: InsightTone.negative,
        text: l10n.insightBalanceNegative(money(-balance), _signed(margin)),
      ));
    }

    // Comparación contra el mes anterior (solo en modo mensual).
    if (month != null && previous.isNotEmpty) {
      final prevExp = _sumBy(previous, isExpense: true);
      final prevInc = _sumBy(previous, isExpense: false);
      if (prevExp != 0 || prevInc != 0) {
        final incDelta = prevInc > 0
            ? (incomes - prevInc) / prevInc * 100
            : (incomes > 0 ? 100.0 : 0.0);
        final expDelta = prevExp > 0
            ? (expenses - prevExp) / prevExp * 100
            : (expenses > 0 ? 100.0 : 0.0);
        out.add(ReportInsight(
          tone: InsightTone.info,
          text: l10n.insightVsPrev(
            _change(expDelta, l10n),
            _change(incDelta, l10n),
            l10n.monthFull[month - 1],
          ),
        ));
      }
    }
  }

  // ---- B. Mayor gasto ----

  void _topExpense(List<Transaction> current, AppLocalizations l10n,
      String Function(double) money, List<ReportInsight> out) {
    final expenses = current.where((t) => t.type.isExpense).toList();
    if (expenses.isEmpty) return;
    final total = _sumBy(expenses, isExpense: true);
    if (total <= 0) return;

    final top = _topCategory(expenses, true, l10n);
    final pct = top.amount / total * 100;
    out.add(ReportInsight(
      tone: pct >= 50 ? InsightTone.negative : InsightTone.info,
      text: l10n.insightTopExpense(
          money(top.amount), top.label, '${pct.toStringAsFixed(0)}%'),
    ));
    if (pct >= 50) {
      out.add(ReportInsight(
        tone: InsightTone.info,
        text: l10n.insightTopExpenseDependency(top.label),
      ));
    }
  }

  // ---- C. Ventas ----

  void _sales(List<Transaction> current, List<Transaction> yearRecords,
      DateTime now, AppLocalizations l10n, String Function(double) money,
      List<ReportInsight> out) {
    final incomes = current.where((t) => !t.type.isExpense).toList();
    if (incomes.isNotEmpty) {
      final total = _sumBy(incomes, isExpense: false);
      final top = _topCategory(incomes, false, l10n);
      final pct = top.amount / total * 100;
      out.add(ReportInsight(
        tone: InsightTone.positive,
        text: l10n.insightTopIncome(
            money(top.amount), top.label, '${pct.toStringAsFixed(0)}%'),
      ));
    }

    // Venta promedio reciente (30 días) vs histórico del año.
    final sales = yearRecords
        .where((t) => !t.type.isExpense && t.category.startsWith('venta_'))
        .toList();
    if (sales.length >= 3) {
      final histAvg = _sumBy(sales, isExpense: false) / sales.length;
      final threshold = DateTime(now.year, now.month, now.day - 30);
      final recent = sales.where((t) => t.date.isAfter(threshold)).toList();
      if (recent.length >= 2) {
        final recentAvg = _sumBy(recent, isExpense: false) / recent.length;
        if (recentAvg < histAvg) {
          out.add(ReportInsight(
            tone: InsightTone.negative,
            text:
                l10n.insightLowPrice(money(histAvg), money(recentAvg)),
          ));
        }
      }
    }
  }

  // ---- D. Comparación temporal ----

  void _bestMonth(int? month, List<Transaction> yearRecords,
      AppLocalizations l10n, String Function(double) money,
      List<ReportInsight> out) {
    final totals = <int, (double income, double expense)>{};
    for (final t in yearRecords) {
      final m = t.date.month;
      final (income, expense) = totals[m] ?? (0.0, 0.0);
      totals[m] = t.type.isExpense
          ? (income, expense + t.amount)
          : (income + t.amount, expense);
    }
    final withSales = totals.entries
        .where((e) => e.value.$1 > 0)
        .toList()
      ..sort((a, b) => b.value.$1.compareTo(a.value.$1));
    final withCosts = totals.entries
        .where((e) => e.value.$2 > 0)
        .toList()
      ..sort((a, b) => a.value.$2.compareTo(b.value.$2));

    if (withSales.isEmpty || withCosts.isEmpty) return;
    final activeMonths = totals.values
        .where((v) => v.$1 > 0 || v.$2 > 0)
        .length;
    if (activeMonths < 2) return;

    final best = withSales.first;
    final lowest = withCosts.first;
    out.add(ReportInsight(
      tone: InsightTone.info,
      text: l10n.insightBestMonth(
        money(lowest.value.$2),
        l10n.monthFull[lowest.key - 1],
        money(best.value.$1),
        l10n.monthFull[best.key - 1],
      ),
    ));
  }

  double _sumBy(List<Transaction> items, {required bool isExpense}) {
    return items
        .where((t) => t.type.isExpense == isExpense)
        .fold<double>(0, (a, t) => a + t.amount);
  }

  ({String label, double amount}) _topCategory(
      List<Transaction> items, bool isExpense, AppLocalizations l10n) {
    final totals = <String, double>{};
    for (final t in items) {
      if (t.type.isExpense != isExpense) continue;
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    final entry = totals.entries.reduce(
        (a, b) => b.value > a.value ? b : a);
    final label = isExpense
        ? l10n.expenseCategory(entry.key)
        : l10n.incomeCategory(entry.key);
    return (label: label, amount: entry.value);
  }

  String _signed(double? v) => v == null
      ? '0%'
      : '${v >= 0 ? '+' : ''}${v.toStringAsFixed(0)}%';

  String _change(double delta, AppLocalizations l10n) {
    if (delta.abs() < 0.5) return l10n.insightChangeFlat;
    final pct = '${delta.abs().toStringAsFixed(0)}%';
    return delta > 0
        ? l10n.insightChangeUp(pct)
        : l10n.insightChangeDown(pct);
  }
}