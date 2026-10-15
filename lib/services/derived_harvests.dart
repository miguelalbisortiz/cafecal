import '../models/categories.dart';
import '../models/harvest.dart';
import '../models/transaction.dart';

/// **Cosecha derivada de la venta** — sin un paso nuevo para el agricultor.
///
/// ## Por qué existe
///
/// La pantalla de Cosechas se ocultó del menú el 2026-09-24 porque «el
/// pequeño agricultor produce y vende sin almacenar». Lo que no se
/// desconectó fueron las cinco cosas que seguían dependiendo de ella:
///
/// 1. la alerta «primera cosecha atrasada» se volvió **una trampa sin
///    salida**: decía *«registrá esa cosecha y este aviso desaparece»* y no
///    había dónde, ni siquiera descartable;
/// 2. los cultivos **nunca salían de `establecimiento`** — la promoción de
///    fase solo corría dentro de `addHarvest`, al que nadie entra —, así que
///    el déficit se reportaba `info` en vez de `danger`;
/// 3. el reporte se quedaba **sin rendimiento ni costo por kilo**;
/// 4. la regla «vendido > cosechado» no tenía con qué comparar;
/// 5. la Ayuda enseñaba un paso que no tenía puerta.
///
/// La solución no es devolver el paso que se quitó: es **deducir lo cosechado
/// de la venta que él ya anotó**. No se le pide nada nuevo y no se inventa
/// ningún número — los kilos son los que escribió en la venta, que es lo que
/// la regla de dominio ya asume: *todo lo que se cosecha se vende*.
///
/// ## Regla — D2, conservadora a propósito
///
/// De cada **venta no borrada** que traiga **cultivo**, **kilos** y
/// **unidad**, y cuyo cultivo **no tenga ninguna cosecha guardada a mano**,
/// sale una cosecha.
///
/// Quien ya lleva cosechas a mano, **esas mandan**: la app no agrega otras
/// encima. Cuesta rendimiento en un cultivo mixto (cosecha manual de 2024 +
/// ventas de 2026), pero prefiere no medir antes que doble-contar. Esa es la
/// regla de oro: *nunca inventar cifras*.
///
/// ## Se calcula al leer — no se guarda (D1)
///
/// No hay fila que subir, que borrar ni que revivir. `mergeRemoteHarvests`
/// re-agrega lo remoto que falte localmente, así que una cosecha persistida y
/// luego borrada **volvería como zombi**. Al ser derivada, si el agricultor
/// corrige o borra la venta, el dato se arregla solo en la siguiente lectura.
///
/// ## La puerta para la Tanda 2 (D4)
///
/// Hoy la única fuente es la venta. Si se aprueba el campo «kilos
/// recolectados» en un jornal de labor «Cosechar», esa fuente entra **por
/// encima** de la venta — porque sí es independiente de ella, y es la única
/// forma de saber lo que se quedó en el campo —, y es **un `if` más** en esta
/// función, no un rediseño. Orden de prioridad:
///
/// 1. `manual`  — lo anotó a mano. Manda siempre.
/// 2. `jornal`  — [Tanda 2] kilos recolectados. Todavía no existe.
/// 3. `venta`   — lo de la venta. Es lo único que hay hoy.
///
/// Por eso la identidad de lo derivado lleva la **fuente** en el prefijo y no
/// un «es derivado» genérico: [isSaleDerivedHarvest] seguirá respondiendo
/// `false` a una cosecha derivada del jornal, que es justamente lo que la
/// tarjeta «vendido vs cosechado» necesita para saber que sí hay una medida
/// independiente (D5).

/// Prefijo de las cosechas derivadas **de la venta**.
///
/// Los id sintéticos empiezan por esto; los guardados son uuid. El prefijo
/// lleva la fuente a propósito — ver el bloque D4 arriba.
const String kSaleDerivedPrefix = 'der_venta_';

/// ¿Esta cosecha salió de la venta?
///
/// Si es así, sus kilos **no son una medida independiente**: son los de la
/// venta. Compararlos contra la venta sería comparar un número consigo mismo.
///
/// Una cosecha derivada del jornal (Tanda 2) llevará otro prefijo y devolverá
/// `false` — que es exactamente lo que debe pasar.
bool isSaleDerivedHarvest(Harvest harvest) =>
    harvest.id.startsWith(kSaleDerivedPrefix);

/// ¿Hay alguna cosecha medida **por fuera** de la venta?
///
/// Es la condición de D5 para mostrar la tarjeta «vendido vs cosechado»: sin
/// una segunda medida, esa comparación no es un hallazgo, es una tautología.
bool hasIndependentHarvest(Iterable<Harvest> harvests) =>
    harvests.any((h) => !isSaleDerivedHarvest(h));

/// Las cosechas que salen de las ventas, según la regla de arriba.
///
/// **Pura**: no lee almacenamiento, no notifica, no escribe nada. Devuelve
/// una lista nueva y **no toca** las que recibe — por eso es testeable sola
/// y por eso el llamador decide dónde concatenarlas.
///
/// [transactions] y [manualHarvests] deben llegar **sin filtrar**: los
/// filtros (`deleted`, tipo, categoría) son de esta función, para que la
/// regla viva en un solo lugar y no se le escape un caso al llamador.
List<Harvest> deriveHarvests({
  required List<Transaction> transactions,
  required List<Harvest> manualHarvests,
}) {
  // Cultivos que ya tienen cosecha guardada a mano: para ellos no se deriva
  // nada (D2). Solo los que traen cultivo: una cosecha suelta no atribuible
  // no debería frenar a nadie.
  final manualCrops = <String>{
    for (final h in manualHarvests)
      if (h.cropId != null) h.cropId!,
  };

  // Para no tratar como «ligada» una venta que apunta a una fila que ya no
  // existe: ese enlace roto hay que SANARLO, no dejar la venta sin contar.
  final manualIds = {for (final h in manualHarvests) h.id};

  final out = <Harvest>[];
  for (final t in transactions) {
    if (t.deleted) continue;
    if (t.type.isExpense) continue;
    if (!isSaleCategory(t.category)) continue;

    // Sin cultivo no hay a quién atribuir los kilos, ni fase que promover.
    final cropId = t.cropId;
    if (cropId == null) continue;

    // D2 · manda lo que él anotó a mano.
    if (manualCrops.contains(cropId)) continue;

    // `null` → oculto, nunca un 0: sin kilos no hay cosecha que derivar.
    final quantity = t.quantity;
    if (quantity == null || quantity <= 0) continue;

    final unit = t.unit;
    if (unit == null || unit.isEmpty) continue;

    // Ya está ligada a una cosecha que sigue viva → no la duplicamos.
    final linked = t.harvestId;
    if (linked != null && manualIds.contains(linked)) continue;

    out.add(Harvest(
      // Nunca se persiste, así que el id solo tiene que ser estable y
      // reconocible: sirve para agrupar y para saber de dónde salió.
      id: '$kSaleDerivedPrefix${t.id}',
      cropId: cropId,
      date: t.date,
      // Bruto, no neto. `netQuantity` ya descuenta lo que el comprador
      // cobró, que es otra cosa (pérdida en la compra, no en el campo).
      // Además la regla 6 compara contra `t.quantity`: con bruto los dos
      // lados miden lo mismo.
      amount: quantity,
      unit: unit,
      destination: HarvestDestination.vendido,
      // Jamás se sube. El sync usa `storedHarvests`, pero aquí no se deja
      // al azar.
      pendingSync: false,
    ));
  }
  return out;
}
