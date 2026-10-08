import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';

import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/excel_export_service.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';

/// Exportaciones con moneda mixta: cada celda con su moneda, sin netos,
/// ROI, saldos ni totales que crucen monedas.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = ExcelExportService();
  final es = stringsFor('es');

  const crops = [
    Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41'),
  ];

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

  Transaction txn({
    required TransactionType type,
    double amount = 1000,
    String category = 'venta_cafe',
    String currency = 'COP',
    String? cropId,
    String? provider,
    DateTime? date,
  }) =>
      Transaction(
        id: 't_${type.name}_${amount}_$currency',
        type: type,
        category: category,
        amount: amount,
        currency: currency,
        cropId: cropId,
        provider: provider,
        date: date ?? DateTime(2026, 9, 5),
        createdAt: DateTime(2026, 9, 5),
      );

  Excel excelDe({
    required List<Transaction> txns,
    ReportPeriod period = ReportPeriod.month,
    int year = 2026,
    int? month = 9,
    double? caja,
  }) =>
      Excel.decodeBytes(Uint8List.fromList(service.buildReport(
        settings: FarmSettings(
            farmName: 'Finca Test', currency: 'COP', cajaMenorMensual: caja),
        transactions: txns,
        crops: crops,
        year: year,
        month: month,
        period: period,
        periodName: 'Periodo',
        l10n: es,
      )));

  group('Excel — Por cultivo', () {
    test('fila mixta: montos por moneda y sin resultado ni ROI', () {
      final rows = excelDe(txns: [
        txn(
            type: TransactionType.income,
            amount: 5000,
            cropId: 'cafe',
            date: DateTime(2026, 9, 3)),
        txn(
            type: TransactionType.income,
            amount: 200,
            currency: 'EUR',
            cropId: 'cafe',
            date: DateTime(2026, 9, 4)),
        txn(
            type: TransactionType.expense,
            amount: 1000,
            category: 'fertilizante',
            cropId: 'cafe',
            date: DateTime(2026, 9, 5)),
        txn(
            type: TransactionType.expense,
            amount: 50,
            currency: 'EUR',
            category: 'transporte',
            cropId: 'cafe',
            date: DateTime(2026, 9, 6)),
      ]).tables['Por cultivo']!.rows;

      final cafe = rows.firstWhere((r) => t0(r[0]).contains('Café'));
      expect(cv(cafe[1]), 4, reason: 'los 4 movimientos visibles');
      expect(t0(cafe[2]), contains('COP'));
      expect(t0(cafe[2]), contains('EUR'), reason: 'gastos moneda por moneda');
      expect(t0(cafe[3]), contains('COP'));
      expect(t0(cafe[3]), contains('EUR'), reason: 'ingresos moneda por moneda');
      expect(cv(cafe[4]), '—', reason: 'sin resultado que cruce monedas');
      expect(cv(cafe[5]), '—', reason: 'sin ROI que cruce monedas');
      expect(
        rows.any((r) => t0(r[0]) == es.currencyMixedByCurrencyNote(2)),
        isTrue,
        reason: 'la hoja explica por qué los montos van separados',
      );
    });

    test('fila de moneda única: números y ROI como siempre', () {
      final rows = excelDe(txns: [
        txn(
            type: TransactionType.income,
            amount: 5000,
            cropId: 'cafe',
            date: DateTime(2026, 9, 3)),
        txn(
            type: TransactionType.expense,
            amount: 2000,
            category: 'fertilizante',
            cropId: 'cafe',
            date: DateTime(2026, 9, 5)),
      ]).tables['Por cultivo']!.rows;

      final cafe = rows.firstWhere((r) => t0(r[0]).contains('Café'));
      expect(cv(cafe[2]), 2000.0, reason: 'celda numérica, sin código');
      expect(cv(cafe[3]), 5000.0);
      expect(cv(cafe[4]), 3000.0, reason: 'el resultado de siempre');
      expect(t0(cafe[5]), contains('150%'));
      expect(
        rows.any((r) => t0(r[0]) == es.currencyMixedByCurrencyNote(2)),
        isFalse,
      );
    });
  });

  group('Excel — Resumen: nómina', () {
    test('trabajador y total mixtos salen por moneda con aviso', () {
      final rows = excelDe(txns: [
        txn(
            type: TransactionType.expense,
            amount: 400000,
            category: 'mano_obra',
            provider: 'Juan',
            date: DateTime(2026, 9, 5)),
        txn(
            type: TransactionType.expense,
            amount: 100,
            currency: 'EUR',
            category: 'mano_obra',
            provider: 'Juan',
            date: DateTime(2026, 9, 6)),
      ]).tables['Resumen']!.rows;

      final juan = rows.firstWhere((r) => t0(r[0]) == 'Juan');
      expect(t0(juan[2]), contains('COP'));
      expect(t0(juan[2]), contains('EUR'));

      final total = rows.firstWhere((r) => t0(r[0]) == es.reportPayrollTotal);
      expect(t0(total[2]), contains('COP'));
      expect(t0(total[2]), contains('EUR'),
          reason: 'el total también va moneda por moneda');
      expect(
        rows.any((r) => t0(r[0]) == es.currencyMixedByCurrencyNote(2)),
        isTrue,
      );
    });

    test('moneda única: subtotales y total siguen numéricos', () {
      final rows = excelDe(txns: [
        txn(
            type: TransactionType.expense,
            amount: 400000,
            category: 'mano_obra',
            provider: 'Juan',
            date: DateTime(2026, 9, 5)),
      ]).tables['Resumen']!.rows;

      final juan = rows.firstWhere((r) => t0(r[0]) == 'Juan');
      expect(cv(juan[2]), 400000.0);
      final total = rows.firstWhere((r) => t0(r[0]) == es.reportPayrollTotal);
      expect(cv(total[2]), 400000.0);
      expect(
        rows.any((r) => t0(r[0]) == es.currencyMixedByCurrencyNote(2)),
        isFalse,
      );
    });
  });

  group('Excel — Resumen: caja menor', () {
    test('mes mixto: montos por moneda y saldo en guion', () {
      final rows = excelDe(
        caja: 800000,
        txns: [
          txn(
              type: TransactionType.expense,
              amount: 400000,
              category: 'mano_obra',
              date: DateTime(2026, 9, 5)),
          txn(
              type: TransactionType.expense,
              amount: 100,
              currency: 'EUR',
              category: 'energia',
              date: DateTime(2026, 9, 6)),
        ],
      ).tables['Resumen']!.rows;

      final sep = rows.firstWhere((r) => t0(r[0]) == es.monthFull[8]);
      expect(cv(sep[1]), 800000.0, reason: 'el presupuesto tiene su moneda');
      expect(t0(sep[2]), contains('COP'), reason: 'jornales por moneda');
      expect(t0(sep[3]), contains('EUR'), reason: 'extras por moneda');
      expect(t0(sep[4]), contains('COP'));
      expect(t0(sep[4]), contains('EUR'));
      expect(cv(sep[5]), '—',
          reason: 'sin saldo: restaría euros al presupuesto en pesos');
      expect(
        rows.any((r) => t0(r[0]) == es.currencyMixedByCurrencyNote(2)),
        isTrue,
      );
    });

    test('mes en la moneda del presupuesto: saldo como siempre', () {
      final rows = excelDe(
        caja: 800000,
        txns: [
          txn(
              type: TransactionType.expense,
              amount: 400000,
              category: 'mano_obra',
              date: DateTime(2026, 9, 5)),
          txn(
              type: TransactionType.expense,
              amount: 100000,
              category: 'energia',
              date: DateTime(2026, 9, 6)),
        ],
      ).tables['Resumen']!.rows;

      final sep = rows.firstWhere((r) => t0(r[0]) == es.monthFull[8]);
      expect(cv(sep[2]), 400000.0);
      expect(cv(sep[3]), 100000.0);
      expect(cv(sep[4]), 500000.0);
      expect(cv(sep[5]), 300000.0, reason: '800.000 − 500.000');
    });
  });

  group('Excel — serie mensual del año', () {
    test('con mezcla cada mes sale por moneda (mes × moneda)', () {
      final rows = excelDe(
        period: ReportPeriod.year,
        txns: [
          txn(
              type: TransactionType.income,
              amount: 5000,
              date: DateTime(2026, 9, 3)),
          txn(
              type: TransactionType.income,
              amount: 100,
              currency: 'EUR',
              date: DateTime(2026, 2, 5)),
        ],
      ).tables['Resumen']!.rows;

      final t = rows.indexWhere((r) => t0(r[0]) == es.excelMonthlyTitle);
      expect(t, greaterThanOrEqualTo(0), reason: 'tabla mensual presente');
      expect(t0(rows[t + 2][0]), '${es.monthFull[0]} · COP');
      expect(t0(rows[t + 3][0]), '${es.monthFull[0]} · EUR');
      expect(t0(rows[t + 4][0]), '${es.monthFull[1]} · COP');
      expect(t0(rows[t + 5][0]), '${es.monthFull[1]} · EUR',
          reason: 'febrero en euros');
      expect(cv(rows[t + 5][1]), 100.0);
      // Septiembre: la venta en COP cae en su propia fila.
      expect(t0(rows[t + 18][0]), '${es.monthFull[8]} · COP');
      expect(cv(rows[t + 18][1]), 5000.0);
      expect(cv(rows[t + 19][1]), 0.0,
          reason: 'septiembre no tiene euros que mezclar');
      // Totales: uno por moneda, nunca uno solo.
      expect(t0(rows[t + 26][0]), '${es.jornalTotalLabel} · COP');
      expect(cv(rows[t + 26][1]), 5000.0);
      expect(t0(rows[t + 27][0]), '${es.jornalTotalLabel} · EUR');
      expect(cv(rows[t + 27][1]), 100.0);
    });

    test('moneda única: 12 filas mensuales y un solo total (como siempre)',
        () {
      final rows = excelDe(
        period: ReportPeriod.year,
        txns: [
          txn(
              type: TransactionType.income,
              amount: 5000,
              date: DateTime(2026, 9, 3)),
        ],
      ).tables['Resumen']!.rows;

      final t = rows.indexWhere((r) => t0(r[0]) == es.excelMonthlyTitle);
      expect(t0(rows[t + 2][0]), es.monthFull[0]);
      expect(t0(rows[t + 13][0]), es.monthFull[11]);
      expect(t0(rows[t + 14][0]), es.jornalTotalLabel,
          reason: 'una sola fila Total, sin moneda adjunta');
      expect(cv(rows[t + 14][1]), 5000.0);
    });
  });

  group('PDF', () {
    test('con moneda mixta el reporte se genera sin errores', () async {
      final bytes = await PdfExportService().buildReport(
        settings: const FarmSettings(farmName: 'Finca Test', currency: 'COP'),
        transactions: [
          txn(
              type: TransactionType.income,
              amount: 5000,
              cropId: 'cafe',
              date: DateTime(2026, 9, 3)),
          txn(
              type: TransactionType.income,
              amount: 200,
              currency: 'EUR',
              cropId: 'cafe',
              date: DateTime(2026, 9, 4)),
          txn(
              type: TransactionType.expense,
              amount: 1000,
              currency: 'EUR',
              category: 'mano_obra',
              provider: 'Juan',
              date: DateTime(2026, 9, 5)),
        ],
        crops: crops,
        year: 2026,
        month: 9,
        period: ReportPeriod.month,
        periodName: 'Septiembre 2026',
        l10n: es,
      );

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    });
  });
}
