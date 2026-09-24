import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/employee.dart';

void main() {
  group('Employee JSON', () {
    test('round-trip conserva id, nombre, dayRate y pendingSync', () {
      const original = Employee(
        id: 'e1',
        name: 'Juan Pérez',
        dayRate: 50000,
        pendingSync: true,
      );
      final restored = Employee.fromJson(original.toJson());
      expect(restored.id, 'e1');
      expect(restored.name, 'Juan Pérez');
      expect(restored.dayRate, 50000);
      expect(restored.pendingSync, isTrue);
    });

    test('retrocompat: JSON sin day_rate ni pending_sync', () {
      final legacy = Employee.fromJson({'id': 'e2', 'name': 'María'});
      expect(legacy.id, 'e2');
      expect(legacy.name, 'María');
      expect(legacy.dayRate, isNull);
      expect(legacy.pendingSync, isFalse);
    });

    test('sin dayRate el JSON no incluye la clave', () {
      const plain = Employee(id: 'e3', name: 'Ana');
      expect(plain.toJson().containsKey('day_rate'), isFalse);
      expect(plain.toJson()['pending_sync'], isFalse);
    });
  });

  group('Employee copyWith', () {
    test('conserva dayRate sin args y al cambiar otros campos', () {
      const original = Employee(id: 'e1', name: 'Juan', dayRate: 50000);
      expect(original.copyWith().dayRate, 50000);
      expect(original.copyWith(name: 'Pedro').dayRate, 50000);
      expect(original.copyWith(name: 'Pedro').name, 'Pedro');
    });

    test('puede limpiar dayRate a null', () {
      const original = Employee(id: 'e1', name: 'Juan', dayRate: 50000);
      final cleared = original.copyWith(dayRate: null);
      expect(cleared.dayRate, isNull);
      expect(cleared.name, original.name);
    });

    test('conserva pendingSync y permite limpiarlo', () {
      const original = Employee(id: 'e1', name: 'Juan', pendingSync: true);
      expect(original.copyWith(name: 'X').pendingSync, isTrue);
      expect(original.copyWith(pendingSync: false).pendingSync, isFalse);
    });
  });
}
