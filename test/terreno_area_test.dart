import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/terreno.dart';
import 'package:mi_cafetal/services/terreno_area.dart';

/// T10 · las áreas avisan, nunca bloquean.
///
/// El productor puede tener dos cultivos en el mismo lote y anotar áreas que
/// se pasen del total: la app lo dice en ámbar, pero lo deja guardar. Un
/// terreno sin área medida no compara nada (no hay contra qué).
void main() {
  const terreno = Terreno(id: 't1', name: 'Lote Alto', areaHa: 8);

  Crop crop(String id, {String? terrenoId = 't1', double? areaHa}) => Crop(
        id: id,
        name: id,
        terrenoId: terrenoId,
        areaHa: areaHa,
      );

  test('suma las áreas de los cultivos del terreno', () {
    final share = terrenoAreaShare(terreno, [
      crop('a', areaHa: 3),
      crop('b', areaHa: 2),
      crop('c', terrenoId: null, areaHa: 10),
    ]);
    expect(share.assigned, 5);
    expect(share.over, isFalse);
    expect(share.withoutArea, 0);
  });

  test('avisa cuando las áreas se pasan del total', () {
    final share = terrenoAreaShare(terreno, [
      crop('a', areaHa: 7),
      crop('b', areaHa: 5),
    ]);
    expect(share.assigned, 12);
    expect(share.over, isTrue,
        reason: '12 ha en un lote de 8: se avisa, no se bloquea');
  });

  test('cuenta los cultivos sin área', () {
    final share = terrenoAreaShare(terreno, [
      crop('a', areaHa: 3),
      crop('b'),
    ]);
    expect(share.assigned, 3);
    expect(share.withoutArea, 1);
    expect(share.over, isFalse);
  });

  test('un terreno sin área medida no compara', () {
    const sinArea = Terreno(id: 't2', name: 'Sin medir');
    final share = terrenoAreaShare(sinArea, [
      crop('a', terrenoId: 't2', areaHa: 40),
    ]);
    expect(share.assigned, 40);
    expect(share.over, isFalse,
        reason: 'sin total del terreno no hay exceso que declarar');
  });
}
