class FarmSettings {
  final String farmName;
  final String currency;
  final String locale;
  final String language;

  /// Último cultivo elegido al registrar: se preselecciona al abrir
  /// "Registrar" para agilizar gastos recurrentes del mismo cultivo.
  final String? lastCropId;

  static const _clearLastCrop = Object();

  const FarmSettings({
    this.farmName = 'Mi Caferin',
    this.currency = 'COP',
    this.locale = 'es_CO',
    this.language = 'es',
    this.lastCropId,
  });

  FarmSettings copyWith({
    String? farmName,
    String? currency,
    String? locale,
    String? language,
    Object? lastCropId = _clearLastCrop,
  }) {
    return FarmSettings(
      farmName: farmName ?? this.farmName,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      language: language ?? this.language,
      lastCropId: lastCropId == _clearLastCrop
          ? this.lastCropId
          : lastCropId as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'farm_name': farmName,
        'currency': currency,
        'locale': locale,
        'language': language,
        if (lastCropId != null) 'last_crop_id': lastCropId,
      };

  factory FarmSettings.fromJson(Map<String, dynamic> json) {
    return FarmSettings(
      farmName: (json['farm_name'] as String?) ?? 'Mi Caferin',
      currency: (json['currency'] as String?) ?? 'COP',
      locale: (json['locale'] as String?) ?? 'es_CO',
      language: (json['language'] as String?) ?? 'es',
      lastCropId: (json['last_crop_id'] as String?),
    );
  }
}