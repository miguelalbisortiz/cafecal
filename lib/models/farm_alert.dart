import 'package:flutter/material.dart';

enum AlertSeverity {
  info,
  warning,
  danger;

  Color get color => switch (this) {
        AlertSeverity.info => const Color(0xFF1976D2),
        AlertSeverity.warning => const Color(0xFFF9A825),
        AlertSeverity.danger => const Color(0xFFD32F2F),
      };
}

enum AlertRule {
  excessiveSpending,
  noIncome,
  consecutiveLosses,
  lowPrice,
  deficitCrop,
  cropEstablishment,
  harvestVsSales,
  cropRecentlyPlanted,
  missingQuantity,
  cajaMenor,
  unpaidSales,
  // C7 · pasó la fecha de primera cosecha que él mismo estimó y no hay
  // ninguna cosecha registrada. Se apaga sola al primer cosecha o a los
  // 12 meses de la fecha (no existe descarte de alertas en la app).
  firstHarvestOverdue,
  // Fase 3 · el precio medio del estado en que vende no cubre el costo real
  // por kg vendible (margen < 10%; en rojo si es negativo).
  realCostVsPrice,
  // Tanda 3 · hito 1: aviso de stock por cultivo. No lo emite `evaluateAlerts`; las
  // filas se appendan en los tres pintadores después de `derive`.
  unsoldStock,
  // Tanda 3 · hito 2: margen por cultivo y por hectárea en una sola fila.
  // Tampoco lo emite `evaluateAlerts`: la fila se appenda tras `derive`.
  cropMargin,
  // Tanda 3 · hito 3: comprador que concentra >50 % de las ventas. Igual que
  // en los hitos 1 y 2, `evaluateAlerts` no lo emite: la fila se appenda.
  buyerConcentration;

  String get key => name;
}

class FarmAlert {
  final String id;
  final AlertRule rule;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String suggestion;

  const FarmAlert({
    required this.id,
    required this.rule,
    required this.severity,
    required this.title,
    required this.message,
    this.suggestion = '',
  });
}