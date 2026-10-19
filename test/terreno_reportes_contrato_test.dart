import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// W1-c · contrato de los tres pintadores.
///
/// Pantalla, PDF y Excel no pueden inventarse su propia agrupación: el orden,
/// los totales y la posición de «Sin terreno» salen de una sola función
/// (`cropBreakdownLayout`). Si alguno vuelve a agrupar por su cuenta, este
/// guarda lo delata antes de que los tres digan cosas distintas.
void main() {
  test('pantalla, PDF y Excel leen la agrupación de la función única', () {
    const pintadores = [
      'lib/screens/report_screen.dart',
      'lib/services/pdf_export_service.dart',
      'lib/services/excel_export_service.dart',
    ];
    for (final path in pintadores) {
      final source = File(path).readAsStringSync();
      expect(
        source.contains('cropBreakdownLayout('),
        isTrue,
        reason: '$path debe agrupar con cropBreakdownLayout, no por su cuenta',
      );
    }
  });
}
