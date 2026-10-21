import '../models/crop.dart';
import '../models/terreno.dart';

/// Cómo se reparten las áreas de un terreno entre sus cultivos.
///
/// [assigned] suma solo las áreas anotadas; [withoutArea] cuenta los cultivos
/// del terreno que todavía no tienen área. [over] es `true` solo cuando el
/// terreno tiene área medida **y** lo asignado se pasa: sin área del terreno no
/// hay contra qué comparar, y no se inventa un límite.
typedef TerrenoAreaShare = ({double assigned, bool over, int withoutArea});

TerrenoAreaShare terrenoAreaShare(Terreno terreno, Iterable<Crop> crops) {
  var assigned = 0.0;
  var withoutArea = 0;
  for (final c in crops) {
    if (c.terrenoId != terreno.id) continue;
    final area = c.areaHa;
    if (area == null || area <= 0) {
      withoutArea++;
    } else {
      assigned += area;
    }
  }
  final total = terreno.areaHa;
  final over = total != null && total > 0 && assigned > total;
  return (assigned: assigned, over: over, withoutArea: withoutArea);
}
