/// Peso de un saco **por defecto**, en kg. El estándar del café colombiano.
///
/// No lo uses directo: `FarmSettings.sacoKg` manda. Está aquí para que las
/// llamadas que no tienen settings (y los tests) mantengan el 70 de la norma.
const double kSacoKgPorDefecto = 70;

/// Conversión de una unidad a kilogramos.
///
/// [sacoKg] es configurable (A2): el saco de la norma pesa 70, pero en la
/// finca el costal puede pesar 60, y reportes, PDF y alertas tienen que usar
/// el peso real — por eso no está escrito a mano dentro del `switch`.
double unitToKg(String? unit, {double sacoKg = kSacoKgPorDefecto}) {
  return switch (unit) {
    'lb' => 0.453592,
    'arroba' => 12.5,
    'saco' => sacoKg,
    'carga' => 27.2155,
    _ => 1,
  };
}

/// Conversión de kilogramos a cargas.
/// 1 carga ≈ 60 lbs ≈ 27.2155 kg (convención cafetera colombiana).
double kgToCargas(double kg) {
  if (kg <= 0) return 0;
  return double.parse((kg / 27.2155).toStringAsFixed(2));
}
