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
    final sucio =
        kind != SowingKind.resiembra && (lost != null || reason != null);
    return Sowing(
      id: json['id'] as String,
      cropId: json['crop_id'] as String?,
      date: DateTime.parse(json['date'] as String),
      kind: kind,
      plants: (json['plants'] as num).toInt(),
      areaHa: (json['area_ha'] as num?)?.toDouble(),
      lostPlants: sucio ? null : lost,
      reason: sucio ? null : reason,
      pendingSync: sucio || ((json['pending_sync'] as bool?) ?? false),
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

/// El día desde el que tiene sentido fechar una pérdida de este cultivo: la
/// **siembra más reciente**.
///
/// Una pérdida anterior a esa siembra no cuenta: el contador lo fija la
/// siembra que viene después (`recomputeCropState`), así que el registro
/// subiría «Pérdidas acumuladas» del informe sin bajar el contador — dos
/// números del mismo informe contradiciéndose. El selector de fecha no deja
/// elegir ese día.
///
/// Sin siembras, arranca en el año 2000, igual que el formulario de siembras.
DateTime lossEarliestDate(List<Sowing> sowings, String cropId) {
  DateTime? ultima;
  for (final s in sowings) {
    if (s.cropId != cropId || s.kind != SowingKind.siembra) continue;
    if (ultima == null || s.date.isAfter(ultima)) ultima = s.date;
  }
  return ultima == null
      ? DateTime(2000)
      : DateTime(ultima.year, ultima.month, ultima.day);
}

/// Recalcula `crop.livePlants` y `crop.areaHa` a partir de las siembras,
/// **por día**.
///
/// El orden es el del calendario, no el del instante: una pérdida y su siembra
/// del **mismo día** cuentan juntas, porque el registro se guarda por día (la
/// fecha del selector llega a las 00:00) y comparar instantes descartaba la
/// pérdida en silencio. Dentro de un mismo día manda la siembra: es la que fija
/// el contador contra el que cuenta la resiembra.
///
/// Devuelve una entrada por cultivo: [cropId, nuevas plantas, nueva área]. Si un
/// cultivo no tiene siembras, sus valores se dejan como estaban.
Map<String, ({int livePlants, double? areaHa})> recomputeCropState(
    List<Sowing> sowings) {
  final result = <String, ({int livePlants, double? areaHa})>{};

  final byCrop = <String, List<Sowing>>{};
  for (final s in sowings) {
    final cid = s.cropId;
    if (cid == null) continue;
    byCrop.putIfAbsent(cid, () => []).add(s);
  }

  for (final entry in byCrop.entries) {
    final sorted = entry.value.toList()
      ..sort((a, b) {
        final byDay = _dayOf(a.date).compareTo(_dayOf(b.date));
        if (byDay != 0) return byDay;
        final byKind = _kindOrder(a.kind) - _kindOrder(b.kind);
        if (byKind != 0) return byKind;
        return a.date.compareTo(b.date);
      });

    int? livePlants;
    double? areaHa;

    for (final s in sorted) {
      switch (s.kind) {
        case SowingKind.siembra:
          livePlants = s.plants;
          if (s.areaHa != null) areaHa = s.areaHa;
        case SowingKind.resiembra:
          if (livePlants != null) {
            livePlants = livePlants - lossOf(s).lost + s.plants;
          }
      }
    }

    if (livePlants != null) {
      result[entry.key] = (livePlants: livePlants, areaHa: areaHa);
    }
  }

  return result;
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
