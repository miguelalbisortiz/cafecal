import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/alert_provider.dart';
import 'package:mi_cafetal/providers/auth_provider.dart';
import 'package:mi_cafetal/providers/sync_provider.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/crops_screen.dart';
import 'package:mi_cafetal/screens/finca_screen.dart';
import 'package:mi_cafetal/screens/home_screen.dart';
import 'package:mi_cafetal/screens/movements_screen.dart';
import 'package:mi_cafetal/screens/register_screen.dart';
import 'package:mi_cafetal/screens/report_screen.dart';
import 'package:mi_cafetal/screens/sowing_screen.dart';
import 'package:mi_cafetal/screens/workers_screen.dart';
import 'package:mi_cafetal/services/currency_conversion.dart';
import 'package:mi_cafetal/services/currency_rates_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/utils/format.dart';
import 'package:mi_cafetal/widgets/alerts_banner.dart';
import 'package:mi_cafetal/widgets/currency_breakdown.dart';
import 'package:mi_cafetal/widgets/period_totals.dart';
import 'package:mi_cafetal/widgets/summary_card.dart';
import 'package:mi_cafetal/widgets/summary_empty_card.dart';

/// Totales del resumen: nunca se suman monedas distintas (A) y, si hay
/// tasa, se convierten a la moneda de Ajustes (B).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(TransactionProvider, AuthProvider, SharedPreferences)> makeProviders() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs);
    return (TransactionProvider(store), AuthProvider(store), prefs);
  }

  Future<void> pumpHome(WidgetTester tester, TransactionProvider tx,
      AuthProvider auth,
      {CurrencyConversionService? fx}) async {
    Widget tree = const MaterialApp(
      locale: Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(),
    );
    if (fx != null) tree = CurrencyConversionScope(service: fx, child: tree);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: tx),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: AlertProvider(tx)),
        ChangeNotifierProvider.value(value: SyncProvider(tx)),
      ],
      child: tree,
    ));
    await tester.pumpAndSettle();
  }

  Future<void> mezclar(TransactionProvider tx) async {
    final hoy = DateTime.now();
    await tx.addTransaction(
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 5000,
        date: hoy);
    await tx.addTransaction(
        type: TransactionType.expense,
        category: 'fertilizante',
        amount: 1000,
        date: hoy);
    await tx.addTransaction(
        type: TransactionType.income,
        category: 'venta_otro',
        amount: 200,
        currency: 'EUR',
        date: hoy);
    await tx.addTransaction(
        type: TransactionType.expense,
        category: 'transporte',
        amount: 50,
        currency: 'EUR',
        date: hoy);
  }

  CurrencyConversionService redCaida(SharedPreferences prefs) =>
      CurrencyConversionService(
        rates: CurrencyRatesService(
            client: MockClient((_) async => throw Exception('sin red'))),
        prefs: () async => prefs,
      );

  CurrencyConversionService tasaEur(SharedPreferences prefs) =>
      CurrencyConversionService(
        rates: CurrencyRatesService(
            client: MockClient((_) async => http.Response(
                  '{"result":"success","rates":{"COP":4.0}}',
                  200,
                  headers: {'content-type': 'application/json'},
                ))),
        prefs: () async => prefs,
      );

  /// Deja pasar los reintentos de la tasa (400 ms + 800 ms).
  Future<void> asentar(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
  }

  testWidgets('moneda única: las tres tarjetas del resumen, como siempre',
      (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final (tx, auth, _) = await makeProviders();
    await tx.addCrop('Café');
    final hoy = DateTime.now();
    await tx.addTransaction(
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 5000,
        date: hoy);
    await tx.addTransaction(
        type: TransactionType.expense,
        category: 'fertilizante',
        amount: 1000,
        date: hoy);

    await pumpHome(tester, tx, auth);

    // Mes y año: 3 tarjetas cada uno.
    expect(find.byType(SummaryCard), findsNWidgets(6));
    expect(find.byType(CurrencyBreakdown), findsNothing);
    expect(find.text(stringsFor('es').currencyRateNote), findsNothing);
  });

  testWidgets(
      'mezcla sin tasa: no hay tarjetas con cifras globales falsas, '
      'sí los totales de cada moneda', (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final (tx, auth, prefs) = await makeProviders();
    await tx.addCrop('Café');
    await mezclar(tx);

    await pumpHome(tester, tx, auth, fx: redCaida(prefs));
    await asentar(tester);

    final l10n = stringsFor('es');
    expect(find.byType(SummaryCard), findsNothing,
        reason: 'sin tasa no se imprime un resultado global de la mezcla');
    expect(find.byType(CurrencyBreakdown), findsNWidgets(2),
        reason: 'mes y año muestran sus totales por moneda');
    expect(find.text(l10n.currencyRateNote), findsNothing);
    expect(
      find.textContaining(l10n.categoryBreakdownTotal('')),
      findsNothing,
      reason: 'tampoco el "Total del período" de los desgloses mezcla monedas',
    );
  });

  testWidgets('mezcla con tasa simulada: tarjetas convertidas y aviso',
      (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final (tx, auth, prefs) = await makeProviders();
    await tx.addCrop('Café');
    await mezclar(tx);

    await pumpHome(tester, tx, auth, fx: tasaEur(prefs));
    await asentar(tester);

    final l10n = stringsFor('es');
    String money(double v) => formatAmount(v, currency: 'COP', locale: 'es_CO');

    expect(find.byType(SummaryCard), findsNWidgets(6),
        reason: 'mes y año recuperan sus tres tarjetas, ahora convertidas');
    expect(
      find.text(l10n.currencyConvertedTotal('COP', money(4600))),
      findsNWidgets(2),
      reason: '5.800 − 1.200 = 4.600 al cambio de 4 COP por EUR',
    );
    expect(find.text(l10n.currencyRateNote), findsNWidgets(2),
        reason: 'cada total avisa de que va al cambio de hoy');
    expect(find.byType(CurrencyBreakdown), findsNothing,
        reason: 'con tasa no hace falta el desglose por moneda');
  });

  testWidgets('A1: con datos, las cifras del mes van encima de las alertas',
      (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final (tx, auth, _) = await makeProviders();
    await tx.addCrop('Café');
    final hoy = DateTime.now();
    // Una venta por cobrar dispara la alerta de la regla 11.
    await tx.addTransaction(
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 5000,
        date: hoy,
        paid: false);
    await tx.addTransaction(
        type: TransactionType.expense,
        category: 'fertilizante',
        amount: 1000,
        date: hoy);

    await pumpHome(tester, tx, auth);

    expect(find.byType(AlertsBanner), findsOneWidget,
        reason: 'la venta sin pagar debe levantar la alerta de por cobrar');
    final dinero = tester.getTopLeft(find.byType(SummaryCard).first).dy;
    final avisos = tester.getTopLeft(find.byType(AlertsBanner)).dy;
    expect(dinero, lessThan(avisos),
        reason: 'A1: el objetivo de la app es ver la plata antes que los '
            'avisos, que hasta ahora quedaban arriba de todo');
  });

  testWidgets('A2: sin registros, el Resumen enseña el estado vacío y no \$0',
      (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final (tx, auth, _) = await makeProviders();
    // Un cultivo alcanza para salir de la puerta E6; todavía no hay plata.
    await tx.addCrop('Café');

    await pumpHome(tester, tx, auth);

    final l10n = stringsFor('es');
    expect(find.byType(SummaryEmptyCard), findsOneWidget);
    expect(find.byType(SummaryCard), findsNothing,
        reason: 'un "\$0" se leería como medido cuando es no registrado');
    expect(find.text(l10n.summaryEmptyTitle), findsOneWidget);
    expect(find.text(l10n.summaryEmptyBody), findsOneWidget);
    expect(find.text(l10n.recordExpense), findsOneWidget,
        reason: 'las dos puertas de entrada siguen a mano');
    expect(find.text(l10n.recordIncome), findsOneWidget);
  });

  /// La etiqueta de una pestaña, sin confundirla con el encabezado de la
  /// pantalla que lleva el mismo texto.
  Finder navTab(String label) => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      );

  testWidgets('navegación: la barra tiene Resumen, Movimientos y Reportes',
      (tester) async {
    final (tx, auth, _) = await makeProviders();
    // Un cultivo alcanza para salir de la puerta E6 y de la de moneda.
    await tx.addCrop('Café');

    await pumpHome(tester, tx, auth);

    final l10n = stringsFor('es');
    final barra = tester.widget<NavigationBar>(find.byType(NavigationBar));
    final etiquetas = barra.destinations
        .cast<NavigationDestination>()
        .map((d) => d.label)
        .toList();
    expect(etiquetas, [l10n.tabOverview, l10n.tabMovements, l10n.tabReports],
        reason: 'Fase 2: Registrar deja de ser pestaña; Reportes entra');

    await tester.tap(navTab(l10n.tabMovements));
    await tester.pumpAndSettle();
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1);

    await tester.tap(navTab(l10n.tabReports));
    await tester.pumpAndSettle();
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2);
  });

  testWidgets('Registrar es un FAB: abre una ruta y no marca una sección',
      (tester) async {
    final (tx, auth, _) = await makeProviders();
    await tx.addCrop('Café');

    await pumpHome(tester, tx, auth);
    final l10n = stringsFor('es');

    expect(find.byType(FloatingActionButton), findsOneWidget,
        reason: 'registrar tiene que estar a un toque desde cualquier pestaña');
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, l10n.registerTitle), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget,
        reason: 'Registrar ahora es una ruta de salida y lleva flecha');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsNothing);
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
        reason: 'volver de Registrar deja la pestaña de origen, no una nueva');
  });

  testWidgets('guardar desde la ruta de Registrar vuelve a la pestaña',
      (tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final (tx, auth, _) = await makeProviders();
    await tx.addCrop('Café');

    await pumpHome(tester, tx, auth);
    final l10n = stringsFor('es');

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byWidgetPredicate((w) =>
        w is DropdownButton<String> &&
        (w.items ?? const []).any((i) => i.value == 'fertilizante')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.textContaining(l10n.expenseCategory('fertilizante')).last);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, l10n.amountFieldLabel), '5000');

    final guardar = find.text(l10n.saveRecord);
    await tester.ensureVisible(guardar);
    await tester.tap(guardar);
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsNothing,
        reason: 'guardar cierra la ruta y devuelve a la pestaña de origen');
    expect(
        tx.transactions.where((t) => !t.deleted).single.amount, 5000);
  });

  testWidgets('el FAB no aparece durante la puerta de bienvenida',
      (tester) async {
    final (tx, auth, _) = await makeProviders();

    await pumpHome(tester, tx, auth);
    final l10n = stringsFor('es');

    // Cuenta nueva: primero la moneda, después la puerta de cultivos.
    await tester.tap(find.text(l10n.currencyGateCta('Peso colombiano (COP)')));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing,
        reason: 'todavía no hay finca: la puerta es el único camino');
  });

  testWidgets('el prefijo Gasto/Ingreso llega a la ruta de Registrar',
      (tester) async {
    final (tx, auth, _) = await makeProviders();
    await tx.addCrop('Café');

    await pumpHome(tester, tx, auth);
    final l10n = stringsFor('es');

    SegmentedButton<TransactionType> tipo() =>
        tester.widget<SegmentedButton<TransactionType>>(
            find.byType(SegmentedButton<TransactionType>));

    await tester.tap(find.text(l10n.recordExpense));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(tipo().selected, {TransactionType.expense});

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.recordIncome));
    await tester.pumpAndSettle();
    expect(tipo().selected, {TransactionType.income},
        reason: 'la ruta se crea nueva y el prefijo tiene que aplicarse');
  });

  testWidgets('Reportes es pestaña: la barra sigue y el mes se conserva',
      (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final (tx, auth, _) = await makeProviders();
    await tx.addCrop('Café');
    await tx.addTransaction(
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 5000,
        date: DateTime.now());

    await pumpHome(tester, tx, auth);
    final l10n = stringsFor('es');

    await tester.tap(navTab(l10n.tabReports));
    await tester.pumpAndSettle();

    expect(find.byType(ReportScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget,
        reason: 'Reportes ya no pierde la barra al abrirse');
    expect(find.byType(BackButton), findsNothing,
        reason: 'una pestaña no es una salida');

    // El mes elegido no puede volver al de hoy al cambiar de pestaña.
    final meses = find.byType(DropdownButtonFormField<int>);
    FormFieldState<int> mesState() =>
        tester.state<FormFieldState<int>>(meses.first);
    final original = mesState().value;
    final objetivo = (original! % 12) + 1;

    await tester.tap(meses.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.monthFull[objetivo - 1]).last);
    await tester.pumpAndSettle();
    expect(mesState().value, objetivo);

    await tester.tap(navTab(l10n.tabOverview));
    await tester.pumpAndSettle();
    await tester.tap(navTab(l10n.tabReports));
    await tester.pumpAndSettle();

    expect(mesState().value, objetivo,
        reason: 'el IndexedStack tiene que conservar el mes del reporte');
  });

  testWidgets('el menú deja Finca, Ajustes, Ayuda y Salir; Finca es un hub',
      (tester) async {
    final (tx, auth, _) = await makeProviders();
    await tx.addCrop('Café');

    await pumpHome(tester, tx, auth);
    final l10n = stringsFor('es');

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    for (final etiqueta in [
      l10n.menuFinca,
      l10n.menuSettings,
      l10n.menuHelp,
      l10n.menuLogout,
    ]) {
      expect(find.text(etiqueta), findsOneWidget);
    }
    expect(find.text(l10n.menuReport), findsNothing,
        reason: 'Reportes ya es pestaña, no una entrada del menú');
    expect(find.text(l10n.menuCrops), findsNothing,
        reason: 'los datos maestros viven en el hub Finca');

    await tester.tap(find.text(l10n.menuFinca));
    await tester.pumpAndSettle();
    expect(find.byType(FincaScreen), findsOneWidget);
    expect(find.text(l10n.fincaHubTitle), findsOneWidget);

    // Las tres pantallas de datos maestros siguen alcanzables y su flecha
    // vuelve a Finca, no a Resumen.
    for (final (etiqueta, pantalla) in [
      (l10n.menuCrops, CropsScreen),
      (l10n.menuSowings, SowingScreen),
      (l10n.menuWorkers, WorkersScreen),
    ]) {
      await tester.tap(find.text(etiqueta));
      await tester.pumpAndSettle();
      expect(find.byType(pantalla), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(FincaScreen), findsOneWidget,
          reason: 'la flecha vuelve a Finca, no a Resumen');
    }

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('movimientos: el scroll sobrevive al cambiar de pestaña',
      (tester) async {
    final (tx, auth, _) = await makeProviders();
    await tx.addCrop('Café');
    final hoy = DateTime.now();
    for (var i = 0; i < 25; i++) {
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'fertilizante',
          amount: 1000.0 + i,
          date: hoy.subtract(Duration(days: i)));
    }

    await pumpHome(tester, tx, auth);
    final l10n = stringsFor('es');

    await tester.tap(navTab(l10n.tabMovements));
    await tester.pumpAndSettle();

    final lista = find.descendant(
        of: find.byType(MovementsScreen), matching: find.byType(Scrollable));
    await tester.drag(lista, const Offset(0, -250));
    await tester.pumpAndSettle();
    final antes = tester.state<ScrollableState>(lista).position.pixels;
    expect(antes, greaterThan(0));

    await tester.tap(navTab(l10n.tabOverview));
    await tester.pumpAndSettle();
    await tester.tap(navTab(l10n.tabMovements));
    await tester.pumpAndSettle();

    expect(tester.state<ScrollableState>(lista).position.pixels, antes,
        reason: 'volver a Movimientos no debe devolverlo al principio');
  });
}
