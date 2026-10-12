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
  workBudget,
  // C7 · pasó la fecha de primera cosecha que él mismo estimó y no hay
  // ninguna cosecha registrada. Se apaga sola al primer cosecha o a los
  // 12 meses de la fecha (no existe descarte de alertas en la app).
  firstHarvestOverdue;

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