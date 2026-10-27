import '../models/report_period.dart';
import '../models/transaction.dart';
import 'currency_totals.dart';
import 'week_utils.dart';

/// Ventana de fechas con los dos extremos incluidos.
///
/// Se usa para el período anterior del comparativo: un movimiento cuenta si
/// su fecha cae entre [start] y [end], ambos incluidos.
class PeriodWindow {
  final DateTime start;
  final DateTime end;

  const PeriodWindow(this.start, this.end);

  bool contains(DateTime date) => !date.isBefore(start) && !date.isAfter(end);
}

/// Ventana del período inmediatamente anterior a uno dado.
///
/// - Semana → los siete días anteriores (la semana ISO previa, aunque caiga
///   en diciembre del año pasado).
/// - Mes → el mes calendario anterior.
/// - Año → el año calendario anterior completo.
/// - Año a la fecha → el mismo tramo del año anterior: del 1 de enero al
///   mismo mes y día. Si el día no existe en el año anterior (29 de febrero),
///   se recorta al último día de ese mes.
///
/// [month] es el número de semana cuando [period] es [ReportPeriod.week] y el
/// número de mes cuando es [ReportPeriod.month]. Igual que los exportadores,
/// si falta se usa la semana 1 / el mes actual.
///
/// Función pura: sin red, sin estado, sin UI. [now] solo existe para poder
/// fijar el "hoy" en los tests.
PeriodWindow previousPeriodWindow({
  required ReportPeriod period,
  required int year,
  int? month,
  DateTime? now,
}) {
  switch (period) {
    case ReportPeriod.week:
      final current = weekRange(year, month ?? 1);
      final start = current.start.subtract(const Duration(days: 7));
      return PeriodWindow(
        start,
        start.add(const Duration(
            days: 6, hours: 23, minutes: 59, seconds: 59)),
      );
    case ReportPeriod.month:
      final m = month ?? (now ?? DateTime.now()).month;
      final first = DateTime(year, m, 1);
      final previousFirst = DateTime(first.year, first.month - 1, 1);
      // El último día del mes anterior: el día 0 del mes en curso.
      final lastDay = DateTime(first.year, first.month, 0);
      return PeriodWindow(
        previousFirst,
        DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59, 999),
      );
    case ReportPeriod.year:
      return PeriodWindow(
        DateTime(year - 1, 1, 1),
        DateTime(year - 1, 12, 31, 23, 59, 59, 999),
      );
    case ReportPeriod.yearToDate:
      final today = now ?? DateTime.now();
      // El mismo corte que hacen la pantalla y los exportadores: un año ya
      // cerrado llega al 31 de diciembre; el año en curso, hasta hoy.
      final currentEnd = year < today.year
          ? DateTime(year, 12, 31, 23, 59, 59, 999)
          : today;
      final previousYear = year - 1;
      final lastDayOfMonth =
          DateTime(previousYear, currentEnd.month + 1, 0).day;
      final day = currentEnd.day > lastDayOfMonth
          ? lastDayOfMonth
          : currentEnd.day;
      return PeriodWindow(
        DateTime(previousYear, 1, 1),
        DateTime(
            previousYear, currentEnd.month, day, 23, 59, 59, 999),
      );
  }
}

/// Comparación del período actual con el anterior.
///
/// Todas las cifras están en **una sola** moneda ([currency]): la del período
/// actual. Nunca se comparan pesos con dólares ni se convierte nada.
class PeriodComparison {
  /// El período comparado: decide el texto del encabezado.
  final ReportPeriod period;

  /// Moneda de las seis cifras.
  final String currency;

  final double previousIncomes;
  final double previousExpenses;
  final double incomes;
  final double expenses;

  const PeriodComparison({
    required this.period,
    required this.currency,
    required this.previousIncomes,
    required this.previousExpenses,
    required this.incomes,
    required this.expenses,
  });

  double get previousBalance => previousIncomes - previousExpenses;

  double get balance => incomes - expenses;

  /// Cambio porcentual de los ingresos; null si el período anterior no tenía
  /// ingresos (dividir por cero no da una cifra honesta).
  double? get incomeChange => changeOf(previousIncomes, incomes);

  double? get expenseChange => changeOf(previousExpenses, expenses);

  double? get balanceChange => changeOf(previousBalance, balance);

  /// Cuánto cambió [current] respecto a [previous], en porcentaje.
  ///
  /// Devuelve `null` cuando [previous] es 0: no hay porcentaje posible y un
  /// `0%` inventado diría que nada cambió. El signo mira el valor absoluto,
  /// así que pasar de `-100` a `100` es `+200%` (mejoró), no `-200%`.
  static double? changeOf(double previous, double current) =>
      previous == 0 ? null : (current - previous) / previous.abs() * 100;
}

/// Compara el período actual con el anterior, con las mismas reglas en
/// pantalla, PDF y Excel.
///
/// Devuelve `null` —y entonces no se pinta nada— cuando la comparación no se
/// puede hacer sin inventar cifras:
/// - el período actual no es de una sola moneda (o está vacío);
/// - el período anterior no tiene movimientos;
/// - el período anterior toca otra moneda, o mezcla monedas.
///
/// [current] son los totales ya calculados del período que se está pintando;
/// así la cifra comparada es exactamente la que se ve arriba. [transactions]
/// es el histórico completo: aquí se filtra la ventana anterior.
///
/// Función pura: sin red, sin estado, sin UI.
PeriodComparison? compareWithPreviousPeriod({
  required PeriodCurrencyTotals current,
  required Iterable<Transaction> transactions,
  required ReportPeriod period,
  required int year,
  int? month,
  DateTime? now,
}) {
  final currencies = current.currencies;
  if (currencies.length != 1) return null;
  final currency = currencies.first;

  final window = previousPeriodWindow(
    period: period,
    year: year,
    month: month,
    now: now,
  );
  final previous = PeriodCurrencyTotals.fromRecords(
    transactions.where((t) => !t.deleted && window.contains(t.date)),
  );

  // Sin datos anteriores no hay comparación que mostrar; con otra moneda
  // tampoco, porque restarlas sería cruzar monedas.
  if (previous.currencies.length != 1 ||
      previous.currencies.first != currency) {
    return null;
  }

  return PeriodComparison(
    period: period,
    currency: currency,
    previousIncomes: previous.incomeOf(currency),
    previousExpenses: previous.expenseOf(currency),
    incomes: current.incomeOf(currency),
    expenses: current.expenseOf(currency),
  );
}
