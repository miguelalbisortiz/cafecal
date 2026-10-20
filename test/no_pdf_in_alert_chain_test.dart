import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **T4 — el arranque no arrastra el motor de PDF.**
///
/// `package:pdf` entraba al grafo inicial por las **alertas**:
/// `main.dart` → `alert_provider.dart` → `alert_service.dart` →
/// `report_payroll_metrics.dart` → `pdf_export_service.dart`, y ese último
/// import existía solo para usar `enum ReportPeriod`.
///
/// Esta guarda recorre el grafo de imports desde `alert_service.dart` y falla
/// si en algún punto aparece `package:pdf` (o `package:excel`). Es el rojo de la
/// tanda: con el enum dentro del servicio de PDF, el camino existe y se ve.
///
/// No lee el compilador: lee los mismos archivos que va a leer dart2js.
void main() {
  test('las alertas no alcanzan package:pdf ni package:excel', () {
    final lib = Directory('lib').absolute.uri; // file:///…/lib/
    final start = lib.resolve('services/alert_service.dart');

    final queue = <Uri>[start];
    final visited = <String>{};
    final offenders = <({String uri, Uri file})>[];

    final directive =
        RegExp(r'''(?:import|export|part)\s+['"]([^'"]+)['"]''');

    while (queue.isNotEmpty) {
      final file = queue.removeLast();
      final path = file.toFilePath();
      if (!visited.add(path)) continue;
      if (!File(path).existsSync()) continue;

      for (final match in directive.allMatches(File(path).readAsStringSync())) {
        final uri = match.group(1)!;
        if (uri.startsWith('dart:')) continue;

        if (uri.startsWith('package:')) {
          if (uri.startsWith('package:mi_cafetal/')) {
            queue.add(lib.resolve(uri.substring('package:mi_cafetal/'.length)));
          } else if (uri.startsWith('package:pdf') ||
              uri.startsWith('package:excel')) {
            offenders.add((uri: uri, file: file));
          }
          continue;
        }

        queue.add(file.resolve(uri));
      }
    }

    final rounded = offenders
        .map((o) => '${o.uri}  ←  ${o.file.toFilePath()}')
        .toSet()
        .toList();

    expect(
      rounded,
      isEmpty,
      reason: 'El arranque de las alertas vuelve a arrastrar el motor de PDF. '
          'Estos imports externos quedaron alcanzables desde '
          '`lib/services/alert_service.dart`:\n  ${rounded.join('\n  ')}',
    );
  });
}
