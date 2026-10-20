import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **T7 — la exportación viaja aparte.**
///
/// Desde `lib/main.dart` no se puede alcanzar `package:pdf` ni `package:excel`
/// por un import normal: los dos servicios entran solo con `deferred as`.
/// Si alguien vuelve a importarlos de frente (aunque sea desde una pantalla),
/// el trozo desaparece y el arranque paga otra vez los ~1,1 MB.
///
/// Complementa a `no_pdf_in_alert_chain_test.dart`: aquel dice «las alertas no
/// lo arrastran»; este dice «nada del arranque lo arrastra».
void main() {
  test('desde main solo se llega a pdf y excel por imports diferidos', () {
    final lib = Directory('lib').absolute.uri;
    final start = lib.resolve('main.dart');

    final queue = <Uri>[start];
    final visited = <String>{};
    final direct = <({String file, String uri})>[];
    final deferred = <String>{};

    // Import con o sin la marca `deferred`.
    final import =
        RegExp(r'''import\s+['"]([^'"]+)['"](\s+deferred)?''');
    final partOrExport = RegExp(r'''(?:part|export)\s+['"]([^'"]+)['"]''');

    void walk(Uri file) {
      final path = file.toFilePath();
      if (!visited.add(path)) return;
      if (!File(path).existsSync()) return;
      final text = File(path).readAsStringSync();

      for (final m in import.allMatches(text)) {
        final uri = m.group(1)!;
        final isDeferred = m.group(2) != null;
        if (isDeferred) deferred.add(uri);
        if (uri.startsWith('dart:')) continue;

        if (uri.startsWith('package:')) {
          if (!uri.startsWith('package:mi_cafetal/')) {
            if (uri.startsWith('package:pdf') ||
                uri.startsWith('package:excel')) {
              direct.add((file: path, uri: uri));
            }
            continue;
          }
          if (isDeferred) continue;
          queue.add(lib.resolve(uri.substring('package:mi_cafetal/'.length)));
          continue;
        }

        if (isDeferred) continue;
        queue.add(file.resolve(uri));
      }

      // `export` y `part` no se difieren: si aparecen, son camino directo.
      for (final m in partOrExport.allMatches(text)) {
        final uri = m.group(1)!;
        if (uri.startsWith('package:')) continue;
        queue.add(file.resolve(uri));
      }
    }

    while (queue.isNotEmpty) {
      walk(queue.removeLast());
    }

    expect(
      direct.map((d) => '${d.uri} ← ${d.file}').toList(),
      isEmpty,
      reason: 'Algo del arranque importa el motor de exportación sin diferir.',
    );

    // Si los `deferred` desaparecen (p. ej. alguien borra la exportación),
    // el test anterior pasaría por vacío. Estos dos lo impiden.
    expect(
      deferred.where((u) => u.endsWith('pdf_export_service.dart')).length,
      1,
      reason: 'falta el import diferido del PDF',
    );
    expect(
      deferred.where((u) => u.endsWith('excel_export_service.dart')).length,
      1,
      reason: 'falta el import diferido del Excel',
    );
  });
}
