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
import 'package:mi_cafetal/screens/home_screen.dart';
import 'package:mi_cafetal/services/currency_conversion.dart';
import 'package:mi_cafetal/services/currency_rates_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/utils/format.dart';
import 'package:mi_cafetal/widgets/currency_breakdown.dart';
import 'package:mi_cafetal/widgets/period_totals.dart';
import 'package:mi_cafetal/widgets/summary_card.dart';

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
}
