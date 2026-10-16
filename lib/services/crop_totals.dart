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
///   neto, el ROI y cualquier % que cruce monedas serían mentira.
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

/// Clave interna de la fila de un lote que no se pudo repartir.
String _claveLote(String terrenoId) => '__lote__$terrenoId';

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

  final filasDeLote = <String, CropBreakdownRow>{};
  for (final entry in delLote.entries) {
    final tid = entry.key;
    final txs = entry.value;
    // La regla vive en [repartoPorHectareas], que es la misma que usan las
    // alertas: así un cultivo no puede verse rentable acá y en pérdida en
    // "Qué hacer".
    final fracciones = repartoPorHectareas(crops: crops, terrenoId: tid);

    if (fracciones == null) {
      final fila = filasDeLote.putIfAbsent(
        _claveLote(tid),
        () => CropBreakdownRow(
          cropId: null,
          terrenoId: tid,
          name: loteNoRepartidoName(terrenoNameById[tid] ?? tid),
        ),
      );
      for (final t in txs) {
        fila.count++;
        fila.expenses[t.currency] = (fila.expenses[t.currency] ?? 0) + t.amount;
        fila.expenseTxs.add(t);
      }
      continue;
    }

    final ids = fracciones.keys.toList();
    // Parte de cada movimiento en cada cultivo, calculada de una vez para
    // que la suma de los trozos dé EXACTAMENTE el gasto: el último cultivo
    // se queda con el resto de la resta y así no queda el residuo de coma
    // flotante que dejaría la finca sumando unos centavos de menos.
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
      final fila = rows[ids[i]]!;
      for (var j = 0; j < txs.length; j++) {
        final p = partes[i][j];
        final t = txs[j];
        fila.count++;
        fila.expenses[t.currency] = (fila.expenses[t.currency] ?? 0) + p;
        // La copia con su porción es lo que suma `expenses`: así
        // "inversión inicial + operación" da exactamente lo que se pinta y
        // el mismo peso no aparece entero en dos cultivos a la vez.
        fila.expenseTxs.add(p == t.amount ? t : t.copyWith(amount: p));
      }
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
/// cifra y su código: `$5.000 COP · €200 EUR`. Nunca se suman entre sí.
///
/// [format] recibe el monto y el código (para que cada render use su
/// formato: pantalla, PDF o Excel).
String byCurrencyText(
  Map<String, double> amounts,
  String Function(double amount, String currency) format, {
  String separator = ' · ',
}) {
  final entries = amounts.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((e) => '${format(e.value, e.key)} ${e.key}').join(separator);
}
