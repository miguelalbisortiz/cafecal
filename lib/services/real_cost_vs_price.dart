import '../models/crop.dart';
import '../models/harvest.dart';
import '../models/product_state.dart';
import '../models/transaction.dart';
import '../models/units.dart';
import 'threshing_yield.dart';

/// Fase 3 · ¿el precio del estado en que vende cubre lo que cuesta producirlo?
///
/// El resto de la app compara costos entre sí y precios entre sí; esta es la
/// única regla que los pone **frente a frente**, que es la pregunta del
/// productor: «lo que me pagan por kilo, ¿me deja algo?».
///
/// Todo sale de piezas que ya existen:
///
///  * el **costo real por kg vendible** lo calcula [threshingRows], la misma
///    función que pinta la tarjeta de Reportes, el PDF y el Excel — la alerta
///    no puede citar un costo distinto del que él ya ve;
///  * el **precio logrado** usa los mismos kilos netos que la tarjeta de
///    ventas por estado ([kgFromUnit] sobre `netQuantity`, con su saco).
///
/// **Los dos lados tienen que hablar del mismo estado.** El costo de
/// [threshingRows] es por kilo **vendible** (pergamino), así que compararlo
/// tal cual contra el precio de la cereza daba un margen de −300% en toda
/// venta de cereza, sin mirar el precio: 100 kg de cereza cuestan lo mismo que
/// los 20 kg de pergamino que salen de ellos. Por eso el costo se pasa a la
/// base del estado antes de restar: en cereza es el costo por kilo vendible
/// dividido por el factor de trilla, porque el factor dice justamente cuántos
/// kilos de cereza hacen un kilo vendible.
///
/// Verde y tueste **no se comparan**: no hay rendimiento de trilla verde ni de
/// tostión anotado, y suponerlo sería inventar el número del que depende el
/// margen. Cuando exista ese dato, se agrega acá y la regla los cubre sola.
class RealCostRow {
  final Crop crop;
  final ProductState state;

  /// Precio medio por kilo del estado, en [currency].
  final double pricePerKg;

  /// Costo real de producción por kilo **en la base de [state]**, en
  /// [currency]. En cereza ya viene dividido por el factor de trilla; en
  /// pergamino es el costo por kilo vendible tal cual.
  final double costPerKg;

  final String currency;

  const RealCostRow({
    required this.crop,
    required this.state,
    required this.pricePerKg,
    required this.costPerKg,
    required this.currency,
  });

  /// Lo que queda después de cubrir el costo: `0.08` = 8% del precio.
  /// Negativo = se vende por debajo del costo.
  double get margin => (pricePerKg - costPerKg) / pricePerKg;
}

/// El margen por debajo del cual la app avisa. Lo eligió el dueño: por debajo
/// del 10% no hay colchón para un imprevisto.
const double kMinRealMargin = 0.10;

/// Una fila por cultivo: **el estado con peor margen** que quede debajo de
/// [minMargin], ordenadas de peor a mejor.
///
/// Una sola fila por cultivo es deliberado. Si vende en cereza, pergamino y
/// verde por debajo del 10%, tres avisos dicen lo mismo y se aprende a
/// ignorarlos: el que importa es el que peor está.
///
/// Ventana de **12 meses** para los dos lados de la resta, igual que «vendido
/// vs cosechado»: el costo de este año no se compara con precios de hace tres.
///
/// Devuelve vacío —nunca una fila con ceros— cuando falta el factor de
/// trilla, no hay cosecha ni ventas, la venta no tiene kilos, o las monedas
/// no coinciden. Un margen inventado es peor que ningún aviso.
List<RealCostRow> realCostWarnings({
  required Iterable<Transaction> transactions,
  required Iterable<Crop> crops,
  required Iterable<Harvest> harvests,
  required double sacoKg,
  required DateTime now,
  double minMargin = kMinRealMargin,
}) {
  final cutoff = DateTime(now.year - 1, now.month, now.day);
  final recentTx = [
    for (final t in transactions)
      if (!t.deleted && !t.date.isBefore(cutoff)) t,
  ];
  final recentHarvests = [
    for (final h in harvests)
      if (!h.date.isBefore(cutoff)) h,
  ];

  final costs = threshingRows(
    crops: crops,
    harvests: recentHarvests,
    transactions: recentTx,
    sacoKg: sacoKg,
  );

  final out = <RealCostRow>[];
  for (final row in costs) {
    final currency = row.costCurrency;
    final cost = row.costPerSellableKg;
    if (currency == null || cost == null || cost <= 0) continue;

    final amount = <ProductState, double>{};
    final kilos = <ProductState, double>{};
    final monedas = <ProductState, Set<String>>{};

    for (final t in recentTx) {
      if (t.type.isExpense) continue;
      if (t.cropId != row.crop.id) continue;
      final state = t.productState;
      if (state == null) continue;
      // Una venta sin kilos no tiene precio por kilo: sumar su plata sobre
      // los kilos de las demás inflaría el promedio y escondería el margen.
      final kg = kgFromUnit(
        t.netQuantity ?? 0,
        t.unit,
        t.equivalentKg,
        sacoKg: sacoKg,
      );
      if (kg == null || kg <= 0 || t.amount <= 0) continue;
      monedas.putIfAbsent(state, () => <String>{}).add(t.currency);
      amount[state] = (amount[state] ?? 0) + t.amount;
      kilos[state] = (kilos[state] ?? 0) + kg;
    }

    RealCostRow? worst;
    for (final state in ProductState.values) {
      // Un estado vendido en dos monedas no tiene «precio medio»: promediar
      // pesos con dólares daría un número que no existe.
      final suyas = monedas[state];
      if (suyas == null || suyas.length != 1) continue;
      // El precio y el costo tienen que estar en la misma moneda.
      if (suyas.first != currency) continue;
      final kg = kilos[state] ?? 0;
      final total = amount[state] ?? 0;
      if (kg <= 0 || total <= 0) continue;

      final costInState = _costInState(cost, row.crop, state);
      if (costInState == null) continue;

      final candidate = RealCostRow(
        crop: row.crop,
        state: state,
        pricePerKg: total / kg,
        costPerKg: costInState,
        currency: currency,
      );
      if (candidate.margin >= minMargin) continue;
      if (worst == null || candidate.margin < worst.margin) worst = candidate;
    }
    if (worst != null) out.add(worst);
  }

  out.sort((a, b) => a.margin.compareTo(b.margin));
  return out;
}

/// El costo por kilo **en la base de [state]**, o `null` si no hay conversión.
///
/// [costPerSellableKg] está en base pergamino (kilo vendible). La cereza se
/// pasa dividiendo por el factor de trilla: si 5 kg de cereza hacen 1 kg
/// vendible, un kilo de cereza cuesta la quinta parte de un kilo de pergamino.
///
/// Verde y tueste devuelven `null` a propósito: la app no tiene anotado el
/// rendimiento de trilla verde ni el de tostión, y suponer un 85% o un 80%
/// haría que el margen dependa de un número que nadie registró.
double? _costInState(
    double costPerSellableKg, Crop crop, ProductState state) {
  switch (state) {
    case ProductState.pergamino:
      return costPerSellableKg;
    case ProductState.cereza:
      final factor = crop.threshingYield;
      if (factor == null || factor <= 1) return null;
      return costPerSellableKg / factor;
    case ProductState.verde:
    case ProductState.tueste:
      return null;
  }
}
