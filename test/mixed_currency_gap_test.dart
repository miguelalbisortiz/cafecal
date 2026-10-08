import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/farm_alert.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/alert_service.dart';
import 'package:mi_cafetal/services/currency_totals.dart';
import 'package:mi_cafetal/services/excel_export_service.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';

/// Últimos huecos de moneda mixta:
///  1. cabeceras de PDF y Excel,
///  2. sección de cosechas (costo por kg e inversión),
///  3. `buildBalanceTemplate` (CSV con fórmulas),
///  4. `alert_service`.
///
/// Con **moneda única** todo debe salir idéntico a siempre; con **mezcla**
/// ninguna cifra cruza monedas: totales por moneda con su código, sin %,
/// sin costo unitario, sin fórmulas de total y sin alertas falsas.
AppLocalizations get _es => stringsFor('es');

const _crops = [
  Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41'),
  Crop(
      id: 'nuevo',
      name: 'Nuevo plantío',
      phase: CropPhase.establecimiento),
];

const _settings = FarmSettings(farmName: 'Finca Test', currency: 'COP');

Transaction txn({
  required TransactionType type,
  required double amount,
  String currency = 'COP',
  String category = 'venta',
  String? cropId,
  String? harvestId,
  DateTime? date,
}) =>
    Transaction(
      id: '${type.name}_${amount}_$currency'
          '${cropId ?? ''}${harvestId ?? ''}${date?.microsecondsSinceEpoch ?? 0}',
      type: type,
      category: category,
      amount: amount,
      currency: currency,
      cropId: cropId,
      harvestId: harvestId,
      date: date ?? DateTime(2026, 9, 5),
      createdAt: DateTime(2026, 9, 5),
    );

Harvest harvest({String? cropId = 'cafe', double amount = 100}) => Harvest(
      id: 'h_$cropId',
      cropId: cropId,
      date: DateTime(2026, 9, 5),
      amount: amount,
      unit: 'kg',
    );

// Extrae el valor nativo de una celda Excel.
dynamic cv(Data? cell) {
  final v = cell?.value;
  if (v == null) return null;
  if (v is IntCellValue) return v.value;
  if (v is DoubleCellValue) return v.value;
  if (v is TextCellValue) return v.value.text;
  return null;
}

String t0(Data? cell) => cv(cell)?.toString() ?? '';

List<List<Data?>> sheet(
  String name, {
  required List<Transaction> txns,
  List<Harvest> harvests = const [],
}) =>
    Excel.decodeBytes(Uint8List.fromList(ExcelExportService().buildReport(
      settings: _settings,
      transactions: txns,
      crops: _crops,
      year: 2026,
      month: 9,
      period: ReportPeriod.month,
      periodName: 'Septiembre 2026',
      l10n: _es,
      harvests: harvests,
    ))).tables[name]!.rows;

String balanceCsv({required List<Transaction> txns}) => utf8.decode(
    ExcelExportService().buildBalanceTemplate(
      settings: _settings,
      transactions: txns,
      year: 2026,
      periodName: 'Septiembre 2026',
      l10n: _es,
    ));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('currency_totals — helpers compartidos', () {
    test('results da el resultado de cada moneda por separado', () {
      final mixed = PeriodCurrencyTotals.fromRecords([
        txn(type: TransactionType.income, amount: 5000),
        txn(type: TransactionType.income, amount: 200, currency: 'EUR'),
        txn(type: TransactionType.expense,
            amount: 1000, category: 'fertilizante'),
      ]);
      expect(mixed.isMixed, isTrue);
      expect(mixed.results, {'COP': 4000.0, 'EUR': 200.0});
      expect(mixed.currencies.length, 2);

      final single = PeriodCurrencyTotals.fromRecords([
        txn(type: TransactionType.income, amount: 5000),
        txn(type: TransactionType.expense,
            amount: 1000, category: 'fertilizante'),
      ]);
      expect(single.isMixed, isFalse);
      expect(single.results, {'COP': 4000.0});
    });

    test('groupAmountsByCurrency separa por clave y por moneda', () {
      final groups = groupAmountsByCurrency([
        txn(type: TransactionType.income, amount: 5000),
        txn(type: TransactionType.income, amount: 100, currency: 'EUR'),
        txn(type: TransactionType.income,
            amount: 200, category: 'subvenciones'),
      ], keyOf: (t) => incomeGroupKey(t.category, t.cropId));
      expect(groups.keys, contains('venta'));
      expect(groups['venta'], {'COP': 5000.0, 'EUR': 100.0});
      expect(groups['subvenciones'], {'COP': 200.0});
      // El orden es por monto (mayor a menor), sin cruzar monedas.
      expect(groups.keys.first, 'venta');
    });
  });

  group('1 · Cabecera del Excel: resumen mono vs mezcla', () {
    test('moneda única: totales numéricos, % sobre el total y margen/ratio',
        () {
      final rows = sheet('Resumen', txns: [
        txn(type: TransactionType.income, amount: 5000),
        txn(
            type: TransactionType.expense,
            amount: 1000,
            category: 'fertilizante'),
      ]);

      final h = rows.indexWhere((r) => t0(r[0]) == _es.pdfIncomesHeader);
      expect(h, greaterThanOrEqualTo(0));
      expect(cv(rows[h][2]), 5000.0, reason: 'celda numérica');
      expect(cv(rows[h][1]), isNull);
      // Detalle de ingresos: % sobre el total.
      expect(t0(rows[h + 1][1]), isNotEmpty, reason: 'con una moneda sí hay %');
      expect(cv(rows[h + 1][2]), 5000.0);

      final e = rows.indexWhere((r) => t0(r[0]) == _es.pdfExpensesHeader);
      expect(cv(rows[e][2]), -1000.0);
      expect(t0(rows[e + 1][1]), isNotEmpty, reason: '% de gastos');

      final result = rows
          .firstWhere((r) => t0(r[0]) == _es.resultPeriodLabel);
      expect(cv(result[2]), 4000.0, reason: 'resultado de siempre');
      final margin = rows.firstWhere((r) => t0(r[0]) == _es.marginLabel);
      expect(cv(margin[1]), isNot('—'),
          reason: 'con una moneda el margen sigue calculándose');
      expect(t0(margin[1]), isNotEmpty);
      final ratio = rows.firstWhere((r) => t0(r[0]) == _es.ratioLabel);
      expect(cv(ratio[1]), isNot('—'));
      expect(
        rows.any((r) => t0(r[0]) == _es.currencyMixedByCurrencyNote(2)),
        isFalse,
      );
    });

    test('mezcla: totales por moneda con código, sin %, sin margen ni ratio',
        () {
      final rows = sheet('Resumen', txns: [
        txn(type: TransactionType.income, amount: 5000),
        txn(type: TransactionType.income, amount: 200, currency: 'EUR'),
        txn(
            type: TransactionType.expense,
            amount: 1000,
            category: 'fertilizante'),
        txn(
            type: TransactionType.expense,
            amount: 50,
            currency: 'EUR',
            category: 'transporte'),
      ]);

      final h = rows.indexWhere((r) => t0(r[0]) == _es.pdfIncomesHeader);
      expect(t0(rows[h][2]), contains('COP'));
      expect(t0(rows[h][2]), contains('EUR'),
          reason: 'cada moneda con su código, nunca una suma');

      final firstIncome = rows[h + 1];
      expect(t0(firstIncome[1]), isEmpty, reason: 'sin % sobre un total mixto');
      expect(t0(firstIncome[2]), contains('COP'));
      expect(t0(firstIncome[2]), contains('EUR'));

      final e = rows.indexWhere((r) => t0(r[0]) == _es.pdfExpensesHeader);
      expect(t0(rows[e][2]), contains('COP'));
      expect(t0(rows[e][2]), contains('EUR'));
      expect(t0(rows[e + 1][1]), isEmpty, reason: 'sin % de gastos');

      final result = rows
          .firstWhere((r) => t0(r[0]) == _es.resultPeriodLabel);
      expect(t0(result[2]), contains('COP'));
      expect(t0(result[2]), contains('EUR'), reason: 'resultado por moneda');
      final margin = rows.firstWhere((r) => t0(r[0]) == _es.marginLabel);
      expect(cv(margin[1]), '—', reason: 'sin margen que cruce monedas');
      final ratio = rows.firstWhere((r) => t0(r[0]) == _es.ratioLabel);
      expect(cv(ratio[1]), '—');
      expect(
        rows.any((r) => t0(r[0]) == _es.currencyMixedByCurrencyNote(2)),
        isTrue,
        reason: 'la hoja explica por qué no hay total global',
      );
    });

    test('mezcla: el cruce categoría × cultivo también va por moneda', () {
      final rows = sheet('Resumen', txns: [
        txn(
            type: TransactionType.expense,
            amount: 2000,
            category: 'fertilizante',
            cropId: 'cafe'),
        txn(
            type: TransactionType.expense,
            amount: 50,
            currency: 'EUR',
            category: 'fertilizante',
            cropId: 'cafe'),
      ]);

      final t = rows.indexWhere((r) => t0(r[0]) == _es.excelCrossExpensesTitle);
      expect(t, greaterThanOrEqualTo(0));
      expect(t0(rows[t + 2][1]), 'Café');
      expect(t0(rows[t + 2][2]), contains('COP'));
      expect(t0(rows[t + 2][2]), contains('EUR'),
          reason: 'la celda del cruce nunca suma monedas distintas');
    });
  });

  group('2 · Cosechas del Excel: costo por kg e inversión', () {
    test('moneda única: costo de recogida y costo por kg numéricos', () {
      final rows = sheet('Cosechas', txns: [
        txn(
            type: TransactionType.expense,
            amount: 50000,
            category: 'mano_obra',
            cropId: 'cafe',
            harvestId: 'h_cafe'),
      ], harvests: [harvest()]);

      final pickup = rows
          .firstWhere((r) => t0(r[0]) == _es.reportPickupCostPerKg);
      expect(cv(pickup[1]), 500.0, reason: '50.000 ÷ 100 kg');
      final cost = rows.firstWhere(
          (r) => t0(r[0]) == 'Café — ${_es.reportTotalCostPerKg}');
      expect(cv(cost[1]), 500.0, reason: 'costo por kg de siempre');
      expect(
        rows.any((r) => t0(r[0]) == _es.currencyMixedByCurrencyNote(2)),
        isFalse,
      );
    });

    test('mezcla: el costo por kg sale en guion y con aviso', () {
      final rows = sheet('Cosechas', txns: [
        txn(
            type: TransactionType.expense,
            amount: 50000,
            category: 'mano_obra',
            cropId: 'cafe',
            harvestId: 'h_cafe'),
        txn(
            type: TransactionType.expense,
            amount: 20,
            currency: 'EUR',
            category: 'mano_obra',
            cropId: 'cafe',
            harvestId: 'h_cafe'),
      ], harvests: [harvest()]);

      final pickup = rows
          .firstWhere((r) => t0(r[0]) == _es.reportPickupCostPerKg);
      expect(cv(pickup[1]), '—',
          reason: 'pesos y dólares entre los mismos kilos = costo falso');
      final cost = rows.firstWhere(
          (r) => t0(r[0]) == 'Café — ${_es.reportTotalCostPerKg}');
      expect(cv(cost[1]), '—');
      expect(
        rows.any((r) => t0(r[0]) == _es.currencyMixedByCurrencyNote(2)),
        isTrue,
        reason: 'la hoja explica por qué no hay cifra por kilo',
      );
    });

    test('mezcla: la inversión acumulada va moneda por moneda', () {
      final rows = sheet('Cosechas', txns: [
        txn(
            type: TransactionType.expense,
            amount: 300000,
            category: 'siembra',
            cropId: 'nuevo'),
        txn(
            type: TransactionType.expense,
            amount: 80,
            currency: 'EUR',
            category: 'siembra',
            cropId: 'nuevo'),
      ], harvests: [
        harvest(),
        harvest(cropId: 'nuevo', amount: 10),
      ]);

      final inv = rows.firstWhere(
          (r) => t0(r[0]) == 'Nuevo plantío — ${_es.reportInvestmentEstablecimiento}');
      expect(t0(inv[1]), contains('COP'));
      expect(t0(inv[1]), contains('EUR'));
      expect(inv[1]?.value, isA<TextCellValue>());
    });

    test('moneda única: la inversión sigue siendo un número', () {
      final rows = sheet('Cosechas', txns: [
        txn(
            type: TransactionType.expense,
            amount: 300000,
            category: 'siembra',
            cropId: 'nuevo'),
      ], harvests: [
        harvest(),
        harvest(cropId: 'nuevo', amount: 10),
      ]);

      final inv = rows.firstWhere(
          (r) => t0(r[0]) == 'Nuevo plantío — ${_es.reportInvestmentEstablecimiento}');
      expect(cv(inv[1]), 300000.0);
    });
  });

  group('3 · buildBalanceTemplate (CSV con fórmulas)', () {
    test('moneda única: idéntico a siempre, con sus fórmulas', () {
      final csv = balanceCsv(txns: [
        txn(type: TransactionType.income, amount: 5000),
        txn(
            type: TransactionType.expense,
            amount: 2000,
            category: 'fertilizante'),
      ]);
      expect(csv, contains('=SUM(B5:B10)'));
      expect(csv, contains('=SUM(B14:B16)'));
      expect(csv, contains('=SUM(B20:B22)'));
      expect(csv, contains('=B11-B17-B23'));
      expect(csv, contains('3000,00'));
      expect(csv, contains(_es.balanceRowNetIncome(2026)));
      expect(csv.split('\r\n').where((l) => l.startsWith('${_es.balanceRowNetIncome(2026)};')).length, 1,
          reason: 'una sola fila de utilidad');
      expect(csv, isNot(contains(_es.balanceMixedCurrencyNote(2))));
    });

    test('mezcla: ni una sola fórmula que pueda sumar monedas distintas', () {
      final csv = balanceCsv(txns: [
        txn(type: TransactionType.income, amount: 5000),
        txn(type: TransactionType.income, amount: 100, currency: 'EUR'),
        txn(
            type: TransactionType.expense,
            amount: 2000,
            category: 'fertilizante'),
      ]);
      // Ninguna celda arranca con '=' (tras un ';' o al inicio de línea).
      expect(RegExp(r'(^|;)=').hasMatch(csv), isFalse,
          reason: 'no puede quedar una fórmula que mezcle COP con USD');
      expect(csv, isNot(contains('=SUM(')));
      expect(csv, isNot(contains('=B11')));
      // Utilidad: una fila por moneda, nunca una cifra global.
      final netLines = csv
          .split('\r\n')
          .where((l) => l.startsWith(_es.balanceRowNetIncome(2026)))
          .toList();
      expect(netLines.length, 2, reason: 'una fila por moneda');
      expect(netLines[0], contains('· COP'));
      expect(netLines[0], endsWith('3000,00'));
      expect(netLines[1], contains('· EUR'));
      expect(netLines[1], endsWith('100,00'));
      expect(csv, contains(_es.balanceMixedCurrencyNote(2)));
    });

    test('mezcla: los totales de activos, pasivos y patrimonio salen vacíos',
        () {
      final csv = balanceCsv(txns: [
        txn(type: TransactionType.income, amount: 5000),
        txn(type: TransactionType.expense,
            amount: 100, currency: 'EUR', category: 'transporte'),
      ]);
      final lines = csv.split('\r\n');
      String cellB(String label) {
        expect(
          lines.any((l) => l == label || l.startsWith('$label;')),
          isTrue,
          reason: 'la fila "$label" debe existir',
        );
        final line = lines
            .firstWhere((l) => l == label || l.startsWith('$label;'));
        return line.split(';').elementAtOrNull(1) ?? '';
      }

      expect(cellB(_es.balanceTotalAssets), isEmpty);
      expect(cellB(_es.balanceTotalLiabilities), isEmpty);
      expect(cellB(_es.balanceTotalEquity), isEmpty);
      expect(cellB(_es.balanceCheckLabel), isEmpty);
    });
  });

  group('4 · alert_service mono vs mezcla', () {
    final now = DateTime(2026, 6, 15);

    List<FarmAlert> alerts(List<Transaction> txns, {double? caja}) =>
        AlertService(now: now)
            .evaluate(txns, _crops, _es, cajaMensual: caja);

    test('ROI por cultivo: mono dispara, mezcla se calla', () {
      final mono = alerts([
        txn(
            type: TransactionType.expense,
            amount: 1000,
            category: 'fertilizante',
            cropId: 'cafe',
            date: DateTime(2026, 1, 10)),
      ]);
      expect(mono.any((a) => a.rule == AlertRule.deficitCrop), isTrue);

      final mixed = alerts([
        txn(
            type: TransactionType.expense,
            amount: 1000,
            category: 'fertilizante',
            cropId: 'cafe',
            date: DateTime(2026, 1, 10)),
        txn(
            type: TransactionType.income,
            amount: 100,
            currency: 'EUR',
            cropId: 'cafe',
            date: DateTime(2026, 2, 10)),
      ]);
      expect(mixed.where((a) => a.rule == AlertRule.deficitCrop), isEmpty,
          reason: 'el ROI de un cultivo que mezcla monedas sería mentira');
    });

    test('cultivo en moneda única sigue evaluándose aunque haya otra moneda '
        'en otro cultivo', () {
      final found = alerts([
        txn(
            type: TransactionType.expense,
            amount: 1000,
            category: 'fertilizante',
            cropId: 'cafe',
            date: DateTime(2026, 1, 10)),
        // Otro cultivo, en euros: no debe tapar el aviso del café.
        txn(
            type: TransactionType.income,
            amount: 200,
            currency: 'EUR',
            cropId: 'nuevo',
            date: DateTime(2026, 2, 10)),
      ]);
      expect(found.any((a) => a.rule == AlertRule.deficitCrop), isTrue);
      expect(
        found.any((a) => a.id == 'deficit_cafe'),
        isTrue,
        reason: 'el café es moneda única: su aviso sigue en pie',
      );
    });

    test('déficit del período: mono dispara, mezcla se calla', () {
      final mono = alerts([
        txn(
            type: TransactionType.expense,
            amount: 500,
            category: 'fertilizante',
            date: DateTime(2026, 4, 10)),
        txn(
            type: TransactionType.expense,
            amount: 500,
            category: 'fertilizante',
            date: DateTime(2026, 5, 10)),
        txn(
            type: TransactionType.expense,
            amount: 500,
            category: 'fertilizante',
            date: DateTime(2026, 6, 10)),
        txn(
            type: TransactionType.income,
            amount: 100,
            date: DateTime(2026, 4, 15)),
      ]);
      expect(mono.any((a) => a.rule == AlertRule.consecutiveLosses), isTrue);

      // Mismo escenario pero con la venta de abril en euros: abril deja de
      // ser comparable y la racha se corta.
      final mixed = alerts([
        txn(
            type: TransactionType.expense,
            amount: 500,
            category: 'fertilizante',
            date: DateTime(2026, 4, 10)),
        txn(
            type: TransactionType.expense,
            amount: 500,
            category: 'fertilizante',
            date: DateTime(2026, 5, 10)),
        txn(
            type: TransactionType.expense,
            amount: 500,
            category: 'fertilizante',
            date: DateTime(2026, 6, 10)),
        txn(
            type: TransactionType.income,
            amount: 100,
            currency: 'EUR',
            date: DateTime(2026, 4, 15)),
      ]);
      expect(
          mixed.where((a) => a.rule == AlertRule.consecutiveLosses), isEmpty);
    });

    test('comparativa por categoría: mono dispara, mezcla se calla', () {
      List<Transaction> base(String historyCurrency, String monthCurrency) => [
            txn(
                type: TransactionType.expense,
                amount: 100,
                currency: historyCurrency,
                category: 'mano_obra',
                date: DateTime(2026, 1, 10)),
            txn(
                type: TransactionType.expense,
                amount: 100,
                currency: historyCurrency,
                category: 'mano_obra',
                date: DateTime(2026, 2, 10)),
            txn(
                type: TransactionType.expense,
                amount: 100,
                currency: historyCurrency,
                category: 'mano_obra',
                date: DateTime(2026, 3, 10)),
            txn(
                type: TransactionType.expense,
                amount: 300,
                currency: monthCurrency,
                category: 'mano_obra',
                date: DateTime(2026, 6, 10)),
          ];

      expect(
        alerts(base('COP', 'COP'))
            .any((a) => a.rule == AlertRule.excessiveSpending),
        isTrue,
        reason: '300 > 2×100 en la misma moneda',
      );
      expect(
        alerts(base('COP', 'EUR'))
            .where((a) => a.rule == AlertRule.excessiveSpending),
        isEmpty,
        reason: 'comparar 300 EUR con 100 COP sería mentira',
      );
    });

    test('caja menor: mono dispara, mezcla se calla', () {
      final mono = alerts([
        txn(
            type: TransactionType.expense,
            amount: 400,
            category: 'mano_obra',
            date: DateTime(2026, 6, 5)),
        txn(
            type: TransactionType.expense,
            amount: 100,
            currency: 'EUR',
            category: 'energia',
            date: DateTime(2026, 6, 10)),
      ], caja: 600);
      expect(mono.where((a) => a.rule == AlertRule.cajaMenor), isEmpty,
          reason: 'solo 400 COP descuentan de la caja, no llega al 80%');

      final mixed = alerts([
        txn(
            type: TransactionType.expense,
            amount: 400,
            category: 'mano_obra',
            date: DateTime(2026, 6, 5)),
        txn(
            type: TransactionType.expense,
            amount: 300,
            currency: 'EUR',
            category: 'energia',
            date: DateTime(2026, 6, 10)),
      ], caja: 600);
      expect(mixed.where((a) => a.rule == AlertRule.cajaMenor), isEmpty,
          reason: '700 que mezclan monedas no se comparan con el presupuesto');
    });

    test('sin ingresos: mono cita el gasto, mezcla se calla', () {
      final mono = alerts([
        txn(
            type: TransactionType.expense,
            amount: 500,
            category: 'fertilizante',
            date: DateTime(2026, 3, 1)),
      ]);
      expect(mono.any((a) => a.id == 'no_income'), isTrue);

      final mixed = alerts([
        txn(
            type: TransactionType.expense,
            amount: 500,
            category: 'fertilizante',
            date: DateTime(2026, 3, 1)),
        txn(
            type: TransactionType.expense,
            amount: 20,
            currency: 'EUR',
            category: 'transporte',
            date: DateTime(2026, 3, 2)),
      ]);
      expect(mixed.where((a) => a.id == 'no_income'), isEmpty,
          reason: 'sin ingresos no hay cifra de gastos que citar');
    });

    test('precio bajo: mono dispara, mezcla se calla', () {
      List<Transaction> sales(String c2) => [
            for (var i = 0; i < 3; i++)
              txn(
                  type: TransactionType.income,
                  amount: 1000000,
                  category: 'venta_cafe',
                  date: DateTime(2026, 1 + i, 10)),
            txn(
                type: TransactionType.income,
                amount: 400000,
                category: 'venta_cafe',
                date: DateTime(2026, 6, 1)),
            txn(
                type: TransactionType.income,
                amount: 400000,
                currency: c2,
                category: 'venta_cafe',
                date: DateTime(2026, 6, 8)),
          ];
      // Con quantity para que la regla evalúe el precio por kilo.
      List<Transaction> withQty(List<Transaction> rows) => [
            for (final t in rows)
              t.copyWith(
                  quantity: 10,
                  unit: 'kg',
                  id: '${t.id}_${t.currency}_qty'),
          ];

      expect(
        alerts(withQty(sales('COP')))
            .any((a) => a.rule == AlertRule.lowPrice),
        isTrue,
      );
      expect(
        alerts(withQty(sales('EUR'))).where((a) => a.rule == AlertRule.lowPrice),
        isEmpty,
        reason: 'el promedio de precio/kg no mezcla monedas',
      );
    });

    test('las reglas que no usan dinero siguen disparándose con mezcla', () {
      final found = alerts([
        txn(
            type: TransactionType.income,
            amount: 500000,
            category: 'venta_cafe',
            date: DateTime(2026, 5, 1)),
        txn(
            type: TransactionType.income,
            amount: 20,
            currency: 'EUR',
            category: 'venta_cafe',
            date: DateTime(2026, 5, 2)),
        txn(
            type: TransactionType.income,
            amount: 300000,
            category: 'venta_cafe',
            date: DateTime(2026, 5, 3)),
      ]);
      expect(found.any((a) => a.rule == AlertRule.missingQuantity), isTrue,
          reason: 'contar ventas sin cantidad no cruza monedas');
      expect(found.any((a) => a.rule == AlertRule.noIncome), isFalse,
          reason: 'sí hubo ventas recientes');
    });
  });

  group('PDF — cabeceras y cosechas', () {
    Future<Uint8List> build(List<Transaction> txns,
            {List<Harvest> harvests = const []}) =>
        PdfExportService().buildReport(
          settings: _settings,
          transactions: txns,
          crops: _crops,
          year: 2026,
          month: 9,
          period: ReportPeriod.month,
          periodName: 'Septiembre 2026',
          l10n: _es,
          harvests: harvests,
        );

    test('moneda única: el PDF se genera íntegro', () async {
      final bytes = await build([
        txn(type: TransactionType.income, amount: 5000),
        txn(
            type: TransactionType.expense,
            amount: 1000,
            category: 'fertilizante'),
      ]);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('mezcla: el PDF se genera íntegro', () async {
      final bytes = await build([
        txn(type: TransactionType.income, amount: 5000),
        txn(type: TransactionType.income, amount: 200, currency: 'EUR'),
        txn(
            type: TransactionType.expense,
            amount: 1000,
            category: 'mano_obra',
            harvestId: 'h_cafe'),
      ], harvests: [harvest()]);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    });
  });
}
