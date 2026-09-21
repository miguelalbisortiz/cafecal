import 'package:flutter/material.dart';

/// Utilidades para calcular rangos de fechas por semana ISO.
/// Semana ISO: lunes a domingo, numerada 1-53.

/// Rango de fechas (lunes 00:00 → domingo 23:59:59) para una semana ISO.
DateTimeRange weekRange(int year, int week) {
  // El 4 de enero siempre está en la semana 1 de su año ISO.
  final jan4 = DateTime(year, 1, 4);
  final startOfWeek1 = jan4.subtract(Duration(days: jan4.weekday - 1));

  // Lunes de la semana deseada.
  final monday = startOfWeek1.add(Duration(days: (week - 1) * 7));
  final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

  return DateTimeRange(start: monday, end: sunday);
}

/// Número de semana ISO para una fecha dada.
int currentWeekNumber(DateTime date) {
  // Algoritmo ISO 8601: el 4 de enero siempre es semana 1.
  final jan4 = DateTime(date.year, 1, 4);
  final startOfFirstWeek = jan4.subtract(Duration(days: jan4.weekday - 1));
  if (date.isBefore(startOfFirstWeek)) {
    // Está en la semana 1 del año anterior.
    return currentWeekNumber(DateTime(date.year - 1, 12, 28));
  }
  final diff = date.difference(startOfFirstWeek).inDays;
  return (diff ~/ 7) + 1;
}

/// Rango de la semana actual (ISO).
DateTimeRange currentWeekRange() {
  final now = DateTime.now();
  return weekRange(now.year, currentWeekNumber(now));
}
