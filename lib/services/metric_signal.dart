/// Señal bueno/malo de las métricas del reporte.
///
/// La señal nunca se comunica solo con color: la UI la acompaña siempre de un
/// icono de forma distinta y de una frase en lenguaje llano (ver
/// `_metricLine` en `report_screen.dart`). Esto es lo que exige el hallazgo
/// H10 del PRD de comprensibilidad (2026-10-01_2111).
enum MetricSignal { positive, neutral, negative, none }

/// Veredicto del margen sobre ventas.
enum MarginVerdict {
  /// Margen >= 20%.
  good,
  /// Margen entre 10% (incluido) y 20%.
  fair,
  /// Margen > 0% y < 10%.
  low,
  /// Margen < 0%: se vendió por debajo de lo que costó.
  loss,
  /// Margen exactamente 0%: ni ganancia ni pérdida.
  breakEven,
  /// No hubo ingresos en el período: no se puede calcular.
  noSales,
}

/// Veredicto de gastos vs ingresos. Menor es mejor: mide qué porcentaje de lo
/// que entra se va en gastos.
enum RatioVerdict {
  /// <= 70%.
  healthy,
  /// > 70% y <= 90%.
  high,
  /// > 90%.
  critical,
  /// No hubo ingresos en el período: no se puede calcular.
  noSales,
}

/// Umbrales de la línea "precio de venta por kilo vs costo por kilo" (P2,
/// aprobada el 2026-10-03). La pregunta que responde es simple: ¿vendo por
/// encima o por debajo de lo que me cuesta producir?
enum CostPriceVerdict {
  /// Precio > costo.
  above,

  /// Precio < costo: se vende por debajo de lo que costó.
  below,

  /// Precio == costo.
  equal,

  /// No se cosechó nada en el período: no hay costo que comparar.
  noCost,

  /// Las ventas no anotan kilos: no hay precio que comparar.
  noQty,
}

/// [costPerKg] y [pricePerKg] son `null` cuando no hay datos suficientes; un
/// `null` no es "mal", es "no se puede saber" y la UI lo dice con su propia
/// frase en vez de señalar en rojo algo que simplemente no existe.
CostPriceVerdict costPriceVerdict(double? costPerKg, double? pricePerKg) {
  if (costPerKg == null) return CostPriceVerdict.noCost;
  if (pricePerKg == null) return CostPriceVerdict.noQty;
  if (pricePerKg > costPerKg) return CostPriceVerdict.above;
  if (pricePerKg < costPerKg) return CostPriceVerdict.below;
  return CostPriceVerdict.equal;
}

MetricSignal signalOfCostPrice(CostPriceVerdict verdict) => switch (verdict) {
      CostPriceVerdict.above => MetricSignal.positive,
      CostPriceVerdict.below => MetricSignal.negative,
      CostPriceVerdict.equal => MetricSignal.neutral,
      CostPriceVerdict.noCost || CostPriceVerdict.noQty => MetricSignal.none,
    };

/// Umbrales aprobados el 2026-10-02 junto con el diseño de la Alternativa 1.
///
/// [marginPercent] es `((ingresos - gastos) / ingresos) * 100`, o `null`
/// cuando no hubo ingresos en el período.
MarginVerdict marginVerdict(double? marginPercent) {
  if (marginPercent == null) return MarginVerdict.noSales;
  if (marginPercent < 0) return MarginVerdict.loss;
  if (marginPercent == 0) return MarginVerdict.breakEven;
  if (marginPercent < 10) return MarginVerdict.low;
  if (marginPercent < 20) return MarginVerdict.fair;
  return MarginVerdict.good;
}

/// [ratioPercent] es `(gastos / ingresos) * 100`, o `null` sin ingresos.
RatioVerdict ratioVerdict(double? ratioPercent) {
  if (ratioPercent == null) return RatioVerdict.noSales;
  if (ratioPercent > 90) return RatioVerdict.critical;
  if (ratioPercent > 70) return RatioVerdict.high;
  return RatioVerdict.healthy;
}

MetricSignal signalOfMargin(MarginVerdict verdict) => switch (verdict) {
      MarginVerdict.good => MetricSignal.positive,
      MarginVerdict.fair => MetricSignal.neutral,
      MarginVerdict.loss || MarginVerdict.low => MetricSignal.negative,
      MarginVerdict.breakEven || MarginVerdict.noSales => MetricSignal.none,
    };

MetricSignal signalOfRatio(RatioVerdict verdict) => switch (verdict) {
      RatioVerdict.healthy => MetricSignal.positive,
      RatioVerdict.high => MetricSignal.neutral,
      RatioVerdict.critical => MetricSignal.negative,
      RatioVerdict.noSales => MetricSignal.none,
    };
