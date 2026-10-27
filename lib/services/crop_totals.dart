import '../models/crop.dart';
import '../models/terreno.dart';
import '../models/transaction.dart';

/// Fila del desglose por cultivo con los montos **separados por moneda**.
///
/// Regla de dominio: todo lo que se cosecha se vende (no hay bodega) y
/// **nunca se suman monedas distintas**. Cada mapa guarda el total de una
/// sola moneda, así que la cifra siempre es cierta.
///
/// - Moneda única → `incomes`/`expenses` tienen una entrada: la cifra de
///   siempre, con su código, es válida.
/// - Dos o más monedas (`isMixed`) → hay que listar moneda por moneda; el
///   neto, el margen y cualquier % que cruce monedas serían mentira.
class CropBreakdownRow {
  /// Id del cultivo (`null` = movimientos sin cultivo asignado).
  final String? cropId;

  /// Lote al que sirve la fila (`null` en casi todas).
  ///
  /// Solo lo lleva la fila de un lote que **no se pudo repartir**: ahí el
  /// gasto sigue unido a su terreno y hay que poder distinguir "Lote Arriba"
  /// de "Lote Abajo" cuando los dos fallan por la misma razón. En las filas
  /// de cultivo va null porque el gasto ya se le atribuyó, y en "Costos
  /// comunes" porque no pertenecen a ningún lote.
  final String? terrenoId;

  /// Nombre ya resuelto para mostrar (nombre del cultivo o el rótulo de
  /// "sin cultivo").
  final String name;

  /// Movimientos del cultivo en el período (sin borrados).
  int count;

  /// Gastos que **contribuyen** a esta fila, ya con la parte que les toca.
  ///
  /// Es la misma lista que suma `expenses`, así que
  /// `inversión inicial + operación` da exactamente lo que muestra la fila —
  /// incluida la parte de un jornal de lote repartido entre varios cultivos,
  /// que entra como una copia del movimiento con su porción y no con el
  /// monto entero (eso sumaría el mismo peso dos veces en la finca).
  final List<Transaction> expenseTxs = [];

  /// Ingresos por código de moneda.
  final Map<String, double> incomes;

  /// Gastos por código de moneda.
  final Map<String, double> expenses;

  CropBreakdownRow({
    required this.cropId,
    this.terrenoId,
    required this.name,
    this.count = 0,
    Map<String, double>? incomes,
    Map<String, double>? expenses,
  })  : incomes = incomes ?? <String, double>{},
        expenses = expenses ?? <String, double>{};

  /// Monedas presentes en el cultivo (ingresos o gastos).
  Set<String> get currencies => {...incomes.keys, ...expenses.keys};

  /// true cuando el cultivo toca más de una moneda.
  bool get isMixed => currencies.length > 1;

  /// Moneda de la fila si es una sola; con más de una no hay cifra única
  /// que mostrar y el caller debe desglosar.
  String? get singleCurrency => currencies.length == 1 ? currencies.first : null;

  /// Suma aritmética de los gastos. **Solo** para ordenar o filtrar filas:
  /// con moneda mixta no es una cifra que se pueda mostrar.
  double get expensesTotal => _sum(expenses.values);

  /// Ídem para los ingresos.
  double get incomesTotal => _sum(incomes.values);

  /// true si la fila tiene algún monto que mostrar.
  bool get hasAnyAmount => expensesTotal > 0 || incomesTotal > 0;

  static double _sum(Iterable<double> values) =>
      values.fold<double>(0, (a, b) => a + b);
}

/// Clave interna de la fila "Costos comunes" — no es un id de cultivo y no
/// puede chocar con uno (los ids son UUIDs).
const String _claveComunes = '__comunes__';

/// La regla de (b): qué fracción del gasto de un lote le toca a cada uno de
/// sus cultivos.
///
/// Devuelve `null` — y no un reparto — cuando no hay proporción posible: el
/// lote no tiene cultivos, o alguno no tiene hectáreas anotadas. En ese caso
/// el caller debe mostrar el gasto como línea aparte; repartirlo de todos
/// modos obligaría a ponerle 0 hectáreas a un cultivo, que es una cifra que
/// nadie midió.
///
/// **La comparten el desglose por cultivo y las alertas.** Si cada una
/// inventara la suya, el mismo café podría verse rentable en Reportes y en
/// pérdida en "Qué hacer".
///
/// Función pura: misma entrada, misma salida, sin red ni estado.
Map<String, double>? repartoPorHectareas({
  required List<Crop> crops,
  required String terrenoId,
}) {
  final cultivos = crops.where((c) => c.terrenoId == terrenoId).toList();
  if (cultivos.isEmpty) return null;
  if (!cultivos.every((c) => (c.areaHa ?? 0) > 0)) return null;
  final total = cultivos.fold<double>(0, (a, c) => a + c.areaHa!);
  return {for (final c in cultivos) c.id: c.areaHa! / total};
}

/// Gastos de lote repartidos por área entre los cultivos del lote.
///
/// Es **la** regla del reparto: la usan el desglose por cultivo y el panel
/// «Por hectárea». Cada trozo se calcula de una vez y el último cultivo se
/// queda con el resto de la resta, para que la suma de los trozos dé
/// EXACTAMENTE el gasto y no quede el residuo de coma flotante.
class LotExpenseSplit {
  /// cultivo → sus porciones (copias con el monto ya prorrateado).
  final Map<String, List<Transaction>> byCrop;

  /// Lotes que **no** se pudieron repartir: a algún cultivo les falta el área.
  final List<String> notSplit;

  const LotExpenseSplit(this.byCrop, this.notSplit);
}

LotExpenseSplit splitLotExpenses({
  required Map<String, List<Transaction>> byTerreno,
  required List<Crop> crops,
}) {
  final byCrop = <String, List<Transaction>>{};
  final notSplit = <String>[];

  for (final entry in byTerreno.entries) {
    final txs = entry.value;
    // La regla vive en [repartoPorHectareas], que es la misma que usan las
    // alertas: así un cultivo no puede verse rentable acá y en pérdida en
    // "Qué hacer".
    final fracciones = repartoPorHectareas(crops: crops, terrenoId: entry.key);

    if (fracciones == null) {
      notSplit.add(entry.key);
      continue;
    }

    final ids = fracciones.keys.toList();
    final partes = [
      for (var i = 0; i < ids.length; i++) <double>[],
    ];
    for (final t in txs) {
      var asignado = 0.0;
      for (var i = 0; i < ids.length - 1; i++) {
        final p = t.amount * fracciones[ids[i]]!;
        partes[i].add(p);
        asignado += p;
      }
      partes[ids.length - 1].add(t.amount - asignado);
    }

    for (var i = 0; i < ids.length; i++) {
      final lista = byCrop.putIfAbsent(ids[i], () => <Transaction>[]);
      for (var j = 0; j < txs.length; j++) {
        final p = partes[i][j];
        final t = txs[j];
        // La copia con su porción es lo que suma el gasto: así "inversión
        // inicial + operación" da exactamente lo que se pinta y el mismo peso
        // no aparece entero en dos cultivos a la vez.
        lista.add(p == t.amount ? t : t.copyWith(amount: p));
      }
    }
  }

  return LotExpenseSplit(byCrop, notSplit);
}

/// Los gastos del período que le tocan a cada cultivo, con **la misma**
/// atribución del desglose ([cropBreakdownRows]):
///
/// 1. Un gasto con cultivo es de ese cultivo, aunque traiga lote.
/// 2. Un gasto de lote sin cultivo se reparte por área entre sus cultivos.
/// 3. Si a algún cultivo del lote le falta el área, **no se reparte** y el
///    lote sale en [CropExpenseShares.lotNotSplit].
/// 4. Un gasto sin cultivo ni lote («Costos comunes») no entra.
///
/// El panel «Por hectárea» la usa para no mostrar un gasto por hectárea
/// distinto del que enseña el desglose. Función pura: sin red ni estado.
class CropExpenseShares {
  final Map<String, List<Transaction>> byCrop;
  final Set<String> lotNotSplit;

  const CropExpenseShares({required this.byCrop, required this.lotNotSplit});

  List<Transaction> of(String cropId) =>
      byCrop[cropId] ?? const <Transaction>[];

  bool notSplit(String? terrenoId) =>
      terrenoId != null && lotNotSplit.contains(terrenoId);
}

CropExpenseShares cropExpenseShares({
  required Iterable<Transaction> records,
  required List<Crop> crops,
}) {
  final byCrop = <String, List<Transaction>>{};
  final delLote = <String, List<Transaction>>{};

  for (final t in records) {
    if (t.deleted || !t.type.isExpense) continue;
    if (t.cropId != null) {
      byCrop.putIfAbsent(t.cropId!, () => <Transaction>[]).add(t);
    } else if (t.terrenoId != null) {
      delLote.putIfAbsent(t.terrenoId!, () => <Transaction>[]).add(t);
    }
  }

  final repartido = splitLotExpenses(byTerreno: delLote, crops: crops);
  for (final e in repartido.byCrop.entries) {
    byCrop.putIfAbsent(e.key, () => <Transaction>[]).addAll(e.value);
  }

  return CropExpenseShares(
    byCrop: byCrop,
    lotNotSplit: repartido.notSplit.toSet(),
  );
}

/// Agrupa los movimientos del período por cultivo y, dentro de cada cultivo,
/// por moneda — **y reparte lo que sirve a todo un lote**.
///
/// [records] llega ya filtrado al período (los borrados se ignoran igual
/// por si acaso). Los cultivos sin movimientos también salen, con los mapas
/// vacíos, para que el caller decida si los pinta.
///
/// Función pura: misma entrada, misma salida; sin red, sin estado, sin UI.
/// Es la misma fuente que usan la pantalla, el PDF y el Excel, para que los
/// tres apliquen exactamente el mismo criterio.
///
/// **Cómo se atribuye cada movimiento (b):**
///
/// 1. Tiene cultivo → es de ese cultivo. Ni más ni menos. Si además trae
///    lote, manda el cultivo: es la información más específica.
/// 2. Es un gasto de lote y TODOS los cultivos del lote tienen hectáreas →
///    se reparte entre ellos en proporción a su superficie. El total de la
///    finca no se mueve: lo que recibe uno deja de recibir el otro.
/// 3. Es un gasto de lote y falta la hectárea de alguno → **no se reparte**:
///    sale como fila propia, "Lote X · sin repartir". Repartir igual obligaría
///    a ponerle 0 hectáreas a un cultivo, que es una cifra que nadie midió.
/// 4. No tiene cultivo ni lote → "Costos comunes", al final, como siempre.
///
/// Un ingreso con lote no existe por diseño (la pantalla solo ofrece el lote
/// en los gastos): los ingresos son de un cultivo o de la finca entera, nunca
/// proporcionales a la superficie. Si aun así llegara uno, se trata como sin
/// lote — no se parte un cobro por hectáreas.
///
/// El orden es parte del contrato: cultivos, luego los lotes sin repartir,
/// y "Costos comunes" siempre al final. Se fija aquí y no en cada pantalla
/// para que Reportes, el PDF y el Excel lo pinten igual sin acordarse.
List<CropBreakdownRow> cropBreakdownRows({
  required Iterable<Transaction> records,
  required List<Crop> crops,
  required List<Terreno> terrenos,
  required String unspecifiedName,
  required String Function(String terrenoName) loteNoRepartidoName,
}) {
  final nameById = {for (final c in crops) c.id: c.name};
  final terrenoNameById = {for (final t in terrenos) t.id: t.name};

  final rows = <String, CropBreakdownRow>{
    _claveComunes: CropBreakdownRow(cropId: null, name: unspecifiedName),
  };
  for (final c in crops) {
    rows.putIfAbsent(c.id, () => CropBreakdownRow(cropId: c.id, name: c.name));
  }

  void apuntar(CropBreakdownRow row, Transaction t) {
    row.count++;
    final target = t.type.isExpense ? row.expenses : row.incomes;
    target[t.currency] = (target[t.currency] ?? 0) + t.amount;
    if (t.type.isExpense) row.expenseTxs.add(t);
  }

  // (b) · los gastos de lote se acumulan aparte: todavía no se sabe si van a
  // poder repartirse. Se guardan como movimientos, no como suma, porque para
  // "inversión inicial vs operación" hace falta saber de qué categoría era
  // cada uno.
  final delLote = <String, List<Transaction>>{};

  for (final t in records) {
    if (t.deleted) continue;

    if (t.cropId == null && t.terrenoId != null && t.type.isExpense) {
      delLote.putIfAbsent(t.terrenoId!, () => <Transaction>[]).add(t);
      continue;
    }

    final row = rows.putIfAbsent(
      t.cropId ?? _claveComunes,
      () => CropBreakdownRow(
        cropId: t.cropId,
        name: t.cropId == null
            ? unspecifiedName
            : (nameById[t.cropId] ?? t.cropId!),
      ),
    );
    apuntar(row, t);
  }

  final repartido = splitLotExpenses(byTerreno: delLote, crops: crops);

  final filasDeLote = <String, CropBreakdownRow>{};
  for (final tid in repartido.notSplit) {
    final txs = delLote[tid]!;
    final fila = CropBreakdownRow(
      cropId: null,
      terrenoId: tid,
      name: loteNoRepartidoName(terrenoNameById[tid] ?? tid),
    );
    for (final t in txs) {
      fila.count++;
      fila.expenses[t.currency] = (fila.expenses[t.currency] ?? 0) + t.amount;
      fila.expenseTxs.add(t);
    }
    filasDeLote[tid] = fila;
  }

  for (final entry in repartido.byCrop.entries) {
    final fila = rows[entry.key]!;
    for (final t in entry.value) {
      fila.count++;
      fila.expenses[t.currency] = (fila.expenses[t.currency] ?? 0) + t.amount;
      fila.expenseTxs.add(t);
    }
  }

  return [
    for (final e in rows.entries)
      if (e.key != _claveComunes) e.value,
    ...filasDeLote.values,
    rows[_claveComunes]!,
  ];
}

/// true si algún terreno tiene más de un cultivo: **cultivos asociados**.
///
/// Es el caso normal de una finca de café con plátano, maíz o frutas en el
/// mismo lote. Ahí un mismo jornal o la misma bolsa de abono sirve a varios
/// cultivos a la vez, así que el costo de cada uno es una **aproximación**:
/// el total de la finca sí cuadra, el reparto entre cultivos no.
///
/// No se calcula el reparto aquí (habría que inventar porcentajes). Solo se
/// detecta el caso para que los tres pintadores avisen con el MISMO texto y
/// en el MISMO sitio — sin acordarse entre ellos.
///
/// Los cultivos sin terreno no cuentan: sin lote no hay terreno compartido
/// del que hablar.
bool hasAssociatedCrops(List<Crop> crops) {
  final porTerreno = <String, int>{};
  for (final c in crops) {
    final id = c.terrenoId;
    if (id == null) continue;
    porTerreno[id] = (porTerreno[id] ?? 0) + 1;
  }
  return porTerreno.values.any((n) => n > 1);
}

/// Montos de un mapa `moneda → monto` en una sola línea, cada moneda con su
/// cifra y su código: `COP 5.000 · EUR 200,00`. Nunca se suman entre sí.
///
/// [format] recibe el monto y el código (para que cada render use su
/// formato: pantalla, PDF o Excel). Es ese formateador quien lleva el
/// código —`formatAmount` y `formatMoneyLabel` devuelven `COP 5.000`—, así
/// que el helper NO lo vuelve a añadir: juntarlos daba `COP 5.000 COP`.
String byCurrencyText(
  Map<String, double> amounts,
  String Function(double amount, String currency) format, {
  String separator = ' · ',
}) {
  final entries = amounts.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((e) => format(e.value, e.key)).join(separator);
}

// ---- W1-c · el desglose por terreno -------------------------------------

/// Una banda del desglose: un terreno y las filas del período que le
/// pertenecen, con el total ya sumado **por moneda**.
///
/// `terrenoId == null` es la banda «Sin terreno» (los cultivos que no tienen
/// lote, o cuyo lote ya no existe). No es una fila más: solo existe cuando la
/// finca usa terrenos y quedó algo suelto.
class CropBreakdownBand {
  /// Terreno de la banda; `null` = «Sin terreno».
  final String? terrenoId;

  /// Nombre ya resuelto para mostrar (el del terreno o el rótulo de huérfanos).
  final String name;

  /// Hectáreas del terreno, si las anotó. `null` = oculto, nunca 0.
  final double? areaHa;

  /// Filas visibles de la banda, en el orden en que se pintan.
  final List<CropBreakdownRow> rows;

  /// Gastos sumados **moneda por moneda** (nunca cruzadas).
  final Map<String, double> expenses;

  /// Ingresos sumados moneda por moneda.
  final Map<String, double> incomes;

  CropBreakdownBand({
    required this.terrenoId,
    required this.name,
    required this.areaHa,
    required this.rows,
    required this.expenses,
    required this.incomes,
  });

  /// Monedas presentes en la banda (gastos o ingresos).
  Set<String> get currencies => {...expenses.keys, ...incomes.keys};

  /// true cuando la banda toca más de una moneda: no hay neto ni margen único.
  bool get isMixed => currencies.length > 1;

  /// Suma aritmética usada **solo para ordenar**: con moneda mixta no es una
  /// cifra que se pueda pintar.
  double get expensesTotal => expenses.values.fold<double>(0, (a, b) => a + b);

  /// Ídem para los ingresos.
  double get incomesTotal => incomes.values.fold<double>(0, (a, b) => a + b);
}

/// El desglose ya agrupado: bandas por terreno (si la finca los usa) y
/// «Costos comunes» aparte, siempre al final.
class CropBreakdownLayout {
  /// true si al menos una fila visible pertenece a un terreno existente.
  ///
  /// Con `false` los pintadores deben usar su camino plano de siempre: la
  /// app sin terrenos no cambia ni un rótulo.
  final bool hasBands;

  /// Bandas en orden de pintado: terrenos por movimiento total y, al final,
  /// «Sin terreno» si hay huérfanos. Vacía cuando [hasBands] es false.
  final List<CropBreakdownBand> bands;

  /// La fila «Costos comunes» si tiene algún monto; nunca dentro de una banda.
  final CropBreakdownRow? commonCosts;

  const CropBreakdownLayout({
    required this.hasBands,
    required this.bands,
    required this.commonCosts,
  });
}

/// Agrupa las filas de [cropBreakdownRows] por terreno.
///
/// **Pertenencia:** una fila de cultivo es de `Crop.terrenoId`; una fila de
/// lote (`cropId == null`, `terrenoId != null`) es de ese lote; si el id no
/// resuelve a un [Terreno], la fila cae en «Sin terreno» (no se inventa una
/// banda con un UUID). «Costos comunes» queda fuera.
///
/// **Visibilidad:** solo entran filas con algún monto (`hasAnyAmount`), la
/// misma regla que ya usan el PDF y el Excel. Una banda vacía no existe.
///
/// **Orden:** bandas por gastos+ingresos descendente (suma solo para ordenar),
/// desempate por nombre y luego por id; dentro, igual. «Sin terreno» va
/// siempre al final, antes de los comunes.
///
/// Función pura: misma entrada, misma salida. La comparten pantalla, PDF y
/// Excel para que los tres digan exactamente lo mismo.
CropBreakdownLayout cropBreakdownLayout({
  required List<CropBreakdownRow> rows,
  required List<Crop> crops,
  required List<Terreno> terrenos,
  required String sinTerrenoName,
}) {
  final cropById = {for (final c in crops) c.id: c};
  final terrenoById = {for (final t in terrenos) t.id: t};

  CropBreakdownRow? comunes;
  final porTerreno = <String, List<CropBreakdownRow>>{};
  final huerfanos = <CropBreakdownRow>[];

  for (final r in rows) {
    if (!r.hasAnyAmount) continue;
    if (r.cropId == null && r.terrenoId == null) {
      comunes = r;
      continue;
    }
    final tid = r.cropId != null ? cropById[r.cropId]?.terrenoId : r.terrenoId;
    if (tid != null && terrenoById.containsKey(tid)) {
      porTerreno.putIfAbsent(tid, () => []).add(r);
    } else {
      huerfanos.add(r);
    }
  }

  if (porTerreno.isEmpty) {
    return CropBreakdownLayout(
      hasBands: false,
      bands: const [],
      commonCosts: comunes,
    );
  }

  final bands = <CropBreakdownBand>[
    for (final e in porTerreno.entries)
      _bandDeTerreno(
        terrenoId: e.key,
        name: terrenoById[e.key]!.name,
        areaHa: terrenoById[e.key]!.areaHa,
        rows: e.value,
      ),
  ]..sort(_compareBands);
  if (huerfanos.isNotEmpty) {
    bands.add(_bandDeTerreno(
      terrenoId: null,
      name: sinTerrenoName,
      areaHa: null,
      rows: huerfanos,
    ));
  }

  return CropBreakdownLayout(
    hasBands: true,
    bands: bands,
    commonCosts: comunes,
  );
}

CropBreakdownBand _bandDeTerreno({
  required String? terrenoId,
  required String name,
  required double? areaHa,
  required List<CropBreakdownRow> rows,
}) {
  final expenses = <String, double>{};
  final incomes = <String, double>{};
  for (final r in rows) {
    for (final e in r.expenses.entries) {
      expenses[e.key] = (expenses[e.key] ?? 0) + e.value;
    }
    for (final e in r.incomes.entries) {
      incomes[e.key] = (incomes[e.key] ?? 0) + e.value;
    }
  }
  final ordenadas = [...rows]..sort(_compareRows);
  return CropBreakdownBand(
    terrenoId: terrenoId,
    name: name,
    areaHa: areaHa,
    rows: ordenadas,
    expenses: expenses,
    incomes: incomes,
  );
}

double _pesoDeFila(CropBreakdownRow r) => r.expensesTotal + r.incomesTotal;

String _idDeFila(CropBreakdownRow r) => r.cropId ?? r.terrenoId ?? '';

int _compareRows(CropBreakdownRow a, CropBreakdownRow b) {
  final porPeso = _pesoDeFila(b).compareTo(_pesoDeFila(a));
  if (porPeso != 0) return porPeso;
  final porNombre = a.name.compareTo(b.name);
  if (porNombre != 0) return porNombre;
  return _idDeFila(a).compareTo(_idDeFila(b));
}

int _compareBands(CropBreakdownBand a, CropBreakdownBand b) {
  final porPeso = (b.expensesTotal + b.incomesTotal)
      .compareTo(a.expensesTotal + a.incomesTotal);
  if (porPeso != 0) return porPeso;
  final porNombre = a.name.compareTo(b.name);
  if (porNombre != 0) return porNombre;
  return (a.terrenoId ?? '').compareTo(b.terrenoId ?? '');
}
