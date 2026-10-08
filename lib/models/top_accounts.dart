import 'transaction.dart';

/// Resumen de "con quién trabajas" en un período: compradores (cliente en
/// ventas) y proveedores (proveedor en gastos), con monto y conteo.
/// Compartido entre el PDF, Excel y la tarjeta del reporte.
///
/// Los montos se guardan **por moneda**: nunca se suman monedas distintas.
class TopAccounts {
  final Map<String, AccountTotal> clients;
  final Map<String, AccountTotal> providers;

  TopAccounts._(this.clients, this.providers);

  static TopAccounts from(List<Transaction> transactions) {
    final clients = <String, AccountTotal>{};
    final providers = <String, AccountTotal>{};
    for (final t in transactions) {
      if (!t.type.isExpense && t.client != null && t.client!.isNotEmpty) {
        final row = clients.putIfAbsent(t.client!, AccountTotal.new);
        row.byCurrency[t.currency] = (row.byCurrency[t.currency] ?? 0) + t.amount;
        row.count++;
      } else if (t.type.isExpense &&
          t.provider != null &&
          t.provider!.isNotEmpty) {
        final row = providers.putIfAbsent(t.provider!, AccountTotal.new);
        row.byCurrency[t.currency] = (row.byCurrency[t.currency] ?? 0) + t.amount;
        row.count++;
      }
    }
    return TopAccounts._(clients, providers);
  }

  /// Entradas ordenadas por monto descendente, top [n] (0 = todas).
  ///
  /// Con moneda única se ordena por el total; con moneda mixta, por el
  /// conteo de operaciones — porque no hay una cifra comparable.
  List<MapEntry<String, AccountTotal>> topClients([int n = 0]) =>
      _sorted(clients, n);
  List<MapEntry<String, AccountTotal>> topProviders([int n = 0]) =>
      _sorted(providers, n);

  List<MapEntry<String, AccountTotal>> _sorted(
      Map<String, AccountTotal> map, int n) {
    final list = map.entries.toList()
      ..sort((a, b) {
        final byAmount =
            (b.value.amount ?? double.negativeInfinity).compareTo(
                a.value.amount ?? double.negativeInfinity);
        return byAmount != 0 ? byAmount : b.value.count.compareTo(a.value.count);
      });
    return n > 0 ? list.take(n).toList() : list;
  }

  bool get isEmpty => clients.isEmpty && providers.isEmpty;
}

class AccountTotal {
  /// Totales de esta cuenta **separados por moneda** (clave = código ISO).
  /// Es la única fuente de montos: aquí nunca se mezclan monedas.
  final Map<String, double> byCurrency = {};

  /// Número de operaciones de esa cuenta en el período.
  int count = 0;

  /// Monedas con las que trabajó esta cuenta.
  Set<String> get currencies => byCurrency.keys.toSet();

  /// true si la cuenta mezcla más de una moneda.
  bool get isMixed => byCurrency.length > 1;

  /// Total de la cuenta cuando todas sus operaciones están en **una sola
  /// moneda**. Si se mezclan monedas devuelve null: un total global sería
  /// falso (sumaría pesos con dólares). Usa [byCurrency] para mostrarlo.
  double? get amount =>
      isMixed ? null : (byCurrency.isEmpty ? 0 : byCurrency.values.first);
}
