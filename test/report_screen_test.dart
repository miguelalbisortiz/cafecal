import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/report_screen.dart';
import 'package:mi_cafetal/services/currency_conversion.dart';
import 'package:mi_cafetal/services/currency_rates_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/utils/format.dart';
import 'package:mi_cafetal/widgets/currency_breakdown.dart';
import 'package:mi_cafetal/widgets/period_totals.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'el mes por defecto del reporte coincide con el mes actual (sin off-by-one)',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final mesActual = stringsFor('es').monthFull[now.month - 1];
    // El mes siguiente, girando de diciembre a enero.
    final mesSiguiente = stringsFor('es').monthFull[now.month % 12];

    expect(find.textContaining(mesActual), findsWidgets,
        reason: 'debe mostrar el mes actual ($mesActual)');
    expect(find.textContaining(mesSiguiente), findsNothing,
        reason: 'no debe mostrar el mes siguiente ($mesSiguiente)');
  });

  testWidgets(
      'sin ventas, margen y ratio explican el guion largo en vez de dejarlo mudo',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text(stringsFor('es').metricNoSales), findsNWidgets(2),
        reason: 'tanto el margen como gastos vs ingresos deben decir por qué '
            'no se pueden calcular');
  });

  testWidgets(
      'la tarjeta de Siembras (P5) muestra el estado actual y las del período',
      (tester) async {
    // El reporte es una ListView larga: sin viewport alto la tarjeta de
    // Siembras queda fuera del área construida y no aparece.
    tester.view.physicalSize = const Size(900, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));

    final crop = await provider.addCrop('Café');
    final hoy = DateTime.now();
    await provider.addSowing(
        cropId: crop.id, date: hoy, plants: 400, areaHa: 0.5);
    await provider.addSowing(
      cropId: crop.id,
      date: hoy,
      kind: SowingKind.resiembra,
      plants: 50,
      lostPlants: 30,
      reason: 'sequía',
    );

    expect(provider.sowings, hasLength(2),
        reason: 'el provider debe conservar las siembras recién creadas');
    expect(provider.crops.map((c) => c.id), contains(crop.id),
        reason: 'el provider debe tener el cultivo creado');

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final l10n = stringsFor('es');
    expect(find.text(l10n.reportSowingsSection), findsOneWidget,
        reason: 'la tarjeta de Siembras debe aparecer tras Cosechas');
    expect(find.text(l10n.reportSowingsNow), findsOneWidget,
        reason: 'debe mostrar qué tengo plantado hoy');
    expect(
      find.text('420 ${l10n.reportSowingsPlantMany}'),
      findsNWidgets(2),
      reason: '400 - 30 perdidas + 50 de resiembra = 420 plantas vivas, '
          'tanto en la fila del cultivo como en el total',
    );
    expect(
      find.text(l10n.reportSowingsLostLine(30, 'sequía')),
      findsOneWidget,
      reason: 'las pérdidas deben mostrar cantidad y motivo (A1)',
    );
    expect(find.textContaining('Siembras en '), findsOneWidget,
        reason: 'debe listar las siembras del período seleccionado');
  });

  testWidgets(
      'P5: el estado de resultados agrupa los gastos sin esconder el detalle',
      (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final hoy = DateTime.now();

    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'fertilizante',
      amount: 1000.0,
      description: 'Fertilizante',
      date: hoy,
    );
    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'transporte',
      amount: 500.0,
      description: 'Transporte',
      date: hoy,
    );
    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'arriendo',
      amount: 300.0,
      description: 'Arriendo',
      date: hoy,
    );

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final l10n = stringsFor('es');
    expect(find.text(l10n.expenseGroupProduccion), findsOneWidget);
    expect(find.text(l10n.expenseGroupVenta), findsOneWidget);
    expect(find.text(l10n.expenseGroupFijos), findsOneWidget);
    expect(find.text(l10n.expenseGroupOtros), findsNothing,
        reason: 'sin gastos "otro" no debe abrirse ese bloque');

    // Agrupar no esconde nada: las categorías siguen listadas debajo.
    expect(find.text(l10n.expenseCategory('fertilizante')), findsOneWidget);
    expect(find.text(l10n.expenseCategory('transporte')), findsOneWidget);
    expect(find.text(l10n.expenseCategory('arriendo')), findsOneWidget);
  });

  testWidgets('P2: el estado de resultados compara precio/kg con costo/kg',
      (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final hoy = DateTime.now();

    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'fertilizante',
      amount: 1000.0,
      date: hoy,
    );
    await provider.addHarvest(
        cropId: null, date: hoy, amount: 10, unit: 'kg');
    await provider.addTransaction(
      type: TransactionType.income,
      category: 'venta_cafe',
      amount: 12000.0,
      quantity: 10,
      unit: 'kg',
      date: hoy,
    );

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final l10n = stringsFor('es');
    // 1000 de gasto sobre 10 kg cosechados = $100/kg de costo;
    // 12000 sobre 10 kg vendidos = $1200/kg de precio.
    expect(find.text(l10n.metricCostPriceLabel), findsOneWidget);
    expect(find.textContaining('por encima de tu costo'), findsOneWidget,
        reason: 'precio > costo debe decirlo con palabras, no solo en verde');
  });

  testWidgets('P2: sin cosecha ni kilos anotados la línea ni aparece',
      (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));

    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'fertilizante',
      amount: 1000.0,
      date: DateTime.now(),
    );

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final l10n = stringsFor('es');
    expect(find.text(l10n.metricCostPriceLabel), findsNothing,
        reason: 'no hay nada que comparar: no hay que llenar el reporte de '
            '"no se puede calcular"');
    // Las otras dos métricas siguen explicándose como antes.
    expect(find.text(l10n.metricNoSales), findsNWidgets(2));
  });

  testWidgets(
      'L2.1: el desglose por cultivo separa inversión inicial de operación '
      'sin cambiar el total', (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final hoy = DateTime.now();
    final cafe = await provider.addCrop('Café');

    await provider.addTransaction(
      type: TransactionType.expense,
      category: kExpenseCategorySowing,
      cropId: cafe.id,
      amount: 600000,
      description: 'Siembra',
      date: hoy,
    );
    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'mano_obra',
      cropId: cafe.id,
      amount: 400000,
      description: 'Jornal',
      date: hoy,
    );
    await provider.addTransaction(
      type: TransactionType.income,
      category: 'venta_cafe',
      cropId: cafe.id,
      amount: 900000,
      date: hoy,
    );

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final l10n = stringsFor('es');
    final now = DateTime.now();
    final titulo = l10n.cropBreakdownTitle(
        l10n.reportPeriodMonth(l10n.monthFull[now.month - 1], now.year));
    final desglose = find.ancestor(
        of: find.text(titulo), matching: find.byType(Card));
    expect(desglose, findsOneWidget,
        reason: 'la tarjeta del desglose por cultivo');

    String money(double v) =>
        formatAmount(v, currency: 'COP', locale: provider.settings.locale);

    expect(
        find.descendant(
            of: desglose, matching: find.text(l10n.cropBreakdownInvestment)),
        findsOneWidget,
        reason: 'debe mostrar la inversión inicial (la siembra)');
    expect(
        find.descendant(
            of: desglose, matching: find.text(l10n.cropBreakdownOperation)),
        findsOneWidget,
        reason: 'debe mostrar la operación del período (el jornal)');
    expect(
        find.descendant(of: desglose, matching: find.text(money(600000))),
        findsOneWidget,
        reason: 'la inversión inicial es el gasto de siembra');
    expect(
        find.descendant(of: desglose, matching: find.text(money(400000))),
        findsOneWidget,
        reason: 'la operación es el resto de gastos del período');
    expect(
        find.descendant(of: desglose, matching: find.text(money(1000000))),
        findsOneWidget,
        reason: 'el total de gastos no cambia: 600.000 + 400.000 = 1.000.000');
    expect(
        find.descendant(
            of: desglose, matching: find.text(l10n.cropBreakdownSummaryG)),
        findsOneWidget,
        reason: 'la línea de gastos de siempre sigue ahí');
    expect(
        find.descendant(
            of: desglose, matching: find.text(money(900000))),
        findsOneWidget,
        reason: 'los ingresos siguen mostrándose como antes');
  });

  testWidgets(
      'L2.1: un cultivo sin gastos no abre filas de inversión ni de operación',
      (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final hoy = DateTime.now();
    final cafe = await provider.addCrop('Café');

    await provider.addTransaction(
      type: TransactionType.income,
      category: 'venta_cafe',
      cropId: cafe.id,
      amount: 900000,
      date: hoy,
    );

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final l10n = stringsFor('es');
    expect(find.text(l10n.cropBreakdownInvestment), findsNothing,
        reason: 'sin gastos de siembra no se muestra una fila vacía');
    expect(find.text(l10n.cropBreakdownOperation), findsNothing,
        reason: 'sin gastos de operación no se muestra una fila vacía');

    // La fila del cultivo sigue ahí, con sus ingresos.
    final now = DateTime.now();
    final titulo = l10n.cropBreakdownTitle(
        l10n.reportPeriodMonth(l10n.monthFull[now.month - 1], now.year));
    final desglose = find.ancestor(
        of: find.text(titulo), matching: find.byType(Card));
    expect(desglose, findsOneWidget);
    expect(
        find.descendant(
            of: desglose, matching: find.text(l10n.cropBreakdownSummaryI)),
        findsOneWidget,
        reason: 'la fila del cultivo sigue mostrando sus ingresos');
  });

  // ---- Monedas del período: nunca se suman (A) ni se inventa (B) ----

  Widget pantalla(TransactionProvider provider, CurrencyConversionService? fx) {
    Widget tree = const MaterialApp(
      locale: Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReportScreen(),
    );
    if (fx != null) tree = CurrencyConversionScope(service: fx, child: tree);
    return ChangeNotifierProvider.value(value: provider, child: tree);
  }

  /// Deja pasar los reintentos de la tasa (400 ms + 800 ms) por si el
  /// proveedor no contesta: la pantalla no se bloquea esperando.
  Future<void> asentar(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
  }

  Future<void> mezclar(TransactionProvider provider) async {
    final hoy = DateTime.now();
    await provider.addTransaction(
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 5000,
        date: hoy);
    await provider.addTransaction(
        type: TransactionType.expense,
        category: 'fertilizante',
        amount: 1000,
        date: hoy);
    await provider.addTransaction(
        type: TransactionType.income,
        category: 'venta_otro',
        amount: 200,
        currency: 'EUR',
        date: hoy);
    await provider.addTransaction(
        type: TransactionType.expense,
        category: 'transporte',
        amount: 50,
        currency: 'EUR',
        date: hoy);
  }

  testWidgets('moneda única: el resultado del período se pinta como siempre',
      (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final hoy = DateTime.now();
    await provider.addTransaction(
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 5000,
        date: hoy);
    await provider.addTransaction(
        type: TransactionType.expense,
        category: 'fertilizante',
        amount: 1000,
        date: hoy);

    await tester.pumpWidget(pantalla(provider, null));
    await tester.pumpAndSettle();

    final l10n = stringsFor('es');
    expect(find.text(l10n.resultPeriodLabel), findsOneWidget);
    // El mismo importe puede salir en otras tarjetas (la de Caja, por
    // ejemplo): lo que importa es que la fila de resultado lo muestre.
    final statement =
        find.ancestor(of: find.text(l10n.resultPeriodLabel), matching: find.byType(Card));
    expect(
        find.descendant(
            of: statement,
            matching:
                find.text(formatAmount(4000, currency: 'COP', locale: 'es_CO'))),
        findsOneWidget,
        reason: '5.000 − 1.000 = 4.000 en la única moneda del período');
    expect(find.byType(CurrencyBreakdown), findsNothing);
    expect(find.text(l10n.currencyRateNote), findsNothing,
        reason: 'sin mezcla no hay conversión que avisar');
  });

  testWidgets(
      'mezcla sin tasa: no aparece un balance global falso, '
      'sí los totales de cada moneda', (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    await mezclar(provider);

    final fx = CurrencyConversionService(
      rates:
          CurrencyRatesService(client: MockClient((_) async => throw Exception('sin red'))),
      prefs: () async => prefs,
    );

    await tester.pumpWidget(pantalla(provider, fx));
    await asentar(tester);

    final l10n = stringsFor('es');
    expect(find.text(l10n.resultPeriodLabel), findsNothing,
        reason: 'no debe imprimirse un resultado global de monedas mezcladas');
    expect(
        find.text(formatAmount(5150, currency: 'COP', locale: 'es_CO')),
        findsNothing,
        reason: 'la cifra falsa 6.200 − 1.050 = 5.150 no aparece');
    expect(find.text(l10n.currencyRateNote), findsNothing,
        reason: 'sin tasa no se promete ningún total convertido');

    expect(find.byType(CurrencyBreakdown), findsOneWidget);
    expect(
        find.textContaining(l10n.currencyMixedHint(2)), findsOneWidget,
        reason: 'los totales salen separados por moneda');
    expect(find.textContaining('COP · Peso colombiano'), findsOneWidget);
    expect(find.textContaining('EUR · Euro'), findsOneWidget);
    expect(
        find.text(formatAmount(4000, currency: 'COP', locale: 'es_CO')),
        findsOneWidget,
        reason: 'resultado de COP: 5.000 − 1.000');
    expect(
        find.text(formatAmount(150, currency: 'EUR', locale: 'es_CO')),
        findsOneWidget,
        reason: 'resultado de EUR: 200 − 50');
  });

  testWidgets(
      'mezcla con tasa simulada: un solo total convertido en la moneda '
      'de Ajustes', (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    await mezclar(provider);

    final fx = CurrencyConversionService(
      rates: CurrencyRatesService(
          client: MockClient((_) async => http.Response(
                '{"result":"success","rates":{"COP":4.0}}',
                200,
                headers: {'content-type': 'application/json'},
              ))),
      prefs: () async => prefs,
    );

    await tester.pumpWidget(pantalla(provider, fx));
    await asentar(tester);

    final l10n = stringsFor('es');
    String money(double v) => formatAmount(v, currency: 'COP', locale: 'es_CO');

    expect(find.text(l10n.resultPeriodLabel), findsOneWidget);
    expect(
      find.text(l10n.currencyConvertedTotal('COP', money(4600))),
      findsOneWidget,
      reason: 'ingresos 5.800 − gastos 1.200 = 4.600 convertidos a COP',
    );
    expect(find.text(l10n.currencyRateNote), findsOneWidget,
        reason: 'avisa de que es al cambio de hoy');
    expect(find.text(money(5800)), findsOneWidget,
        reason: 'la línea de ingresos usa el total convertido');
    expect(find.byType(CurrencyBreakdown), findsOneWidget,
        reason: 'el desglose por moneda sigue como referencia');
  });
}