import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fase 2 · ninguna pantalla se queda sin puerta.
///
/// La navegación se reparte en tres sitios: la barra (Resumen, Movimientos,
/// Reportes), el FAB (Registrar) y el menú con su hub Finca. Este test barre
/// **todas** las pantallas de `lib/screens`: si alguien reordena la navegación
/// y deja una inalcanzable, aquí se entera antes que el agricultor.
void main() {
  /// Pantallas que no se abren desde otra pantalla porque son la raíz.
  const raices = <String, String>{
    'home_screen': 'raíz con sesión (AuthGate)',
    'auth_screen': 'raíz sin sesión (AuthGate)',
  };

  /// Única pantalla conservada a propósito sin puerta visible.
  ///
  /// El 2026-09-24 se ocultó «Cosechas» del menú: el pequeño agricultor
  /// produce y vende sin almacenar y no usa esa pantalla. D4 manda conservar
  /// el archivo; retirar la feature es otro PRD. La lista es explícita para
  /// que un huérfano nuevo falle el test en vez de esconderse aquí.
  const huerfanasConocidas = <String, String>{
    'harvest_screen': 'oculta del menú el 2026-09-24; conservada por D4',
  };

  String normalizar(String ruta) => ruta.replaceAll('\\', '/');

  String nombreDePantalla(File archivo) {
    final match = RegExp(r'class\s+(\w+Screen)\b')
        .firstMatch(archivo.readAsStringSync());
    expect(match, isNotNull,
        reason: '${archivo.path} debería declarar una clase ...Screen');
    return match!.group(1)!;
  }

  test('cada pantalla de lib/screens se abre desde otro archivo', () {
    final pantallas = Directory('lib/screens')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    expect(pantallas.length, greaterThanOrEqualTo(13),
        reason: 'el barrido tiene que ver todas las pantallas');

    final lib = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    for (final pantalla in pantallas) {
      final base = pantalla.uri.pathSegments.last.replaceAll('.dart', '');
      if (raices.containsKey(base) || huerfanasConocidas.containsKey(base)) {
        continue;
      }
      final clase = nombreDePantalla(pantalla);
      // No basta con mencionarla (un import también la menciona): tiene que
      // haber una instanciación real en otro archivo.
      final instanciacion = RegExp('\\b${RegExp.escape(clase)}\\s*\\(');
      final puertas = lib.where((f) =>
          normalizar(f.path) != normalizar(pantalla.path) &&
          instanciacion.hasMatch(f.readAsStringSync()));
      expect(puertas, isNotEmpty,
          reason: '$clase no se instancia desde ningún archivo de lib/: '
              'quedó sin puerta (${pantalla.path})');
    }
  });

  test('las excepciones están justificadas y siguen existiendo', () {
    for (final base in {...raices.keys, ...huerfanasConocidas.keys}) {
      expect(File('lib/screens/$base.dart').existsSync(), isTrue,
          reason: 'la excepción $base ya no corresponde a un archivo real');
    }
  });

  test('Cosechas se conserva pero sigue fuera del menú (D4)', () {
    // D4 · retirar la feature es otro PRD: la pantalla se conserva. La ruta
    // sigue oculta desde el 2026-09-24 (ver la lista de excepciones).
    expect(File('lib/screens/harvest_screen.dart').existsSync(), isTrue);

    final menu = File('lib/screens/home_screen.dart').readAsStringSync();
    expect(menu.contains("'harvests'"), isFalse,
        reason: 'el menú ya no ofrece Cosechas; si vuelve, que sea a propósito');
    expect(menu.contains('HarvestScreen'), isFalse,
        reason: 'ninguna ruta de Cosechas debe colarse sin decisión');
  });
}
