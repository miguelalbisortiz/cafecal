import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/report_screen.dart';
import 'package:mi_cafetal/services/currency_conversion.dart';
import 'package:mi_cafetal/services/currency_rates_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/utils/format.dart';
import 'package:mi_cafetal/widgets/cash_box_card.dart';
import 'package:mi_cafetal/widgets/period_totals.dart';

/// Regla A estricta: 1 moneda → igual que siempre; 2+ monedas → cada monto
/// con su código, sin netos, ROI, % ni saldos que crucen monedas.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void viewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<(SharedPreferences, TransactionProvider)> nuevaFinca() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return (prefs, TransactionProvider(LocalStore(prefs)));
  }

  Widget pantalla(TransactionProvider tx, {CurrencyConversionService? fx}) {
    Widget tree = const MaterialApp(
      locale: Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReportScreen(),
    );
    if (fx != null) tree = CurrencyConversionScope(service: fx, child: tree);
    return ChangeNotifierProvider.value(value: tx, child: tree);
  }

  /// Deja pasar los reintentos de la tasa (400 ms + 800 ms) por si el
  /// proveedor no contesta: la pantalla no se bloquea esperando.
  Future<void> asentar(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
  }

  /// Servicio de tasa sin red: el período mezclado lanza la consulta y hay
  /// que dejar que termine para no dejar timers pendientes.
  CurrencyConversionService sinRed(SharedPreferences prefs) =>
      CurrencyConversionService(
        rates: CurrencyRatesService(
            client: MockClient((_) async => throw Exception('sin red'))),
        prefs: () async => prefs,
      );

  group('Desglose por cultivo', () {
    testWidgets(
        'cultivo con dos monedas: desglose por moneda y sin ROI ni resultado',
        (tester) async {
      viewport(tester);
      final (prefs, tx) = await nuevaFinca();
      final cafe = await tx.addCrop('Café');
      final hoy = DateTime.now();
      await tx.addTransaction(
          type: TransactionType.income,
          category: 'venta_cafe',
          amount: 5000,
          cropId: cafe.id,
          date: hoy);
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'fertilizante',
          amount: 1000,
          cropId: cafe.id,
          date: hoy);
      await tx.addTransaction(
          type: TransactionType.income,
          category: 'venta_otro',
          amount: 200,
          currency: 'EUR',
          cropId: cafe.id,
          date: hoy);
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'transporte',
          amount: 50,
          currency: 'EUR',
          cropId: cafe.id,
          date: hoy);

      await tester.pumpWidget(pantalla(tx, fx: sinRed(prefs)));
      await asentar(tester);

      final l10n = stringsFor('es');
      final now = DateTime.now();
      final titulo = l10n.cropBreakdownTitle(
          l10n.reportPeriodMonth(l10n.monthFull[now.month - 1], now.year));
      final desglose = find.ancestor(
          of: find.text(titulo), matching: find.byType(Card));
      expect(desglose, findsOneWidget);
      String money(double v, String c) =>
          formatAmount(v, currency: c, locale: tx.settings.locale);

      expect(
        find.descendant(
            of: desglose,
            matching: find.text(l10n.cropMixedCurrencyNote(2))),
        findsOneWidget,
        reason: 'avisa de que cada moneda va por separado',
      );
      expect(
          find.descendant(
              of: desglose,
              matching: find.text('${l10n.cropBreakdownSummaryG} · COP')),
          findsOneWidget);
      expect(
          find.descendant(
              of: desglose,
              matching: find.text('${l10n.cropBreakdownSummaryI} · EUR')),
          findsOneWidget);
      expect(
          find.descendant(
              of: desglose,
              matching: find.text('${money(1000, 'COP')} COP')),
          findsOneWidget);
      expect(
          find.descendant(
              of: desglose, matching: find.text('${money(200, 'EUR')} EUR')),
          findsOneWidget);
      expect(
        find.descendant(
          of: desglose,
          matching: find.byWidgetPredicate(
              (w) => w is Text && (w.data ?? '').startsWith('ROI ')),
        ),
        findsNothing,
        reason: 'el ROI cruzando pesos y euros sería mentira',
      );
      expect(
        find.descendant(
            of: desglose, matching: find.text(l10n.cropBreakdownSummaryR)),
        findsNothing,
        reason: 'tampoco se imprime un resultado único',
      );
    });

    testWidgets('cultivo de una sola moneda: ROI y resultado como siempre',
        (tester) async {
      viewport(tester);
      final (_, tx) = await nuevaFinca();
      final cafe = await tx.addCrop('Café');
      final hoy = DateTime.now();
      await tx.addTransaction(
          type: TransactionType.income,
          category: 'venta_cafe',
          amount: 5000,
          cropId: cafe.id,
          date: hoy);
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'fertilizante',
          amount: 1000,
          cropId: cafe.id,
          date: hoy);

      await tester.pumpWidget(pantalla(tx));
      await tester.pumpAndSettle();

      final l10n = stringsFor('es');
      final now = DateTime.now();
      final titulo = l10n.cropBreakdownTitle(
          l10n.reportPeriodMonth(l10n.monthFull[now.month - 1], now.year));
      final desglose = find.ancestor(
          of: find.text(titulo), matching: find.byType(Card));
      expect(desglose, findsOneWidget);
      String money(double v) =>
          formatAmount(v, currency: 'COP', locale: tx.settings.locale);

      expect(
          find.descendant(
              of: desglose, matching: find.textContaining('ROI 400%')),
          findsOneWidget,
          reason: '(5.000 − 1.000) / 1.000 = 400%');
      expect(
          find.descendant(
              of: desglose, matching: find.text(l10n.cropBreakdownSummaryR)),
          findsOneWidget);
      expect(
          find.descendant(of: desglose, matching: find.text(money(4000))),
          findsOneWidget,
          reason: 'el resultado de siempre sigue ahí');
      expect(
          find.descendant(
              of: desglose, matching: find.text(l10n.cropMixedCurrencyNote(2))),
          findsNothing,
          reason: 'sin mezcla no hay nada que avisar');
    });
  });

  group('Tarjeta de Planilla', () {
    Future<void> sembrarPlanilla(TransactionProvider tx) async {
      final hoy = DateTime.now();
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 400000,
          quantity: 8,
          unit: 'día',
          provider: 'Juan',
          date: hoy);
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 100,
          currency: 'EUR',
          quantity: 1,
          unit: 'día',
          provider: 'Juan',
          date: hoy);
    }

    testWidgets('moneda mixta: cada moneda con su código y sin total único',
        (tester) async {
      viewport(tester);
      final (prefs, tx) = await nuevaFinca();
      await sembrarPlanilla(tx);

      await tester.pumpWidget(pantalla(tx, fx: sinRed(prefs)));
      await asentar(tester);

      final l10n = stringsFor('es');
      final planilla = find.ancestor(
          of: find.text(l10n.reportPayrollSection), matching: find.byType(Card));
      expect(planilla, findsOneWidget);

      expect(
        find.descendant(
            of: planilla,
            matching:
                find.text(l10n.currencyMixedByCurrencyNote(2))),
        findsOneWidget,
      );
      expect(
        find.descendant(of: planilla, matching: find.textContaining('EUR')),
        findsNWidgets(2),
        reason: 'fila del trabajador y total, ambos moneda por moneda',
      );
      final falsoTotal = formatAmount(400100,
          currency: 'COP', locale: tx.settings.locale);
      expect(
        find.descendant(of: planilla, matching: find.text(falsoTotal)),
        findsNothing,
        reason: '400.000 COP + 100 EUR no suman 400.100',
      );
    });

    testWidgets('moneda única: subtotal y total siguen como siempre',
        (tester) async {
      viewport(tester);
      final (_, tx) = await nuevaFinca();
      final hoy = DateTime.now();
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 400000,
          quantity: 8,
          unit: 'día',
          provider: 'Juan',
          date: hoy);

      await tester.pumpWidget(pantalla(tx));
      await tester.pumpAndSettle();

      final l10n = stringsFor('es');
      final planilla = find.ancestor(
          of: find.text(l10n.reportPayrollSection), matching: find.byType(Card));
      expect(planilla, findsOneWidget);
      final total = formatAmount(400000,
          currency: 'COP', locale: tx.settings.locale);

      expect(
        find.descendant(of: planilla, matching: find.text(total)),
        findsNWidgets(2),
        reason: 'subtotal del trabajador y total del período',
      );
      expect(
        find.descendant(
            of: planilla,
            matching: find.text(l10n.currencyMixedByCurrencyNote(2))),
        findsNothing,
      );
    });
  });

  group('Tarjeta de Caja', () {
    Future<void> sembrarCaja(TransactionProvider tx) async {
      await tx.updateSettings(
          tx.settings.copyWith(cajaMenorMensual: 800000.0));
      final hoy = DateTime.now();
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 400000,
          date: hoy);
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'energia',
          amount: 100,
          currency: 'EUR',
          date: hoy);
    }

    testWidgets('en el reporte: gastos por moneda y sin saldo contra presupuesto',
        (tester) async {
      viewport(tester);
      final (prefs, tx) = await nuevaFinca();
      await sembrarCaja(tx);

      await tester.pumpWidget(pantalla(tx, fx: sinRed(prefs)));
      await asentar(tester);

      final l10n = stringsFor('es');
      final caja = find.ancestor(
          of: find.text(l10n.cashBoxTitle), matching: find.byType(Card));
      expect(caja, findsOneWidget);

      expect(
        find.descendant(
            of: caja,
            matching: find.text(l10n.currencyMixedByCurrencyNote(2))),
        findsOneWidget,
      );
      expect(
        find.descendant(of: caja, matching: find.text(l10n.reportCashBoxBalance)),
        findsNothing,
        reason: 'restar euros al presupuesto en pesos daría un saldo falso',
      );
      expect(
        find.descendant(of: caja, matching: find.textContaining('EUR')),
        findsWidgets,
        reason: 'los gastos salen con su moneda',
      );
    });

    testWidgets('tarjeta del home: con mezcla no hay barra ni porcentaje',
        (tester) async {
      viewport(tester);
      final (_, tx) = await nuevaFinca();
      await sembrarCaja(tx);

      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: tx,
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CashBoxCard()),
        ),
      ));
      await tester.pumpAndSettle();

      final l10n = stringsFor('es');
      expect(find.text(l10n.currencyMixedByCurrencyNote(2)), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing,
          reason: 'sin comparación posible no se pinta una barra');
      expect(find.textContaining(l10n.reportCashBoxBudget), findsOneWidget,
          reason: 'el presupuesto se muestra con su propia moneda');
    });

    testWidgets('tarjeta del home: moneda única conserva barra y porcentaje',
        (tester) async {
      viewport(tester);
      final (_, tx) = await nuevaFinca();
      await tx.updateSettings(
          tx.settings.copyWith(cajaMenorMensual: 800000.0));
      final hoy = DateTime.now();
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 400000,
          date: hoy);

      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: tx,
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CashBoxCard()),
        ),
      ));
      await tester.pumpAndSettle();

      final l10n = stringsFor('es');
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('%'), findsOneWidget);
      expect(find.textContaining(l10n.cashBoxRemaining), findsOneWidget);
      expect(find.text(l10n.currencyMixedByCurrencyNote(2)), findsNothing);
    });
  });

  testWidgets(
      'P2: con moneda mixta (aunque haya tasa) no se inventa un precio por kilo',
      (tester) async {
    viewport(tester);
    final (prefs, tx) = await nuevaFinca();
    final hoy = DateTime.now();

    await tx.addTransaction(
        type: TransactionType.expense,
        category: 'fertilizante',
        amount: 1000,
        date: hoy);
    await tx.addHarvest(cropId: null, date: hoy, amount: 10, unit: 'kg');
    await tx.addTransaction(
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 12000,
        quantity: 10,
        unit: 'kg',
        date: hoy);
    // Segunda moneda: el período queda mezclado.
    await tx.addTransaction(
        type: TransactionType.income,
        category: 'venta_otro',
        amount: 100,
        currency: 'EUR',
        date: hoy);

    final fx = CurrencyConversionService(
      rates: CurrencyRatesService(
          client: MockClient((_) async => http.Response(
                '{"result":"success","rates":{"COP":4.0}}',
                200,
                headers: {'content-type': 'application/json'},
              ))),
      prefs: () async => prefs,
    );

    await tester.pumpWidget(pantalla(tx, fx: fx));
    await asentar(tester);

    final l10n = stringsFor('es');
    expect(find.text(l10n.currencyRateNote), findsOneWidget,
        reason: 'la tasa sí está disponible: el test entra por esa rama');
    expect(find.text(l10n.metricCostPriceLabel), findsNothing,
        reason: 'precio/kg y costo/kg no estarían en la misma moneda');
  });
}
