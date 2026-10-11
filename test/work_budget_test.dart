import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/farm_alert.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/alert_service.dart';
import 'package:mi_cafetal/services/backup_service.dart' show mergeBackupSettings;
import 'package:mi_cafetal/services/pdf_export_service.dart' show ReportPeriod;
import 'package:mi_cafetal/services/report_payroll_metrics.dart';

/// E3 · el presupuesto de obra separado de la caja menor.
///
/// Existe porque "gasté mucho en trabajadores" y "gasté mucho en
/// misceláneos" son señales opuestas: la primera dice que hubo producción,
/// la segunda que se escapó plata. Antes compartían una sola barra y al
/// 80 % no se sabía cuál de las dos había pasado.
///
/// **Opt-in**: mientras `presupuestoObraMensual` sea null, la caja menor se
/// comporta exactamente igual que siempre. Estos tests son sobre todo eso:
/// que nadie herede un cambio de comportamiento.

AppLocalizations get _es => stringsFor('es');

final _now = DateTime(2026, 10, 15);

Transaction _txn({
  required String category,
  required double amount,
  DateTime? date,
  String currency = 'COP',
}) =>
    Transaction(
      id: '${category}_${amount}_${date ?? _now.millisecondsSinceEpoch}_$currency',
      type: TransactionType.expense,
      category: category,
      amount: amount,
      currency: currency,
      date: date ?? _now,
      createdAt: DateTime(2026, 1, 1),
    );

List<FarmAlert> _alerts({
  required double? caja,
  required double? obra,
  List<Transaction>? txns,
}) =>
    AlertService(now: _now).evaluate(
      txns ?? [
        _txn(category: 'mano_obra', amount: 900),
        _txn(category: 'energia', amount: 100),
      ],
      const [],
      _es,
      cajaMensual: caja,
      workBudgetMensual: obra,
    );

void main() {
  group('Ajustes (E3)', () {
    test('el presupuesto de obra arranca vacío y el copyWith puede limpiarlo',
        () {
      const s = FarmSettings();
      expect(s.presupuestoObraMensual, isNull,
          reason: 'sin configurar: la caja mide lo de siempre');

      final set = s.copyWith(presupuestoObraMensual: 1000000);
      expect(set.presupuestoObraMensual, 1000000);

      // La sentinela es lo que permite VACIARLO: `??` no podría, y sin
      // poder vaciarlo no habría forma de volver al comportamiento anterior.
      final cleared = set.copyWith(presupuestoObraMensual: null);
      expect(cleared.presupuestoObraMensual, isNull);
      expect(set.presupuestoObraMensual, 1000000,
          reason: 'limpiar uno no toca el original');
    });

    test('un respaldo viejo no borra el presupuesto ya configurado aquí', () {
      const local = FarmSettings(presupuestoObraMensual: 500000);
      // Un respaldo anterior a E3 no trae la clave → null.
      const backup = FarmSettings();
      expect(backup.presupuestoObraMensual, isNull);

      expect(mergeBackupSettings(local, backup).presupuestoObraMensual, 500000,
          reason: 'restaurar un respaldo viejo no puede apagar la obra');
    });
  });

  group('Regla 12 · presupuesto de obra (E3)', () {
    test('sin presupuesto configurado no se evalúa', () {
      final alerts = _alerts(caja: 1000, obra: null);
      expect(alerts.where((a) => a.rule == AlertRule.workBudget), isEmpty,
          reason: 'opt-in: quien no lo pide no ve nada nuevo');
    });

    test('al 80% avisa como warning', () {
      final alerts = _alerts(caja: null, obra: 1000);
      final found =
          alerts.where((a) => a.rule == AlertRule.workBudget).toList();
      expect(found, hasLength(1));
      expect(found.single.severity, AlertSeverity.warning);
    });

    test('pasado el 100% sube a danger', () {
      final alerts = _alerts(
        caja: null,
        obra: 500,
        txns: [_txn(category: 'mano_obra', amount: 900)],
      );
      final found = alerts.firstWhere((a) => a.rule == AlertRule.workBudget);
      expect(found.severity, AlertSeverity.danger);
    });

    test('los misceláneos NO descuentan de la obra', () {
      final alerts = _alerts(
        caja: null,
        obra: 5000,
        txns: [
          _txn(category: 'mano_obra', amount: 100),
          _txn(category: 'energia', amount: 4900),
        ],
      );
      expect(alerts.where((a) => a.rule == AlertRule.workBudget), isEmpty,
          reason: 'la obra mide gente, no luz ni agua');
    });
  });

  group('La caja menor no cuenta la gente dos veces (E3)', () {
    test('SIN presupuesto de obra, la caja sigue midiendo jornales + extras',
        () {
      final alerts = _alerts(caja: 1000, obra: null);
      expect(alerts.any((a) => a.rule == AlertRule.cajaMenor), isTrue,
          reason: 'comportamiento de siempre, sin cambios');
    });

    test('CON presupuesto de obra, la caja deja de contar jornales', () {
      // 900 de jornal + 100 de luz. Con obra configurada, la caja solo ve
      // los 100 de luz → 10 % → no dispara.
      final alerts = _alerts(caja: 1000, obra: 5000);
      expect(alerts.where((a) => a.rule == AlertRule.cajaMenor), isEmpty,
          reason: 'el jornal ya está en su propia barra');
    });

    test('los misceláneos siguen vigilados por la caja', () {
      final alerts = _alerts(
        caja: 100,
        obra: 100000,
        txns: [_txn(category: 'energia', amount: 150)],
      );
      expect(alerts.any((a) => a.rule == AlertRule.cajaMenor), isTrue);
    });
  });

  group('Métricas compartidas (E3)', () {
    final txns = [
      _txn(category: 'mano_obra', amount: 800),
      _txn(category: 'energia', amount: 150),
    ];

    test('workBudgetByMonth solo suma mano de obra', () {
      final rows = const ReportPayrollMetrics().workBudgetByMonth(
        periodTx: txns,
        budget: 1000,
        period: ReportPeriod.month,
        year: 2026,
        month: 10,
        now: _now,
      );
      expect(rows, hasLength(1));
      expect(rows.first.used, 800);
      expect(rows.first.balance, 200);
    });

    test('cashBoxByMonth con includeLabor:false deja afuera los jornales', () {
      final rows = const ReportPayrollMetrics().cashBoxByMonth(
        periodTx: txns,
        budget: 1000,
        period: ReportPeriod.month,
        year: 2026,
        month: 10,
        now: _now,
        includeLabor: false,
      );
      expect(rows.first.labor, 0);
      expect(rows.first.extras, 150);
    });

    test('por defecto la caja sigue contando jornales + extras', () {
      final rows = const ReportPayrollMetrics().cashBoxByMonth(
        periodTx: txns,
        budget: 1000,
        period: ReportPeriod.month,
        year: 2026,
        month: 10,
        now: _now,
      );
      expect(rows.first.labor, 800,
          reason: 'sin tocar el parámetro, la caja es la de siempre');
      expect(rows.first.extras, 150);
      expect(rows.first.total, 950);
    });
  });
}
