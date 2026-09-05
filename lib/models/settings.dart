class FarmSettings {
  final String farmName;
  final String currency;
  final String locale;
  final String language;

  const FarmSettings({
    this.farmName = 'Mi Caferin',
    this.currency = 'COP',
    this.locale = 'es_CO',
    this.language = 'es',
  });

  FarmSettings copyWith({
    String? farmName,
    String? currency,
    String? locale,
    String? language,
  }) {
    return FarmSettings(
      farmName: farmName ?? this.farmName,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() => {
        'farm_name': farmName,
        'currency': currency,
        'locale': locale,
        'language': language,
      };

  factory FarmSettings.fromJson(Map<String, dynamic> json) {
    return FarmSettings(
      farmName: (json['farm_name'] as String?) ?? 'Mi Caferin',
      currency: (json['currency'] as String?) ?? 'COP',
      locale: (json['locale'] as String?) ?? 'es_CO',
      language: (json['language'] as String?) ?? 'es',
    );
  }
}