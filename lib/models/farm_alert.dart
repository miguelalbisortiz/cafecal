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
  deficitCrop;

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