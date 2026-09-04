import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart';

void main() {
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
      monthName: 'Junio',
    );

    expect(bytes, isA<Uint8List>());
    expect(bytes.length, greaterThan(1000));
    final header = String.fromCharCodes(bytes.take(5).toList());
    expect(header, '%PDF-');
  });
}

List<Crop> _crops() => const [
      Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41'),
    ];