import 'transaction.dart';

/// Resumen de "con quién trabajas" en un período: compradores (cliente en
/// ventas) y proveedores (proveedor en gastos), con monto y conteo.
/// Compartido entre el PDF, Excel y la tarjeta del reporte.
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
        row.amount += t.amount;
        row.count++;
      } else if (t.type.isExpense &&
          t.provider != null &&
          t.provider!.isNotEmpty) {
        final row = providers.putIfAbsent(t.provider!, AccountTotal.new);
        row.amount += t.amount;
        row.count++;
      }
    }
    return TopAccounts._(clients, providers);
  }

  /// Entradas ordenadas por monto descendente, top [n] (0 = todas).
  List<MapEntry<String, AccountTotal>> topClients([int n = 0]) =>
      _sorted(clients, n);
  List<MapEntry<String, AccountTotal>> topProviders([int n = 0]) =>
      _sorted(providers, n);

  List<MapEntry<String, AccountTotal>> _sorted(
      Map<String, AccountTotal> map, int n) {
    final list = map.entries.toList()
      ..sort((a, b) => b.value.amount.compareTo(a.value.amount));
    return n > 0 ? list.take(n).toList() : list;
  }

  bool get isEmpty => clients.isEmpty && providers.isEmpty;
}

class AccountTotal {
  double amount = 0;
  int count = 0;
}