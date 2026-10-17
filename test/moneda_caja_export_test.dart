// Caja menor con UNA sola moneda ajena al presupuesto.
//
// Los dos tests que ya existían en `mixed_currency_export_test.dart` cubrían:
// (1) mes con DOS monedas → `isMixed` true → guion, y (2) mes todo en la
// moneda del presupuesto → saldo. Faltaba el medio: un mes cuyo ÚNICO gasto
// de caja está en otra moneda. Ahí `isMixed` es false, así que PDF y Excel
// pintaban saldo… restando euros a pesos: 800.000 − 100 = 799.900, que no es
// ninguna cifra real. La pantalla NO lo hacía: `report_screen` exigía además
// `currencies.first == budgetCurrency`.
//
// Los tres pintadores pasan ahora por `comparableToBudget`, que es la única
// casa donde se decide esto.
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/currency_totals.dart';
import 'package:mi_cafetal/services/excel_export_service.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = ExcelExportService();
  final es = stringsFor('es');

  const crops = [
    Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41'),
  ];

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
    DateTime? date,
  }) =>
      Transaction(
        id: 't_${type.name}_${amount}_$currency',
        type: type,
        category: category,
        amount: amount,
        currency: currency,
        date: date ?? DateTime(2026, 9, 5),
        createdAt: DateTime(2026, 9, 5),
      );

  Excel excelDe({
    required List<Transaction> txns,
    double? caja,
  }) =>
      Excel.decodeBytes(Uint8List.fromList(service.buildReport(
        settings: FarmSettings(
            farmName: 'Finca Test', currency: 'COP', cajaMenorMensual: caja),
        transactions: txns,
        crops: crops,
        year: 2026,
        month: 9,
        period: ReportPeriod.month,
        periodName: 'Periodo',
        l10n: es,
      )));

  /// La fila de septiembre de la hoja Resumen, tal como la pinta el Excel.
  List<Data?> septiembre({required List<Transaction> txns, double? caja}) =>
      excelDe(txns: txns, caja: caja)
          .tables['Resumen']!
          .rows
          .firstWhere((r) => t0(r[0]) == es.monthFull[8]);

  final soloEuros = [
    txn(
        type: TransactionType.expense,
        amount: 100,
        currency: 'EUR',
        category: 'energia',
        date: DateTime(2026, 9, 6)),
  ];

  group('caja · mes cuyo único gasto está en euros', () {
    test('el Excel no inventa saldo', () {
      final sep = septiembre(txns: soloEuros, caja: 800000);

      expect(cv(sep[1]), 800000, reason: 'el presupuesto sí está en pesos');
      expect(cv(sep[5]), '—',
          reason: 'presupuesto en pesos y gasto solo en euros: restarlos daría '
              '800.000 − 100 = 799.900, que no es ninguna cifra real. La '
              'pantalla ya se calla en este caso; el exportador debe hacer lo '
              'mismo.');
    });

    test('y el gasto sale con su propia moneda y su código', () {
      final sep = septiembre(txns: soloEuros, caja: 800000);

      // Sin la regla, esta celda se pintaba como si 100 euros fueran 100
      // pesos: mismo número, moneda ajena.
      expect(t0(sep[3]), contains('100'), reason: 'la cantidad sigue siendo 100');
      expect(t0(sep[3]), contains('EUR'),
          reason: 'pero hay que decir en qué moneda, no pasarla por pesos');
      expect(t0(sep[3]), isNot(contains(r'$')),
          reason: 'y no con el símbolo del presupuesto');
    });
  });

  group('comparableToBudget · la regla misma', () {
    test('mes vacío compara: no gastó, el saldo es el presupuesto entero', () {
      expect(comparableToBudget(const {}, 'COP'), isTrue);
    });

    test('una moneda igual a la del presupuesto compara', () {
      expect(comparableToBudget(const {'COP'}, 'COP'), isTrue);
    });

    test('una sola moneda ajena NO compara', () {
      // Este es el caso que faltaba: `isMixed` era false porque había una
      // sola moneda, y aun así restarla al presupuesto es mentira.
      expect(comparableToBudget(const {'EUR'}, 'COP'), isFalse);
    });

    test('dos monedas no comparan', () {
      expect(comparableToBudget(const {'COP', 'USD'}, 'COP'), isFalse);
    });

    test('dos monedas ninguna de ellas del presupuesto tampoco', () {
      expect(comparableToBudget(const {'USD', 'EUR'}, 'COP'), isFalse);
    });
  });
}
