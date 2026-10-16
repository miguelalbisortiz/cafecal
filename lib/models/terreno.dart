/// Un terreno: la unidad de tierra en la que el productor piensa.
///
/// Tiene nombre y, si él lo sabe, hectáreas. Dentro puede haber varios
/// cultivos de distinto tipo — café con plátano y sombra — y ahí es donde
/// se apoya la idea de que unos gastos le pertenecen al terreno entero y
/// no a ninguno de los cultivos por separado.
///
/// Es **opcional**. La app sin terrenos es exactamente la misma de antes:
/// `Crop.terrenoId` nulo se comporta como no existir.
///
/// ## La ubicación (GPS)
///
/// `lat`/`lng` son **el punto del lote**, no la posición del teléfono. Por
/// eso la app **nunca los re-mide sola**: mover la tierra en silencio sería
/// inventar datos. Se toman una vez — con el botón o escritos a mano — y el
/// productor puede corregirlos o borrarlos cuando quiera.
///
/// [locatedAt] guarda el día en que se midió. Es metadata **automática** (no
/// se la pide a nadie) y existe para poder decirle «esto se midió el 16 de
/// octubre», en vez de dejarlo creer que la coordenada es su posición de
/// ahora. `null` en cualquiera de los tres → oculto, nunca 0.
class Terreno {
  final String id;
  final String name;

  /// Hectáreas del terreno. Opcional: si él no las mide, se queda en null
  /// y la app no pinta nada en su lugar (regla de oro: null → oculto).
  final double? areaHa;

  /// Latitud del lote en grados decimales (−90 a 90). `null` = sin ubicar.
  final double? lat;

  /// Longitud del lote en grados decimales (−180 a 180). `null` = sin ubicar.
  final double? lng;

  /// Día en que se tomó la ubicación. Automático, no lo escribe nadie.
  final DateTime? locatedAt;

  final bool pendingSync;

  const Terreno({
    required this.id,
    required this.name,
    this.areaHa,
    this.lat,
    this.lng,
    this.locatedAt,
    this.pendingSync = false,
  });

  Terreno copyWith({
    String? id,
    String? name,
    Object? areaHa = _sentinel,
    Object? lat = _sentinel,
    Object? lng = _sentinel,
    Object? locatedAt = _sentinel,
    bool? pendingSync,
  }) {
    return Terreno(
      id: id ?? this.id,
      name: name ?? this.name,
      // Con `double?` a secas, `copyWith(areaHa: null)` se leería como
      // "no me toques" y el campo no se podría borrar. Por eso el centinela:
      // `null` significa **borrar**, y el valor por omisión del parámetro
      // (el centinela) significa "déjalo como está".
      areaHa: areaHa == _sentinel ? this.areaHa : (areaHa as num?)?.toDouble(),
      lat: lat == _sentinel ? this.lat : (lat as num?)?.toDouble(),
      lng: lng == _sentinel ? this.lng : (lng as num?)?.toDouble(),
      locatedAt:
          locatedAt == _sentinel ? this.locatedAt : (locatedAt as DateTime?),
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (areaHa != null) 'area_ha': areaHa,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (locatedAt != null) 'located_at': locatedAt!.toIso8601String(),
        'pending_sync': pendingSync,
      };

  factory Terreno.fromJson(Map<String, dynamic> json) {
    return Terreno(
      id: json['id'] as String,
      name: json['name'] as String,
      areaHa: (json['area_ha'] as num?)?.toDouble(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      locatedAt: DateTime.tryParse(json['located_at'] as String? ?? ''),
      pendingSync: (json['pending_sync'] as bool?) ?? false,
    );
  }
}

const _sentinel = Object();
