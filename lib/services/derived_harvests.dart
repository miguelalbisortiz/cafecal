import '../models/categories.dart';
import '../models/harvest.dart';
import '../models/tasks.dart';
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
/// La venta no es la única fuente. Un jornal de labor «Cosechar» puede traer
/// **kilos recolectados** (Tanda 2), y esa sí es una medida independiente de
/// la venta: es la única forma de saber lo que se quedó en el campo. Entra
/// **por encima** de la venta y es **un `if` más** en esta función, no un
/// rediseño. Orden de prioridad, por cultivo:
///
/// 1. `manual`  — lo anotó a mano. Manda siempre.
/// 2. `jornal`  — kilos recolectados en un jornal de «Cosechar».
/// 3. `venta`   — lo de la venta, cuando no hay medida mejor.
///
/// Por eso la identidad de lo derivado lleva la **fuente** en el prefijo y no
/// un «es derivado» genérico: [isSaleDerivedHarvest] responde `false` a una
/// cosecha derivada del jornal, que es justamente lo que la tarjeta «vendido
/// vs cosechado» necesita para saber que sí hay una medida independiente (D5).
///
/// «Por encima» quiere decir que, si el cultivo tiene al menos un jornal
/// medido, **la venta no deriva para ese cultivo**: sumar las dos fuentes
/// contaría los mismos kilos dos veces. El costo es explícito: si solo se
/// miden algunos jornales, la venta no rellena los que faltan. Se prefiere
/// medir de menos antes que inflar la cosecha (la regla de oro).

/// Prefijo de las cosechas derivadas **de la venta**.
///
/// Los id sintéticos empiezan por esto; los guardados son uuid. El prefijo
/// lleva la fuente a propósito — ver el bloque D4 arriba.
const String kSaleDerivedPrefix = 'der_venta_';

/// Prefijo de las cosechas derivadas **del jornal** (Tanda 2).
///
/// Igual que el de la venta: el prefijo dice de dónde salió. [isSaleDerivedHarvest]
/// devuelve `false` para estas, que es lo que enciende la tarjeta «vendido vs
/// cosechado»: el jornal sí es una medida independiente.
const String kJornalDerivedPrefix = 'der_jornal_';

/// ¿Esta cosecha salió de los kilos anotados en un jornal de «Cosechar»?
bool isJornalDerivedHarvest(Harvest harvest) =>
    harvest.id.startsWith(kJornalDerivedPrefix);

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

  // Cultivos con al menos un jornal medido: para ellos la venta no deriva.
  // Se calcula antes del bucle de ventas para que la regla viva en un solo
  // lugar y ninguna de las dos fuentes se cuele por su cuenta.
  final jornalCrops = <String>{
    for (final t in transactions)
      if (_isMeasuredHarvestJornal(t)) t.cropId!,
  };

  final out = <Harvest>[];

  // 1 · jornal — una cosecha por cada jornal medido (D11). La manual ya ganó:
  // si el cultivo tiene una, ni siquiera se emite la del jornal.
  for (final t in transactions) {
    if (!_isMeasuredHarvestJornal(t)) continue;

    final cropId = t.cropId!;
    if (manualCrops.contains(cropId)) continue;

    out.add(Harvest(
      id: '$kJornalDerivedPrefix${t.id}',
      cropId: cropId,
      date: t.date,
      amount: t.harvestedKg!,
      unit: 'kg',
      destination: HarvestDestination.vendido,
      pendingSync: false,
    ));
  }

  // 2 · venta — solo para los cultivos que no tienen una medida mejor.
  for (final t in transactions) {
    if (t.deleted) continue;
    if (t.type.isExpense) continue;
    if (!isSaleCategory(t.category)) continue;

    // Sin cultivo no hay a quién atribuir los kilos, ni fase que promover.
    final cropId = t.cropId;
    if (cropId == null) continue;

    // D2 · manda lo que él anotó a mano.
    if (manualCrops.contains(cropId)) continue;

    // D3 · si hay un jornal medido, la venta no vuelve a contar esos kilos.
    if (jornalCrops.contains(cropId)) continue;

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

/// ¿Este gasto es un jornal de «Cosechar» con kilos medidos?
///
/// Los filtros son la regla entera: gasto no borrado, categoría de mano de
/// obra, la tecla del catálogo (no texto libre de «Otra…»), cultivo y kilos
/// mayores que 0. `null`, 0 o negativo = no medido: no se deriva nada.
bool _isMeasuredHarvestJornal(Transaction t) {
  if (t.deleted) return false;
  if (!t.type.isExpense) return false;
  if (t.category != 'mano_obra') return false;
  if (t.task != kTaskCosechar) return false;
  if (t.cropId == null) return false;

  final kg = t.harvestedKg;
  return kg != null && kg > 0;
}
