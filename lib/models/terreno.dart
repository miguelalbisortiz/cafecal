/// Un terreno: la unidad de tierra en la que el productor piensa.
///
/// Tiene nombre y, si él lo sabe, hectáreas. Dentro puede haber varios
/// cultivos de distinto tipo — café con plátano y sombra — y ahí es donde
/// se apoya la idea de que unos gastos le pertenecen al terreno entero y
/// no a ninguno de los cultivos por separado.
///
/// Es **opcional**. La app sin terrenos es exactamente la misma de antes:
/// `Crop.terrenoId` nulo se comporta como no existir.
class Terreno {
  final String id;
  final String name;

  /// Hectáreas del terreno. Opcional: si él no las mide, se queda en null
  /// y la app no pinta nada en su lugar (regla de oro: null → oculto).
  final double? areaHa;
  final bool pendingSync;

  const Terreno({
    required this.id,
    required this.name,
    this.areaHa,
    this.pendingSync = false,
  });

  Terreno copyWith({
    String? id,
    String? name,
    Object? areaHa = _sentinel,
    bool? pendingSync,
  }) {
    return Terreno(
      id: id ?? this.id,
      name: name ?? this.name,
      // Con `double?` a secas, `copyWith(areaHa: null)` se leería como
      // "no me toques" y el campo no se podría borrar. Por eso el centinela.
      areaHa: areaHa == _sentinel ? this.areaHa : (areaHa as num?)?.toDouble(),
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (areaHa != null) 'area_ha': areaHa,
        'pending_sync': pendingSync,
      };

  factory Terreno.fromJson(Map<String, dynamic> json) {
    return Terreno(
      id: json['id'] as String,
      name: json['name'] as String,
      areaHa: (json['area_ha'] as num?)?.toDouble(),
      pendingSync: (json['pending_sync'] as bool?) ?? false,
    );
  }
}

const _sentinel = Object();
