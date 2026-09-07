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
    int? lostPlants,
    String? reason,
    bool? pendingSync,
  }) {
    return Sowing(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      date: date ?? this.date,
      kind: kind ?? this.kind,
      plants: plants ?? this.plants,
      areaHa: areaHa ?? this.areaHa,
      lostPlants: lostPlants ?? this.lostPlants,
      reason: reason ?? this.reason,
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
    return Sowing(
      id: json['id'] as String,
      cropId: json['crop_id'] as String?,
      date: DateTime.parse(json['date'] as String),
      kind: SowingKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => SowingKind.siembra,
      ),
      plants: (json['plants'] as num).toInt(),
      areaHa: (json['area_ha'] as num?)?.toDouble(),
      lostPlants: (json['lost_plants'] as num?)?.toInt(),
      reason: json['reason'] as String?,
      pendingSync: (json['pending_sync'] as bool?) ?? false,
    );
  }
}

enum SowingKind {
  siembra,
  resiembra;
}

/// Recomputes crop.livePlants and crop.areaHa from sowings in chronological order.
/// Returns a list of crop update candidates: each entry is [cropId, newLivePlants, newAreaHa].
/// If there are no sowings for a crop, its values are left untouched.
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
      ..sort((a, b) => a.date.compareTo(b.date));

    int? livePlants;
    double? areaHa;

    for (final s in sorted) {
      switch (s.kind) {
        case SowingKind.siembra:
          livePlants = s.plants;
          if (s.areaHa != null) areaHa = s.areaHa;
        case SowingKind.resiembra:
          if (livePlants != null) {
            livePlants = livePlants - (s.lostPlants ?? 0) + s.plants;
          }
      }
    }

    if (livePlants != null) {
      result[entry.key] = (livePlants: livePlants, areaHa: areaHa);
    }
  }

  return result;
}
