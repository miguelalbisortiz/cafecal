import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/widgets/per_hectare_panel.dart';

Widget _wrap(TransactionProvider provider, Widget child) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

Future<TransactionProvider> _provider() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  return TransactionProvider(LocalStore(prefs));
}

Crop _crop({double? area, double? establishmentCost}) => Crop(
      id: 'cafe',
      name: 'Café',
      areaHa: area,
      establishmentCost: establishmentCost,
    );

Transaction _tx(String id, {required double amount, TransactionType type = TransactionType.expense, String? cropId = 'cafe', DateTime? date, String currency = 'COP'}) =>
    Transaction(
      id: id,
      cropId: cropId,
      type: type,
      category: type == TransactionType.expense ? 'catManoObra' : 'catVentaCafe',
      amount: amount,
      currency: currency,
      date: date ?? DateTime(2026, 8, 1),
      createdAt: DateTime(2026, 8, 1),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('oculta el panel si no hay datos ni área', (tester) async {
    await tester.pumpWidget(_wrap(await _provider(), PerHectarePanel(
      crops: [_crop()],
      periodTransactions: const [],
      periodHarvests: const [],
      allTransactions: const [],
    )));
    await tester.pump();
    expect(find.text('Por hectárea'), findsNothing);
  });

  testWidgets('sugiere registrar el área si hay datos pero ninguna tiene área', (tester) async {
    await tester.pumpWidget(_wrap(await _provider(), PerHectarePanel(
      crops: [_crop()],
      periodTransactions: const [],
      periodHarvests: [Harvest(id: 'h1', cropId: 'cafe', date: DateTime(2026, 8), amount: 10)],
      allTransactions: const [],
    )));
    await tester.pump();
    expect(find.textContaining('Registra el área'), findsOneWidget);
  });

  testWidgets('muestra KPIs por hectárea con área y datos', (tester) async {
    final harvests = [
      Harvest(id: 'h1', cropId: 'cafe', date: DateTime(2026, 8, 10), amount: 50),
    ];
    final txs = [
      _tx('e1', amount: 200000),
      _tx('i1', amount: 1000000, type: TransactionType.income),
    ];
    await tester.pumpWidget(_wrap(await _provider(), PerHectarePanel(
      crops: [_crop(area: 2)],
      periodTransactions: txs,
      periodHarvests: harvests,
      allTransactions: txs,
    )));
    await tester.pump();
    expect(find.text('Por hectárea'), findsOneWidget);
    expect(find.text('Café · 2.00 ha'), findsOneWidget);
    expect(find.text('25.0 kg/ha'), findsOneWidget);
    expect(find.text('Ventas por ha'), findsOneWidget);
    expect(find.text('Gastos por ha'), findsOneWidget);
    expect(find.text('Margen por ha'), findsOneWidget);
  });

  testWidgets('muestra amortización solo si hay inversión registrada', (tester) async {
    final txs = [
      _tx('e1', amount: 200000),
      _tx('i1', amount: 1000000, type: TransactionType.income),
    ];
    await tester.pumpWidget(_wrap(await _provider(), PerHectarePanel(
      crops: [_crop(area: 2, establishmentCost: 8000000)],
      periodTransactions: txs,
      periodHarvests: const [],
      allTransactions: txs,
    )));
    await tester.pump();
    expect(find.text('Inversión del establecimiento'), findsOneWidget);
    expect(find.text('Recuperado'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    expect(find.textContaining('años (aprox.)'), findsOneWidget);
  });

  testWidgets('no inventa amortización si solo hay inversión y ningún movimiento', (tester) async {
    await tester.pumpWidget(_wrap(await _provider(), PerHectarePanel(
      crops: [_crop(area: 2, establishmentCost: 8000000)],
      periodTransactions: const [],
      periodHarvests: const [],
      allTransactions: const [],
    )));
    await tester.pump();
    expect(find.text('Inversión del establecimiento'), findsOneWidget);
    expect(find.text('Pendiente de recuperarse'), findsOneWidget);
    expect(find.textContaining('años (aprox.)'), findsNothing);
  });

  // ---- Moneda mixta: nunca una cifra de dinero inventada ----

  testWidgets('cultivo con moneda mixta: sin totales de dinero falsos',
      (tester) async {
    final l10n = stringsFor('es');
    final txs = [
      _tx('e1', amount: 200000),
      _tx('i1', amount: 1000000, type: TransactionType.income),
      _tx('e2', amount: 300, currency: 'USD'),
      _tx('i2', amount: 200, type: TransactionType.income, currency: 'USD'),
    ];
    await tester.pumpWidget(_wrap(await _provider(), PerHectarePanel(
      crops: [_crop(area: 2)],
      periodTransactions: txs,
      periodHarvests: [
        Harvest(id: 'h1', cropId: 'cafe', date: DateTime(2026, 8, 10), amount: 50),
      ],
      allTransactions: txs,
    )));
    await tester.pump();

    expect(find.text('Por hectárea'), findsOneWidget);
    expect(find.text('25.0 kg/ha'), findsOneWidget,
        reason: 'los kilos no son dinero: la producción sigue midiéndose');
    expect(find.text('Ventas por ha'), findsNothing,
        reason: 'no se imprime un ingreso/ha cruzando pesos con dólares');
    expect(find.text('Gastos por ha'), findsNothing);
    expect(find.text('Margen por ha'), findsNothing,
        reason: 'el margen resta las dos monedas: sería falso');
    expect(find.textContaining(l10n.currencyMixedHint(2)), findsOneWidget,
        reason: 'el aviso explica por qué faltan las cifras');
  });

  testWidgets(
      'histórico mixto: muestra la inversión pero sin % recuperado inventado',
      (tester) async {
    final l10n = stringsFor('es');
    final txs = [
      _tx('e1', amount: 200000),
      _tx('i1', amount: 300, type: TransactionType.income, currency: 'USD'),
    ];
    await tester.pumpWidget(_wrap(await _provider(), PerHectarePanel(
      crops: [_crop(area: 2, establishmentCost: 8000000)],
      periodTransactions: txs,
      periodHarvests: const [],
      allTransactions: txs,
    )));
    await tester.pump();

    expect(find.text('Inversión del establecimiento'), findsOneWidget);
    expect(find.text('Recuperado'), findsNothing,
        reason: 'el margen histórico mezcla monedas: no hay % cierto');
    expect(find.text('Pendiente de recuperarse'), findsNothing);
    expect(find.textContaining('años (aprox.)'), findsNothing,
        reason: 'sin margen anual no se estima el pago');
    // Un aviso por bloque: los KPIs del período y el histórico.
    expect(find.textContaining(l10n.currencyMixedHint(2)), findsNWidgets(2));
    // Lo que sí es de una sola moneda sale con esa moneda al lado.
    expect(find.textContaining('USD'), findsOneWidget,
        reason: 'ingresos por ha medidos solo en USD');
    expect(find.textContaining('COP'), findsOneWidget,
        reason: 'gastos por ha medidos solo en COP');
  });
}
