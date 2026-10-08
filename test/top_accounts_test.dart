import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/top_accounts.dart';
import 'package:mi_cafetal/models/transaction.dart';

Transaction _t({
  required TransactionType type,
  required double amount,
  String? client,
  String? provider,
  String currency = 'COP',
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
    currency: currency,
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

  // ---- Moneda mixta: nunca un total global falso ----

  test('moneda única: amount devuelve el total de siempre', () {
    final accounts = TopAccounts.from([
      _t(type: TransactionType.income, amount: 100, client: 'Juan'),
      _t(type: TransactionType.income, amount: 200, client: 'Juan'),
    ]);
    final juan = accounts.clients['Juan']!;
    expect(juan.isMixed, isFalse);
    expect(juan.amount, 300);
    expect(juan.byCurrency, {'COP': 300.0});
    expect(juan.currencies, {'COP'});
  });

  test('moneda mixta: no devuelve un total global falso, lista por moneda',
      () {
    final accounts = TopAccounts.from([
      _t(type: TransactionType.income, amount: 100, client: 'Juan'),
      _t(
          type: TransactionType.income,
          amount: 50,
          client: 'Juan',
          currency: 'USD'),
      _t(
          type: TransactionType.expense,
          amount: 30,
          provider: 'Agrofertil',
          currency: 'EUR'),
      _t(type: TransactionType.expense, amount: 70, provider: 'Agrofertil'),
    ]);

    final juan = accounts.clients['Juan']!;
    expect(juan.isMixed, isTrue);
    expect(juan.amount, isNull,
        reason: '100 COP + 50 USD no es una cifra que se pueda mostrar');
    expect(juan.byCurrency, {'COP': 100.0, 'USD': 50.0});
    expect(juan.count, 2);

    // Cada cuenta conserva su total por moneda; la lista sigue ordenada.
    final agro = accounts.providers['Agrofertil']!;
    expect(agro.amount, isNull);
    expect(agro.byCurrency, {'COP': 70.0, 'EUR': 30.0});
    expect(accounts.topProviders().map((e) => e.key), ['Agrofertil']);
  });
}