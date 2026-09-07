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

  static const _sentinel = Object();

  const FarmSettings({
    this.farmName = 'Mi Caferin',
    this.currency = 'COP',
    this.locale = 'es_CO',
    this.language = 'es',
    this.lastCropId,
    this.lowPriceThresholdPerKg,
  });

  FarmSettings copyWith({
    String? farmName,
    String? currency,
    String? locale,
    String? language,
    Object? lastCropId = _sentinel,
    Object? lowPriceThresholdPerKg = _sentinel,
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
    );
  }
}