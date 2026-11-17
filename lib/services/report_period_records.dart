import '../models/report_period.dart';
import '../models/transaction.dart';
import 'week_utils.dart';

/// Selección de registros del período. Regla compartida por Reportes, PDF y
/// Excel: si los tres pintadores derivan el período por separado, tarde o
/// temprano uno se queda atrás y el informe compartido dice otra cosa.
///
/// [month] es el número de semana cuando [period] es [ReportPeriod.week] y el
/// número de mes cuando es [ReportPeriod.month]. Los registros borrados nunca
/// cuentan. [now] solo existe para fijar el "hoy" en los tests.
List<Transaction> recordsForPeriod({
  required Iterable<Transaction> transactions,
  required ReportPeriod period,
  required int year,
  int? month,
  DateTime? now,
}) {
  final active = transactions.where((t) => !t.deleted).toList();
  final today = now ?? DateTime.now();
  return switch (period) {
    ReportPeriod.week => () {
        final range = weekRange(year, month ?? 1);
        return active
            .where((t) => !t.date.isBefore(range.start) &&
                !t.date.isAfter(range.end))
            .toList();
      }(),
    ReportPeriod.month => active
        .where((t) => t.date.year == year && t.date.month == (month ?? today.month))
        .toList(),
    ReportPeriod.year => active.where((t) => t.date.year == year).toList(),
    ReportPeriod.yearToDate => active
        .where((t) =>
            t.date.year == year &&
            !t.date.isAfter(year < today.year ? DateTime(year, 12, 31) : today))
        .toList(),
  };
}

/// Registros de la semana o mes anterior, que es lo que compara la conclusión
/// de tendencia. Para un período anual no hay "mes anterior": la conclusión
/// compara entonces los meses del año entre sí.
///
/// Misma regla que la pantalla usaba en `_previousMonthRecords` (semana ISO
/// previa, con el salto de diciembre; mes calendario anterior).
List<Transaction> previousMonthRecordsForPeriod({
  required Iterable<Transaction> transactions,
  required ReportPeriod period,
  required int year,
  int? month,
}) {
  final active = transactions.where((t) => !t.deleted).toList();
  if (period == ReportPeriod.week) {
    var previousWeek = (month ?? 1) - 1;
    var previousYear = year;
    if (previousWeek < 1) {
      previousWeek = 52;
      previousYear--;
    }
    final range = weekRange(previousYear, previousWeek);
    return active
        .where((t) =>
            !t.date.isBefore(range.start) && !t.date.isAfter(range.end))
        .toList();
  }
  if (period != ReportPeriod.month) return const [];
  final m = month ?? DateTime.now().month;
  final previousYear = m == 1 ? year - 1 : year;
  final previousMonth = m == 1 ? 12 : m - 1;
  return active
      .where((t) =>
          t.date.year == previousYear && t.date.month == previousMonth)
      .toList();
}
