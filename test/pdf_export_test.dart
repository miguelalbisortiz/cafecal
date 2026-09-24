import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildReport genera un PDF válido con resumen y cultivos', () async {
    final txns = [
      Transaction(
        id: '1',
        type: TransactionType.expense,
        category: 'fertilizante',
        amount: 200000,
        cropId: 'cafe',
        date: DateTime(2026, 6, 5),
        createdAt: DateTime(2026, 6, 5),
      ),
      Transaction(
        id: '2',
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 500000,
        cropId: 'cafe',
        date: DateTime(2026, 6, 10),
        createdAt: DateTime(2026, 6, 10),
      ),
    ];

    final bytes = await PdfExportService().buildReport(
      settings: const FarmSettings(farmName: 'Finca La Esperanza'),
      transactions: txns,
      crops: _crops(),
      year: 2026,
      month: 5,
      period: ReportPeriod.month,
      periodName: 'Junio de 2026',
      l10n: stringsFor('es'),
    );

    expect(bytes, isA<Uint8List>());
    expect(bytes.length, greaterThan(1000));
    final header = String.fromCharCodes(bytes.take(5).toList());
    expect(header, '%PDF-');
  });

  test('la sección Caja menor crece el PDF (mismo dato, solo cambia el monto)',
      () async {
    final txns = [
      Transaction(
        id: '1',
        type: TransactionType.expense,
        category: 'mano_obra',
        amount: 400000,
        quantity: 8,
        unit: 'día',
        pricePerUnit: 50000,
        provider: 'Juan Pérez',
        date: DateTime(2026, 6, 5),
        createdAt: DateTime(2026, 6, 5),
      ),
      Transaction(
        id: '2',
        type: TransactionType.expense,
        category: 'energia',
        amount: 100000,
        date: DateTime(2026, 6, 10),
        createdAt: DateTime(2026, 6, 10),
      ),
    ];
    final sinCaja = await _build(settings: const FarmSettings(), txns: txns);
    final conCaja = await _build(
        settings: const FarmSettings(cajaMenorMensual: 600000),
        txns: txns);
    expect(String.fromCharCodes(conCaja.take(5)), '%PDF-');
    expect(conCaja.length, greaterThan(sinCaja.length),
        reason: 'con presupuesto configurado se dibuja la tabla mensual');
  });

  test('la sección Nómina crece el PDF (gasto con trabajador vs sin él)',
      () async {
    final sin = await _build(
      settings: const FarmSettings(),
      txns: [
        Transaction(
          id: '1',
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 500000,
          date: DateTime(2026, 6, 5),
          createdAt: DateTime(2026, 6, 5),
        ),
      ],
    );
    final con = await _build(
      settings: const FarmSettings(),
      txns: [
        Transaction(
          id: '1',
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 500000,
          quantity: 10,
          unit: 'día',
          pricePerUnit: 50000,
          provider: 'Juan Pérez',
          date: DateTime(2026, 6, 5),
          createdAt: DateTime(2026, 6, 5),
        ),
      ],
    );
    expect(String.fromCharCodes(con.take(5)), '%PDF-');
    expect(con.length, greaterThan(sin.length),
        reason: 'la tabla de nómina añade filas, total y empleados');
  });
  test('cosechas con personal y kilos generan un PDF válido', () async {
    final bytes = await _build(
      settings: const FarmSettings(cajaMenorMensual: 600000),
      txns: [
        Transaction(
          id: '1',
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 600000,
          quantity: 12,
          unit: 'día',
          pricePerUnit: 50000,
          provider: 'Juan Pérez',
          date: DateTime(2026, 6, 5),
          createdAt: DateTime(2026, 6, 5),
        ),
      ],
      harvests: [
        Harvest(
          id: 'h1',
          cropId: 'cafe',
          date: DateTime(2026, 6, 8),
          amount: 30,
          unit: 'racimo',
          workers: 3,
          equivalentKg: 420,
        ),
      ],
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });
}

List<Crop> _crops() => const [
      Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41'),
    ];

Future<Uint8List> _build({
  required FarmSettings settings,
  required List<Transaction> txns,
  List<Harvest> harvests = const [],
}) =>
    PdfExportService().buildReport(
      settings: settings,
      transactions: txns,
      crops: _crops(),
      year: 2026,
      month: 6,
      period: ReportPeriod.month,
      periodName: 'Junio de 2026',
      l10n: stringsFor('es'),
      harvests: harvests,
    );