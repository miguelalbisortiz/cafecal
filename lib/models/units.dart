double unitToKg(String? unit) {
  return switch (unit) {
    'arroba' => 12.5,
    'saco' => 70,
    _ => 1,
  };
}

/// Conversión de kilogramos a cargas.
/// 1 carga ≈ 60 lbs ≈ 27.2155 kg (convención cafetera colombiana).
double kgToCargas(double kg) {
  if (kg <= 0) return 0;
  return double.parse((kg / 27.2155).toStringAsFixed(2));
}
