import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/crop.dart';
import '../models/transaction.dart';
import 'currency_totals.dart';
import 'low_price_check.dart';
import 'period_delta.dart';

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
  /// - [mixedTotals] el período toca más de una moneda. Sin tasa de cambio
  ///   **ninguna** conclusión que pinte dinero se emite: ni el balance, ni el
  ///   mayor gasto, ni la tarjeta de ventas, ni el mejor mes, porque todas
  ///   sumarían o compararían monedas distintas y el número sería falso.
  ///   Nunca se inventa una cifra.
  ///
  /// Además, cada conclusión que mira el año comprueba **su propio conjunto
  /// de registros**: aunque el período sea de una sola moneda, si el año
  /// mezcla no se emite el "mejor mes" ni el "precio bajo" (compararían mes
  /// con mes cruzando monedas). Con una sola moneda el resultado es idéntico
  /// al de siempre.
  List<ReportInsight> build({
    required DateTime now,
    required List<Transaction> current,
    required List<Transaction> previousMonth,
    required List<Transaction> yearRecords,
    required int year,
    int? month,
    List<Crop> crops = const [],
    required AppLocalizations l10n,
    required String Function(double) money,
    bool mixedTotals = false,

    /// Histórico completo del productor: es contra lo que compara la alerta
    /// de Inicio, y con eso tiene que comparar también este insight — si el
    /// reporte mirara solo el año, la misma venta daría dos precios distintos
    /// en dos pantallas. Vacío → se usa [yearRecords] (retrocompatible).
    List<Transaction> allRecords = const [],
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

    // B1 · si lo que se mira es el mes en curso, el mes anterior se recorta
    // al mismo tramo de días: comparar 1–13 contra 1–30 diría que bajaron
    // los gastos solo porque faltan días por anotar.
    final partialWindow = month != null && isCurrentMonth(year, month, now);
    final comparablePrevious =
        partialWindow ? sameDayWindow(previousMonth, now) : previousMonth;

    if (!mixedTotals) {
      _balance(current, comparablePrevious, month, l10n, money, insights,
          partialWindow: partialWindow);
    }
    _topExpense(current, l10n, money, insights, crops, mixedTotals);
    _sales(current, now, l10n, money, insights, crops, mixedTotals,
        allRecords.isNotEmpty ? allRecords : yearRecords);
    _bestMonth(month, currentYear, l10n, money, insights, mixedTotals);

    return insights;
  }

  // ---- A. Balance y tendencia ----

  void _balance(List<Transaction> current, List<Transaction> previous,
      int? month, AppLocalizations l10n, String Function(double) money,
      List<ReportInsight> out,
      {required bool partialWindow}) {
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
        final incDelta = percentChange(incomes, prevInc);
        final expDelta = percentChange(expenses, prevExp);
        // La frase compara contra el mes ANTERIOR —que es lo que trae
        // `_previousMonthRecords`—, así que nombra a ese. Nombrar el mes
        // visto decía "Frente a junio" mientras se comparaba contra mayo.
        final monthName = l10n.monthFull[month == 1 ? 11 : month - 2];
        // B1 · con el mes anterior recortado, la frase avisa de que los dos
        // períodos cubren lo mismo, para que el % no se lea como 1–30.
        out.add(ReportInsight(
          tone: InsightTone.info,
          text: partialWindow
              ? l10n.insightVsPrevPartial(
                  monthName,
                  changeText(incDelta, l10n),
                  changeText(expDelta, l10n),
                )
              : l10n.insightVsPrev(
                  monthName,
                  changeText(incDelta, l10n),
                  changeText(expDelta, l10n),
                ),
        ));
      }
    }
  }

  // ---- B. Mayor gasto ----

  void _topExpense(List<Transaction> current, AppLocalizations l10n,
      String Function(double) money, List<ReportInsight> out, List<Crop> crops,
      bool mixedTotals) {
    final expenses = current.where((t) => t.type.isExpense).toList();
    if (expenses.isEmpty) return;
    // Sin tasa, "el mayor gasto" y su % sobre el total solo se emiten si el
    // período es de una sola moneda: con mezcla cruzaría pesos y dólares.
    if (mixedTotals || isMixedCurrency(expenses)) return;
    final total = _sumBy(expenses, isExpense: true);
    if (total <= 0) return;

    final top = _topCategory(expenses, true, l10n, crops);
    final pct = top.amount / total * 100;
    out.add(ReportInsight(
      tone: pct >= 50 ? InsightTone.negative : InsightTone.info,
      text: l10n.insightTopExpense(
          top.label, money(top.amount), '${pct.toStringAsFixed(0)}%'),
    ));
    if (pct >= 50) {
      out.add(ReportInsight(
        tone: InsightTone.info,
        text: l10n.insightTopExpenseDependency(top.label),
      ));
    }
  }

  // ---- C. Ventas ----

  void _sales(List<Transaction> current, DateTime now, AppLocalizations l10n,
      String Function(double) money, List<ReportInsight> out, List<Crop> crops,
      bool mixedTotals, List<Transaction> allRecords) {
    final incomes = current.where((t) => !t.type.isExpense).toList();
    // El "% del total" del mejor ingreso solo es cierto en moneda única.
    if (incomes.isNotEmpty && !mixedTotals && !isMixedCurrency(incomes)) {
      final total = _sumBy(incomes, isExpense: false);
      final top = _topCategory(incomes, false, l10n, crops);
      final pct = top.amount / total * 100;
      out.add(ReportInsight(
        tone: InsightTone.positive,
        text: l10n.insightTopIncome(
            top.label, money(top.amount), '${pct.toStringAsFixed(0)}%'),
      ));
    }

    // Precio bajo: [lowPriceCheck] es la MISMA función de la alerta de Inicio
    // (Regla 4) — aquí solo cambia quién la pinta. Mide **precio por kilo**
    // sobre el histórico completo, y se calla si ninguna venta anotó kilos:
    // un "precio" calculado sin cantidad sería una cifra inventada.
    // El período mixto se descarta igual: no se cruza un precio en pesos con
    // otro en dólares.
    if (!mixedTotals) {
      final check = lowPriceCheck(records: allRecords, now: now);
      if (check != null && check.isBelow) {
        out.add(ReportInsight(
          tone: InsightTone.negative,
          text: l10n.insightLowPrice(money(check.recentAvgPerKg), money(check.histAvgPerKg)),
        ));
      }
    }
  }

  // ---- D. Comparación temporal ----

  void _bestMonth(int? month, List<Transaction> yearRecords,
      AppLocalizations l10n, String Function(double) money,
      List<ReportInsight> out, bool mixedTotals) {
    // El ranking entre meses solo tiene sentido cuando el reporte es del año
    // completo: mirando un mes concreto, "tu mejor mes fue agosto" no sirve
    // para decidir nada de lo que pasa este mes y solo llena la conclusion.
    // La comparación que sí decide, contra el periodo anterior, ya la hace
    // _balance.
    if (month != null) return;
    // Comparar los meses del año exige sumar todos los meses: si el período
    // o el año mezclan monedas ese ranking sería mentira, así que no se emite.
    if (mixedTotals || isMixedCurrency(yearRecords)) return;
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
        l10n.monthFull[best.key - 1],
        money(best.value.$1),
        l10n.monthFull[lowest.key - 1],
        money(lowest.value.$2),
      ),
    ));
  }

  double _sumBy(List<Transaction> items, {required bool isExpense}) {
    return items
        .where((t) => t.type.isExpense == isExpense)
        .fold<double>(0, (a, t) => a + t.amount);
  }

  ({String label, double amount}) _topCategory(List<Transaction> items,
      bool isExpense, AppLocalizations l10n, List<Crop> crops) {
    final totals = <String, double>{};
    for (final t in items) {
      if (t.type.isExpense != isExpense) continue;
      // Las ventas con cultivo se agrupan aparte: "Venta plátano" ≠ "Venta café".
      final key = isExpense ? t.category : incomeGroupKey(t.category, t.cropId);
      totals[key] = (totals[key] ?? 0) + t.amount;
    }
    final entry = totals.entries.reduce(
        (a, b) => b.value > a.value ? b : a);
    final label = isExpense
        ? l10n.expenseCategory(entry.key)
        : l10n.incomeGroupLabel(entry.key, crops);
    return (label: label, amount: entry.value);
  }

  String _signed(double? v) => v == null
      ? '0%'
      : '${v >= 0 ? '+' : ''}${v.toStringAsFixed(0)}%';
}