import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/services/week_utils.dart';

void main() {
  group('weekRange', () {
    test('semana 38 de 2026 inicia el lunes 14 de septiembre', () {
      final range = weekRange(2026, 38);
      expect(range.start, DateTime(2026, 9, 14));
      expect(range.end, DateTime(2026, 9, 20, 23, 59, 59));
    });

    test('semana 1 de 2026 inicia el lunes 29 de diciembre de 2025', () {
      // La semana 1 de 2026 contiene el jueves 1 de enero
      final range = weekRange(2026, 1);
      expect(range.start.year, 2025);
      expect(range.start.month, 12);
      expect(range.start.day, 29);
    });

    test('semana 52 de 2025 inicia el lunes 22 de diciembre', () {
      final range = weekRange(2025, 52);
      expect(range.start, DateTime(2025, 12, 22));
      expect(range.end, DateTime(2025, 12, 28, 23, 59, 59));
    });

    test('currentWeekNumber devuelve un número entre 1 y 53', () {
      final now = DateTime.now();
      final week = currentWeekNumber(now);
      expect(week, greaterThanOrEqualTo(1));
      expect(week, lessThanOrEqualTo(53));
    });
  });
}
