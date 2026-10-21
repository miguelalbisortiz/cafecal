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
import 'package:mi_cafetal/widgets/crop_loss_dialog.dart';
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

  testWidgets('P5: una siembra con pérdidas pegadas no infla las pérdidas',
      (tester) async {
    tester.view.physicalSize = const Size(900, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final crop = await provider.addCrop('Café');

    // Registro viejo mal guardado: una siembra con el -50 que se le quedó
    // pegado de cuando era resiembra. No puede sumar en el informe.
    await provider.addSowing(
      cropId: crop.id,
      date: DateTime(2026, 3, 1),
      plants: 1000,
      lostPlants: 50,
      reason: 'plaga',
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
    expect(find.text(l10n.reportSowingsLosses), findsNothing,
        reason: 'sin resiembras no hay pérdidas acumuladas que enseñar');
    expect(find.text(l10n.reportSowingsLostOnly(50)), findsNothing,
        reason: 'ni la fila de la siembra puede decir que se perdió nada');
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

  testWidgets('un negativo en pantalla lleva su signo, no paréntesis',
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
      amount: 5000.0,
      description: 'Fertilizante',
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

    // En pantalla el negativo lo lee el agricultor: con su signo.
    expect(
        find.textContaining(
            formatAmount(-5000, currency: 'COP', locale: 'es_CO')),
        findsWidgets,
        reason: 'el gasto se lee con su signo, no entre paréntesis');
    // El paréntesis contable queda para el PDF y el Excel.
    final parentesisContable =
        '(${formatAmount(5000, currency: 'COP', locale: 'es_CO')})';
    expect(find.text(parentesisContable), findsNothing,
        reason: 'quien no es contador lee el paréntesis como una cifra más');
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
    // Nivel 1 · el numero que decide: 1200 - 100 = 1100 por kilo.
    expect(find.text(l10n.metricMarginPerKgLabel), findsOneWidget);
    expect(find.textContaining('1.100'), findsOneWidget,
        reason: 'el margen por kilo se pinta como plata, no solo el veredicto');
    expect(find.text(l10n.metricMarginPerKgGood), findsOneWidget,
        reason: 'la senal va siempre con frase: icono y color no bastan (H10)');
  });

  testWidgets('P3: lo vendido sin pagar se avisa como por cobrar',
      (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final hoy = DateTime.now();

    await provider.addTransaction(
      type: TransactionType.income,
      category: 'venta_cafe',
      amount: 12000.0,
      quantity: 10,
      unit: 'kg',
      date: hoy,
      paid: false,
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
    expect(find.text(l10n.metricReceivablesLabel), findsOneWidget);
    expect(find.textContaining('12.000'), findsAtLeastNWidgets(1),
        reason: 'la plata por cobrar se pinta en cifra, no solo en aviso');
    expect(find.text(l10n.metricReceivablesNote), findsOneWidget,
        reason: 'el aviso va con frase, no solo con un icono (H10)');
  });

  testWidgets('P3: si todo esta cobrado no se ensena un cero de por cobrar',
      (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final hoy = DateTime.now();

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
    expect(find.text(l10n.metricReceivablesLabel), findsNothing,
        reason: 'nada por cobrar: mejor callar que ensenar un cero');
  });

  testWidgets('P4: la nomina se pinta como parte del gasto del periodo',
      (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final hoy = DateTime.now();

    // 1000 de mano de obra sobre 4000 de gasto total = 25%.
    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'mano_obra',
      amount: 1000.0,
      date: hoy,
    );
    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'fertilizante',
      amount: 3000.0,
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
    expect(find.text(l10n.metricLaborShareLabel), findsOneWidget);
    expect(find.textContaining('25%'), findsAtLeastNWidgets(1),
        reason: '1000 de 4000 es una cuarta parte del gasto');
    // Informativa, sin veredicto: no hay umbral que valga para toda finca.
    expect(find.text(l10n.metricLaborShareNote), findsOneWidget);
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
    expect(find.text(l10n.metricMarginPerKgLabel), findsNothing,
        reason: 'sin las dos cifras no hay margen que pintar');
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
        formatAmount(v, currency: 'COP', locale: provider.settings.numberLocale);

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

  testWidgets(
      'filas de categoría con mezcla: cada moneda con su código y sin % '
      'sobre un total que cruzaría monedas', (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
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
    final statement = find.ancestor(
        of: find.text(l10n.incomeStatementTitle), matching: find.byType(Card));

    String money(double v, String currency) =>
        formatAmount(v, currency: currency, locale: 'es_CO');

    // Cada fila de categoría lleva su moneda y su código.
    //
    // El ingreso en COP sale DOS veces —subtotal del bloque y fila del
    // cultivo—, como ya salían los gastos. Antes coincidía una sola vez con
    // `find.text` porque las dos se pintaban distinto (`$5.000` en un sitio
    // y `$5.000 COP` en otro): mismas cifras, dos formas. Con el código
    // dentro del monto las dos dicen lo mismo.
    expect(
      find.descendant(
          of: statement, matching: find.text(money(5000, 'COP'))),
      findsNWidgets(2),
      reason: 'subtotal del bloque y fila de café, ambos en COP',
    );
    expect(
      find.descendant(
          of: statement, matching: find.text(money(200, 'EUR'))),
      // Mismo motivo que en COP: la cifra en EUR salía antes en dos formas
      // (`€200,00` y `€200,00 EUR`) y solo una coincidía. Ahora las dos
      // dicen `EUR 200,00`.
      findsNWidgets(2),
      reason: 'subtotal del bloque y fila del cultivo, ambos en EUR',
    );
    // Los gastos salen en tres bloques: el subtotal del grupo, el total del
    // período y la fila de fertilizante. Antes solo dos coincidían con
    // `find.text` porque la tercera se escribía `-$1.000 COP`: mismas cifras,
    // dos grafías. Ahora las tres dicen lo mismo.
    expect(
      find.descendant(
          of: statement, matching: find.text('-${money(1000, 'COP')}')),
      findsNWidgets(3),
      reason: 'subtotal, total y fila de fertilizante, todos en COP',
    );
    expect(
      find.descendant(
          of: statement, matching: find.text('-${money(50, 'EUR')}')),
      findsNWidgets(3),
      reason: 'subtotal, total y fila de transporte, todos en EUR',
    );

    // Sin tasa no hay total global: ningún % se calcula sobre monedas cruzadas.
    final textos = tester
        .widgetList<Text>(find.descendant(
            of: statement, matching: find.byType(Text)))
        .map((t) => t.data ?? '')
        .toList();
    expect(
      textos.where((s) => s.endsWith('%')),
      isEmpty,
      reason: 'los porcentajes exigirían sumar pesos con euros',
    );
  });

  // F4 · Guarda (no rojo/verde): una pérdida de hoy sí entra en el período que
  // se está mirando. Fija que la lista del período sigue funcionando.
  testWidgets('F4 · una pérdida fechada este mes se lista en el período',
      (tester) async {
    tester.view.physicalSize = const Size(900, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final crop = await provider.addCrop('Café');
    final hoy = DateTime.now();

    await provider.addSowing(
      cropId: crop.id,
      date: DateTime(hoy.year, hoy.month, 1),
      plants: 500,
    );
    await provider.addSowing(
      cropId: crop.id,
      date: hoy,
      kind: SowingKind.resiembra,
      plants: 0,
      lostPlants: 50,
      reason: 'se murieron',
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
    expect(
      find.text(l10n.reportSowingsLostLine(50, 'se murieron')),
      findsOneWidget,
      reason: 'la pérdida de hoy entra en el período que se está mirando',
    );
  });

  // F4 · Camino completo y **rojo/verde**: él anota la pérdida con el diálogo y
  // elige el mes pasado. La lista del período sale de `s.date`
  // (`_periodSowings`, `report_screen.dart:614`), así que no entra en el informe
  // de este mes; la tarjeta «Pérdidas acumuladas» sí la cuenta, porque suma
  // todo el historial a propósito.
  testWidgets('F4 · la pérdida re-fechada al mes pasado no entra en el período',
      (tester) async {
    tester.view.physicalSize = const Size(900, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final crop = await provider.addCrop('Café');
    final hoy = DateTime.now();
    final mesPasado = DateTime(hoy.year, hoy.month - 1, 15);

    await provider.addSowing(
      cropId: crop.id,
      date: DateTime(mesPasado.year, mesPasado.month, 1),
      plants: 500,
    );

    // 1) El diálogo de pérdidas, con la fecha llevada al mes pasado.
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showDialog<int>(
                  context: context,
                  builder: (_) => CropLossDialog(
                    crop: provider.crops.single,
                    currentPlants: provider.crops.single.livePlants!,
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    final dl10n =
        AppLocalizations.of(tester.element(find.byType(CropLossDialog)))!;
    final material = MaterialLocalizations.of(
        tester.element(find.byType(CropLossDialog)));

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left)); // al mes pasado
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(material.okButtonLabel));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '450');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, dl10n.add));
    await tester.pumpAndSettle();

    expect(provider.sowings.last.date, mesPasado,
        reason: 'la pérdida quedó fechada el día que él eligió');

    // 2) El informe de este mes.
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
    expect(find.text(l10n.reportSowingsLostOnly(50)), findsNothing,
        reason: 'el informe mira este mes; esa resiembra fue el mes pasado');
    expect(find.text(l10n.reportSowingsLosses), findsOneWidget,
        reason: 'el acumulado sí la cuenta: suma todo el historial');
    expect(provider.crops.single.livePlants, 450,
        reason: 'y el contador del cultivo ya bajó: la pérdida cuenta');
  });

  // ---- W1-c · el desglose por terreno ------------------------------------

  testWidgets(
      'W1-c: el desglose por cultivo se agrupa bajo la banda de su terreno',
      (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final alto = await provider.addTerreno('Lote Alto', areaHa: 2);
    final bajo = await provider.addTerreno('Lote Bajo');
    final cafe = await provider.addCrop('Café', terrenoId: alto.id, areaHa: 1.2);
    final platano =
        await provider.addCrop('Plátano', terrenoId: alto.id, areaHa: 0.8);
    // Sin hectáreas: el gasto de su lote no se puede repartir y sale como
    // fila propia, pero DENTRO de la banda del lote.
    await provider.addCrop('Maíz', terrenoId: bajo.id);

    final hoy = DateTime.now();
    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'mano_obra',
      cropId: cafe.id,
      amount: 30000,
      date: hoy,
    );
    await provider.addTransaction(
      type: TransactionType.income,
      category: 'venta_cafe',
      cropId: platano.id,
      amount: 50000,
      date: hoy,
    );
    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'mano_obra',
      terrenoId: bajo.id,
      amount: 70000,
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
    expect(find.text('Lote Alto'), findsOneWidget);
    expect(find.text('Lote Bajo'), findsOneWidget);
    expect(find.text(l10n.loteNoRepartido('Lote Bajo')), findsOneWidget);

    // El orden manda: el lote con más movimiento arriba y la fila «sin
    // repartir» debajo de SU cabecera, no suelta al final del desglose.
    final yAlto = tester.getTopLeft(find.text('Lote Alto')).dy;
    final yBajo = tester.getTopLeft(find.text('Lote Bajo')).dy;
    final ySinRepartir =
        tester.getTopLeft(find.text(l10n.loteNoRepartido('Lote Bajo'))).dy;
    expect(yAlto, lessThan(yBajo));
    expect(yBajo, lessThan(ySinRepartir),
        reason: 'la fila del lote va dentro de su banda');
    // El área solo se pinta donde está anotada.
    expect(find.text('2 ha'), findsOneWidget);
  });

  testWidgets(
      'W1-c: una finca sin terrenos no estrena bandas ni «Sin terreno»',
      (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final cafe = await provider.addCrop('Café');
    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'mano_obra',
      cropId: cafe.id,
      amount: 30000,
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

    expect(find.text(stringsFor('es').cropTerrenoNone), findsNothing,
        reason: 'sin terrenos no hay nada que agrupar');
  });

  testWidgets('T6: «sin peso» lista la cosecha y baja al anotar el peso',
      (tester) async {
    tester.view.physicalSize = const Size(900, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final provider = TransactionProvider(LocalStore(prefs));
    final crop = await provider.addCrop('Plátano');
    final h = await provider.addHarvest(
      cropId: crop.id,
      date: DateTime.now(),
      amount: 12,
      unit: 'racimo',
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

    final es = stringsFor('es');
    expect(find.text(es.reportPendingWeightTitle), findsOneWidget);
    expect(find.text(es.reportPendingWeightHarvests(1)), findsOneWidget);

    // Al completar el peso, la tarjeta baja el contador sin recargar nada.
    await provider.updateHarvest(h.copyWith(equivalentKg: 240.0));
    await tester.pumpAndSettle();

    expect(find.text(es.reportPendingWeightTitle), findsNothing,
        reason: 'ya no hay nada pendiente: 240 kg anotados');
  });
}