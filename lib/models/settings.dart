class FarmSettings {
  final String farmName;
  final String currency;
  final String locale;
  final String language;

  /// Último cultivo elegido al registrar: se preselecciona al abrir
  /// "Registrar" para agilizar gastos recurrentes del mismo cultivo.
  final String? lastCropId;

  /// Umbral manual de alerta de precio bajo (moneda activa por kg).
  /// Si se define, se dispara una alerta cuando una venta con cantidad
  /// se registra por debajo de este precio por kilogramo.
  /// `null` = desactivado (solo se compara contra el histórico propio).
  final double? lowPriceThresholdPerKg;

  /// Monto de la caja menor destinado **cada mes** a jornales y gastos extras.
  /// Se reinicia solo con el calendario (el saldo no se acumula al siguiente
  /// mes). `null` = desactivado (sin widget de caja ni alerta).
  final double? cajaMenorMensual;

  /// A2 · peso real de un saco de café, en kg.
  ///
  /// La norma dice 70, pero en la finca el costal puede pesar 60. Este número
  /// manda para pasar **todo** a kilogramos (reportes, PDF, Excel y alertas).
  /// Nunca es `null`: si no lo tocó, vale 70.
  ///
  /// Es retroactivo **a propósito**: el kg no se guarda por registro, se
  /// recalcula al vuelo, así que cambiarlo reescribe el histórico entero de
  /// una. Si algún día se quiere congelar lo ya registrado, haría falta
  /// guardar el peso junto a cada cosecha.
  final double sacoKg;

  static const _sentinel = Object();

  const FarmSettings({
    this.farmName = 'Mi Caferin',
    this.currency = 'COP',
    this.locale = 'es_CO',
    this.language = 'es',
    this.lastCropId,
    this.lowPriceThresholdPerKg,
    this.cajaMenorMensual,
    this.sacoKg = 70,
  });

  FarmSettings copyWith({
    String? farmName,
    String? currency,
    String? locale,
    String? language,
    Object? lastCropId = _sentinel,
    Object? lowPriceThresholdPerKg = _sentinel,
    Object? cajaMenorMensual = _sentinel,
    double? sacoKg,
  }) {
    return FarmSettings(
      farmName: farmName ?? this.farmName,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      language: language ?? this.language,
      lastCropId: lastCropId == _sentinel
          ? this.lastCropId
          : lastCropId as String?,
      lowPriceThresholdPerKg: lowPriceThresholdPerKg == _sentinel
          ? this.lowPriceThresholdPerKg
          : lowPriceThresholdPerKg as double?,
      cajaMenorMensual: cajaMenorMensual == _sentinel
          ? this.cajaMenorMensual
          : cajaMenorMensual as double?,
      // Como nunca es null no necesita sentinela: `??` basta, igual que
      // `farmName` más arriba — solo se cambia si se pasa un valor.
      sacoKg: sacoKg ?? this.sacoKg,
    );
  }

  Map<String, dynamic> toJson() => {
        'farm_name': farmName,
        'currency': currency,
        'locale': locale,
        'language': language,
        if (lastCropId != null) 'last_crop_id': lastCropId,
        if (lowPriceThresholdPerKg != null)
          'low_price_threshold_per_kg': lowPriceThresholdPerKg,
        if (cajaMenorMensual != null)
          'caja_menor_mensual': cajaMenorMensual,
        'saco_kg': sacoKg,
      };

  factory FarmSettings.fromJson(Map<String, dynamic> json) {
    return FarmSettings(
      farmName: (json['farm_name'] as String?) ?? 'Mi Caferin',
      currency: (json['currency'] as String?) ?? 'COP',
      locale: (json['locale'] as String?) ?? 'es_CO',
      language: (json['language'] as String?) ?? 'es',
      lastCropId: (json['last_crop_id'] as String?),
      lowPriceThresholdPerKg:
          (json['low_price_threshold_per_kg'] as num?)?.toDouble(),
      cajaMenorMensual: (json['caja_menor_mensual'] as num?)?.toDouble(),
      // Respaldos viejos no traen la clave → 70, el de la norma.
      sacoKg: (json['saco_kg'] as num?)?.toDouble() ?? 70,
    );
  }
}