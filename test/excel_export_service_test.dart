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
      // Balance is now a DoubleCellValue in column[2]
      expect(cv(resultRow[2]), 3000.0);
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

    test('movements excluye borrados y monto negativo para gasto', () async {
      final rows = excel.tables['Movimientos']!.rows;
      // 1 header + 2 datos visibles
      expect(rows.length, 3);

      final expRow = rows.firstWhere(
          (r) => (cv(r[1])?.toString() ?? '') == 'Gasto');
      expect(cv(expRow[0]).toString(), contains('2026-09'));
      // Column shifted: date(0) type(1) cat(2) desc(3) crop(4) currency(5) amount(6)
      expect(cv(expRow[6]), -2000.0);

      final incRow = rows.firstWhere(
          (r) => (cv(r[1])?.toString() ?? '') == 'Ingreso');
      expect(cv(incRow[6]), 5000.0);
    });
  });

  group('Resumen — secciones Nómina y Caja menor', () {
    // Jornales de septiembre: Juan 8 días, María 6 días a $50.000/día.
    // Extras: energía $100.000. Fertilizante NO descuenta de caja.
    final laborTxns = [
      Transaction(
        id: 'j1',
        type: TransactionType.expense,
        category: 'mano_obra',
        amount: 400000,
        quantity: 8,
        unit: 'día',
        pricePerUnit: 50000,
        provider: 'Juan',
        date: DateTime(2026, 9, 5),
        createdAt: DateTime(2026, 9, 5),
      ),
      Transaction(
        id: 'j2',
        type: TransactionType.expense,
        category: 'mano_obra',
        amount: 300000,
        quantity: 6,
        unit: 'día',
        pricePerUnit: 50000,
        provider: 'María',
        date: DateTime(2026, 9, 10),
        createdAt: DateTime(2026, 9, 10),
      ),
      Transaction(
        id: 'e1',
        type: TransactionType.expense,
        category: 'energia',
        amount: 100000,
        date: DateTime(2026, 9, 12),
        createdAt: DateTime(2026, 9, 12),
      ),
      Transaction(
        id: 'f1',
        type: TransactionType.expense,
        category: 'fertilizante',
        amount: 500000,
        date: DateTime(2026, 9, 15),
        createdAt: DateTime(2026, 9, 15),
      ),
    ];

    List<List<Data?>> rowsWith({double? caja}) {
      final bytes = Uint8List.fromList(service.buildReport(
        settings: FarmSettings(
            farmName: 'Finca Test', currency: 'COP', cajaMenorMensual: caja),
        transactions: laborTxns,
        crops: _crops,
        year: 2026,
        month: 9,
        period: ReportPeriod.month,
        periodName: 'Septiembre 2026',
        l10n: _es,
      ));
      return Excel.decodeBytes(bytes).tables['Resumen']!.rows;
    }

    test('nómina: trabajadores, días, subtotal, total y empleados distintos',
        () {
      final rows = rowsWith(caja: 800000);
      bool has(String s) => rows.any((r) => r.any(
          (c) => (cv(c)?.toString() ?? '').contains(s)));

      expect(has('Nómina del período'), isTrue);
      expect(has('Trabajador'), isTrue);
      expect(has('Empleados distintos: 2'), isTrue);

      final juan = rows.firstWhere(
          (r) => (cv(r[0])?.toString() ?? '') == 'Juan');
      expect(cv(juan[1]), 8.0, reason: 'días');
      expect(cv(juan[2]), 400000.0, reason: 'subtotal');
      final maria = rows.firstWhere(
          (r) => (cv(r[0])?.toString() ?? '') == 'María');
      expect(cv(maria[1]), 6.0);
      expect(cv(maria[2]), 300000.0);

      final total = rows.firstWhere(
          (r) => (cv(r[0])?.toString() ?? '') == 'Total nómina');
      expect(cv(total[2]), 700000.0);
    });

    test('caja: fila del mes con presupuesto, jornales, extras y saldo', () {
      final rows = rowsWith(caja: 800000);
      bool has(String s) => rows.any((r) => r.any(
          (c) => (cv(c)?.toString() ?? '').contains(s)));

      expect(has('Caja menor'), isTrue);
      expect(has('Presupuesto'), isTrue);
      expect(has('Saldo'), isTrue);

      final sep = rows.firstWhere(
          (r) => (cv(r[0])?.toString() ?? '') == 'Septiembre');
      expect(cv(sep[1]), 800000.0, reason: 'presupuesto');
      expect(cv(sep[2]), 700000.0, reason: 'jornales');
      expect(cv(sep[3]), 100000.0, reason: 'extras (energía)');
      expect(cv(sep[4]), 800000.0, reason: 'total = jornales + extras');
      expect(cv(sep[5]), 0.0,
          reason: 'saldo; el fertilizante no descuenta');
    });

    test('sin presupuesto no se dibuja la sección de caja', () {
      final rows = rowsWith(caja: null);
      expect(
          rows.any((r) => r.any(
              (c) => (cv(c)?.toString() ?? '').contains('Caja menor'))),
          isFalse);
    });

    test('sin gastos de mano de obra no se dibuja la sección de nómina', () {
      final bytes = Uint8List.fromList(service.buildReport(
        settings: const FarmSettings(
            farmName: 'Finca Test', currency: 'COP', cajaMenorMensual: 800000),
        transactions: [
          Transaction(
            id: 'e1',
            type: TransactionType.expense,
            category: 'energia',
            amount: 100000,
            date: DateTime(2026, 9, 12),
            createdAt: DateTime(2026, 9, 12),
          ),
        ],
        crops: _crops,
        year: 2026,
        month: 9,
        period: ReportPeriod.month,
        periodName: 'Septiembre 2026',
        l10n: _es,
      ));
      final rows = Excel.decodeBytes(bytes).tables['Resumen']!.rows;
      expect(
          rows.any((r) => r.any(
              (c) => (cv(c)?.toString() ?? '').contains('Nómina del período'))),
          isFalse);
      // La caja sí se muestra (presupuesto configurado, mes con extras).
      expect(
          rows.any((r) => r.any(
              (c) => (cv(c)?.toString() ?? '').contains('Caja menor'))),
          isTrue);
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

    test('farmName malicioso (=) se neutraliza y las fórmulas internas siguen',
        () {
      final bytes = service.buildBalanceTemplate(
        settings: const FarmSettings(
            farmName: '=HYPERLINK("http://evil.com")', currency: 'COP'),
        transactions: const [],
        year: 2026,
        periodName: 'Septiembre 2026',
        l10n: _es,
      );
      final csv = utf8.decode(bytes);
      // La celda que arranca con el nombre queda con comilla simple.
      expect(csv, contains("'=HYPERLINK("));
      // Ninguna celda arranca con un '=' desnudo.
      expect(RegExp(r'(^|;)=HYPERLINK').hasMatch(csv), isFalse);
      // Las fórmulas internas del template siguen funcionales.
      expect(csv, contains('=SUM(B5:B10)'));
      expect(csv, contains('=B11-B17-B23'));
    });

    test('farmName con prefijos + y @ también se neutraliza', () {
      for (final evil in ['+cmd|whoami', '@SUM(1)']) {
        final bytes = service.buildBalanceTemplate(
          settings: FarmSettings(farmName: evil, currency: 'COP'),
          transactions: const [],
          year: 2026,
          periodName: 'Septiembre 2026',
          l10n: _es,
        );
        final csv = utf8.decode(bytes);
        expect(csv, contains("'$evil"));
      }
    });

    test('guion seguido de letra se neutraliza; un número negativo no', () {
      final evilBytes = service.buildBalanceTemplate(
        settings: const FarmSettings(farmName: '-cmd /e', currency: 'COP'),
        transactions: const [],
        year: 2026,
        periodName: 'Septiembre 2026',
        l10n: _es,
      );
      expect(utf8.decode(evilBytes), contains("'-cmd"));

      final negBytes = service.buildBalanceTemplate(
        settings: _settings,
        transactions: [
          _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 9, 3)),
          _txn(type: TransactionType.expense, amount: 2000, date: DateTime(2026, 9, 5)),
        ],
        year: 2026,
        periodName: 'Septiembre 2026',
        l10n: _es,
      );
      final csv = utf8.decode(negBytes);
      expect(csv, contains('-1000,00'));
      expect(csv.contains("'-1000,00"), isFalse);
    });
  });
}
