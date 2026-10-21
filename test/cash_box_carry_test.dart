import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/farm_alert.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/alert_service.dart';
import 'package:mi_cafetal/services/backup_service.dart'
    show mergeBackupSettings;
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/services/pdf_export_service.dart' show ReportPeriod;
import 'package:mi_cafetal/services/report_payroll_metrics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La caja es **un solo pote**: el aporte mensual cubre los jornales y los
/// gastos chicos, y lo que no se gasta se arrastra al mes siguiente.
///
/// Estos tests son la contra-memoria de tres reglas fáciles de romper:
/// 1. quien venía con dos montos (caja + obra) **no pierde presupuesto**;
/// 2. el sobrante es un **límite**, no dinero en mano — la liquidez la dice
///    el resultado acumulado;
/// 3. un mes que mezcla monedas **no** produce sobrante calculable.
///
/// El presupuesto de obra sigue existiendo en la BD y en las métricas
/// compartidas (PDF y Excel lo siguen imprimiendo); lo que cambió es que la
/// tarjeta y la alerta ya no lo tratan como un segundo pote.

AppLocalizations get _es => stringsFor('es');

final _now = DateTime(2026, 10, 15);

Transaction _txn({
  required String category,
  required double amount,
  DateTime? date,
  String currency = 'COP',
  TransactionType type = TransactionType.expense,
  bool deleted = false,
}) =>
    Transaction(
      id:
          '${category}_${amount}_${date?.millisecondsSinceEpoch ?? 0}_$currency',
      type: type,
      category: category,
      amount: amount,
      currency: currency,
      date: date ?? _now,
      createdAt: DateTime(2026, 1, 1),
      deleted: deleted,
    );

List<FarmAlert> _alerts({
  required double? caja,
  String currency = 'COP',
  List<Transaction>? txns,
}) =>
    AlertService(now: _now).evaluate(
      txns ??
          [
            _txn(category: 'mano_obra', amount: 900),
            _txn(category: 'energia', amount: 100),
          ],
      const [],
      _es,
      cajaMensual: caja,
      currency: currency,
    );

void main() {
  group('Ajustes · la obra ya va dentro de la caja', () {
    test('sin nada configurado no hay aporte', () {
      expect(const FarmSettings().cajaMensualEfectiva, isNull);
    });

    test('solo caja → ese es el aporte', () {
      expect(
        const FarmSettings(cajaMenorMensual: 600).cajaMensualEfectiva,
        600,
      );
    });

    test('solo obra → la caja igual existe', () {
      expect(
        const FarmSettings(presupuestoObraMensual: 500).cajaMensualEfectiva,
        500,
        reason: 'la plata se sacó igual: no desaparece porque falte otro monto',
      );
    });

    test('quien venía con los dos montos no pierde presupuesto', () {
      // El caso real de una cuenta vieja: caja 600 y obra 500. Debe seguir
      // viendo 1100, no 600.
      const s =
          FarmSettings(cajaMenorMensual: 600, presupuestoObraMensual: 500);
      expect(s.cajaMensualEfectiva, 1100);
    });

    test('los dos campos siguen existiendo por separado en el modelo', () {
      const s =
          FarmSettings(cajaMenorMensual: 600, presupuestoObraMensual: 500);
      expect(s.cajaMenorMensual, 600, reason: 'la BD no cambió');
      expect(s.presupuestoObraMensual, 500, reason: 'la BD no cambió');
    });

    test('al guardar ajustes la obra queda plegada y en null', () {
      const s =
          FarmSettings(cajaMenorMensual: 600, presupuestoObraMensual: 500);
      final saved =
          s.copyWith(cajaMenorMensual: 1100.0, presupuestoObraMensual: null);
      expect(saved.cajaMenorMensual, 1100);
      expect(saved.presupuestoObraMensual, isNull);
      expect(saved.cajaMensualEfectiva, 1100,
          reason: 'la suma no se dobla al releer');
    });

    test('un respaldo viejo no borra la obra ya configurada', () {
      const local = FarmSettings(presupuestoObraMensual: 500);
      const backup = FarmSettings();
      expect(mergeBackupSettings(local, backup).presupuestoObraMensual, 500);
    });
  });

  group('cashCarryUpTo · el sobrante se arrastra', () {
    double? carry(
      List<Transaction> txns, {
      int year = 2026,
      int month = 10,
      double budget = 600,
      String cur = 'COP',
    }) =>
        const ReportPayrollMetrics().cashCarryUpTo(
          allTx: txns,
          budget: budget,
          budgetCurrency: cur,
          year: year,
          month: month,
        );

    test('sin registros no hay sobrante (0, no null)', () {
      expect(carry(const []), 0,
          reason: '0 dice «no gasté nada», que es cierto');
    });

    test('lo que no se gasta en un mes se arrastra al siguiente', () {
      final txns = [
        _txn(category: 'energia', amount: 100, date: DateTime(2026, 9, 5)),
      ];
      // Septiembre: aporté 600, gasté 100 → sobran 500.
      expect(carry(txns), 500);
    });

    test('un mes sin anotar nada también aporta', () {
      final txns = [
        _txn(category: 'energia', amount: 100, date: DateTime(2026, 8, 5)),
      ];
      // Agosto sobran 500; septiembre no hubo gasto → +600. Total 1100.
      expect(carry(txns), 1100,
          reason: 'un mes mudo no es un mes en que el aporte desapareció');
    });

    test('no hay reinicio en enero', () {
      final txns = [
        _txn(category: 'energia', amount: 100, date: DateTime(2025, 11, 5)),
        _txn(category: 'energia', amount: 100, date: DateTime(2025, 12, 5)),
      ];
      // Nov y dic de 2025 sobran 500 cada uno; ene y feb de 2026 aportan
      // 600 cada uno. El año viejo no se borra.
      expect(carry(txns, year: 2026, month: 3), 500 + 500 + 600 + 600);
    });

    test('el mes en curso todavía no aporta', () {
      final txns = [
        _txn(category: 'energia', amount: 100, date: DateTime(2026, 9, 5)),
      ];
      // Preguntando por septiembre, septiembre no cuenta: el límite de ese
      // mes era el aporte solo.
      expect(carry(txns, year: 2026, month: 9), 0);
    });

    test('los borrados no descuentan', () {
      final txns = [
        _txn(category: 'energia', amount: 100, date: DateTime(2026, 8, 5)),
        _txn(
          category: 'energia',
          amount: 500,
          date: DateTime(2026, 9, 5),
          deleted: true,
        ),
      ];
      // Agosto sobran 500; septiembre solo tiene un gasto borrado, así que
      // aporta su mes entero.
      expect(carry(txns), 1100, reason: 'un gasto borrado no fue gasto');
    });

    test('los ingresos no mueven el sobrante', () {
      final txns = [
        _txn(
          category: 'cosecha',
          amount: 9999,
          date: DateTime(2026, 9, 5),
          type: TransactionType.income,
        ),
      ];
      expect(carry(txns), 600, reason: 'el aporte no es la cosecha');
    });

    test('un mes que mezcla monedas no produce sobrante', () {
      final txns = [
        _txn(category: 'energia', amount: 100, date: DateTime(2026, 9, 5)),
        _txn(
          category: 'agua',
          amount: 2,
          date: DateTime(2026, 9, 9),
          currency: 'USD',
        ),
      ];
      expect(
        carry(txns),
        isNull,
        reason: 'null dice «no lo sé»; un 0 diría «no gasté nada», mentira',
      );
    });

    test('la moneda del mes objetivo no arruina el sobrante', () {
      // El mes actual sí mezcla, pero el sobrante solo mira meses anteriores.
      final txns = [
        _txn(category: 'energia', amount: 100, date: DateTime(2026, 9, 5)),
        _txn(
          category: 'agua',
          amount: 2,
          date: DateTime(2026, 10, 9),
          currency: 'USD',
        ),
      ];
      expect(carry(txns), 500);
    });

    test('sin moneda configurada no se calcula', () {
      expect(carry(const [], cur: ''), isNull);
    });

    test('presupuesto cero no se calcula', () {
      expect(carry(const [], budget: 0), isNull);
    });
  });

  group('Regla 10 · la alerta mira el mismo límite que la tarjeta', () {
    test('jornales y extras juntos descuentan del aporte', () {
      final alerts = _alerts(caja: 1000);
      expect(alerts.any((a) => a.rule == AlertRule.cajaMenor), isTrue,
          reason: 'un solo pote: el jornal también cuenta');
    });

    test('con la obra plegada, el límite es la suma', () {
      // Obra 5000 + caja 1000 = 6000. Un jornal de 1000 es 17 %: nada.
      final alerts = _alerts(
        caja: 6000,
        txns: [_txn(category: 'mano_obra', amount: 1000)],
      );
      expect(alerts.where((a) => a.rule == AlertRule.cajaMenor), isEmpty,
          reason: 'la obra no se come el límite, lo agranda');
    });

    test('el sobrante agranda el límite y baja el aviso', () {
      // Septiembre aportó 1000 y solo gastó 400 → sobran 600. Octubre gasta
      // 1300: sobre el aporte solo sería 130 % (danger); con el sobrante el
      // límite es 1600 y el gasto es 81 % (warning). El aviso correcto.
      final alerts = _alerts(
        caja: 1000,
        txns: [
          _txn(category: 'energia', amount: 400, date: DateTime(2026, 9, 5)),
          _txn(category: 'mano_obra', amount: 1300),
        ],
      );
      final found = alerts.firstWhere((a) => a.rule == AlertRule.cajaMenor);
      expect(found.severity, AlertSeverity.warning,
          reason: 'con el sobrante todavía hay límite: no es agotamiento');
    });

    test('sin moneda configurada el límite vuelve al aporte solo', () {
      final alerts = _alerts(caja: 1000, currency: '');
      expect(alerts.any((a) => a.rule == AlertRule.cajaMenor), isTrue,
          reason: 'sin sobrante calculable no se silencia el aviso');
    });

    test('sin aporte configurado no se evalúa', () {
      final alerts = _alerts(caja: null);
      expect(alerts.where((a) => a.rule == AlertRule.cajaMenor), isEmpty);
    });
  });

  group('Métricas compartidas · PDF y Excel siguen intactos', () {
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

    test('por defecto la caja cuenta jornales + extras', () {
      final rows = const ReportPayrollMetrics().cashBoxByMonth(
        periodTx: txns,
        budget: 1000,
        period: ReportPeriod.month,
        year: 2026,
        month: 10,
        now: _now,
      );
      expect(rows.first.labor, 800);
      expect(rows.first.extras, 150);
      expect(rows.first.total, 950);
    });

    test('includeLabor:false sigue disponible para los exportadores', () {
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
  });

  group('Tanda 4 · el aporte rige desde que se configura', () {
    double? carryWithHistory(
      List<Transaction> txns, {
      Map<String, double> history = const {},
      double? budget = 600,
      int year = 2026,
      int month = 10,
    }) =>
        const ReportPayrollMetrics().cashCarryUpTo(
          allTx: txns,
          budget: budget,
          budgetHistory: history,
          budgetCurrency: 'COP',
          year: year,
          month: month,
        );

    test('cambiar el aporte hoy no reescribe los meses viejos', () {
      final txns = [
        _txn(category: 'energia', amount: 100, date: DateTime(2026, 9, 5)),
      ];
      // Septiembre: 600 → sobraron 500. Octubre: 900 (el nuevo).
      const history = {'2026-09': 600.0, '2026-10': 900.0};
      expect(carryWithHistory(txns, history: history, budget: 900), 500,
          reason: 'septiembre aportó 600: el cambio de octubre no lo alcanza');
    });

    test('los meses anteriores a la primera entrada no suman ni restan', () {
      final txns = [
        _txn(category: 'energia', amount: 100, date: DateTime(2026, 7, 5)),
      ];
      // El historial arranca en septiembre: julio no tenía caja, así que sus
      // 100 no se restan de un aporte que no existía.
      const history = {'2026-09': 600.0};
      expect(carryWithHistory(txns, history: history), 600,
          reason: 'solo septiembre aporta, y completo: julio no resta');
    });

    test('un mes sin aporte explícito (0) no suma', () {
      final txns = [
        _txn(category: 'energia', amount: 100, date: DateTime(2026, 9, 5)),
      ];
      const history = {'2026-09': 600.0, '2026-10': 0.0};
      expect(carryWithHistory(txns, history: history, budget: null), 500,
          reason: 'octubre no aporta, pero septiembre sí dejó 500');
    });

    test('sin historial manda el aporte único de siempre', () {
      final txns = [
        _txn(category: 'energia', amount: 100, date: DateTime(2026, 9, 5)),
      ];
      expect(carryWithHistory(txns), 500);
    });

    test('cada mes de la tabla usa su propio aporte', () {
      final txns = [
        _txn(category: 'energia', amount: 100, date: DateTime(2026, 9, 5)),
        _txn(category: 'energia', amount: 50, date: DateTime(2026, 10, 5)),
      ];
      final rows = const ReportPayrollMetrics().cashBoxByMonth(
        periodTx: txns,
        budget: 900,
        budgetHistory: const {'2026-09': 600.0, '2026-10': 900.0},
        period: ReportPeriod.yearToDate,
        year: 2026,
        month: 10,
        now: _now,
      );
      expect(rows.map((r) => r.budget), [600, 900]);
    });

    test('los meses anteriores al historial no se listan', () {
      final txns = [
        _txn(category: 'energia', amount: 100, date: DateTime(2026, 7, 5)),
        _txn(category: 'energia', amount: 100, date: DateTime(2026, 9, 5)),
      ];
      final rows = const ReportPayrollMetrics().cashBoxByMonth(
        periodTx: txns,
        budget: 600,
        budgetHistory: const {'2026-09': 600.0},
        period: ReportPeriod.yearToDate,
        year: 2026,
        month: 10,
        now: _now,
      );
      expect(rows.map((r) => r.month), [9, 10],
          reason: 'julio y agosto son anteriores a la primera entrada; '
              'octubre es el mes en curso y ya tiene aporte');
    });

    test('el historial se siembra al abrir la app por primera vez', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final p = TransactionProvider(LocalStore(prefs));
      await p.updateSettings(const FarmSettings(cajaMenorMensual: 1200000));

      // Al volver a abrir, el historial arranca este mes con lo configurado.
      final reabierto = TransactionProvider(LocalStore(prefs));
      final now = DateTime.now();
      expect(
        reabierto.settings.cashBudgetHistory[cashBudgetMonthKey(now)],
        1200000,
      );
      expect(reabierto.settings.cashBudgetHistory, hasLength(1));
    });

    test('un historial existente no se vuelve a sembrar', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final p = TransactionProvider(LocalStore(prefs));
      await p.updateSettings(const FarmSettings(
        cajaMenorMensual: 500,
        cashBudgetHistory: {'2026-01': 700},
      ));

      final reabierto = TransactionProvider(LocalStore(prefs));
      expect(reabierto.settings.cashBudgetHistory, {'2026-01': 700.0},
          reason: 'el pasado no se reescribe al abrir');
    });

    test('un respaldo con historial manda; uno sin historial no lo borra', () {
      const local = FarmSettings(cashBudgetHistory: {'2026-01': 600.0});
      const conHistorial =
          FarmSettings(cashBudgetHistory: {'2026-03': 900.0});
      const sinHistorial = FarmSettings();
      expect(mergeBackupSettings(local, conHistorial).cashBudgetHistory,
          {'2026-03': 900.0});
      expect(mergeBackupSettings(local, sinHistorial).cashBudgetHistory,
          {'2026-01': 600.0});
    });
  });
}
