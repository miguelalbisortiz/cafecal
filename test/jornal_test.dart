import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/services/report_payroll_metrics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gasto de mano de obra con la misma forma que escribe el bloque jornal
/// de register_screen (total = días × valor día).
Transaction _jornal({
  required String provider,
  required double days,
  required double rate,
  required DateTime date,
  bool deleted = false,
}) =>
    Transaction(
      id: 'j_${provider}_${date.millisecondsSinceEpoch}',
      type: TransactionType.expense,
      category: 'mano_obra',
      amount: days * rate,
      quantity: days,
      unit: 'día',
      pricePerUnit: rate,
      provider: provider,
      date: date,
      createdAt: date,
      deleted: deleted,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bloque jornal — total y campos en la transacción', () {
    test('total = días × valor día y campos persisten en el store', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs);
      final tx = TransactionProvider(store);

      // Réplica del cálculo del formulario (register_screen._save).
      const days = 12.0;
      const rate = 50000.0;
      final t = await tx.addTransaction(
        type: TransactionType.expense,
        category: 'mano_obra',
        amount: days * rate,
        date: DateTime(2026, 6, 5),
        quantity: days,
        unit: 'día',
        pricePerUnit: rate,
        provider: 'Juan Pérez',
      );

      expect(t.amount, 600000);
      expect(t.quantity! * t.pricePerUnit!, t.amount,
          reason: 'el monto debe ser días × valor día');
      expect(t.quantity, 12);
      expect(t.unit, 'día');
      expect(t.pricePerUnit, 50000);
      expect(t.provider, 'Juan Pérez');
      expect(t.category, 'mano_obra');

      // Persistido con los campos intactos (clave para el historial).
      final saved = store.loadTransactions().single;
      expect(saved.amount, 600000);
      expect(saved.quantity, 12);
      expect(saved.unit, 'día');
      expect(saved.pricePerUnit, 50000);
      expect(saved.provider, 'Juan Pérez');
    });

    test('serialización conserva los campos del jornal', () {
      final t = _jornal(
        provider: 'María López',
        days: 6,
        rate: 45000,
        date: DateTime(2026, 6, 10),
      );
      final json = t.toJson();
      expect(json['quantity'], 6);
      expect(json['unit'], 'día');
      expect(json['price_per_unit'], 45000);
      expect(json['provider'], 'María López');

      final back = Transaction.fromJson(json);
      expect(back.quantity, 6);
      expect(back.unit, 'día');
      expect(back.pricePerUnit, 45000);
      expect(back.provider, 'María López');
      expect(back.amount, 270000);
    });
  });

  group('Payroll — empleados distintos del período', () {
    test('agrupa por trabajador, suma días y ordena por subtotal', () {
      final txns = [
        _jornal(
            provider: 'Juan',
            days: 12,
            rate: 50000,
            date: DateTime(2026, 6, 5)),
        _jornal(
            provider: 'Juan',
            days: 6,
            rate: 50000,
            date: DateTime(2026, 6, 12)),
        _jornal(
            provider: 'María',
            days: 8,
            rate: 50000,
            date: DateTime(2026, 6, 10)),
      ];
      final s = const ReportPayrollMetrics().payroll(txns);
      expect(s.rows, hasLength(2));
      expect(s.rows.first.provider, 'Juan', reason: 'orden por subtotal desc');
      final juan = s.rows.first;
      expect(juan.days, 18, reason: '12 + 6 días');
      expect(juan.subtotal, 900000);
      expect(s.total, 900000 + 400000);
      expect(s.distinctEmployees, 2);
    });

    test('empleados distintos solo cuenta nombres; el total incluye a todos',
        () {
      final txns = [
        _jornal(
            provider: 'Juan',
            days: 5,
            rate: 50000,
            date: DateTime(2026, 6, 5)),
        _jornal(
            provider: '  ', // sin nombre: entra al total, no a empleados
            days: 2,
            rate: 50000,
            date: DateTime(2026, 6, 6)),
        _jornal(
            provider: 'María',
            days: 3,
            rate: 50000,
            date: DateTime(2026, 6, 7)),
        // Mismo nombre con espacios → mismo trabajador.
        _jornal(
            provider: ' Juan ',
            days: 1,
            rate: 50000,
            date: DateTime(2026, 6, 8)),
      ];
      final s = const ReportPayrollMetrics().payroll(txns);
      expect(s.distinctEmployees, 2, reason: 'Juan y María');
      expect(s.rows, hasLength(3), reason: 'los sin nombre se agrupan aparte');
      final unnamed = s.rows.firstWhere((r) => r.provider.isEmpty);
      expect(unnamed.subtotal, 100000);
      final juan = s.rows.firstWhere((r) => r.provider == 'Juan');
      expect(juan.days, 6, reason: '5 + 1 (trim)');
      expect(s.total, 250000 + 100000 + 150000 + 50000,
          reason: '250k (Juan) + 100k (sin nombre) + 150k (María) + 50k');
    });

    test('ignora borrados, ingresos y otras categorías', () {
      final txns = [
        _jornal(
            provider: 'Juan',
            days: 5,
            rate: 50000,
            date: DateTime(2026, 6, 5)),
        _jornal(
            provider: 'Oculto',
            days: 5,
            rate: 50000,
            date: DateTime(2026, 6, 5),
            deleted: true),
        Transaction(
          id: 'ing',
          type: TransactionType.income,
          category: 'mano_obra',
          amount: 999999,
          date: DateTime(2026, 6, 6),
          createdAt: DateTime(2026, 6, 6),
          provider: 'NoCuenta',
        ),
        Transaction(
          id: 'fert',
          type: TransactionType.expense,
          category: 'fertilizante',
          amount: 888888,
          provider: 'Tampoco',
          date: DateTime(2026, 6, 7),
          createdAt: DateTime(2026, 6, 7),
        ),
      ];
      final s = const ReportPayrollMetrics().payroll(txns);
      expect(s.rows, hasLength(1));
      expect(s.rows.single.provider, 'Juan');
      expect(s.total, 250000);
      expect(s.distinctEmployees, 1);
    });

    test('sin gastos de mano de obra el resumen queda vacío', () {
      final txns = [
        Transaction(
          id: 'fert',
          type: TransactionType.expense,
          category: 'fertilizante',
          amount: 500000,
          date: DateTime(2026, 6, 5),
          createdAt: DateTime(2026, 6, 5),
        ),
      ];
      final s = const ReportPayrollMetrics().payroll(txns);
      expect(s.isEmpty, isTrue);
      expect(s.total, 0);
      expect(s.distinctEmployees, 0);
    });

    test('mano de obra sin campos de jornal cuenta con 0 días', () {
      final txns = [
        Transaction(
          id: 'mo',
          type: TransactionType.expense,
          category: 'mano_obra',
          amount: 300000,
          provider: 'Pedro',
          date: DateTime(2026, 6, 5),
          createdAt: DateTime(2026, 6, 5),
        ),
      ];
      final s = const ReportPayrollMetrics().payroll(txns);
      expect(s.rows.single.days, 0);
      expect(s.rows.single.subtotal, 300000);
      expect(s.distinctEmployees, 1);
    });
  });
}
