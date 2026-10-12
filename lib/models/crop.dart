import 'sowing.dart';

enum CropPhase { establecimiento, produccion, renovacion }

enum CropCycle { perenne, anual }

const _sentinel = Object();

class Crop {
  final String id;
  final String name;
  final String icon;
  final String color;
  final bool pendingSync;
  final CropPhase phase;
  final CropCycle cycle;
  final String? defaultUnit;
  final double? areaHa;
  final int? livePlants;
  final double? establishmentCost;

  /// E4 · **su meta**, no una tabla de referencia.
  ///
  /// Es "kg/ha que quiero sacar de este lote", escritos por el productor.
  /// La app tiene que servir a cualquier agricultor de cualquier región: una
  /// tabla precargada (Cenicafé, por ejemplo) le pondría a todos un número
  /// que no aplica a su altitud, su lluvia ni su sombra, y lo peor es que
  /// parecería autoridad.
  ///
  /// `null` = sin meta → no se pinta nada, nunca un 0.
  final double? expectedYieldPerHa;

  /// Moneda del cultivo — todos los gastos/ingresos vinculados heredan esta
  /// moneda. Si es null, se usa la moneda de configuración.
  final String? currency;

  /// C1 · fecha en que empezó el cultivo, **opcional**.
  ///
  /// No hace falta anotarla si ya hay siembras: en ese caso manda la fecha de
  /// la última siembra/resiembra. Es la segunda opción para calcular la edad
  /// y, al **crear** un cultivo, la que deduce la fase (C2).
  final DateTime? plantedAt;

  /// E5 · **su fecha**, no una tabla de especies.
  ///
  /// El productor ya sabe cuánto tarda su cultivo cuando lo planta; lo que no
  /// tiene a mano es la cuenta de calendario. Esa la hace la app: con esta
  /// fecha y hoy, sale "faltan 6 meses".
  ///
  /// Una tabla Café→3 años / Plátano→9 meses obligaría a adivinar la especie
  /// por el nombre del cultivo y le pondría un número que no aplica a su
  /// altitud ni a su lluvia — el mismo problema descartado en E4.
  ///
  /// `null` = no la estima → no se pinta nada.
  final DateTime? primerCosechaEsperada;

  const Crop({
    required this.id,
    required this.name,
    this.icon = '🌱',
    this.color = '#2E7D32',
    this.pendingSync = false,
    this.phase = CropPhase.produccion,
    this.cycle = CropCycle.perenne,
    this.defaultUnit,
    this.areaHa,
    this.livePlants,
    this.establishmentCost,
    this.currency,
    this.plantedAt,
    this.expectedYieldPerHa,
    this.primerCosechaEsperada,
  });

  Crop copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    bool? pendingSync,
    CropPhase? phase,
    CropCycle? cycle,
    String? defaultUnit,
    double? areaHa,
    int? livePlants,
    double? establishmentCost,
    Object? currency = _sentinel,
    Object? plantedAt = _sentinel,
    Object? expectedYieldPerHa = _sentinel,
    Object? primerCosechaEsperada = _sentinel,
  }) {
    return Crop(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      pendingSync: pendingSync ?? this.pendingSync,
      phase: phase ?? this.phase,
      cycle: cycle ?? this.cycle,
      defaultUnit: defaultUnit ?? this.defaultUnit,
      areaHa: areaHa ?? this.areaHa,
      livePlants: livePlants ?? this.livePlants,
      establishmentCost: establishmentCost ?? this.establishmentCost,
      currency: currency == _sentinel ? this.currency : currency as String?,
      // Sentinela también aquí: el campo es opcional y el productor puede
      // **borrar** la fecha. Con `DateTime?` a secas, `copyWith(plantedAt: null)`
      // habría conservado la anterior.
      plantedAt: plantedAt == _sentinel ? this.plantedAt : plantedAt as DateTime?,
      // Sentinela por lo mismo que plantedAt: la meta es opcional y se puede
      // BORRAR. Con `double?` a secas, `copyWith(expectedYieldPerHa: null)`
      // habría conservado la anterior y no habría forma de quitarla.
      expectedYieldPerHa: expectedYieldPerHa == _sentinel
          ? this.expectedYieldPerHa
          : (expectedYieldPerHa as num?)?.toDouble(),
      // Sentinela por lo mismo: la fecha se puede borrar desde el editor.
      primerCosechaEsperada: primerCosechaEsperada == _sentinel
          ? this.primerCosechaEsperada
          : primerCosechaEsperada as DateTime?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'pending_sync': pendingSync,
        'phase': phase.name,
        'cycle': cycle.name,
        'default_unit': defaultUnit,
        'area_ha': areaHa,
        'live_plants': livePlants,
        'establishment_cost': establishmentCost,
        'currency': currency,
        'planted_at': plantedAt?.toIso8601String(),
        'expected_yield_kg_ha': expectedYieldPerHa,
        'primer_cosecha_esperada': primerCosechaEsperada?.toIso8601String(),
      };

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: (json['icon'] as String?) ?? '🌱',
      color: (json['color'] as String?) ?? '#2E7D32',
      pendingSync: (json['pending_sync'] as bool?) ?? false,
      phase: CropPhase.values.firstWhere(
        (p) => p.name == json['phase'],
        orElse: () => CropPhase.produccion,
      ),
      cycle: CropCycle.values.firstWhere(
        (c) => c.name == json['cycle'],
        orElse: () => CropCycle.perenne,
      ),
      defaultUnit: json['default_unit'] as String?,
      areaHa: (json['area_ha'] as num?)?.toDouble(),
      livePlants: (json['live_plants'] as num?)?.toInt(),
      establishmentCost: (json['establishment_cost'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      // `tryParse` y no `parse`: local va ISO completo y Supabase manda
      // 'YYYY-MM-DD', y una fecha corrupta no debe tumbar la carga de todos
      // los cultivos — peor caso, se queda sin edad.
      plantedAt: _fechaDe(json['planted_at']),
      // Respaldo anterior a E4 no trae la clave → null → sin meta.
      expectedYieldPerHa: (json['expected_yield_kg_ha'] as num?)?.toDouble(),
      // Respaldo anterior a E5 no trae la clave → null → sin fecha estimada.
      primerCosechaEsperada: _fechaDe(json['primer_cosecha_esperada']),
    );
  }

  /// Acepta ISO completo (almacenamiento local), 'YYYY-MM-DD' (columna `date`
  /// de Supabase) y `DateTime` por si algún camino lo pasa ya convertido.
  static DateTime? _fechaDe(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}

/// F5 · años cumplidos entre [desde] y [hoy].
///
/// 0 significa "todavía no cumple uno" (o que la fecha es del futuro); no se
/// usa para decir "sin datos" — eso es `null`, que resuelve quien lo pide.
int aniosCumplidos(DateTime desde, DateTime hoy) {
  var anios = hoy.year - desde.year;
  if (hoy.month < desde.month ||
      (hoy.month == desde.month && hoy.day < desde.day)) {
    anios--;
  }
  return anios < 0 ? 0 : anios;
}

/// E5 · edad de un cultivo en años, o `null` si **no hay datos**.
///
/// Orden fijo, de lo que él anotó en el campo a lo que escribió en el editor:
///
/// 1. la **última siembra** — es lo que de verdad arrancó el lote;
/// 2. si no hay ninguna, `plantedAt`;
/// 3. si no hay ninguna de las dos → `null` (se oculta, nunca un 0 inventado).
///
/// **Una resiembra no reinicia la edad.** En la finca, la resiembra repone
/// plantas muertas: la app misma lo dice con su aritmética, vivas − muertas +
/// nuevas. Un cafetal de 7 años con 20 matas reponidas sigue teniendo 7 años.
/// Lo que sí la reinicia es una **siembra nueva** (una renovación completa se
/// anota como siembra).
///
/// Un cultivo anual no tiene edad de cafetal → `null`.
int? edadDeCrop(Crop crop, List<Sowing> sowings, {DateTime? hoy}) {
  if (crop.cycle == CropCycle.anual) return null;
  final ahora = hoy ?? DateTime.now();

  DateTime? desde;
  for (final s in sowings) {
    if (s.cropId != crop.id) continue;
    if (s.kind != SowingKind.siembra) continue;
    if (desde == null || s.date.isAfter(desde)) desde = s.date;
  }
  desde ??= crop.plantedAt;
  if (desde == null || desde.isAfter(ahora)) return null;
  return aniosCumplidos(desde, ahora);
}

/// E5 · lo que la app puede decir sobre la primera cosecha que el productor
/// espera de un lote.
///
/// Es **informativa**: no cambia la fase por su cuenta ni dispara alertas.
/// La fase la decide la primera cosecha registrada
/// (`TransactionProvider._promotePhaseOnHarvest`).
class FirstHarvestEstimate {
  /// La fecha que él anotó.
  final DateTime date;

  /// Meses que faltan hasta esa fecha. `0` = cae este mismo mes.
  ///
  /// Solo tiene sentido leerse junto a [overdue]: si la fecha ya pasó, el
  /// contador se queda en 0 y manda el mensaje de que ya debería estar
  /// rindiendo.
  final int monthsOut;

  /// true cuando la fecha ya pasó **y nunca llegó una cosecha**: el lote
  /// debería estar rindiendo.
  ///
  /// Nunca es una alerta dura ni se pinta en rojo — es un dato, no un regaño.
  final bool overdue;

  const FirstHarvestEstimate({
    required this.date,
    required this.monthsOut,
    required this.overdue,
  });
}

/// E5 · qué decir sobre la primera cosecha estimada, o `null` si **no hay
/// nada que decir**.
///
/// Calla en dos casos, y ambos son la regla de oro trabajando:
///
/// 1. no anotó fecha (`null` → oculto, nunca un 0 inventado);
/// 2. **ya cosechó de verdad** — ahí manda lo que cosechó, no lo que estimó.
FirstHarvestEstimate? primerCosechaEstimada(
  Crop crop, {
  required bool yaCosecho,
  DateTime? hoy,
}) {
  final f = crop.primerCosechaEsperada;
  if (f == null || yaCosecho) return null;
  final ahora = hoy ?? DateTime.now();
  final hoySolo = DateTime(ahora.year, ahora.month, ahora.day);
  final meses = (f.year - hoySolo.year) * 12 + (f.month - hoySolo.month);
  return FirstHarvestEstimate(
    date: f,
    monthsOut: meses < 0 ? 0 : meses,
    // `isBefore` y no `<=`: la fecha es solo día, y "hoy" ya avanzó de hora.
    overdue: f.isBefore(hoySolo),
  );
}

/// E6 · fase que le toca a un cultivo recién creado.
///
/// **Un solo lugar para esta regla.** Antes vivía privada dentro del editor
/// de cultivos; la puerta de bienvenida (E6) necesita la misma cuenta y
/// duplicarla habría dejado el umbral de 3 años escrito en dos sitios — el
/// hallazgo H2 que ya venimos combatiendo.
///
/// El umbral **no es una tabla de especies**: es solo el respaldo que decide
/// entre Establecimiento y Producción cuando él no dijo nada y todavía no
/// hay cosecha que lo demuestre. Lo que manda de verdad es la primera
/// cosecha registrada (`TransactionProvider._promotePhaseOnHarvest`) y, ya
/// en E5, la fecha de primera cosecha que él estimó.
CropPhase deducePhaseOnCreate({
  required CropCycle cycle,
  DateTime? plantedAt,
  DateTime? hoy,
}) {
  // Un anual no tiene fases de cafetal: se siembra y se cosecha en el año.
  if (cycle == CropCycle.anual) return CropPhase.produccion;
  final ahora = hoy ?? DateTime.now();
  // Sin fecha, el contador arranca en cero → establecimiento, que es el
  // valor por defecto de un cultivo nuevo (P3). Mejor callar que afirmar.
  final anios = plantedAt == null ? 0 : aniosCumplidos(plantedAt, ahora);
  return anios >= _anosParaProduccion
      ? CropPhase.produccion
      : CropPhase.establecimiento;
}

/// Respaldo cuando no hay ni fecha ni cosecha. Ver [deducePhaseOnCreate].
const int _anosParaProduccion = 3;

const List<Crop> defaultCrops = [
  Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41'),
  Crop(id: 'platano', name: 'Plátano', icon: '🍌', color: '#F9A825'),
  Crop(id: 'otro', name: 'Otro', icon: '🌱', color: '#2E7D32'),
];

/// Los tres ids fijos con que antes se sembraban los cultivos por defecto.
///
/// [defaultCrops] ya no se siembra, pero cualquier navegador antiguo todavía
/// los puede tener guardados en local, mientras que la BD solo acepta uuid
/// y jamás tendrá esos ids. Sirven para reconocerlos y **adoptar** el cultivo
/// remoto equivalente en lugar de deduplicar por nombre (ver
/// `TransactionProvider.mergeRemoteCrops`).
final Set<String> legacyCropIds = {for (final c in defaultCrops) c.id};
