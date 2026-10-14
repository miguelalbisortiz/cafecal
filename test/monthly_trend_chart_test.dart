import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/currency_totals.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/utils/format.dart';
import 'package:mi_cafetal/widgets/monthly_trend_chart.dart';

Future<TransactionProvider> _provider() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  return TransactionProvider(LocalStore(prefs));
}

Widget _wrap(TransactionProvider provider, int year) =>
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonthlyTrendChart(year: year),
          ),
        ),
      ),
    );

/// Curva acumulada: con una sola moneda grafica; con dos o más no dibuja
/// nada que sumaría monedas distintas.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('puntos del acumulado', () {
    test('el último punto es el resultado del año, no una cifra aparte', () async {
      final provider = await _provider();
      final year = DateTime.now().year;
      await provider.addTransaction(
          type: TransactionType.income,
          category: 'venta_cafe',
          amount: 5000,
          date: DateTime(year, 3, 10));
      await provider.addTransaction(
          type: TransactionType.expense,
          category: 'fertilizante',
          amount: 1000,
          date: DateTime(year, 4, 10));

      // Mismo cálculo que usan las tarjetas del panel.
      final incomes = amountsByCurrency(provider.transactions,
          type: TransactionType.income);
      final expenses = amountsByCurrency(provider.transactions,
          type: TransactionType.expense);
      final expected = incomes.values.fold<double>(0, (a, b) => a + b) -
          expenses.values.fold<double>(0, (a, b) => a + b);

      final spots = accumulatedSpots(provider.transactions, year);

      expect(spots, isNotEmpty);
      expect(spots.first.x, -1);
      expect(spots.first.y, 0,
          reason: 'la curva arranca en cero el 1 de enero');
      expect(spots.last.y, expected,
          reason: 'el último punto debe ser el Resultado del año');
    });

    test('termina en el último mes con movimiento, sin cola hacia el futuro',
        () async {
      final provider = await _provider();
      final year = DateTime.now().year;
      await provider.addTransaction(
          type: TransactionType.income,
          category: 'venta_cafe',
          amount: 3000,
          date: DateTime(year, 3, 10));
      await provider.addTransaction(
          type: TransactionType.expense,
          category: 'transporte',
          amount: 500,
          date: DateTime(year, 5, 10));

      final spots = accumulatedSpots(provider.transactions, year);

      // Mayo es el índice 4 (enero = 0): nada más.
      expect(spots.last.x, 4);
      expect(spots.length, 6,
          reason: 'un mes vacío al final no se dibuja como "no pasó nada"');
    });

    test('sin movimientos en el año no devuelve ningún punto', () async {
      final provider = await _provider();
      expect(accumulatedSpots(provider.transactions, DateTime.now().year),
          isEmpty,
          reason: 'cero sin registrar no puede pintarse como cero medido');
    });
  });

  testWidgets('moneda única: la curva se dibuja y dice en qué va el año',
      (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final provider = await _provider();
    final year = DateTime.now().year;
    await provider.addTransaction(
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 5000,
        date: DateTime(year, 3, 10));
    await provider.addTransaction(
        type: TransactionType.expense,
        category: 'fertilizante',
        amount: 1000,
        date: DateTime(year, 4, 10));

    await tester.pumpWidget(_wrap(provider, year));
    await tester.pumpAndSettle();

    final l10n = stringsFor('es');
    expect(find.text(l10n.chartCumulativeTitle(year)), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget,
        reason: 'con una sola moneda la curva se grafica');
    expect(find.byType(BarChart), findsNothing,
        reason: 'la gráfica de barras quedó reemplazada por la curva');
    expect(find.textContaining(l10n.chartAccumDelta('')), findsOneWidget,
        reason: 'el pie dice en qué estado está el año');
    expect(find.textContaining(l10n.currencyMixedHint(1)), findsNothing);
  });

  testWidgets(
      'mezcla sin tasa: no dibuja curva ni imprime una cifra que cruce '
      'monedas', (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final provider = await _provider();
    final year = DateTime.now().year;
    await provider.addTransaction(
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 5000,
        date: DateTime(year, 3, 10));
    await provider.addTransaction(
        type: TransactionType.expense,
        category: 'transporte',
        amount: 1000,
        currency: 'EUR',
        date: DateTime(year, 4, 10));

    await tester.pumpWidget(_wrap(provider, year));
    await tester.pumpAndSettle();

    final l10n = stringsFor('es');
    final locale = provider.settings.locale;
    expect(find.byType(LineChart), findsNothing,
        reason: 'la curva sumaría pesos con euros: no se grafica');
    expect(find.byType(BarChart), findsNothing);
    expect(find.textContaining(l10n.currencyMixedHint(2)), findsOneWidget,
        reason: 'un aviso breve explica por qué no hay gráfica');

    // Cada moneda con su total, por separado.
    expect(
      find.text(
          'COP · ${l10n.incomeLabel} ${formatAmount(5000, currency: 'COP', locale: locale)}'),
      findsOneWidget,
    );
    expect(
      find.text(
          'EUR · ${l10n.expensesLabel} ${formatAmount(1000, currency: 'EUR', locale: locale)}'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
          formatAmount(6000, currency: 'COP', locale: locale)),
      findsNothing,
      reason: '5.000 + 1.000 es la suma falsa que ya no se imprime',
    );
  });
}
