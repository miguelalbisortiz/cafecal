import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/movements_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/services/report_insights_service.dart';
import 'package:mi_cafetal/widgets/category_breakdown.dart';

/// Últimos huecos de moneda mixta (2/2):
///  1. `ReportInsightsService` (mayor gasto, ventas, mejor mes),
///  2. filas de `CategoryBreakdown` (monto, % y barra),
///  3. mini-stats de `MovementsScreen`,
///  4. `totalExpenses`/`totalIncomes` del proveedor.
///
/// Con **moneda única** todo sale idéntico a siempre; con **mezcla** ninguna
/// cifra cruza monedas: se omite la conclusión, se lista moneda por moneda o
/// se devuelve `null`. Nunca un total global falso.

AppLocalizations get _es => stringsFor('es');

String _money(double v) => '\$${v.round()}';

Transaction txn({
  required TransactionType type,
  required double amount,
  required DateTime date,
  String currency = 'COP',
  String category = 'venta_cafe',
}) =>
    Transaction(
      id: '${type.name}_${amount}_${currency}_${date.microsecondsSinceEpoch}',
      type: type,
      category: category,
      amount: amount,
      currency: currency,
      date: date,
      createdAt: date,
    );

List<String> _texts(Iterable<ReportInsight> insights) =>
    insights.map((i) => i.text).toList();

Future<TransactionProvider> makeProvider() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  return TransactionProvider(LocalStore(prefs));
}

Widget _wrap(TransactionProvider tx, Widget home) => MultiProvider(
      providers: [ChangeNotifierProvider<TransactionProvider>.value(value: tx)],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

/// Datos del año: marzo con ventas y junio con ventas + gastos.
/// Cada moneda se puede cambiar por separado para armar el caso mezcla.
List<Transaction> _year({
  String marIncomeCurrency = 'COP',
  String junIncomeCurrency = 'COP',
  String junIncome2Currency = 'COP',
  String junExpenseCurrency = 'COP',
}) =>
    [
      txn(
          type: TransactionType.income,
          amount: 9000,
          date: DateTime(2026, 3, 10),
          currency: marIncomeCurrency),
      txn(
          type: TransactionType.expense,
          amount: 1000,
          date: DateTime(2026, 3, 11),
          category: 'mano_obra'),
      txn(
          type: TransactionType.income,
          amount: 5000,
          date: DateTime(2026, 6, 5),
          currency: junIncomeCurrency),
      txn(
          type: TransactionType.income,
          amount: 200,
          date: DateTime(2026, 6, 6),
          category: 'venta_otro',
          currency: junIncome2Currency),
      txn(
          type: TransactionType.expense,
          amount: 600,
          date: DateTime(2026, 6, 1),
          category: 'mano_obra'),
      txn(
          type: TransactionType.expense,
          amount: 300,
          date: DateTime(2026, 6, 2),
          category: 'transporte',
          currency: junExpenseCurrency),
    ];

List<String> _buildInsights(List<Transaction> year, {bool mixedTotals = false}) {
  final current = year.where((t) => t.date.month == 6).toList();
  return _texts(const ReportInsightsService().build(
    now: DateTime(2026, 6, 15),
    current: current,
    previousMonth: const [],
    yearRecords: year,
    year: 2026,
    month: 6,
    l10n: _es,
    money: _money,
    mixedTotals: mixedTotals,
  ));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('5 · report_insights_service mono vs mezcla', () {
    test('moneda única: mayor gasto, mejor ingreso y mejor mes siguen ahí',
        () {
      final texts = _buildInsights(_year());
      expect(texts.any((t) => t.contains('Tu mayor gasto')), isTrue);
      expect(texts.any((t) => t.contains('Tu mejor ingreso')), isTrue);
      expect(texts.any((t) => t.contains('Tu mejor mes')), isTrue);
      expect(texts.any((t) => t.contains('Resultado del período')), isTrue);
    });

    test('mezcla: no hay "mejor mes", ni "mayor gasto", ni "mejor ingreso"',
        () {
      final texts = _buildInsights(
        _year(junIncome2Currency: 'EUR', junExpenseCurrency: 'EUR'),
        mixedTotals: true,
      );
      expect(texts.any((t) => t.contains('Tu mayor gasto')), isFalse,
          reason: 'un gasto en pesos y otro en euros no tienen un tope común');
      expect(texts.any((t) => t.contains('Tu mejor ingreso')), isFalse,
          reason: 'el % sobre un total mixto sería mentira');
      expect(texts.any((t) => t.contains('Tu mejor mes')), isFalse,
          reason: 'el ranking de meses cruzaría monedas');
      expect(texts.any((t) => t.contains('Resultado del período')), isFalse);
      expect(texts.where((t) => t.contains(r'$')), isEmpty,
          reason: 'sin tasa no se pinta ni una cifra');
    });

    test('período mono en un año mixto: conclusiones del mes sí, anuales no',
        () {
      // Junio es 100 % COP (lo de siempre se pinta), pero marzo trae euros:
      // "mejor mes" y "precio bajo" compararían meses en monedas distintas.
      final texts = _buildInsights(_year(marIncomeCurrency: 'EUR'));
      expect(texts.any((t) => t.contains('Tu mayor gasto')), isTrue);
      expect(texts.any((t) => t.contains('Tu mejor ingreso')), isTrue);
      expect(texts.any((t) => t.contains('Resultado del período')), isTrue);
      expect(texts.any((t) => t.contains('Tu mejor mes')), isFalse,
          reason: 'el ranking de meses cruzaría COP con EUR');
      expect(texts.any((t) => t.contains('Vendes por montos menores')),
          isFalse,
          reason: 'el promedio anual de ventas también cruzaría monedas');
    });

    test('mezcla en el período: ni siquiera el subconjunto mono emite cifra',
        () {
      // Los gastos de junio son todos COP, pero el período mezcla monedas y
      // el informe formatea con la moneda de Ajustes: mejor callar.
      final texts = _buildInsights(
        _year(junIncome2Currency: 'EUR'),
        mixedTotals: true,
      );
      expect(texts, isEmpty);
    });

    test('precio bajo: mono avisa, mezcla se calla', () {
      List<Transaction> sales(String c) => [
            for (var i = 1; i <= 3; i++)
              txn(
                  type: TransactionType.income,
                  amount: 1000,
                  date: DateTime(2026, i, 10)),
            txn(
                type: TransactionType.income,
                amount: 400,
                date: DateTime(2026, 6, 1)),
            txn(
                type: TransactionType.income,
                amount: 400,
                currency: c,
                date: DateTime(2026, 6, 8)),
          ];

      final mono = _buildInsights(sales('COP'));
      expect(mono.any((t) => t.contains('Vendes por montos menores')), isTrue);

      final mixed = _buildInsights(sales('EUR'), mixedTotals: true);
      expect(
          mixed.any((t) => t.contains('Vendes por montos menores')), isFalse,
          reason: 'el promedio de ventas cruzaría pesos y euros');
      expect(mixed.where((t) => t.contains(r'$')), isEmpty);
    });
  });

  group('6 · category_breakdown mono vs mezcla', () {
    Future<void> pumpBreakdown(
        WidgetTester tester, TransactionProvider tx) async {
      await tester.pumpWidget(_wrap(
        tx,
        const Scaffold(
          body: SingleChildScrollView(
            child: CategoryBreakdown(
              year: 2026,
              month: 9,
              type: TransactionType.expense,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('moneda única: % por fila y barra proporcional',
        (WidgetTester tester) async {
      final tx = await makeProvider();
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'fertilizante',
          amount: 1000,
          date: DateTime(2026, 9, 5));
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'transporte',
          amount: 500,
          date: DateTime(2026, 9, 6));

      await pumpBreakdown(tester, tx);

      expect(find.text('67%'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
      expect(find.text('\$1.000'), findsOneWidget);
      expect(find.text('\$500'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
      expect(find.textContaining(_es.currencyMixedHint(2)), findsNothing);
    });

    testWidgets('mezcla: fila sin % y sin barra mentirosa, monto por moneda',
        (WidgetTester tester) async {
      final tx = await makeProvider();
      // Una misma categoría con las dos monedas: es justo la fila que antes
      // pintaba un solo monto y un % sobre un total falso.
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'fertilizante',
          amount: 1000,
          date: DateTime(2026, 9, 5));
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'fertilizante',
          amount: 50,
          currency: 'EUR',
          date: DateTime(2026, 9, 6));
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'transporte',
          amount: 500,
          date: DateTime(2026, 9, 7));

      await pumpBreakdown(tester, tx);

      expect(find.byType(LinearProgressIndicator), findsNothing,
          reason: 'sin proporciones sobre monedas que no se suman');
      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();
      expect(labels.any((l) => l.endsWith('%')), isFalse,
          reason: 'ningún % sobre un total que mezcla monedas');
      expect(
        labels.any((l) => l.contains('COP') && l.contains('EUR')),
        isTrue,
        reason: 'la fila mixta lista cada moneda con su código',
      );
      expect(find.text('\$1.550'), findsNothing,
          reason: '1000 + 50 + 500 no es una cifra real');
      expect(find.textContaining(_es.currencyMixedHint(2)), findsOneWidget);
    });
  });

  group('7 · movements_screen mini-stats mono vs mezcla', () {
    Future<void> pumpMovements(
        WidgetTester tester, TransactionProvider tx) async {
      await tester.pumpWidget(_wrap(tx, const Scaffold(body: MovementsScreen())));
      await tester.pumpAndSettle();
    }

    testWidgets('moneda única: ingresos, gastos y resultado de siempre',
        (WidgetTester tester) async {
      final tx = await makeProvider();
      await tx.addTransaction(
          type: TransactionType.income,
          category: 'venta_cafe',
          amount: 3000,
          date: DateTime(2026, 9, 1));
      await tx.addTransaction(
          type: TransactionType.income,
          category: 'venta_cafe',
          amount: 2000,
          date: DateTime(2026, 9, 2));
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 1000,
          date: DateTime(2026, 9, 3));

      await pumpMovements(tester, tx);

      expect(find.text('\$5.000'), findsOneWidget, reason: 'ingresos');
      expect(find.text('\$1.000'), findsOneWidget, reason: 'gastos');
      expect(find.text('\$4.000'), findsOneWidget, reason: 'resultado');
      expect(find.textContaining(_es.currencyMixedHint(2)), findsNothing);
    });

    testWidgets('mezcla: cada mini-stat va por moneda y no hay total global',
        (WidgetTester tester) async {
      final tx = await makeProvider();
      await tx.addTransaction(
          type: TransactionType.income,
          category: 'venta_cafe',
          amount: 3000,
          date: DateTime(2026, 9, 1));
      await tx.addTransaction(
          type: TransactionType.income,
          category: 'venta_cafe',
          amount: 200,
          currency: 'EUR',
          date: DateTime(2026, 9, 2));
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 1000,
          date: DateTime(2026, 9, 3));
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'transporte',
          amount: 50,
          currency: 'EUR',
          date: DateTime(2026, 9, 4));

      await pumpMovements(tester, tx);

      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();

      expect(
        labels.any((l) => l.contains('COP') && l.contains('EUR')),
        isTrue,
        reason: 'los tres mini-stats listan sus monedas con código',
      );
      expect(find.text('\$3.200'), findsNothing,
          reason: '3000 + 200 no es un ingreso');
      expect(find.text('\$1.050'), findsNothing,
          reason: '1000 + 50 no es un gasto');
      expect(find.text('\$2.150'), findsNothing,
          reason: 'no hay resultado global entre monedas');
      expect(find.textContaining(_es.currencyMixedHint(2)), findsOneWidget,
          reason: 'la fila compacta explica por qué no hay una sola cifra');
    });
  });

  group('8 · transaction_provider totalExpenses/totalIncomes', () {
    test('moneda única: devuelven la suma de siempre', () async {
      final tx = await makeProvider();
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'fertilizante',
          amount: 100,
          date: DateTime(2026, 3, 1));
      await tx.addTransaction(
          type: TransactionType.income,
          category: 'venta_cafe',
          amount: 300,
          date: DateTime(2026, 3, 2));

      expect(tx.totalExpenses(year: 2026), 100);
      expect(tx.totalIncomes(year: 2026), 300);
      expect(tx.totalExpenses(year: 2025), 0);
    });

    test('mezcla: devuelven null, nunca un total cruzando monedas', () async {
      final tx = await makeProvider();
      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'fertilizante',
          amount: 100,
          date: DateTime(2026, 3, 1));
      await tx.addTransaction(
          type: TransactionType.income,
          category: 'venta_cafe',
          amount: 300,
          date: DateTime(2026, 3, 2));
      expect(tx.totalExpenses(year: 2026), 100);

      await tx.addTransaction(
          type: TransactionType.expense,
          category: 'transporte',
          amount: 50,
          currency: 'EUR',
          date: DateTime(2026, 3, 3));
      await tx.addTransaction(
          type: TransactionType.income,
          category: 'venta_cafe',
          amount: 20,
          currency: 'EUR',
          date: DateTime(2026, 3, 4));

      expect(tx.totalExpenses(year: 2026), isNull,
          reason: 'no puede devolver 150 mezclando pesos y euros');
      expect(tx.totalIncomes(year: 2026), isNull);
      // El twin por moneda sí da una cifra cierta.
      expect(
        tx.sumByCurrency(TransactionType.expense, year: 2026),
        {'COP': 100.0, 'EUR': 50.0},
      );
      expect(
        tx.sumByCurrency(TransactionType.income, year: 2026),
        {'COP': 300.0, 'EUR': 20.0},
      );
      // El filtro por año sigue aislando la mezcla: otro año es mono.
      expect(tx.totalExpenses(year: 2025), 0);
    });
  });
}
