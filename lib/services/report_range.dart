import 'package:flutter/material.dart' show DateTimeRange;

import '../models/report_period.dart';
import 'week_utils.dart';

/// Ventana de fechas del período elegido en Reportes.
///
/// Una sola definición para la pantalla y para los dos exportadores: la
/// tarjeta de aporte por producto y el PDF/Excel no pueden recortar días
/// distintos del mismo período.
///
/// En [ReportPeriod.week] la semana es ISO y puede cruzar de año, así que la
/// ventana no se recorta al año elegido.
DateTimeRange reportPeriodRange({
  required ReportPeriod period,
  required int year,
  int? month,
  int? week,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  switch (period) {
    case ReportPeriod.week:
      return weekRange(year, week ?? month ?? 1);
    case ReportPeriod.month:
      final m = month ?? today.month;
      return DateTimeRange(
        start: DateTime(year, m, 1),
        end: DateTime(year, m + 1, 0, 23, 59, 59, 999),
      );
    case ReportPeriod.year:
      return DateTimeRange(
        start: DateTime(year, 1, 1),
        end: DateTime(year, 12, 31, 23, 59, 59, 999),
      );
    case ReportPeriod.yearToDate:
      final end = year < today.year ? DateTime(year, 12, 31) : today;
      return DateTimeRange(
        start: DateTime(year, 1, 1),
        end: DateTime(end.year, end.month, end.day, 23, 59, 59, 999),
      );
  }
}
