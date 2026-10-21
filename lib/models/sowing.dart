const _sentinel = Object();

class Sowing {
  final String id;
  final String? cropId;
  final DateTime date;
  final SowingKind kind;
  final int plants;
  final double? areaHa;
  final int? lostPlants;
  final String? reason;

  /// Etapa A · cuántas matas del lote viejo reemplaza esta siembra.
  /// `null` = dato viejo (sin normalizar); `0` = expansión explícita.
  final int? replacesPlants;

  /// Etapa A · cuántas hectáreas del lote viejo reemplaza. Solo tiene sentido
  /// junto a [replacesPlants]; sin él se descarta al entrar.
  final double? replacesAreaHa;

  /// Etapa A · a qué cohorte se refiere: la que **reemplaza** (siembra) o a la
  /// que **pertenece** (resiembra). Es el `id` de la siembra que abrió la
  /// cohorte. `null` en una siembra que abre cohorte nueva.
  final String? cohortSowingId;

  final bool pendingSync;

  const Sowing({
    required this.id,
    this.cropId,
    required this.date,
    this.kind = SowingKind.siembra,
    required this.plants,
    this.areaHa,
    this.lostPlants,
    this.reason,
    this.replacesPlants,
    this.replacesAreaHa,
    this.cohortSowingId,
    this.pendingSync = false,
  });

  Sowing copyWith({
    String? id,
    String? cropId,
    DateTime? date,
    SowingKind? kind,
    int? plants,
    double? areaHa,
    Object? lostPlants = _sentinel,
    Object? reason = _sentinel,
    Object? replacesPlants = _sentinel,
    Object? replacesAreaHa = _sentinel,
    Object? cohortSowingId = _sentinel,
    bool? pendingSync,
  }) {
    return Sowing(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      date: date ?? this.date,
      kind: kind ?? this.kind,
      plants: plants ?? this.plants,
      areaHa: areaHa ?? this.areaHa,
      // Sentinela (igual que en Crop.copyWith): los dos campos son opcionales
      // y dependen del tipo. Al pasar una resiembra a siembra hay que poder
      // BORRARLOS. Con `int?`/`String?` a secas, `copyWith(lostPlants: null)`
      // conservaba el -50 viejo y la siembra seguía diciendo "se perdieron 50".
      lostPlants:
          lostPlants == _sentinel ? this.lostPlants : lostPlants as int?,
      reason: reason == _sentinel ? this.reason : reason as String?,
      // Etapa A: las tres también tienen que poder volver a `null` (pasar una
      // renovación a expansión, o una siembra a resiembra).
      replacesPlants: replacesPlants == _sentinel
          ? this.replacesPlants
          : replacesPlants as int?,
      replacesAreaHa: replacesAreaHa == _sentinel
          ? this.replacesAreaHa
          : replacesAreaHa as double?,
      cohortSowingId: cohortSowingId == _sentinel
          ? this.cohortSowingId
          : cohortSowingId as String?,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'crop_id': cropId,
        'date': date.toIso8601String(),
        'kind': kind.name,
        'plants': plants,
        'area_ha': areaHa,
        'lost_plants': lostPlants,
        'reason': reason,
        'replaces_plants': replacesPlants,
        'replaces_area_ha': replacesAreaHa,
        'cohort_sowing_id': cohortSowingId,
        'pending_sync': pendingSync,
      };

  factory Sowing.fromJson(Map<String, dynamic> json) {
    final kind = SowingKind.values.firstWhere(
      (k) => k.name == json['kind'],
      orElse: () => SowingKind.siembra,
    );
    final lost = (json['lost_plants'] as num?)?.toInt();
    final reason = json['reason'] as String?;
    // Puerta única de entrada (disco, nube y respaldo): una siembra no tiene
    // pérdidas ni motivo, son cosa de la resiembra. Un registro viejo puede
    // traerlos pegados —pasó al pasar una resiembra a siembra—: se limpian al
    // entrar y se re-marca `pendingSync` para que la corrección suba.
    final sucioPerdidas =
        kind != SowingKind.resiembra && (lost != null || reason != null);

    // Etapa A · la misma puerta para el reemplazo y el puntero de cohorte.
    // Claves ausentes (cliente o respaldo viejo) entran `null` sin marcar sucio.
    var replacesPlants = (json['replaces_plants'] as num?)?.toInt();
    var replacesAreaHa = (json['replaces_area_ha'] as num?)?.toDouble();
    final cohortSowingId = json['cohort_sowing_id'] as String?;
    var sucioReemplazo = false;

    // Un negativo no significa nada: se limpia y se re-marca.
    if (replacesPlants != null && replacesPlants < 0) {
      replacesPlants = null;
      sucioReemplazo = true;
    }
    if (replacesAreaHa != null && replacesAreaHa < 0) {
      replacesAreaHa = null;
      sucioReemplazo = true;
    }
    // Un área sin matas no significa nada: con `null` matas se descarta.
    if (replacesAreaHa != null && replacesPlants == null) {
      replacesAreaHa = null;
      sucioReemplazo = true;
    }
    // Una resiembra no reemplaza: son campos de la siembra. Se limpian, pero
    // el puntero se conserva porque la resiembra sí lo usa (a qué cohorte
    // pertenece).
    if (kind == SowingKind.resiembra &&
        (replacesPlants != null || replacesAreaHa != null)) {
      replacesPlants = null;
      replacesAreaHa = null;
      sucioReemplazo = true;
    }
    // Una siembra con `replaces_plants > 0` y sin puntero se conserva tal cual:
    // el puntero puede faltar por un borrado remoto en otro dispositivo. No
    // resta (no se sabe a quién) y la lista la marca «sin lote». No hay nada
    // que corregir, así que no se marca sucia.

    return Sowing(
      id: json['id'] as String,
      cropId: json['crop_id'] as String?,
      date: DateTime.parse(json['date'] as String),
      kind: kind,
      plants: (json['plants'] as num).toInt(),
      areaHa: (json['area_ha'] as num?)?.toDouble(),
      lostPlants: sucioPerdidas ? null : lost,
      reason: sucioPerdidas ? null : reason,
      replacesPlants: replacesPlants,
      replacesAreaHa: replacesAreaHa,
      cohortSowingId: cohortSowingId,
      pendingSync: sucioPerdidas ||
          sucioReemplazo ||
          ((json['pending_sync'] as bool?) ?? false),
    );
  }
}

enum SowingKind {
  siembra,
  resiembra;
}

/// Las pérdidas son cosa de la resiembra: una siembra no pierde plantas ni
/// tiene motivo de mortandad. Es la **única regla de lectura**, para el
/// modelo, la lista y los informes: un registro viejo mal guardado no cuenta
/// ni se pinta, aunque el dato siga en el JSON.
({int lost, String? reason}) lossOf(Sowing s) =>
    s.kind == SowingKind.resiembra
        ? (lost: s.lostPlants ?? 0, reason: s.reason)
        : (lost: 0, reason: null);

/// El día desde el que tiene sentido fechar una pérdida de este cultivo.
///
/// Con [cohortSowingId], el día de **siembra de esa cohorte**: un lote viejo
/// que sigue vivo después de una renovación parcial tiene sus propias pérdidas,
/// y fecharlas desde la siembra más reciente del cultivo las rechazaría.
///
/// Sin puntero —o si el puntero no resuelve— se mantiene el comportamiento de
/// siempre (la siembra más reciente), para que el selector nunca se rompa.
///
/// Una pérdida anterior a esa fecha no cuenta: el contador lo fija la siembra
/// que viene después, así que el registro subiría «Pérdidas acumuladas» del
/// informe sin bajar el contador. El selector de fecha no deja elegir ese día.
///
/// Sin siembras, arranca en el año 2000, igual que el formulario de siembras.
DateTime lossEarliestDate(List<Sowing> sowings, String cropId,
    {String? cohortSowingId}) {
  if (cohortSowingId != null) {
    for (final s in sowings) {
      if (s.cropId == cropId &&
          s.kind == SowingKind.siembra &&
          s.id == cohortSowingId) {
        return _dayOf(s.date);
      }
    }
  }
  DateTime? ultima;
  for (final s in sowings) {
    if (s.cropId != cropId || s.kind != SowingKind.siembra) continue;
    if (ultima == null || s.date.isAfter(ultima)) ultima = s.date;
  }
  return ultima == null ? DateTime(2000) : _dayOf(ultima);
}

/// Etapa A · un **lote con su fecha**: lo que abre una siembra y lo que
/// ajustan las resiembras.
///
/// [sowingId] es el `id` de la siembra que la abrió; [date] su día de
/// nacimiento (no se reordena al restar); [livePlants] nunca es negativo;
/// [areaHa] queda en `null` si no se conoce; [closedOn] es el día de la siembra
/// que la dejó en 0 —`null` si se quedó en 0 por pérdidas, porque ahí no hay
/// fecha que inventar.
class Cohort {
  final String sowingId;
  final DateTime date;
  final int livePlants;
  final double? areaHa;
  final DateTime? closedOn;

  const Cohort({
    required this.sowingId,
    required this.date,
    required this.livePlants,
    this.areaHa,
    this.closedOn,
  });

  bool get open => livePlants > 0;
}

/// Etapa A · las cohortes de un cultivo, en orden cronológico.
///
/// Es la **única fuente de verdad**: el total del cultivo, las edades y la
/// lista de lotes salen de aquí. Determinista: el orden de la lista guardada no
/// cambia el resultado (día; siembra antes que resiembra; y a igualdad de día y
/// tipo, el `id`).
List<Cohort> cropCohorts(String cropId, List<Sowing> sowings) {
  final sorted = sowings.where((s) => s.cropId == cropId).toList()
    ..sort(_orderSowings);

  final cohorts = <_CohortBuilder>[];
  final byId = <String, _CohortBuilder>{};

  for (final s in sorted) {
    if (s.kind == SowingKind.siembra) {
      final c = _CohortBuilder(
          id: s.id, date: s.date, live: s.plants, area: s.areaHa);
      cohorts.add(c);
      byId[s.id] = c;
      _applyReplacement(s, byId);
    } else {
      _applyResiembra(s, cohorts, byId);
    }
  }

  return [for (final c in cohorts) c.build()];
}

/// Etapa A · solo las cohortes con matas vivas.
List<Cohort> openCohorts(String cropId, List<Sowing> sowings) =>
    cropCohorts(cropId, sowings).where((c) => c.open).toList();

/// Etapa A · cuántas edades tiene el cultivo hoy (cohortes con vivas > 0).
int nEdades(String cropId, List<Sowing> sowings) =>
    openCohorts(cropId, sowings).length;

/// Etapa A · qué se puede decir del área que suman las cohortes.
///
/// [manualArea] es el área que el productor tiene escrita en el cultivo.
/// `measuredSum` es la suma de las cohortes vivas **solo si todas la tienen**
/// (redondeada a 2 decimales); `incomplete` avisa de que falta alguna;
/// `overManual`, de que la suma ya supera el valor manual (aviso, nunca bloqueo).
({double? measuredSum, bool incomplete, bool overManual}) cohortAreaStatus(
    double? manualArea, List<Cohort> cohorts) {
  final open = cohorts.where((c) => c.open).toList();
  final incomplete = open.any((c) => c.areaHa == null);
  double? measuredSum;
  if (open.isNotEmpty && !incomplete) {
    measuredSum = _round2(open.fold<double>(0, (a, c) => a + c.areaHa!));
  }
  final overManual =
      measuredSum != null && manualArea != null && measuredSum > manualArea;
  return (
    measuredSum: measuredSum,
    incomplete: incomplete,
    overManual: overManual,
  );
}

/// Recalcula `crop.livePlants` y `crop.areaHa` a partir de las siembras, por
/// cohortes (etapa A).
///
/// - `livePlants` = suma de las cohortes con vivas > 0. Si **todas** están en 0
///   el resultado es `0`, que es un hecho, no un dato faltante.
/// - `areaHa` = suma redondeada de las cohortes vivas **solo si todas tienen
///   área**; si falta alguna es `null` y el cultivo conserva su valor manual.
///
/// El orden es el del calendario, no el del instante: una pérdida y su siembra
/// del **mismo día** cuentan juntas, porque el registro se guarda por día (la
/// fecha del selector llega a las 00:00) y comparar instantes descartaba la
/// pérdida en silencio. Dentro de un mismo día manda la siembra: es la que abre
/// la cohorte contra la que cuenta la resiembra.
///
/// Devuelve una entrada por cultivo con siembras; uno sin siembras no entra al
/// mapa y se deja como estaba.
Map<String, ({int livePlants, double? areaHa})> recomputeCropState(
    List<Sowing> sowings) {
  final result = <String, ({int livePlants, double? areaHa})>{};

  final cropIds = <String>{};
  for (final s in sowings) {
    final cid = s.cropId;
    if (cid != null) cropIds.add(cid);
  }

  for (final cropId in cropIds) {
    final cohorts = cropCohorts(cropId, sowings);
    if (cohorts.isEmpty) continue;

    var livePlants = 0;
    for (final c in cohorts) {
      if (c.livePlants > 0) livePlants += c.livePlants;
    }

    final open = cohorts.where((c) => c.open).toList();
    double? areaHa;
    if (open.isNotEmpty && open.every((c) => c.areaHa != null)) {
      areaHa = _round2(open.fold<double>(0, (a, c) => a + c.areaHa!));
    }

    result[cropId] = (livePlants: livePlants, areaHa: areaHa);
  }

  return result;
}

/// Etapa A · normaliza los datos viejos **sin mover un número** (D9).
///
/// Por cultivo, en orden cronológico: la primera siembra queda como está y cada
/// siembra posterior con los **tres** campos en `null` se marca como reemplazo
/// de lo que quedaba vivo en ese instante (apunta a la cohorte viva más
/// antigua). Si no había nada vivo queda `0` explícito: es la verdad («no
/// reemplacé nada») y evita que la fila se vuelva a procesar.
///
/// Idempotente sin bandera: en cuanto se toca una fila deja de estar en `null`
/// y no se procesa más. Las resiembras no se normalizan (sin puntero se
/// resuelven por fecha, como antes).
({List<Sowing> sowings, bool changed}) normalizeLegacyCohorts(
    List<Sowing> sowings) {
  final byCrop = <String, List<Sowing>>{};
  for (final s in sowings) {
    final cid = s.cropId;
    if (cid == null) continue;
    byCrop.putIfAbsent(cid, () => []).add(s);
  }

  final patched = <String, Sowing>{};

  for (final entry in byCrop.entries) {
    final sorted = entry.value.toList()..sort(_orderSowings);
    final cohorts = <_CohortBuilder>[];
    final byId = <String, _CohortBuilder>{};
    var siembras = 0;

    for (final s in sorted) {
      var row = s;
      if (s.kind == SowingKind.siembra) {
        siembras++;
        final virgen = s.replacesPlants == null &&
            s.replacesAreaHa == null &&
            s.cohortSowingId == null;
        if (siembras > 1 && virgen) {
          _CohortBuilder? target;
          var total = 0;
          for (final c in cohorts) {
            if (c.open) {
              target ??= c;
              total += c.live;
            }
          }
          row = s.copyWith(
            replacesPlants: target == null ? 0 : total,
            replacesAreaHa: target?.area,
            cohortSowingId: target?.id,
            pendingSync: true,
          );
          patched[s.id] = row;
        }
      }

      if (row.kind == SowingKind.siembra) {
        final c = _CohortBuilder(
            id: row.id, date: row.date, live: row.plants, area: row.areaHa);
        cohorts.add(c);
        byId[row.id] = c;
        _applyReplacement(row, byId);
      } else {
        _applyResiembra(row, cohorts, byId);
      }
    }
  }

  if (patched.isEmpty) return (sowings: sowings, changed: false);
  return (
    sowings: [for (final s in sowings) patched[s.id] ?? s],
    changed: true,
  );
}

/// Etapa A · por qué un reemplazo no se puede guardar. `none` = está bien.
enum ReplacementError { none, empty, notPositive, tooMany, noTarget }

/// Etapa A · valida el campo «cuántas matas viejas reemplaza».
///
/// En una expansión (`renew == false`) no hay nada que validar. En una
/// renovación hace falta una cohorte destino y una cantidad **positiva** que no
/// supere sus matas vivas.
ReplacementError validateReplacement({
  required bool renew,
  int? replacesPlants,
  Cohort? target,
}) {
  if (!renew) return ReplacementError.none;
  if (target == null) return ReplacementError.noTarget;
  if (replacesPlants == null) return ReplacementError.empty;
  if (replacesPlants <= 0) return ReplacementError.notPositive;
  if (replacesPlants > target.livePlants) return ReplacementError.tooMany;
  return ReplacementError.none;
}

/// Etapa A · cuántas matas viejas reemplaza, estimado por área.
///
/// `round(vivas × áreaNueva / áreaVieja)`, solo si **las dos** áreas existen y
/// la vieja es mayor que 0. Es una precarga: el productor la corrige.
int? replacementPrefill(Cohort target, double? newAreaHa) {
  final vieja = target.areaHa;
  if (vieja == null || newAreaHa == null || vieja <= 0) return null;
  final v = (target.livePlants * newAreaHa / vieja).round();
  return v < 0 ? 0 : v;
}

/// Etapa A · el máximo reemplazable: las matas vivas de la cohorte («Todas»).
int maxReplacement(Cohort target) => target.livePlants;

/// Orden determinista del motor: por día, siembra antes que resiembra y, a
/// igualdad de día y tipo, por `id` (el orden de la lista guardada no puede
/// cambiar el resultado).
int _orderSowings(Sowing a, Sowing b) {
  final byDay = _dayOf(a.date).compareTo(_dayOf(b.date));
  if (byDay != 0) return byDay;
  final byKind = _kindOrder(a.kind) - _kindOrder(b.kind);
  if (byKind != 0) return byKind;
  return a.id.compareTo(b.id);
}

double _round2(double v) => double.parse(v.toStringAsFixed(2));

/// Estado mutable de una cohorte mientras se recorren las siembras.
class _CohortBuilder {
  final String id;
  final DateTime date;
  int live;
  double? area;
  DateTime? closedOn;

  _CohortBuilder({
    required this.id,
    required this.date,
    required this.live,
    this.area,
  });

  bool get open => live > 0;

  Cohort build() => Cohort(
        sowingId: id,
        date: date,
        livePlants: live,
        areaHa: area,
        closedOn: closedOn,
      );
}

/// Aplica el reemplazo de una siembra (etapa A).
///
/// La resta **exige un puntero que resuelva** (D3): sin puntero, o si apunta a
/// una cohorte cerrada o con fecha posterior, no se resta y la fila se lista
/// «sin lote». `closedOn` se anota solo cuando la deja en 0 un reemplazo.
void _applyReplacement(Sowing s, Map<String, _CohortBuilder> byId) {
  final n = s.replacesPlants;
  if (n == null || n <= 0) return;
  final target = byId[s.cohortSowingId];
  if (target == null || !target.open) return;
  if (target.date.isAfter(s.date)) return;
  target.live -= n > target.live ? target.live : n;
  if (target.area != null && s.replacesAreaHa != null) {
    final a = target.area! - s.replacesAreaHa!;
    target.area = a < 0 ? 0 : a;
  }
  if (target.live == 0) target.closedOn = s.date;
}

/// Ajusta la cohorte de una resiembra: `vivas − muertas + nuevas`, con piso en
/// 0 y **sin revivir** una cohorte ya en 0.
///
/// Con puntero usa esa cohorte (validando que no sea del futuro); sin puntero
/// cae en la más reciente con fecha ≤ la suya (semántica anterior, D9).
void _applyResiembra(
    Sowing s, List<_CohortBuilder> cohorts, Map<String, _CohortBuilder> byId) {
  _CohortBuilder? target;
  if (s.cohortSowingId != null) {
    final t = byId[s.cohortSowingId];
    if (t != null && !_dayOf(t.date).isAfter(_dayOf(s.date))) target = t;
  } else {
    for (final c in cohorts) {
      if (_dayOf(c.date).isAfter(_dayOf(s.date))) break;
      target = c;
    }
  }
  if (target == null || !target.open) return;
  final vivas = target.live - lossOf(s).lost + s.plants;
  target.live = vivas < 0 ? 0 : vivas;
}

/// El día calendario de una fecha, sin la hora.
DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
/// T12 · ¿falta anotar la mortandad en una resiembra?
///
/// Solo cuando es resiembra, hay plantas nuevas y el campo quedó en blanco.
/// `lostPlants == 0` es una respuesta explícita y no se vuelve a preguntar.
bool resiembraMissingLosses(SowingKind kind, int plants, int? lostPlants) =>
    kind == SowingKind.resiembra && plants > 0 && lostPlants == null;

/// Dentro de un mismo día: primero la siembra (fija el contador), después la
/// resiembra (lo ajusta).
int _kindOrder(SowingKind kind) => kind == SowingKind.siembra ? 0 : 1;
