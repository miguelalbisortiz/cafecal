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

/// Unidades cuyo peso no es fijo: lo pone el productor en cada registro.
///
/// Un racimo de plátano y un cajón de cereza pesan distinto según el producto
/// y el día. Contarlos como 1 kg era una mentira que ensuciaba kg/ha,
/// kg/planta, costo por kilo y las exportaciones.
const Set<String> kUnitsNeedingWeight = {'racimo', 'cajon'};

/// ¿La unidad necesita que el productor escriba el peso total?
bool unitNeedsWeight(String? unit) => kUnitsNeedingWeight.contains(unit);

/// Kilos de un registro, o `null` si no se pueden saber sin inventar.
///
/// Es el **único** camino para convertir una cantidad a kilos cuando va a un
/// total. [unitToKg] sigue existiendo para las unidades con factor, pero
/// `racimo` y `cajon` caen ahí en `_ => 1` y valdrían 1 kg.
///
/// - Unidades con factor (`kg`, `lb`, `arroba`, `saco`, `carga`): cantidad ×
///   factor.
/// - Unidades con peso variable (`racimo`, `cajon`): el [totalKg] que escribió
///   el productor. Si falta o no es positivo, `null` — nunca 1 por unidad.
///
/// `null` significa «no entra a los totales»: el llamador decide si lo cuenta
/// como pendiente de peso (ver la lista de «sin peso»).
double? kgFromUnit(
  double amount,
  String? unit,
  double? totalKg, {
  double sacoKg = kSacoKgPorDefecto,
}) {
  if (unitNeedsWeight(unit)) {
    if (totalKg == null || totalKg <= 0) return null;
    return totalKg;
  }
  return amount * unitToKg(unit, sacoKg: sacoKg);
}

/// Conversión de kilogramos a cargas.
/// 1 carga ≈ 60 lbs ≈ 27.2155 kg (convención cafetera colombiana).
double kgToCargas(double kg) {
  if (kg <= 0) return 0;
  return double.parse((kg / 27.2155).toStringAsFixed(2));
}
