class FarmSettings {
  final String farmName;
  final String currency;
  final String locale;

  const FarmSettings({
    this.farmName = 'Mi Caferin',
    this.currency = 'COP',
    this.locale = 'es_CO',
  });

  FarmSettings copyWith({
    String? farmName,
    String? currency,
    String? locale,
  }) {
    return FarmSettings(
      farmName: farmName ?? this.farmName,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
    );
  }

  Map<String, dynamic> toJson() => {
        'farm_name': farmName,
        'currency': currency,
        'locale': locale,
      };

  factory FarmSettings.fromJson(Map<String, dynamic> json) {
    return FarmSettings(
      farmName: (json['farm_name'] as String?) ?? 'Mi Caferin',
      currency: (json['currency'] as String?) ?? 'COP',
      locale: (json['locale'] as String?) ?? 'es_CO',
    );
  }
}