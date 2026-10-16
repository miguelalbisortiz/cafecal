import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/farm_alert.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/terreno.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/alert_service.dart';
import 'package:mi_cafetal/services/crop_totals.dart';

/// (b) · el gasto que sirve a varios cultivos va al lote y se reparte por
/// hectáreas — pero solo cuando TODOS los cultivos del lote tienen superficie
/// anotada. Si falta alguna, el gasto sale como fila propia "sin repartir":
/// repartir igual obligaría a ponerle 0 hectáreas a un cultivo, y eso es una
/// cifra que nadie midió.
///
/// Aquí se fija el criterio que comparten la pantalla, el PDF y el Excel:
/// [cropBreakdownRows] es la única fuente de los tres, y si alguno se separa
/// de este archivo dejarán de decir lo mismo.
void main() {
  const loteAlto = Terreno(id: 'l1', name: 'Lote Alto');
  const loteBajo = Terreno(id: 'l2', name: 'Lote Bajo');

  const cafe = Crop(
    id: 'cafe',
    name: 'Café',
    icon: '☕',
    color: '#6D4C41',
    areaHa: 1.2,
    terrenoId: 'l1',
  );
  const platano = Crop(
    id: 'plat',
    name: 'Plátano',
    icon: '🍌',
    color: '#8BC34A',
    areaHa: 0.8,
    terrenoId: 'l1',
  );
  // Del lote 2 y SIN hectáreas: para este cultivo no hay proporción posible.
  const maiz = Crop(
    id: 'maiz',
    name: 'Maíz',
    icon: '🌽',
    color: '#FBC02D',
    terrenoId: 'l2',
  );

  final dia = DateTime(2026, 6, 5);

  Transaction mov({
    required TransactionType type,
    required double amount,
    String category = 'jornal',
    String? cropId,
    String? terrenoId,
  }) =>
      Transaction(
        id: '${type.name}_$amount',
        type: type,
        category: category,
        amount: amount,
        cropId: cropId,
        terrenoId: terrenoId,
        date: dia,
        createdAt: dia,
      );

  Transaction gastoDeLote(double amount, [String lote = 'l1']) =>
      mov(type: TransactionType.expense, amount: amount, terrenoId: lote);

  Transaction gastoComun(double amount) =>
      mov(type: TransactionType.expense, amount: amount, category: 'luz');

  List<CropBreakdownRow> desglose(
    List<Transaction> records, {
    List<Crop> crops = const [cafe, platano],
  }) =>
      cropBreakdownRows(
        records: records,
        crops: crops,
        terrenos: const [loteAlto, loteBajo],
        unspecifiedName: 'Costos comunes',
        loteNoRepartidoName: (n) => '$n · sin repartir',
      );

  CropBreakdownRow fila(List<CropBreakdownRow> rows, String id) =>
      rows.firstWhere((r) => r.cropId == id);

  group('(b) reparto por hectáreas', () {
    test('el gasto del lote se divide en proporción a la superficie', () {
      // 1,2 ha de café y 0,8 de plátano en un lote de 2: 60/40 de $100.000.
      final rows = desglose([gastoDeLote(100000)]);

      expect(fila(rows, 'cafe').expenses['COP'], closeTo(60000, 1e-9));
      expect(fila(rows, 'plat').expenses['COP'], closeTo(40000, 1e-9));
    });

    test('la suma de los trozos da exactamente el gasto, sin residuo', () {
      // 1,1 · 33333,33 · 0,1 son decimales que en binario no cierran solos:
      // el reparto por cociente dejaría la finca sumando unos centavos de más
      // o de menos, y el total dejaría de cuadrar.
      for (final m in [0.1, 1.1, 100000.0, 33333.33]) {
        final rows = desglose([gastoDeLote(m)]);
        final suma = fila(rows, 'cafe').expenses['COP']! +
            fila(rows, 'plat').expenses['COP']!;
        expect(suma, m, reason: 'con $m el reparto debe cerrar exacto en $m');
        expect(
          rows.any((r) => r.terrenoId != null),
          isFalse,
          reason: 'con todas las superficies anotadas no hay fila sin repartir',
        );
      }
    });

    test('los gastos de lote no se cuelan en Costos comunes', () {
      final rows = desglose([
        gastoDeLote(100000),
        gastoComun(5000),
      ]);

      final comunes =
          rows.singleWhere((r) => r.cropId == null && r.terrenoId == null);
      expect(comunes.expenses['COP'], 5000,
          reason: 'un gasto de lote no es de la finca entera');
      expect(
        rows.fold<double>(0, (a, r) => a + r.expensesTotal),
        105000,
        reason: 'el total de la finca no se mueve con el reparto',
      );
    });

    test('los gastos que suma la fila son los que aporta: nada se cuenta dos veces',
        () {
      final rows = desglose([gastoDeLote(100000)]);

      for (final r in rows) {
        final suma = r.expenseTxs.fold<double>(0, (a, t) => a + t.amount);
        expect(suma, r.expensesTotal,
            reason: '${r.name}: inversión + operación debe dar lo pintado');
      }
      expect(
        fila(rows, 'cafe').expenseTxs.single.amount +
            fila(rows, 'plat').expenseTxs.single.amount,
        100000,
        reason: 'el mismo jornal no aparece entero en los dos cultivos',
      );
    });

    test('la fila del cultivo cuenta los movimientos que la forman', () {
      final rows = desglose([gastoDeLote(100000), gastoComun(5000)]);

      expect(fila(rows, 'cafe').count, 1,
          reason: 'aporta el gasto de lote, no los comunes');
      expect(fila(rows, 'cafe').expenses['COP'], closeTo(60000, 1e-9));
    });
  });

  group('(b) cuando no se puede repartir', () {
    test('si a un cultivo del lote le falta la superficie, no se reparte', () {
      final rows = desglose([gastoDeLote(100000, 'l2')], crops: const [maiz]);

      final lote = rows.singleWhere((r) => r.terrenoId == 'l2');
      expect(lote.cropId, isNull);
      expect(lote.name, 'Lote Bajo · sin repartir');
      expect(lote.expenses['COP'], 100000,
          reason: 'el gasto entero va a la fila del lote');
      expect(fila(rows, 'maiz').expenses['COP'], isNull,
          reason: 'no se le pega un peso a un cultivo cuya superficie no se sabe');
    });

    test('la fila sin repartir va entre los cultivos y los comunes', () {
      final rows = desglose(
        [gastoDeLote(100000, 'l2'), gastoDeLote(1000), gastoComun(500)],
        crops: const [cafe, platano, maiz],
      );

      expect(rows.map((r) => r.name).toList(), [
        'Café',
        'Plátano',
        'Maíz',
        'Lote Bajo · sin repartir',
        'Costos comunes',
      ]);
    });
  });

  group('(b) exclusividad y límites', () {
    test('si un movimiento trae cultivo Y lote, manda el cultivo', () {
      final rows = desglose([
        mov(
          type: TransactionType.expense,
          amount: 10000,
          category: 'abono',
          cropId: 'cafe',
          terrenoId: 'l1',
        ),
      ]);

      expect(fila(rows, 'cafe').expenses['COP'], 10000);
      expect(rows.any((r) => r.terrenoId != null), isFalse,
          reason: 'contarlo dos veces sería doblar el peso en la finca');
    });

    test('un ingreso anotado al lote no se reparte por hectáreas', () {
      final rows = desglose([
        mov(
          type: TransactionType.income,
          amount: 90000,
          category: 'venta',
          terrenoId: 'l1',
        ),
      ]);

      final comunes =
          rows.singleWhere((r) => r.cropId == null && r.terrenoId == null);
      expect(comunes.incomes['COP'], 90000,
          reason: 'un cobro no es proporcional a la superficie');
      expect(fila(rows, 'cafe').incomes['COP'], isNull);
    });
  });

  group('Transaction.terrenoId', () {
    Transaction base({String? cropId, String? terrenoId}) => mov(
          type: TransactionType.expense,
          amount: 800,
          cropId: cropId,
          terrenoId: terrenoId,
        );

    test('sobrevive al respaldo local', () {
      final back = Transaction.fromJson(base(terrenoId: 'l1').toJson());
      expect(back.terrenoId, 'l1');
    });

    test('los respaldos viejos sin la clave quedan en null', () {
      final viejo = Map<String, dynamic>.from(base(cropId: 'cafe').toJson())
        ..remove('terreno_id');
      expect(Transaction.fromJson(viejo).terrenoId, isNull,
          reason: 'nada de lo anterior cambia de significado');
    });

    test('copyWith lo pone y lo borra de verdad', () {
      final t = base();
      final con = t.copyWith(terrenoId: 'l1');
      expect(con.terrenoId, 'l1');
      expect(t.terrenoId, isNull, reason: 'copyWith no toca el original');
      expect(con.copyWith(terrenoId: null).terrenoId, isNull,
          reason: 'sin centinela no se podría desvincular el gasto del lote');
    });

    test('los gastos viejos quedan sin lote, igual que siempre', () {
      expect(base(cropId: 'cafe').terrenoId, isNull);
      expect(base().terrenoId, isNull);
    });
  });

  group('(b) la alerta de ROI usa el MISMO reparto', () {
    final es = stringsFor('es');
    List<FarmAlert> alertas(List<Transaction> txns, List<Crop> crops) =>
        AlertService(now: DateTime(2026, 10, 16)).evaluate(txns, crops, es);

    test('la porción del lote pesa en el ROI de cada cultivo', () {
      final ids =
          alertas([gastoDeLote(100000)], [cafe, platano]).map((a) => a.id);

      expect(ids, containsAll(['deficit_cafe', 'deficit_plat']),
          reason: 'el gasto del lote le toca a los dos: los dos invirtieron');
      expect(ids.where((i) => i.startsWith('deficit_')).length, 2);
    });

    test('la porción recién recibida todavía no acusa en rojo', () {
      final ids = alertas([gastoDeLote(100000)], [cafe, platano])
          .where((a) => a.rule == AlertRule.deficitCrop);

      for (final a in ids) {
        expect(a.severity, AlertSeverity.info,
            reason: 'sin cosecha registrada es inversión, no pérdida');
      }
    });

    test('quien ya cosechó y sigue sin recuperar sí sale en rojo', () {
      final harvests = [
        Harvest(id: 'h1', cropId: 'cafe', date: DateTime(2026, 5, 20), amount: 3),
      ];
      final alerts = AlertService(now: DateTime(2026, 10, 16))
          .evaluate([gastoDeLote(100000)], [cafe, platano], es,
              harvests: harvests);

      expect(alerts.firstWhere((a) => a.id == 'deficit_cafe').severity,
          AlertSeverity.danger);
      expect(alerts.firstWhere((a) => a.id == 'deficit_plat').severity,
          AlertSeverity.info,
          reason: 'el plátano no ha cosechado nada todavía');
    });

    test('un gasto de lote no es un gasto "sin cultivo asignado"', () {
      final ids = alertas(
        [gastoDeLote(100000), gastoComun(10000)],
        [cafe, platano],
      ).map((a) => a.id);

      expect(ids, contains('deficit_null'),
          reason: 'los 10.000 comunes sí siguen sin etiquetar');
      // El de lote ya está puesto en su terreno: no cuenta como movimiento
      // abandonado, aunque no se haya podido repartir.
      expect(ids.where((i) => i == 'deficit_null').length, 1);
    });

    test('si el lote no se puede repartir, la alerta no juzga nada', () {
      final ids = alertas([gastoDeLote(100000, 'l2')], [maiz])
          .map((a) => a.id)
          .where((i) => i.startsWith('deficit_'));

      expect(ids, isEmpty,
          reason: 'repartir a ojo sería peor: el dinero queda en su lote');
    });

    test('el reparto de las alertas es la MISMA regla que el desglose', () {
      // Si las dos hicieran lo suyo, el café podría verse rentable en
      // Reportes y en pérdida en "Qué hacer". Comparten [repartoPorHectareas].
      final gasto = gastoDeLote(100000);
      final rows = desglose([gasto]);
      final alerts = alertas([gasto], [cafe, platano]);

      expect(alerts.any((a) => a.id == 'deficit_cafe'), isTrue);
      expect(fila(rows, 'cafe').expenses['COP'], closeTo(60000, 1e-9));
    });
  });
}
