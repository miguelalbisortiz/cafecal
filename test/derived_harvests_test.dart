import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/derived_harvests.dart';

/// La cosecha **se deduce de la venta que él ya anotó**.
///
/// Estos tests son la contra-memoria de las cinco decisiones del plan
/// 2026-10-15, las que son fáciles de romper sin darse cuenta:
///
/// * **D1** — se calcula al leer: no escribe nada y no toca sus entradas.
/// * **D2** — si el cultivo ya tiene cosecha anotada a mano, **esa manda**:
///   derivar encima sería doble-contar kilos.
/// * **D4** — la identidad lleva la fuente (`der_venta_`), para que una
///   futura fuente independiente (jornal) se pueda distinguir sin tocar nada.
/// * **D5** — `hasIndependentHarvest` es lo que decide si la tarjeta
///   «vendido vs cosechado» puede mostrarse: con solo datos de venta sería
///   comparar un número consigo mismo.
///
/// Y la regla de oro entera: **`null` → oculto, nunca un 0.** Una venta sin
/// kilos no produce una cosecha de cero kilos; produce *nada*.

final _now = DateTime(2026, 10, 15);

Transaction _venta({
  required String id,
  String? cropId = 'c1',
  double? quantity = 50,
  String? unit = 'kg',
  String category = kIncomeCategorySale,
  bool deleted = false,
  String? harvestId,
  DateTime? date,
}) =>
    Transaction(
      id: id,
      cropId: cropId,
      type: TransactionType.income,
      category: category,
      amount: 150000,
      currency: 'COP',
      date: date ?? _now,
      createdAt: DateTime(2026, 1, 1),
      deleted: deleted,
      quantity: quantity,
      unit: unit,
      harvestId: harvestId,
    );

Transaction _gasto({String id = 'g1', String? cropId = 'c1'}) =>
    Transaction(
      id: id,
      cropId: cropId,
      type: TransactionType.expense,
      category: 'fertilizante',
      amount: 5000,
      currency: 'COP',
      date: _now,
      createdAt: DateTime(2026, 1, 1),
      quantity: 999,
      unit: 'kg',
    );

Harvest _manual({String id = 'm1', String? cropId = 'c1'}) => Harvest(
      id: id,
      cropId: cropId,
      date: _now,
      amount: 40,
      unit: 'kg',
    );

List<Harvest> _derive({
  List<Transaction>? txns,
  List<Harvest>? manual,
}) =>
    deriveHarvests(
      transactions: txns ?? [_venta(id: 'v1')],
      manualHarvests: manual ?? const [],
    );

void main() {
  group('Derivar de la venta · lo que sí', () {
    test('una venta con cultivo y kilos da exactamente una cosecha', () {
      final out = _derive();
      expect(out, hasLength(1));

      final h = out.single;
      expect(h.id, 'der_venta_v1',
          reason: 'sintético y con la fuente a la vista (D4)');
      expect(h.cropId, 'c1');
      expect(h.amount, 50, reason: 'los kilos que él escribió, ni más ni menos');
      expect(h.unit, 'kg');
      expect(h.date, _now, reason: 'la fecha de la venta: no se inventa otra');
      expect(h.destination, HarvestDestination.vendido,
          reason: 'todo lo que se cosecha se vende');
      expect(h.workers, isNull);
      expect(h.equivalentKg, isNull);
    });

    test('dos ventas dan dos cosechas, una por cada venta', () {
      final out = _derive(txns: [
        _venta(id: 'v1', date: DateTime(2026, 9, 1)),
        _venta(id: 'v2', date: DateTime(2026, 10, 1), quantity: 30),
      ]);
      expect(out, hasLength(2));
      expect(out.map((h) => h.amount).toList(), [50, 30]);
    });

    test('una venta legada (venta_cafe) deriva igual que la nueva', () {
      final out = _derive(txns: [
        _venta(id: 'v1', category: 'venta_cafe'),
      ]);
      expect(out, hasLength(1),
          reason: 'las claves legadas siguen siendo ventas');
    });

    test('las unidades llegan tal cual: la regla 6 las convierte', () {
      final out = _derive(txns: [
        _venta(id: 'v1', quantity: 12, unit: 'saco'),
      ]);
      expect(out.single.unit, 'saco');
      expect(out.single.amount, 12);
    });
  });

  group('Derivar de la venta · lo que no', () {
    test('un gasto nunca deriva, aunque traiga kilos', () {
      expect(_derive(txns: [_gasto()]), isEmpty,
          reason: 'gastar no es cosechar');
    });

    test('un ingreso que no es venta no deriva', () {
      expect(_derive(txns: [_venta(id: 'v1', category: 'otro')]), isEmpty);
    });

    test('una venta borrada no deriva', () {
      expect(_derive(txns: [_venta(id: 'v1', deleted: true)]), isEmpty,
          reason: 'lo borrado no fue');
    });

    test('una venta sin cultivo no deriva', () {
      expect(_derive(txns: [_venta(id: 'v1', cropId: null)]), isEmpty,
          reason: 'sin cultivo no hay a quién atribuir ni fase que promover');
    });

    test('una venta sin kilos no deriva', () {
      expect(_derive(txns: [_venta(id: 'v1', quantity: null)]), isEmpty,
          reason: 'null → oculto; una cosecha de 0 kilos sería mentira');
    });

    test('kilos en cero o negativos no derivan', () {
      expect(_derive(txns: [_venta(id: 'a', quantity: 0)]), isEmpty);
      expect(_derive(txns: [_venta(id: 'b', quantity: -5)]), isEmpty);
    });

    test('una venta sin unidad no deriva', () {
      expect(_derive(txns: [_venta(id: 'v1', unit: null)]), isEmpty,
          reason: 'kilos sin unidad es un dato a medias');
    });

    test('una venta ya ligada a una cosecha viva no la duplica', () {
      final manual = [_manual(id: 'm9', cropId: 'c1')];
      final out = _derive(
        txns: [_venta(id: 'v1', harvestId: 'm9')],
        manual: manual,
      );
      expect(out, isEmpty,
          reason: 'la ligada es la cosecha manual, no otra derivada');
    });
  });

  group('D2 · manda la cosecha anotada a mano', () {
    test('cultivo con cosecha manual no deriva nada', () {
      final out = _derive(
        txns: [_venta(id: 'v1', cropId: 'cafe')],
        manual: [_manual(id: 'm1', cropId: 'cafe')],
      );
      expect(out, isEmpty,
          reason: 'ella ya midió: derivar encima doble-contaría los kilos');
    });

    test('la cosecha manual no se cuela en la salida', () {
      final out = _derive(
        txns: [_venta(id: 'v1', cropId: 'otro')],
        manual: [_manual(id: 'm1', cropId: 'cafe')],
      );
      expect(out, hasLength(1));
      expect(out.every((h) => h.id.startsWith(kSaleDerivedPrefix)), isTrue,
          reason: 'esta función solo calcula derivadas; el llamador concatena');
    });

    test('cada cultivo se decide por su cuenta', () {
      final out = _derive(
        txns: [
          _venta(id: 'vCafe', cropId: 'cafe'),
          _venta(id: 'vPlatano', cropId: 'platano'),
        ],
        manual: [_manual(id: 'm1', cropId: 'cafe')],
      );
      expect(out.single.id, 'der_venta_vPlatano',
          reason: 'café tiene cosecha propia; plátano no, y ese sigue midiendo');
    });

    test('una cosecha manual sin cultivo no frena a nadie', () {
      final out = _derive(
        txns: [_venta(id: 'v1', cropId: 'c1')],
        manual: [_manual(id: 'm1', cropId: null)],
      );
      expect(out, hasLength(1),
          reason: 'una cosecha suelta no atribuible no debe bloquear');
    });

    test('un cultivo con cosecha manual y ventas varias sigue mudo', () {
      final out = _derive(
        txns: [
          _venta(id: 'v1', cropId: 'cafe'),
          _venta(id: 'v2', cropId: 'cafe', quantity: 12),
          _venta(id: 'v3', cropId: 'cafe', quantity: 8),
        ],
        manual: [_manual(id: 'm1', cropId: 'cafe')],
      );
      expect(out, isEmpty);
    });
  });

  group('Enlace roto · se sana, no se ignora', () {
    test('venta ligada a una cosecha que ya no existe sí deriva', () {
      final out = _derive(txns: [
        _venta(id: 'v1', harvestId: 'm-borrada'),
      ]);
      expect(out, hasLength(1),
          reason: 'el enlace apunta a nada: dejar la venta sin contar sería '
              'perder datos, no ser conservador');
    });
  });

  group('D1 · se calcula al leer, no se guarda', () {
    test('devuelve una lista nueva, nunca la misma referencia', () {
      final txns = [_venta(id: 'v1')];
      final out = _derive(txns: txns);
      expect(identical(out, txns), isFalse);
    });

    test('no muta las listas que recibe', () {
      final txns = [_venta(id: 'v1'), _venta(id: 'v2', quantity: null)];
      final manual = [_manual(id: 'm1', cropId: 'c2')];
      final txnsLen = txns.length;
      final manualLen = manual.length;

      _derive(txns: txns, manual: manual);

      expect(txns, hasLength(txnsLen));
      expect(manual, hasLength(manualLen));
      expect(txns.first.quantity, 50, reason: 'nada se le toca');
    });

    test('jamás sale marcada para subir', () {
      expect(_derive().single.pendingSync, isFalse,
          reason: 'si subiera, el pull la reviviría como zombi');
    });

    test('dos llamadas seguidas dan el mismo resultado', () {
      final txns = [_venta(id: 'v1')];
      final a = _derive(txns: txns);
      final b = _derive(txns: txns);
      expect(a.single.id, b.single.id);
      expect(a.single.amount, b.single.amount);
    });
  });

  group('D4 / D5 · la fuente se distingue sin mirar adentro', () {
    test('isSaleDerivedHarvest marca solo las de la venta', () {
      expect(isSaleDerivedHarvest(_manual()), isFalse,
          reason: 'un uuid no parece de venta');
      expect(isSaleDerivedHarvest(_derive().single), isTrue);
    });

    test('sin cosechas, no hay medida independiente', () {
      expect(hasIndependentHarvest(const []), isFalse);
    });

    test('solo derivadas de venta → ninguna medida independiente', () {
      expect(hasIndependentHarvest(_derive()), isFalse,
          reason: 'la tarjeta «vendido vs cosechado» debe quedarse callada');
    });

    test('una cosecha manual la vuelve independiente', () {
      expect(
        hasIndependentHarvest([..._derive(), _manual()]),
        isTrue,
        reason: 'ahí sí hay una segunda medida que confrontar',
      );
    });

    test('una derivada de OTRA fuente también cuenta como independiente', () {
      // Simula lo que hará la Tanda 2: una cosecha derivada del jornal lleva
      // su propio prefijo, y como no es de venta, la tarjeta se enciende.
      final delJornal = Harvest(
        id: 'der_jornal_v1',
        cropId: 'c1',
        date: _now,
        amount: 50,
      );
      expect(isSaleDerivedHarvest(delJornal), isFalse);
      expect(hasIndependentHarvest([delJornal]), isTrue,
          reason: 'D4 deja la puerta lista: es un prefijo, no un rediseño');
    });
  });
}
