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

  /// E4 · cosechas de dos años cerrados (500 y 700 kg), y opcionalmente una
  /// más del año en curso — que **no** debe contar en el promedio.
  ///
  /// Las fechas se calculan contra el reloj para que el test no envejezca.
  List<Harvest> _historico(int anio, {double? extra}) => [
        Harvest(
            id: 'h1',
            cropId: 'cafe',
            date: DateTime(anio - 1, 8, 10),
            amount: 500),
        Harvest(
            id: 'h2',
            cropId: 'cafe',
            date: DateTime(anio - 2, 8, 10),
            amount: 700),
        if (extra != null)
          Harvest(
              id: 'hx',
              cropId: 'cafe',
              date: DateTime(anio, 8, 10),
              amount: extra),
      ];

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

  testWidgets('histórico mixto: muestra la inversión pero sin % recuperado inventado',
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
    // Lo que sí es de una sola moneda sale con ESA moneda. El código va
    // dentro del propio monto, así que ya no se busca «COP» a secas: la
    // inversión del establecimiento también está en COP y ahora también lo
    // dice, que es correcto, no un fallo.
    expect(find.text('USD 150,00'), findsOneWidget,
        reason: 'ingresos por ha medidos solo en USD: 300 / 2 ha');
    expect(find.text('COP 100.000'), findsOneWidget,
        reason: 'gastos por ha medidos solo en COP: 200.000 / 2 ha');
    expect(find.text('COP 8.000.000'), findsOneWidget,
        reason: 'la inversión es de Ajustes, y ahora lo dice con su código');
  });

  // ---- E4 · El rendimiento: la referencia es SU tierra ----

  testWidgets('E4: muestra el promedio de su tierra y su propia meta',
      (tester) async {
    final l10n = stringsFor('es');
    final anio = DateTime.now().year;
    final periodHs = [
      Harvest(id: 'h0', cropId: 'cafe', date: DateTime(anio, 8, 10), amount: 50),
    ];
    final txs = [
      _tx('e1', amount: 200000),
      _tx('i1', amount: 1000000, type: TransactionType.income),
    ];
    await tester.pumpWidget(_wrap(await _provider(), PerHectarePanel(
      crops: const [
        Crop(
            id: 'cafe',
            name: 'Café',
            areaHa: 0.5,
            livePlants: 300,
            expectedYieldPerHa: 1500),
      ],
      periodTransactions: txs,
      periodHarvests: periodHs,
      allTransactions: txs,
      allHarvests: _historico(anio, extra: 50),
    )));
    await tester.pump();

    expect(find.text('Por hectárea'), findsOneWidget);
    // Lo del período sale como siempre.
    expect(find.text('100.0 kg/ha'), findsOneWidget, reason: '50 kg / 0,5 ha');

    // Lo de su tierra: (500 + 700) / 2 = 600 kg por año → 1.200 kg/ha.
    expect(find.text(l10n.yieldAvgHaLabel(2)), findsOneWidget);
    expect(find.text('1200.0 kg/ha'), findsOneWidget,
        reason: 'sale de los años cerrados, no del período');
    expect(find.text(l10n.yieldAvgPlantLabel(2)), findsOneWidget);
    expect(find.text('2.00 kg/planta'), findsOneWidget, reason: '600 / 300');

    // Su meta, puesta por él. Sin tabla de Cenicafé en ningún lado.
    expect(find.text(l10n.yieldGoalLabel), findsOneWidget);
    expect(find.text('1500.0 kg/ha'), findsOneWidget);
  });

  testWidgets('E4: sin dos años cerrados no se inventa un promedio',
      (tester) async {
    final l10n = stringsFor('es');
    final anio = DateTime.now().year;
    await tester.pumpWidget(_wrap(await _provider(), PerHectarePanel(
      crops: const [
        Crop(id: 'cafe', name: 'Café', areaHa: 0.5, livePlants: 300),
      ],
      periodTransactions: const [],
      periodHarvests: [
        Harvest(id: 'h0', cropId: 'cafe', date: DateTime(anio, 8, 10), amount: 50),
      ],
      allTransactions: const [],
      allHarvests: [
        Harvest(
            id: 'h0', cropId: 'cafe', date: DateTime(anio, 8, 10), amount: 50),
        Harvest(
            id: 'h1',
            cropId: 'cafe',
            date: DateTime(anio - 1, 8, 10),
            amount: 500),
      ],
    )));
    await tester.pump();

    expect(find.text('Por hectárea'), findsOneWidget);
    expect(find.text(l10n.yieldAvgHaLabel(1)), findsNothing,
        reason: 'un año cerrado no es un promedio');
    expect(find.text(l10n.yieldAvgHaLabel(2)), findsNothing);
    expect(find.text(l10n.yieldGoalLabel), findsNothing,
        reason: 'no puso meta → no se pinta nada, nunca un 0');
  });

  testWidgets('E4: con matas contadas y sin área se ve kg/planta',
      (tester) async {
    final l10n = stringsFor('es');
    final anio = DateTime.now().year;
    final txs = [
      _tx('e1', amount: 200000),
      _tx('i1', amount: 1000000, type: TransactionType.income),
    ];
    await tester.pumpWidget(_wrap(await _provider(), PerHectarePanel(
      // Contó las matas, nunca midió el terreno: igual tiene rendimiento
      // que ver, y antes el panel entero se le quedaba en blanco.
      crops: const [Crop(id: 'cafe', name: 'Café', livePlants: 300)],
      periodTransactions: txs,
      periodHarvests: [
        Harvest(id: 'h0', cropId: 'cafe', date: DateTime(anio, 8, 10), amount: 50),
      ],
      allTransactions: txs,
      allHarvests: _historico(anio, extra: 50),
    )));
    await tester.pump();

    expect(find.text('Por hectárea'), findsOneWidget);
    expect(find.text('Café · 300 matas'), findsOneWidget,
        reason: 'el encabezado no puede exigir un área que no existe');
    expect(find.text(l10n.perHaYieldPlantLabel), findsOneWidget);
    expect(find.text('0.17 kg/planta'), findsOneWidget);
    expect(find.text(l10n.yieldAvgPlantLabel(2)), findsOneWidget);
    expect(find.text('2.00 kg/planta'), findsOneWidget);
    // Lo que sí necesita área no se pinta.
    expect(find.text('1200.0 kg/ha'), findsNothing);
    expect(find.textContaining('kg/ha'), findsNothing);
  });
}
