import '../models/categories.dart';
import '../models/transaction.dart';
import '../models/units.dart';
import 'currency_totals.dart';

/// Mínimo de ventas con kilo anotado para poder hablar de "precio bajo".
///
/// Con menos que esto el promedio es ruido: tres precios de tres sacos ya
/// cuentan una historia, dos no.
const int kMinSalesForLowPriceAlert = 3;

/// Resultado de comparar el precio por kilo de las ventas recientes contra el
/// histórico. `null` en el caller significa "no hay dato para hablar" — nunca
/// un cero, nunca un promedio de menos de tres ventas.
class LowPriceCheck {
  /// Precio por kilo de las ventas de los últimos 30 días.
  final double recentAvgPerKg;

  /// Precio por kilo de todas las ventas que anotaron kilos.
  final double histAvgPerKg;

  const LowPriceCheck({
    required this.recentAvgPerKg,
    required this.histAvgPerKg,
  });

  /// true → el precio reciente quedó por debajo del histórico.
  bool get isBelow => recentAvgPerKg < histAvgPerKg;
}

/// La **única** regla de "precio bajo": la comparten la alerta de Inicio
/// (Regla 4) y el insight de Reportes.
///
/// ## Por qué una sola función
///
/// Antes cada una calculaba lo suyo y podían contradecirse el mismo día: la
/// alerta medía **pesos por kilo** y el insight **pesos por venta**, con
/// ventanas de referencia distintas. Con dos reglas, el mismo café podía verse
/// normal en Inicio y barato en Reportes.
///
/// ## Por qué precio por kilo y no monto por venta
///
/// Un quintal y un kilo son montos muy distintos. Comparar "cuánto entra por
/// venta" le dice *«vendes más barato»* al que solo vendió menos, y eso no es
/// un problema de precio: es un problema de volumen. Por eso además **exige
/// que se anoten los kilos** — sin cantidad no hay precio, y un número
/// calculado sin dato es una cifra inventada.
///
/// ## Cuándo se calla
///
/// Devuelve `null` — y no un promedio — cuando:
/// * ninguna venta anotó cantidad;
/// * las ventas están en más de una moneda (no se cruzan pesos y dólares);
/// * no hay [kMinSalesForLowPriceAlert] ventas con kilo, ni 2 en los últimos
///   30 días;
/// * el promedio histórico no es positivo.
///
/// [records] es el histórico completo del productor: la alerta ya miraba todo
/// lo vendido, y que el insight mirara solo el año daría otro número para la
/// misma venta.
///
/// Función pura: misma entrada, misma salida; sin red, sin estado, sin UI.
LowPriceCheck? lowPriceCheck({
  required Iterable<Transaction> records,
  required DateTime now,
  double sacoKg = kSacoKgPorDefecto,
}) {
  final sales = records
      .where((t) =>
          !t.deleted &&
          !t.type.isExpense &&
          isSaleCategory(t.category) &&
          t.quantity != null &&
          t.quantity! > 0)
      .toList();
  if (sales.isEmpty) return null;

  // Un precio por kilo cruzando monedas no es un precio: la regla se calla.
  if (isMixedCurrency(sales)) return null;

  /// Precio por kilo, o `null` si la venta no tiene kilos (racimo/cajón sin
  /// peso). Nunca se completa con 1 kg por unidad.
  double? pricePerKg(Transaction t) {
    final kg = kgFromUnit(t.quantity!, t.unit, t.equivalentKg, sacoKg: sacoKg);
    return kg == null || kg <= 0 ? null : t.amount / kg;
  }

  // Solo las ventas con kilos conocidos entran a los promedios.
  final priced = <({Transaction t, double price})>[];
  for (final t in sales) {
    final p = pricePerKg(t);
    if (p != null && p > 0) priced.add((t: t, price: p));
  }
  if (priced.length < kMinSalesForLowPriceAlert) return null;
  final histAvg =
      priced.fold<double>(0, (a, e) => a + e.price) / priced.length;
  if (histAvg <= 0) return null;

  final limit = DateTime(now.year, now.month, now.day - 30);
  final recent = priced.where((e) => e.t.date.isAfter(limit)).toList();
  if (recent.length < 2) return null;

  final recentAvg =
      recent.fold<double>(0, (a, e) => a + e.price) / recent.length;

  return LowPriceCheck(recentAvgPerKg: recentAvg, histAvgPerKg: histAvg);
}
