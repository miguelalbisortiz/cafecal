enum CropPhase { establecimiento, produccion, renovacion }

enum CropCycle { perenne, anual }

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
    );
  }
}

const List<Crop> defaultCrops = [
  Crop(id: 'cafe', name: 'Café', icon: '☕', color: '#6D4C41'),
  Crop(id: 'platano', name: 'Plátano', icon: '🍌', color: '#F9A825'),
  Crop(id: 'otro', name: 'Otro', icon: '🌱', color: '#2E7D32'),
];
