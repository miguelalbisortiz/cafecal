import '../l10n/generated/app_localizations.dart';
import '../models/transaction.dart';
import '../utils/format.dart';
import 'currency_totals.dart';
import 'metric_signal.dart';

/// B1 · comparación mensual con el **mismo tramo de días**.
///
/// El mes en curso va del día 1 hasta hoy; el mes anterior está completo. Si
/// se comparan los dos enteros, el 1 de cada mes la app diría "bajaron los
/// gastos" solo porque todavía no quedan días por anotar: es un sesgo
/// optimista falso. Aquí el mes anterior se recorta para que los dos cubran
/// el mismo tramo de días.
///
/// Registros borrados ya vienen filtrados por quien los cargó.
List<Transaction> sameDayWindow(Iterable<Transaction> records, DateTime now) =>
    records.where((t) => t.date.day <= now.day).toList();

/// true si el período que se mira es el mes en curso: el único caso en que
/// la comparación necesita el recorte de [sameDayWindow]. Los demás meses ya
/// están cerrados y se comparan enteros.
bool isCurrentMonth(int year, int month, DateTime now) =>
    year == now.year && month == now.month;

/// Variación porcentual de [current] contra [previous].
///
/// Sin base anterior no hay porcentaje posible: con movimiento nuevo se
/// reporta 100 (el criterio que ya usaba Reportes) y sin movimiento, 0.
/// Nunca divide entre cero.
double percentChange(double current, double previous) {
  if (previous > 0) return (current - previous) / previous * 100;
  return current > 0 ? 100.0 : 0.0;
}

/// Frase en lenguaje llano del cambio: "subieron 12%" · "bajaron 18%" ·
/// "sin cambios".
///
/// Es la misma función para el Resumen y para Reportes: las dos pantallas
/// dicen exactamente lo mismo porque salen del mismo texto.
String changeText(double deltaPercent, AppLocalizations l10n) {
  if (deltaPercent.abs() < 0.5) return l10n.insightChangeFlat;
  final pct = '${deltaPercent.abs().toStringAsFixed(0)}%';
  return deltaPercent > 0
      ? l10n.insightChangeUp(pct)
      : l10n.insightChangeDown(pct);
}

/// Señal de una variación ya orientada por quien la usa: subir es bueno para
/// lo que entra y malo para lo que sale, así quien calcula invierte el signo
/// del gasto antes de llamar.
///
/// La señal nunca va sola (H10): la UI la acompaña de icono de forma
/// distinta y de una frase que se lee sin depender del color.
MetricSignal signalOfDelta(double delta) {
  if (delta.abs() < 0.5) return MetricSignal.neutral;
  return delta > 0 ? MetricSignal.positive : MetricSignal.negative;
}

/// Las tres líneas de comparación que el Resumen pinta bajo las tarjetas del
/// mes: ingresos, gastos y resultado contra el mes anterior.
class MonthComparison {
  /// "subieron 12%" · "bajaron 18%" · "sin cambios"
  final String incomeText;
  final MetricSignal incomeSignal;

  final String expenseText;
  final MetricSignal expenseSignal;

  /// Resultado en **monto**: un porcentaje sobre un resultado que puede ser
  /// negativo o cruzar de cero sería mentira.
  final String resultText;
  final MetricSignal resultSignal;

  /// "vs. septiembre" — va en cada tarjeta.
  final String vsLabel;

  /// "Comparado con los mismos días de septiembre." — pie de la fila, para
  /// que "bajaron 18%" no se lea como si el mes anterior estuviera entero.
  final String note;

  const MonthComparison({
    required this.incomeText,
    required this.incomeSignal,
    required this.expenseText,
    required this.expenseSignal,
    required this.resultText,
    required this.resultSignal,
    required this.vsLabel,
    required this.note,
  });
}

/// Arma la comparación de un mes contra [previous], que debe venir ya
/// recortada con [sameDayWindow] cuando aplique.
///
/// Devuelve `null` —y no se pinta nada— cuando no hay con qué comparar: sin
/// datos en uno de los dos meses, o cuando tocaría cruzar monedas distintas.
/// Un `null` no se sustituye por cero ni por una cifra aproximada.
MonthComparison? buildMonthComparison({
  required PeriodCurrencyTotals current,
  required PeriodCurrencyTotals previous,
  required String locale,
  required String monthName,
  required AppLocalizations l10n,
}) {
  final cur = current.currencies;
  final prev = previous.currencies;

  // Solo moneda única e idéntica en los dos meses: con mezcla el
  // porcentaje cruzaría pesos y dólares y sería falso.
  if (cur.length != 1 || prev.length != 1 || cur.first != prev.first) {
    return null;
  }
  final currency = cur.first;

  final incNow = current.incomeOf(currency);
  final incPrev = previous.incomeOf(currency);
  final expNow = current.expenseOf(currency);
  final expPrev = previous.expenseOf(currency);

  final incDelta = percentChange(incNow, incPrev);
  final expDelta = percentChange(expNow, expPrev);
  final resultDelta = (incNow - expNow) - (incPrev - expPrev);

  String resultText;
  if (resultDelta.abs() < 0.005) {
    resultText = l10n.insightChangeFlat;
  } else {
    final amount =
        formatAmount(resultDelta.abs(), currency: currency, locale: locale);
    resultText = resultDelta > 0
        ? l10n.summaryResultBetter(amount)
        : l10n.summaryResultWorse(amount);
  }

  return MonthComparison(
    incomeText: changeText(incDelta, l10n),
    incomeSignal: signalOfDelta(incDelta),
    expenseText: changeText(expDelta, l10n),
    // Subir los ingresos es bueno; subir los gastos es malo: por eso el
    // gasto se evalúa con el signo invertido.
    expenseSignal: signalOfDelta(-expDelta),
    resultText: resultText,
    resultSignal: signalOfDelta(resultDelta),
    vsLabel: l10n.summaryVsPrev(monthName),
    note: l10n.summaryVsPrevNote(monthName),
  );
}
