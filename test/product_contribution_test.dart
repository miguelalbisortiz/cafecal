import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/tasks.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/product_contribution.dart';

const _cafe = Crop(id: 'c1', name: 'Café');
const _platano = Crop(id: 'c2', name: 'Plátano');

DateTimeRange _yearRange(int year) => DateTimeRange(
      start: DateTime(year, 1, 1),
      end: DateTime(year, 12, 31, 23, 59, 59, 999),
    );

ProductContributionReport _build(
  List<Transaction> transactions, {
  List<Crop> crops = const [_cafe, _platano],
  DateTimeRange? period,
  DateTime? coverageThrough,
  List<Harvest> harvests = const [],
}) =>
    buildProductContribution(
      transactions: transactions,
      crops: crops,
      period: period ?? _yearRange(2026),
      coverageThrough: coverageThrough,
      harvests: harvests,
    );

Transaction _tx({
  required String id,
  required TransactionType type,
  required double amount,
  required DateTime date,
  String category = 'otro',
  String currency = 'COP',
  String? cropId,
  String? terrenoId,
  String? sowingId,
  String? task,
  double? harvestedKg,
  bool deleted = false,
}) {
  return Transaction(
    id: id,
    type: type,
    category: category,
    amount: amount,
    currency: currency,
    date: date,
    createdAt: date,
    cropId: cropId,
    terrenoId: terrenoId,
    sowingId: sowingId,
    task: task,
    harvestedKg: harvestedKg,
    deleted: deleted,
  );
}

void main() {
  group('buildProductContribution', () {
    test('separa ingresos y gastos directos por mes', () {
      final report = _build([
        _tx(
          id: 'a',
          type: TransactionType.income,
          amount: 1000,
          date: DateTime(2026, 1, 10),
          cropId: 'c1',
        ),
        _tx(
          id: 'b',
          type: TransactionType.expense,
          amount: 400,
          date: DateTime(2026, 1, 20),
          cropId: 'c1',
        ),
        _tx(
          id: 'c',
          type: TransactionType.expense,
          amount: 100,
          date: DateTime(2026, 2, 5),
          cropId: 'c1',
        ),
        _tx(
          id: 'd',
          type: TransactionType.income,
          amount: 300,
          date: DateTime(2026, 2, 9),
          cropId: 'c2',
        ),
      ]);

      final cafe = report.rows.firstWhere((r) => r.cropId == 'c1');
      expect(cafe.netOf(1)['COP'], 600);
      expect(cafe.netOf(2)['COP'], -100);
      expect(cafe.netTotal['COP'], 500);

      final platano = report.rows.firstWhere((r) => r.cropId == 'c2');
      expect(platano.netOf(2)['COP'], 300);
      expect(platano.netOf(1), isEmpty);
      expect(report.monthsWithData, [1, 2]);
    });

    test('no reparte gastos de lote: los informa aparte', () {
      final report = _build([
        _tx(
          id: 'g1',
          type: TransactionType.expense,
          amount: 500,
          date: DateTime(2026, 3, 4),
          terrenoId: 't1',
        ),
        _tx(
          id: 'g2',
          type: TransactionType.expense,
          amount: 200,
          date: DateTime(2026, 3, 5),
        ),
      ]);

      expect(report.hasData, isFalse);
      expect(report.lotExpenseTotal['COP'], 500);
      expect(report.commonExpenseTotal['COP'], 200);
    });

    test('un ingreso sin cultivo no se suma a los gastos comunes', () {
      final report = _build([
        _tx(
          id: 'g1',
          type: TransactionType.expense,
          amount: 200,
          date: DateTime(2026, 3, 5),
        ),
        _tx(
          id: 'i1',
          type: TransactionType.income,
          amount: 900,
          date: DateTime(2026, 3, 6),
        ),
      ]);

      expect(report.commonExpenseTotal['COP'], 200,
          reason: 'la línea dice «gastos»: no puede contar una '
              'subvención');
      expect(report.commonIncomeTotal['COP'], 900);
    });

    test('una fila con dos monedas no tiene neto único', () {
      final report = _build([
        _tx(
          id: 'a',
          type: TransactionType.income,
          amount: 1000,
          date: DateTime(2026, 1, 3),
          cropId: 'c1',
        ),
        _tx(
          id: 'b',
          type: TransactionType.income,
          amount: 50,
          currency: 'USD',
          date: DateTime(2026, 1, 4),
          cropId: 'c1',
        ),
      ]);

      expect(report.rows.single.netTotal, {'COP': 1000, 'USD': 50});
    });

    test('ignora borrados y fechas fuera del período', () {
      final report = _build([
        _tx(
          id: 'borrado',
          type: TransactionType.income,
          amount: 1000,
          date: DateTime(2026, 1, 3),
          cropId: 'c1',
          deleted: true,
        ),
        // Antes del rango, aunque sea el mismo año.
        _tx(
          id: 'enero',
          type: TransactionType.income,
          amount: 100,
          date: DateTime(2026, 1, 31, 23, 59),
          cropId: 'c1',
        ),
        // Después del rango.
        _tx(
          id: 'marzo',
          type: TransactionType.income,
          amount: 900,
          date: DateTime(2026, 3, 1),
          cropId: 'c1',
        ),
      ],
          period: DateTimeRange(
            start: DateTime(2026, 2, 1),
            end: DateTime(2026, 2, 28, 23, 59, 59),
          ));

      expect(report.hasData, isFalse);
    });

    test('conserva un movimiento de un cultivo que ya no existe', () {
      final report = _build(
        [
          _tx(
            id: 'a',
            type: TransactionType.income,
            amount: 700,
            date: DateTime(2026, 4, 3),
            cropId: 'borrado',
          ),
        ],
        crops: const [_cafe],
      );

      expect(report.rows.single.cropId, 'borrado');
      expect(report.rows.single.name, 'borrado');
      expect(report.rows.single.netTotal['COP'], 700);
    });
  });

  group('coffeeCoverage', () {
    // C9 · la cobertura se mide contra la inversión de establecimiento, y las
    // cercas solo son establecimiento mientras el café no haya cosechado.
    test('las cercas de antes de la primera cosecha son inversión', () {
      final report = _build(
        [
          _tx(
            id: 'siembra',
            type: TransactionType.expense,
            amount: 1000,
            category: kExpenseCategorySowing,
            date: DateTime(2023, 3, 1),
            cropId: 'c1',
          ),
          // Antes de la primera cosecha (dic-2023): inversión.
          _tx(
            id: 'cercas-pre',
            type: TransactionType.expense,
            amount: 500,
            category: kExpenseCategoryFences,
            date: DateTime(2023, 6, 1),
            cropId: 'c1',
          ),
          // Después: mantenimiento, no inversión.
          _tx(
            id: 'cercas-post',
            type: TransactionType.expense,
            amount: 300,
            category: kExpenseCategoryFences,
            date: DateTime(2024, 6, 1),
            cropId: 'c1',
          ),
          _tx(
            id: 'platano',
            type: TransactionType.income,
            amount: 400,
            date: DateTime(2024, 7, 1),
            cropId: 'c2',
          ),
        ],
        harvests: [
          Harvest(
            id: 'h1',
            cropId: 'c1',
            date: DateTime(2023, 12, 15),
            amount: 500,
          ),
        ],
      );

      final cov = report.coverage;
      expect(cov, isNotNull);
      expect(cov!.investment, 1500,
          reason: 'siembra 1000 + cercas previas 500; las de 2024 son operación');
      expect(cov.contributed, 400);
      // 400 de 1500 son 26,6%: el modelo publica el entero redondeado.
      expect(cov.percent, 27);
      expect(cov.isCovered, isFalse);
    });

    // C9 · el corte es la primera cosecha que la app conoce, y esa lista
    // incluye los kilos del jornal de «Cosechar» (la misma que cuenta
    // Reportes), no solo las cosechas anotadas a mano.
    test('la primera cosecha es la del jornal medido, no solo la manual', () {
      final cov = coffeeCoverage(
        transactions: [
          _tx(
            id: 'cercas-pre',
            type: TransactionType.expense,
            amount: 500,
            category: kExpenseCategoryFences,
            date: DateTime(2024, 5, 1),
            cropId: 'c1',
          ),
          // Kilos medidos: no hay fila de cosecha guardada a mano.
          _tx(
            id: 'jornal',
            type: TransactionType.expense,
            amount: 100000,
            category: 'mano_obra',
            date: DateTime(2024, 6, 10),
            cropId: 'c1',
            task: kTaskCosechar,
            harvestedKg: 300,
          ),
          _tx(
            id: 'cercas-post',
            type: TransactionType.expense,
            amount: 300,
            category: kExpenseCategoryFences,
            date: DateTime(2024, 9, 1),
            cropId: 'c1',
          ),
          _tx(
            id: 'platano',
            type: TransactionType.income,
            amount: 400,
            date: DateTime(2024, 10, 1),
            cropId: 'c2',
          ),
        ],
        crops: const [_cafe, _platano],
      );

      expect(cov, isNotNull);
      expect(cov!.investment, 500,
          reason: 'las cercas de mayo son de antes de la cosecha de junio; '
              'las de septiembre son mantenimiento');
      expect(cov.percent, 80);
    });

    test('sin cosechas registradas, las cercas cuentan como inversión', () {
      final cov = coffeeCoverage(
        transactions: [
          _tx(
            id: 'cercas',
            type: TransactionType.expense,
            amount: 800,
            category: kExpenseCategoryFences,
            date: DateTime(2024, 2, 1),
            cropId: 'c1',
          ),
          _tx(
            id: 'platano',
            type: TransactionType.income,
            amount: 200,
            date: DateTime(2024, 7, 1),
            cropId: 'c2',
          ),
        ],
        crops: const [_cafe, _platano],
      );
      expect(cov, isNotNull);
      expect(cov!.investment, 800);
      expect(cov.percent, 25);
    });

    test('porcentaje de la inversión cubierto por los otros productos', () {
      final report = _build([
        // Inversión del café (siembra).
        _tx(
          id: 'inv',
          type: TransactionType.expense,
          amount: 1000,
          category: kExpenseCategorySowing,
          date: DateTime(2023, 3, 1),
          cropId: 'c1',
        ),
        // Aporte del plátano.
        _tx(
          id: 'i1',
          type: TransactionType.income,
          amount: 600,
          date: DateTime(2024, 5, 1),
          cropId: 'c2',
        ),
        _tx(
          id: 'e1',
          type: TransactionType.expense,
          amount: 200,
          date: DateTime(2024, 6, 1),
          cropId: 'c2',
        ),
      ]);

      final cov = report.coverage;
      expect(cov, isNotNull);
      expect(cov!.currency, 'COP');
      expect(cov.investment, 1000);
      expect(cov.contributed, 400);
      expect(cov.percent, 40);
      expect(cov.isCovered, isFalse);
    });

    test('cuenta también el gasto de siembra con sowingId', () {
      final report = _build([
        _tx(
          id: 'inv',
          type: TransactionType.expense,
          amount: 500,
          sowingId: 's1',
          date: DateTime(2023, 3, 1),
          cropId: 'c1',
        ),
        _tx(
          id: 'i',
          type: TransactionType.income,
          amount: 750,
          date: DateTime(2025, 1, 1),
          cropId: 'c2',
        ),
      ]);

      expect(report.coverage!.investment, 500);
      expect(report.coverage!.percent, 150);
      expect(report.coverage!.isCovered, isTrue);
    });

    test('la cobertura se corta al cierre del período', () {
      final report = _build([
        _tx(
          id: 'inv',
          type: TransactionType.expense,
          amount: 1000,
          category: kExpenseCategorySowing,
          date: DateTime(2025, 3, 1),
          cropId: 'c1',
        ),
        _tx(
          id: 'ene',
          type: TransactionType.income,
          amount: 500,
          date: DateTime(2026, 1, 15),
          cropId: 'c2',
        ),
        _tx(
          id: 'feb',
          type: TransactionType.income,
          amount: 500,
          date: DateTime(2026, 2, 15),
          cropId: 'c2',
        ),
      ],
          period: DateTimeRange(
            start: DateTime(2026, 1, 1),
            end: DateTime(2026, 1, 31, 23, 59, 59),
          ));

      expect(report.coverage!.contributed, 500);
      expect(report.coverage!.percent, 50);
    });

    test('la cobertura no cuenta fechas futuras', () {
      final report = _build(
        [
          _tx(
            id: 'inv',
            type: TransactionType.expense,
            amount: 1000,
            category: kExpenseCategorySowing,
            date: DateTime(2025, 3, 1),
            cropId: 'c1',
          ),
          _tx(
            id: 'hoy',
            type: TransactionType.income,
            amount: 400,
            date: DateTime(2026, 5, 1),
            cropId: 'c2',
          ),
          // Diciembre: dentro del año, pero todavía no pasó.
          _tx(
            id: 'futuro',
            type: TransactionType.income,
            amount: 5000,
            date: DateTime(2026, 12, 20),
            cropId: 'c2',
          ),
        ],
        coverageThrough: DateTime(2026, 5, 10, 23, 59, 59, 999),
      );

      // El movimiento futuro no infla la cobertura; el aporte del período sí
      // lo sigue mostrando, porque la fila no es la cobertura.
      expect(report.coverage!.contributed, 400);
      expect(report.coverage!.percent, 40);
      expect(report.rows.firstWhere((r) => r.cropId == 'c2').netTotal['COP'],
          5400);
    });

    test('sin café no hay cobertura', () {
      final report = _build(
        [
          _tx(
            id: 'a',
            type: TransactionType.income,
            amount: 100,
            date: DateTime(2026, 1, 1),
            cropId: 'c2',
          ),
        ],
        crops: const [_platano],
      );
      expect(report.coverage, isNull);
    });

    test('sin inversión de siembra no hay porcentaje', () {
      final report = _build([
        _tx(
          id: 'g',
          type: TransactionType.expense,
          amount: 100,
          date: DateTime(2026, 1, 1),
          cropId: 'c1',
        ),
        _tx(
          id: 'a',
          type: TransactionType.income,
          amount: 100,
          date: DateTime(2026, 1, 2),
          cropId: 'c2',
        ),
      ]);
      expect(report.coverage, isNull);
    });

    test('no cruza monedas distintas', () {
      final report = _build([
        _tx(
          id: 'inv',
          type: TransactionType.expense,
          amount: 1000,
          category: kExpenseCategorySowing,
          date: DateTime(2023, 3, 1),
          cropId: 'c1',
        ),
        _tx(
          id: 'a',
          type: TransactionType.income,
          amount: 100,
          currency: 'USD',
          date: DateTime(2024, 3, 1),
          cropId: 'c2',
        ),
      ]);
      expect(report.coverage, isNull);
    });

    test('reconoce el café por el nombre', () {
      const cafeLote = Crop(id: 'x1', name: 'Cafetal El Alto');
      final report = _build(
        [
          _tx(
            id: 'inv',
            type: TransactionType.expense,
            amount: 100,
            category: kExpenseCategorySowing,
            date: DateTime(2023, 3, 1),
            cropId: 'x1',
          ),
          _tx(
            id: 'a',
            type: TransactionType.income,
            amount: 50,
            date: DateTime(2024, 3, 1),
            cropId: 'c2',
          ),
        ],
        crops: const [cafeLote, _platano],
      );
      expect(report.coverage!.coffeeName, 'Cafetal El Alto');
      expect(report.coverage!.percent, 50);
    });
  });

  test('sin movimientos no hay filas ni cobertura', () {
    final report = _build([]);
    expect(report.hasData, isFalse);
    expect(report.rows, isEmpty);
    expect(report.coverage, isNull);
  });
}
