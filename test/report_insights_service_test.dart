import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/report_insights_service.dart';
import 'package:mi_cafetal/utils/format.dart';

AppLocalizations get _es => stringsFor('es');

/// El formateador de la casa, el que inyecta la pantalla: con uno de mentira
/// (`'$' + round()`) el arnés no ve la notación que lee el agricultor.
String _money(double v) => formatAmount(v, currency: 'COP', locale: 'es_CO');

Transaction _txn({
  required TransactionType type,
  required double amount,
  required DateTime date,
  String category = 'otro',
  String? cropId,
  double? quantity,
  String? unit,
}) {
  return Transaction(
    id: '${type.name}_${amount}_${date.millisecondsSinceEpoch}',
    type: type,
    category: category,
    amount: amount,
    date: date,
    createdAt: DateTime(2026, 1, 1),
    cropId: cropId,
    quantity: quantity,
    unit: unit,
  );
}

void main() {
  final now = DateTime(2026, 6, 15);
  const service = ReportInsightsService();

  group('Bloque A — Balance y tendencia', () {
    test('mes con pérdida emite resultado negativo con margen', () {
      final current = [
        _txn(type: TransactionType.expense, amount: 1000, date: DateTime(2026, 6, 2)),
        _txn(type: TransactionType.income, amount: 400, date: DateTime(2026, 6, 5)),
      ];
      final insights = service.build(
        now: now,
        current: current,
        previousMonth: [],
        yearRecords: current,
        year: 2026,
        month: 6,
        l10n: _es,
        money: _money,
      );
      // P4: el insight debe usar el mismo nombre que la tarjeta
      // RESULTADO DEL PERÍODO.
      final bal = insights.firstWhere((i) => i.text.contains('Resultado del período'));
      expect(bal.tone, InsightTone.negative);
      expect(bal.text, contains('COP 600'));
      expect(bal.text, contains('-150%'));
    });

    test('compara contra el mes anterior cuando hay datos', () {
      final current = [
        _txn(type: TransactionType.income, amount: 5000, date: DateTime(2026, 6, 2)),
      ];
      final previous = [
        _txn(type: TransactionType.income, amount: 4000, date: DateTime(2026, 5, 2)),
      ];
      final insights = service.build(
        now: now,
        current: current,
        previousMonth: previous,
        yearRecords: [...current, ...previous],
        year: 2026,
        month: 6,
        l10n: _es,
        money: _money,
      );
      final vs = insights.firstWhere((i) => i.text.contains('Frente a Mayo'));
      expect(vs.text, contains('subieron 25%'));
    });

    test('sin ventas pero con gastos avisa', () {
      final current = [
        _txn(type: TransactionType.expense, amount: 700, date: DateTime(2026, 6, 2)),
      ];
      final insights = service.build(
        now: now,
        current: current,
        previousMonth: [],
        yearRecords: current,
        year: 2026,
        month: 6,
        l10n: _es,
        money: _money,
      );
      expect(
        insights.any((i) =>
            i.text.startsWith('Resultado del período') &&
            i.text.contains('ninguna venta')),
        isTrue,
        reason: 'sin ventas debe avisarlo usando la etiqueta canónica del '
            'resultado (P4)',
      );
    });
  });

  group('B1 · misma ventana de días', () {
    test('recorta el mes anterior al día de hoy antes de comparar', () {
      // now = 15 de junio: el gasto del 20 de mayo queda fuera del tramo.
      final current = [
        _txn(
            type: TransactionType.expense,
            amount: 1000,
            date: DateTime(2026, 6, 2)),
      ];
      final previous = [
        _txn(
            type: TransactionType.expense,
            amount: 5000,
            date: DateTime(2026, 5, 20)),
      ];
      final insights = service.build(
        now: now,
        current: current,
        previousMonth: previous,
        yearRecords: [...current, ...previous],
        year: 2026,
        month: 6,
        l10n: _es,
        money: _money,
      );

      expect(
        insights.any((i) => i.text.contains('Frente a')),
        isFalse,
        reason: 'sin datos del mismo tramo no se emite comparación',
      );
    });

    test('viendo el mes en curso la frase aclara que es el mismo tramo', () {
      final current = [
        _txn(
            type: TransactionType.income,
            amount: 5000,
            date: DateTime(2026, 6, 2)),
      ];
      final previous = [
        _txn(
            type: TransactionType.income,
            amount: 4000,
            date: DateTime(2026, 5, 10)),
      ];
      final insights = service.build(
        now: now,
        current: current,
        previousMonth: previous,
        yearRecords: [...current, ...previous],
        year: 2026,
        month: 6,
        l10n: _es,
        money: _money,
      );

      final vs = insights.firstWhere((i) => i.text.contains('Frente a Mayo'));
      expect(vs.text, contains('mismos días'));
      expect(vs.text, contains('subieron 25%'));
    });

    test('un mes ya cerrado se compara entero y sin el aviso', () {
      final current = [
        _txn(
            type: TransactionType.income,
            amount: 5000,
            date: DateTime(2026, 5, 30)),
      ];
      final previous = [
        _txn(
            type: TransactionType.income,
            amount: 4000,
            date: DateTime(2026, 4, 25)),
      ];
      final insights = service.build(
        now: now, // 15 de junio: mirando mayo, mes ya cerrado
        current: current,
        previousMonth: previous,
        yearRecords: [...current, ...previous],
        year: 2026,
        month: 5,
        l10n: _es,
        money: _money,
      );

      final vs = insights.firstWhere((i) => i.text.contains('Frente a Abril'));
      expect(vs.text, isNot(contains('mismos días')));
      expect(vs.text, contains('subieron 25%'));
    });
  });

  group('Bloque B — Mayor gasto', () {
    test('cita la categoría tope con porcentaje y dependencia > 50%', () {
      final current = [
        _txn(type: TransactionType.expense, amount: 600, date: DateTime(2026, 6, 1), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 300, date: DateTime(2026, 6, 2), category: 'transporte'),
      ];
      final insights = service.build(
        now: now,
        current: current,
        previousMonth: [],
        yearRecords: current,
        year: 2026,
        month: 6,
        l10n: _es,
        money: _money,
      );
      final top = insights.firstWhere((i) => i.text.contains('Tu mayor gasto'));
      expect(top.text, contains('Mano de obra'));
      expect(top.text, contains('67%'));
      expect(
        insights.any((i) => i.text.contains('Concentras más de la mitad')),
        isTrue,
      );
    });
  });

  group('Bloque C — Ventas', () {
    test('detecta venta promedio reciente menor al histórico', () {
      // Con kilo anotado sí hay precio por kilo que comparar.
      final year = [
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 1, 10), category: 'venta_cafe', quantity: 1, unit: 'kg'),
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 2, 10), category: 'venta_cafe', quantity: 1, unit: 'kg'),
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 3, 10), category: 'venta_cafe', quantity: 1, unit: 'kg'),
        _txn(type: TransactionType.income, amount: 400, date: DateTime(2026, 6, 1), category: 'venta_cafe', quantity: 1, unit: 'kg'),
        _txn(type: TransactionType.income, amount: 400, date: DateTime(2026, 6, 8), category: 'venta_cafe', quantity: 1, unit: 'kg'),
      ];
      final insights = service.build(
        now: now,
        current: year.where((t) => t.date.month == 6).toList(),
        previousMonth: const [],
        yearRecords: year,
        year: 2026,
        month: 6,
        l10n: _es,
        money: _money,
      );
      expect(
        insights.any((i) => i.text.contains('Vendes más barato')),
        isTrue,
      );
      // La cifra es precio por kilo, no monto por venta.
      final low = insights.firstWhere((i) => i.text.contains('Vendes más barato'));
      expect(low.text, contains('por kilo'));
    });

    test('el precio por kilo se lee como en la alerta, no como un double', () {
      // La alerta de Inicio cita ese mismo precio por kilo (Regla 4): si aquí
      // saliera "400.0" serían dos notaciones para el mismo dato, y la fea
      // —un número de máquina— sería la que lee el agricultor en Reportes.
      final year = [
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 1, 10), category: 'venta_cafe', quantity: 1, unit: 'kg'),
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 2, 10), category: 'venta_cafe', quantity: 1, unit: 'kg'),
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 3, 10), category: 'venta_cafe', quantity: 1, unit: 'kg'),
        _txn(type: TransactionType.income, amount: 400, date: DateTime(2026, 6, 1), category: 'venta_cafe', quantity: 1, unit: 'kg'),
        _txn(type: TransactionType.income, amount: 400, date: DateTime(2026, 6, 8), category: 'venta_cafe', quantity: 1, unit: 'kg'),
      ];
      final insights = service.build(
        now: now,
        current: year.where((t) => t.date.month == 6).toList(),
        previousMonth: const [],
        yearRecords: year,
        year: 2026,
        month: 6,
        l10n: _es,
        money: _money,
      );
      final low = insights.firstWhere((i) => i.text.contains('Vendes más barato'));
      expect(low.text, contains('promedio reciente COP 400'),
          reason: 'el precio reciente, con su código de moneda');
      expect(low.text, contains('COP 760 por kilo'),
          reason: 'el histórico, con su código de moneda');
      expect(low.text, isNot(contains('.0')),
          reason: 'un double crudo no es una cifra que se lea');
    });

    test('sin kilos anotados no hay precio y el insight se calla', () {
      // Regla de oro: un "precio" calculado sin cantidad sería inventado.
      final year = [
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 1, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 2, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 3, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 400, date: DateTime(2026, 6, 1), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 400, date: DateTime(2026, 6, 8), category: 'venta_cafe'),
      ];
      final insights = service.build(
        now: now,
        current: year.where((t) => t.date.month == 6).toList(),
        previousMonth: const [],
        yearRecords: year,
        year: 2026,
        month: 6,
        l10n: _es,
        money: _money,
      );
      expect(insights.any((i) => i.text.contains('Vendes más barato')), isFalse);
    });

    test('la mayor venta cita el cultivo (Venta Plátano ≠ Venta Café)', () {
      final current = [
        _txn(
            type: TransactionType.income,
            amount: 800,
            date: DateTime(2026, 6, 1),
            category: 'venta',
            cropId: 'p1'),
        _txn(
            type: TransactionType.income,
            amount: 300,
            date: DateTime(2026, 6, 2),
            category: 'venta',
            cropId: 'c1'),
      ];
      final insights = service.build(
        now: now,
        current: current,
        previousMonth: const [],
        yearRecords: current,
        year: 2026,
        month: 6,
        crops: const [
          Crop(id: 'p1', name: 'Plátano'),
          Crop(id: 'c1', name: 'Café'),
        ],
        l10n: _es,
        money: _money,
      );
      final top = insights.firstWhere((i) => i.text.contains('COP 800'));
      expect(top.text, contains('Venta Plátano'));
    });

    test('las ventas con la clave nueva cuentan para el promedio', () {
      final year = [
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 1, 10), category: 'venta', quantity: 1, unit: 'kg'),
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 2, 10), category: 'venta', quantity: 1, unit: 'kg'),
        _txn(type: TransactionType.income, amount: 1000, date: DateTime(2026, 3, 10), category: 'venta', quantity: 1, unit: 'kg'),
        _txn(type: TransactionType.income, amount: 400, date: DateTime(2026, 6, 1), category: 'venta', quantity: 1, unit: 'kg'),
        _txn(type: TransactionType.income, amount: 400, date: DateTime(2026, 6, 8), category: 'venta', quantity: 1, unit: 'kg'),
      ];
      final insights = service.build(
        now: now,
        current: year.where((t) => t.date.month == 6).toList(),
        previousMonth: const [],
        yearRecords: year,
        year: 2026,
        month: 6,
        l10n: _es,
        money: _money,
      );
      expect(
        insights.any((i) => i.text.contains('Vendes más barato')),
        isTrue,
      );
    });
  });

  group('Bloque D — Comparación temporal', () {
    final year = [
      _txn(type: TransactionType.income, amount: 9000, date: DateTime(2026, 3, 10), category: 'venta_cafe'),
      _txn(type: TransactionType.expense, amount: 1000, date: DateTime(2026, 3, 11)),
      _txn(type: TransactionType.income, amount: 3000, date: DateTime(2026, 5, 10), category: 'venta_cafe'),
      _txn(type: TransactionType.expense, amount: 4000, date: DateTime(2026, 5, 11)),
    ];

    test('en el reporte del año cita el mejor mes y el de menor gasto', () {
      final insights = service.build(
        now: now,
        current: year,
        previousMonth: const [],
        yearRecords: year,
        year: 2026,
        month: null,
        l10n: _es,
        money: _money,
      );
      final best = insights.firstWhere((i) => i.text.contains('Tu mejor mes'));
      expect(best.text, contains('Marzo'));
      expect(best.text, contains('COP 9.000'));
      expect(best.text, contains('COP 1.000'));
    });

    test('mirando un mes no se emite: no sirve para decidir ese mes', () {
      final insights = service.build(
        now: now,
        current: year,
        previousMonth: const [],
        yearRecords: year,
        year: 2026,
        month: 6,
        l10n: _es,
        money: _money,
      );
      expect(
        insights.any((i) => i.text.contains('Tu mejor mes')),
        isFalse,
        reason: 'la comparación que decide es contra el periodo anterior, '
            'no contra otros meses del año',
      );
    });
  });

  test('sin actividad emite un solo aviso informativo', () {
    final insights = service.build(
      now: now,
      current: const [],
      previousMonth: const [],
      yearRecords: const [],
      year: 2026,
      month: 6,
      l10n: _es,
      money: _money,
    );
    expect(insights.single.tone, InsightTone.info);
    expect(insights.single.text, contains('No hay movimientos'));
  });
}