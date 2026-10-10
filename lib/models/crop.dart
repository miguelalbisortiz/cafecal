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

  /// Moneda del cultivo — todos los gastos/ingresos vinculados heredan esta
  /// moneda. Si es null, se usa la moneda de configuración.
  final String? currency;

  /// C1 · fecha en que empezó el cultivo, **opcional**.
  ///
  /// No hace falta anotarla si ya hay siembras: en ese caso manda la fecha de
  /// la última siembra/resiembra. Es la segunda opción para calcular la edad
  /// y, al **crear** un cultivo, la que deduce la fase (C2).
  final DateTime? plantedAt;

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

/// F5 · edad de un cultivo en años, o `null` si **no hay datos**.
///
/// Orden fijo, de lo que él anotó en el campo a lo que escribió en el editor:
///
/// 1. la **última** siembra/resiembra — es lo que de verdad ocurrió;
/// 2. si no hay ninguna, `plantedAt`;
/// 3. si no hay ninguna de las dos → `null` (se oculta, nunca un 0 inventado).
///
/// Un cultivo anual no tiene edad de cafetal → `null`.
int? edadDeCrop(Crop crop, List<Sowing> sowings, {DateTime? hoy}) {
  if (crop.cycle == CropCycle.anual) return null;
  final ahora = hoy ?? DateTime.now();

  DateTime? desde;
  for (final s in sowings) {
    if (s.cropId != crop.id) continue;
    if (desde == null || s.date.isAfter(desde)) desde = s.date;
  }
  desde ??= crop.plantedAt;
  if (desde == null || desde.isAfter(ahora)) return null;
  return aniosCumplidos(desde, ahora);
}

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
