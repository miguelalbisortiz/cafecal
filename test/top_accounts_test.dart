import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/top_accounts.dart';
import 'package:mi_cafetal/models/transaction.dart';

Transaction _t({
  required TransactionType type,
  required double amount,
  String? client,
  String? provider,
}) {
  return Transaction(
    id: '${type.name}_$amount',
    type: type,
    category: 'otro',
    amount: amount,
    date: DateTime(2026, 1, 10),
    createdAt: DateTime(2026, 1, 1),
    client: client,
    provider: provider,
  );
}

void main() {
  test('agrupa compradores y proveedores con monto y conteo', () {
    final accounts = TopAccounts.from([
      _t(type: TransactionType.income, amount: 100, client: 'Juan'),
      _t(type: TransactionType.income, amount: 200, client: 'Juan'),
      _t(type: TransactionType.income, amount: 300, client: 'Maria'),
      _t(type: TransactionType.expense, amount: 50, provider: 'Agrofertil'),
      _t(type: TransactionType.expense, amount: 150, provider: 'Agrofertil'),
    ]);
    expect(accounts.clients['Juan']!.amount, 300);
    expect(accounts.clients['Juan']!.count, 2);
    expect(accounts.clients['Maria']!.count, 1);
    expect(accounts.providers['Agrofertil']!.amount, 200);
    expect(accounts.providers['Agrofertil']!.count, 2);
  });

  test('top ordena por monto descendente y respeta el tope', () {
    final accounts = TopAccounts.from([
      _t(type: TransactionType.income, amount: 100, client: 'A'),
      _t(type: TransactionType.income, amount: 500, client: 'B'),
      _t(type: TransactionType.income, amount: 300, client: 'C'),
      _t(type: TransactionType.income, amount: 400, client: 'D'),
    ]);
    final top = accounts.topClients(3);
    expect(top.map((e) => e.key).toList(), ['B', 'D', 'C']);
    expect(top.length, 3);
  });

  test('ventas sin cliente y gastos sin proveedor no cuentan', () {
    final accounts = TopAccounts.from([
      _t(type: TransactionType.income, amount: 100),
      _t(type: TransactionType.expense, amount: 50),
      _t(type: TransactionType.income, amount: 100, client: ''),
    ]);
    expect(accounts.isEmpty, isTrue);
  });

  test('venta con cliente y proveedor al mismo tiempo solo cuenta el cliente', () {
    // Una venta puede tener client; el branch provider solo aplica a gastos.
    final accounts = TopAccounts.from([
      Transaction(
        id: 'x',
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 100,
        date: DateTime(2026, 1, 10),
        createdAt: DateTime(2026, 1, 1),
        client: 'Juan',
        provider: 'no aplica',
      ),
    ]);
    expect(accounts.clients.containsKey('Juan'), isTrue);
    expect(accounts.providers, isEmpty);
  });
}