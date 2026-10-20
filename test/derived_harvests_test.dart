import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/tasks.dart';
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

/// Jornal de mano de obra con la misma forma que escribe `register_screen`:
/// `quantity` son días, `unit = 'día'` y los kilos viven aparte.
Transaction _jornal({
  required String id,
  String? cropId = 'c1',
  String? task = kTaskCosechar,
  double? harvestedKg = 500,
  double days = 2,
  double rate = 50000,
  bool deleted = false,
  DateTime? date,
}) =>
    Transaction(
      id: id,
      cropId: cropId,
      type: TransactionType.expense,
      category: 'mano_obra',
      amount: days * rate,
      currency: 'COP',
      date: date ?? _now,
      createdAt: DateTime(2026, 1, 1),
      deleted: deleted,
      quantity: days,
      unit: 'día',
      pricePerUnit: rate,
      task: task,
      harvestedKg: harvestedKg,
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

    test('una derivada del jornal también cuenta como independiente', () {
      final delJornal =
          _derive(txns: [_jornal(id: 'j1', harvestedKg: 50)]).single;
      expect(delJornal.id, 'der_jornal_j1');
      expect(isSaleDerivedHarvest(delJornal), isFalse);
      expect(hasIndependentHarvest([delJornal]), isTrue,
          reason: 'la medida del jornal es independiente de la venta');
      expect(delJornal.pendingSync, isFalse);
    });
  });

  group('Jornal · lo que sí', () {
    test('un jornal de Cosechar con kilos da exactamente una cosecha', () {
      final out = _derive(txns: [_jornal(id: 'j1')]);
      expect(out, hasLength(1));

      final h = out.single;
      expect(h.id, 'der_jornal_j1');
      expect(h.cropId, 'c1');
      expect(h.date, _now);
      expect(h.amount, 500);
      expect(h.unit, 'kg');
      expect(h.destination, HarvestDestination.vendido);
      expect(h.pendingSync, isFalse);
    });

    test('varios jornales medidos dan una cosecha por jornal', () {
      final out = _derive(txns: [
        _jornal(id: 'j1', harvestedKg: 500, date: DateTime(2026, 10, 1)),
        _jornal(id: 'j2', harvestedKg: 120, date: DateTime(2026, 10, 8)),
      ]);
      expect(out, hasLength(2));
      expect(out.map((h) => h.id), ['der_jornal_j1', 'der_jornal_j2']);
      expect(out.map((h) => h.amount), [500, 120]);
    });

    test('el id lleva el prefijo der_jornal_ y no es de venta', () {
      final h = _derive(txns: [_jornal(id: 'j1')]).single;
      expect(h.id.startsWith(kJornalDerivedPrefix), isTrue);
      expect(isJornalDerivedHarvest(h), isTrue);
      expect(isSaleDerivedHarvest(h), isFalse);
    });

    test('la cosecha del jornal enciende la medida independiente', () {
      final out = _derive(txns: [_jornal(id: 'j1')]);
      expect(hasIndependentHarvest(out), isTrue);
    });
  });

  group('Jornal · lo que no', () {
    test('sin kilos no deriva', () {
      expect(_derive(txns: [_jornal(id: 'j1', harvestedKg: null)]), isEmpty);
    });

    test('kilos 0 o negativos no derivan', () {
      expect(_derive(txns: [_jornal(id: 'a', harvestedKg: 0)]), isEmpty);
      expect(_derive(txns: [_jornal(id: 'b', harvestedKg: -5)]), isEmpty);
    });

    test('labor distinta de Cosechar no deriva', () {
      expect(_derive(txns: [_jornal(id: 'j1', task: 'abonar')]), isEmpty);
      expect(_derive(txns: [_jornal(id: 'j2', task: null)]), isEmpty);
    });

    test('sin cultivo no deriva', () {
      expect(_derive(txns: [_jornal(id: 'j1', cropId: null)]), isEmpty);
    });

    test('un jornal borrado no deriva', () {
      expect(_derive(txns: [_jornal(id: 'j1', deleted: true)]), isEmpty);
    });

    test('«Otra…» con texto «cosechar» no deriva', () {
      expect(_derive(txns: [_jornal(id: 'j1', task: 'cosechar café')]), isEmpty,
          reason: 'solo la tecla del catálogo, no texto libre');
    });

    test('un ingreso con categoría mano_obra no deriva', () {
      final ingreso = Transaction(
        id: 'i1',
        cropId: 'c1',
        type: TransactionType.income,
        category: 'mano_obra',
        amount: 1000,
        date: _now,
        createdAt: _now,
        task: kTaskCosechar,
        harvestedKg: 500,
      );
      expect(_derive(txns: [ingreso]), isEmpty);
    });
  });

  group('Prioridad manual > jornal > venta', () {
    test('la cosecha manual manda sobre el jornal', () {
      final out = _derive(
        txns: [_jornal(id: 'j1')],
        manual: [_manual(cropId: 'c1')],
      );
      expect(out, isEmpty);
    });

    test('la cosecha manual de otro cultivo no frena el jornal', () {
      final out = _derive(
        txns: [_jornal(id: 'j1', cropId: 'c1')],
        manual: [_manual(cropId: 'c2')],
      );
      expect(out.single.id, 'der_jornal_j1');
    });

    test('el jornal suprime la venta del mismo cultivo', () {
      final out = _derive(txns: [
        _jornal(id: 'j1', harvestedKg: 500),
        _venta(id: 'v1', quantity: 480),
      ]);
      expect(out, hasLength(1));
      expect(out.single.id, 'der_jornal_j1');
      expect(out.single.amount, 500);
    });

    test('un jornal medido no suprime la venta de otro cultivo', () {
      final out = _derive(txns: [
        _jornal(id: 'j1', cropId: 'c1'),
        _venta(id: 'v1', cropId: 'c2', quantity: 480),
      ]);
      expect(out.map((h) => h.id), ['der_jornal_j1', 'der_venta_v1']);
    });

    test('un jornal sin kilos no suprime la venta', () {
      final out = _derive(txns: [
        _jornal(id: 'j1', harvestedKg: null),
        _venta(id: 'v1', quantity: 480),
      ]);
      expect(out.single.id, 'der_venta_v1');
    });

    test('con un jornal medido, la venta no rellena los jornales sin kilos', () {
      final out = _derive(txns: [
        _jornal(id: 'j1', harvestedKg: 500),
        _jornal(id: 'j2', harvestedKg: null),
        _venta(id: 'v1', quantity: 480),
      ]);
      expect(out, hasLength(1));
      expect(out.single.amount, 500,
          reason: 'trade-off D3: no se inventa el resto');
    });

    test('un jornal borrado no suprime la venta', () {
      final out = _derive(txns: [
        _jornal(id: 'j1', deleted: true),
        _venta(id: 'v1', quantity: 480),
      ]);
      expect(out.single.id, 'der_venta_v1');
    });
  });
}
