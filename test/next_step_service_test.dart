import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/next_step_service.dart';

Crop _crop(String id, {CropPhase phase = CropPhase.produccion}) => Crop(
      id: id,
      name: id,
      phase: phase,
    );

Sowing _sowing(String id, {String? cropId, SowingKind kind = SowingKind.siembra}) =>
    Sowing(id: id, cropId: cropId, date: DateTime(2026, 1, 10), plants: 100, kind: kind);

Harvest _harvest(String id, {String? cropId}) =>
    Harvest(id: id, cropId: cropId, date: DateTime(2026, 2, 1), amount: 10);

Transaction _txn(
  String id, {
  TransactionType type = TransactionType.expense,
  String category = 'fertilizante',
  DateTime? date,
}) =>
    Transaction(
      id: id,
      type: type,
      category: category,
      amount: 100,
      date: date ?? DateTime(2026, 3, 1),
      createdAt: date ?? DateTime(2026, 3, 1),
    );

void main() {
  const year = 2026;

  group('needsOnboarding — gate de bienvenida', () {
    test('sin cultivos exige onboarding', () {
      expect(needsOnboarding(const [], const []), isTrue);
    });

    test('cultivo en producción NO exige onboarding (finca establecida)', () {
      expect(
        needsOnboarding([_crop('cafe', phase: CropPhase.produccion)], const []),
        isFalse,
      );
    });

    test('cultivo joven sin siembra exige onboarding', () {
      expect(
        needsOnboarding(
            [_crop('cafe', phase: CropPhase.establecimiento)], const []),
        isTrue,
      );
    });

    test('cultivo joven con siembra inicial NO exige onboarding', () {
      expect(
        needsOnboarding(
          [_crop('cafe', phase: CropPhase.establecimiento)],
          [_sowing('s1', cropId: 'cafe')],
        ),
        isFalse,
      );
    });

    test('resiembra suelta no cubre la siembra inicial (gate sigue activo)', () {
      expect(
        needsOnboarding(
          [_crop('cafe', phase: CropPhase.establecimiento)],
          [_sowing('s1', cropId: 'cafe', kind: SowingKind.resiembra)],
        ),
        isTrue,
      );
    });

    test('al menos un cultivo listo desbloquea aunque otro esté en establecimiento',
        () {
      expect(
        needsOnboarding(
          [
            _crop('cafe', phase: CropPhase.produccion),
            _crop('tomate', phase: CropPhase.establecimiento),
          ],
          const [],
        ),
        isFalse,
      );
    });
  });

  group('nextStepFor — reglas en orden', () {
    test('sin cultivos sugiere crear el primer cultivo', () {
      final step = nextStepFor(
        crops: const [],
        sowings: const [],
        harvests: const [],
        transactions: const [],
        year: year,
      );
      expect(step?.type, NextStepType.crop);
    });

    test('cuenta vacía (crops pre-cargados) sin datos sugiere el cultivo', () {
      final step = nextStepFor(
        crops: [_crop('cafe')],
        sowings: const [],
        harvests: const [],
        transactions: const [],
        year: year,
      );
      expect(step?.type, NextStepType.expenses);
    });

    test('establecimiento sin siembra propia sugiere sembrar ese cultivo', () {
      final step = nextStepFor(
        crops: [_crop('cafe', phase: CropPhase.establecimiento)],
        sowings: const [],
        harvests: const [],
        transactions: const [],
        year: year,
      );
      expect(step?.type, NextStepType.sowing);
      expect(step?.cropId, 'cafe');
    });

    test('renovacion sin siembra sugiere sembrar (aun con cultivo en produccion)', () {
      final step = nextStepFor(
        crops: [
          _crop('cafe', phase: CropPhase.produccion),
          _crop('platano', phase: CropPhase.renovacion),
        ],
        sowings: const [],
        harvests: const [],
        transactions: const [],
        year: year,
      );
      expect(step?.type, NextStepType.sowing);
      expect(step?.cropId, 'platano');
    });

    test('la siembra inicial registrada quita el paso de siembra', () {
      final step = nextStepFor(
        crops: [_crop('cafe', phase: CropPhase.establecimiento)],
        sowings: [_sowing('s1', cropId: 'cafe')],
        harvests: const [],
        transactions: const [],
        year: year,
      );
      expect(step?.type, NextStepType.expenses);
    });

    test('resiembra suelta no cubre la siembra inicial', () {
      final step = nextStepFor(
        crops: [_crop('cafe', phase: CropPhase.establecimiento)],
        sowings: [_sowing('s1', cropId: 'cafe', kind: SowingKind.resiembra)],
        harvests: const [],
        transactions: const [],
        year: year,
      );
      expect(step?.type, NextStepType.sowing);
      expect(step?.cropId, 'cafe');
    });

    test('produccion sin siembra NO exige sembrar y pasa a gastos', () {
      final step = nextStepFor(
        crops: [_crop('cafe', phase: CropPhase.produccion)],
        sowings: const [],
        harvests: const [],
        transactions: const [],
        year: year,
      );
      expect(step?.type, NextStepType.expenses);
    });

    test('con gastos del año y sin cosechas sugiere la primera cosecha', () {
      final step = nextStepFor(
        crops: [_crop('cafe', phase: CropPhase.produccion)],
        sowings: const [],
        harvests: const [],
        transactions: [_txn('e1', category: 'cosecha')],
        year: year,
      );
      expect(step?.type, NextStepType.harvest);
    });

    test('con cosecha y sin ventas sugiere registrar la venta', () {
      final step = nextStepFor(
        crops: [_crop('cafe', phase: CropPhase.produccion)],
        sowings: const [],
        harvests: [_harvest('h1', cropId: 'cafe')],
        transactions: [_txn('e1', category: 'cosecha')],
        year: year,
      );
      expect(step?.type, NextStepType.sale);
    });

    test('gastos de otro año no cuentan como gastos del año', () {
      final step = nextStepFor(
        crops: [_crop('cafe', phase: CropPhase.produccion)],
        sowings: const [],
        harvests: const [],
        transactions: [
          _txn('e1', category: 'cosecha', date: DateTime(2025, 12, 1)),
        ],
        year: year,
      );
      expect(step?.type, NextStepType.expenses);
    });

    test('venta registrada este año oculta la tarjeta', () {
      final step = nextStepFor(
        crops: [_crop('cafe', phase: CropPhase.produccion)],
        sowings: const [],
        harvests: [_harvest('h1', cropId: 'cafe')],
        transactions: [
          _txn('e1', category: 'cosecha'),
          _txn('i1', type: TransactionType.income, category: 'venta_cafe'),
        ],
        year: year,
      );
      expect(step, isNull);
    });

    test('ventas de otro año no ocultan el paso de venta', () {
      final step = nextStepFor(
        crops: [_crop('cafe', phase: CropPhase.produccion)],
        sowings: const [],
        harvests: [_harvest('h1', cropId: 'cafe')],
        transactions: [
          _txn('e1', category: 'cosecha'),
          _txn('i1',
              type: TransactionType.income,
              category: 'venta_cafe',
              date: DateTime(2025, 12, 1)),
        ],
        year: year,
      );
      expect(step?.type, NextStepType.sale);
    });

    test('la siembra tiene prioridad sobre gastos y cosechas', () {
      final step = nextStepFor(
        crops: [_crop('cafe', phase: CropPhase.establecimiento)],
        sowings: const [],
        harvests: [_harvest('h1', cropId: 'cafe')],
        transactions: [
          _txn('e1', category: 'cosecha'),
          _txn('i1', type: TransactionType.income, category: 'venta_cafe'),
        ],
        year: year,
      );
      expect(step?.type, NextStepType.sowing);
    });
  });
}