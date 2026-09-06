import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/excel_export_service.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart' show ReportPeriod;

AppLocalizations get _es => stringsFor('es');

FarmSettings get _settings =>
    const FarmSettings(farmName: 'Finca Test', currency: 'COP');

List<Crop> get _crops => const [
      Crop(id: 'cafe', name: 'Café'),
      Crop(id: 'platano', name: 'Plátano'),
    ];

Transaction _txn({
  required TransactionType type,
  required double amount,
  required DateTime date,
  String category = 'venta',
  String? cropId,
  bool deleted = false,
}) =>
    Transaction(
      id: 't_${type.name}_$amount',
      type: type,
      category: category,
      amount: amount,
      date: date,
      createdAt: DateTime(2026, 1, 1),
      cropId: cropId,
      deleted: deleted,
    );

void main() {
  final service = ExcelExportService();

  // Extrae el valor nativo de una celda Excel.
  dynamic cv(Data? cell) {
    final v = cell?.value;
    if (v == null) return null;
    if (v is IntCellValue) return v.value;
    if (v is DoubleCellValue) return v.value;
    if (v is TextCellValue) return v.value.text;
    return null;
  }

  group('buildReport', () {
    final txns = [
      _txn(
          type: TransactionType.income,
          amount: 5000,
          date: DateTime(2026, 9, 3),
          cropId: 'cafe'),
      _txn(
          type: TransactionType.expense,
          amount: 2000,
          date: DateTime(2026, 9, 5),
          cropId: 'cafe'),
      // borrada → no debe aparecer
      _txn(
          type: TransactionType.expense,
          amount: 1000,
          date: DateTime(2026, 9, 10),
          deleted: true),
    ];

    late Excel excel;
    setUp(() {
      final bytes = Uint8List.fromList(service.buildReport(
        settings: _settings,
        transactions: txns,
        crops: _crops,
        year: 2026,
        month: 9,
        period: ReportPeriod.month,
        periodName: 'Septiembre 2026',
        l10n: _es,
      ));
      excel = Excel.decodeBytes(bytes);
    });

    test('produce 3 hojas', () {
      expect(excel.tables.keys,
          containsAll(['Resumen', 'Por cultivo', 'Movimientos']));
    });

    test('resumen contiene balance correcto (5000−2000 = 3000)', () {
      final rows = excel.tables['Resumen']!.rows;
      final resultRow = rows.firstWhere(
          (r) => (cv(r[0])?.toString() ?? '').contains('RESULTADO'));
      expect(cv(resultRow[1]).toString(), contains('\$3000'));
    });

    test('crops sheet tiene ROI correcto y excluye borrados', () {
      final rows = excel.tables['Por cultivo']!.rows;
      final cafeRow = rows.firstWhere(
          (r) => (cv(r[0])?.toString() ?? '').contains('Café'));
      // 2 movimientos visibles
      expect(cv(cafeRow[1]), 2);
      // ROI (5000−2000)/2000 = 150%
      expect(cv(cafeRow[5]).toString(), contains('150%'));
      // Plátano sin datos → sin fila
      expect(
          rows.any((r) =>
              (cv(r[0])?.toString() ?? '').contains('Plátano')),
          isFalse);
    });

    test('movements excluye borrados y monto negativo para gasto', () {
      final rows = excel.tables['Movimientos']!.rows;
      // 1 header + 2 datos visibles
      expect(rows.length, 3);

      final expRow = rows.firstWhere(
          (r) => (cv(r[1])?.toString() ?? '') == 'Gasto');
      expect(cv(expRow[0]).toString(), contains('2026-09'));
      expect(cv(expRow[5]), -2000.0);

      final incRow = rows.firstWhere(
          (r) => (cv(r[1])?.toString() ?? '') == 'Ingreso');
      expect(cv(incRow[5]), 5000.0);
    });
  });

  group('buildBalanceTemplate', () {
    test('utilidad positiva contiene fórmulas y separador decimal coma', () {
      final bytes = service.buildBalanceTemplate(
        settings: _settings,
        transactions: [
          _txn(
              type: TransactionType.income,
              amount: 5000,
              date: DateTime(2026, 9, 3)),
          _txn(
              type: TransactionType.expense,
              amount: 2000,
              date: DateTime(2026, 9, 5)),
        ],
        year: 2026,
        periodName: 'Septiembre 2026',
        l10n: _es,
      );
      final csv = utf8.decode(bytes);
      // utf8.decode omite BOM U+FEFF; solo verificamos integridad del contenido
      expect(csv, contains('=SUM(B5:B10)'));
      expect(csv, contains('=B11-B17-B23'));
      expect(csv, contains('3000,00'));
      expect(csv, contains('Finca Test'));
      expect(csv, contains('VERIFICACIÓN'));
    });

    test('utilidad negativa muestra signo menos', () {
      final bytes = service.buildBalanceTemplate(
        settings: _settings,
        transactions: [
          _txn(
              type: TransactionType.income,
              amount: 1000,
              date: DateTime(2026, 9, 3)),
          _txn(
              type: TransactionType.expense,
              amount: 2000,
              date: DateTime(2026, 9, 5)),
        ],
        year: 2026,
        periodName: 'Septiembre 2026',
        l10n: _es,
      );
      final csv = utf8.decode(bytes);
      expect(csv, contains('-1000,00'));
    });

    test('sin datos muestra 0,00', () {
      final bytes = service.buildBalanceTemplate(
        settings: _settings,
        transactions: const [],
        year: 2026,
        periodName: 'Septiembre 2026',
        l10n: _es,
      );
      final csv = utf8.decode(bytes);
      expect(csv, contains('0,00'));
    });
  });
}
