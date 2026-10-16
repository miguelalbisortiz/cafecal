import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/excel_export_service.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart' show ReportPeriod;

/// hueco 1 de la revisión: el Excel evaluaba las alertas sobre `periodTx`,
/// solo el mes exportado. Una venta barata de enero se quedaba fuera del
/// informe de junio y "Qué hacer" decía «Sin recomendaciones» con el banner
/// de Inicio encendido.
///
/// El escenario es mínimo a propósito: **una sola venta, en enero**, y el
/// período exportado es junio. Si el motor vuelve a recortarse al período,
/// esta prueba se cae.
AppLocalizations get _es => stringsFor('es');

dynamic cv(Data? cell) {
  final v = cell?.value;
  if (v == null) return null;
  if (v is IntCellValue) return v.value;
  if (v is DoubleCellValue) return v.value;
  if (v is TextCellValue) return v.value.text;
  return null;
}

/// Todas las cadenas escritas en una hoja.
List<String> _textos(Excel libro, String hoja) {
  final tabla = libro.tables[hoja];
  if (tabla == null) return const [];
  return [
    for (final fila in tabla.rows)
      for (final celda in fila)
        if (cv(celda) != null) cv(celda).toString(),
  ];
}

void main() {
  final servicio = ExcelExportService();

  final ventaDeEnero = [
    Transaction(
      id: 'venta_enero',
      type: TransactionType.income,
      category: 'venta',
      amount: 50000,
      quantity: 1,
      unit: 'kg',
      date: DateTime(2026, 1, 10),
      createdAt: DateTime(2026, 1, 10),
    ),
  ];

  // Con cosecha en junio para que la hoja llegue hasta "Qué hacer".
  final cosechasDeJunio = [
    Harvest(
      id: 'h1',
      cropId: 'cafe',
      date: DateTime(2026, 6, 5),
      amount: 100,
      unit: 'kg',
    ),
  ];

  Excel exportar(FarmSettings settings) => Excel.decodeBytes(
        Uint8List.fromList(servicio.buildReport(
          settings: settings,
          transactions: ventaDeEnero,
          crops: const [Crop(id: 'cafe', name: 'Café')],
          year: 2026,
          month: 6,
          period: ReportPeriod.month,
          periodName: 'Junio 2026',
          l10n: _es,
          harvests: cosechasDeJunio,
        )),
      );

  test('la venta de enero llega al informe de junio', () {
    final libro = exportar(const FarmSettings(lowPriceThresholdPerKg: 80000));

    expect(_textos(libro, 'Cosechas').any((t) => t.contains(_es.alertLowPriceManualTitle)),
        isTrue,
        reason: 'el motor tiene que ver el histórico completo, no el mes');
  });

  test('sin el precio mínimo en Ajustes no sale ese aviso', () {
    // Misma venta, mismo informe: lo único que cambia es el ajuste que él
    // puso o no puso. Sin él la regla no se dispara y no se inventa nada.
    final libro = exportar(const FarmSettings());

    expect(_textos(libro, 'Cosechas').any((t) => t.contains(_es.alertLowPriceManualTitle)),
        isFalse);
  });

  test('el informe de junio no cuelga del mes exportado', () {
    final libro = exportar(const FarmSettings(lowPriceThresholdPerKg: 80000));
    final textos = _textos(libro, 'Cosechas');

    expect(textos.contains(_es.reportNoRecommendations), isFalse,
        reason: 'con una venta barata en el histórico nunca puede decir que '
            'no hay nada que hacer');
  });
}
