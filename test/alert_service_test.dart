import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/farm_alert.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/alert_service.dart';

/// AppLocalizations en espaÃ±ol para las pruebas de mensajes.
AppLocalizations get _es => stringsFor('es');

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
    cropId: cropId,
    category: category,
    amount: amount,
    quantity: quantity,
    unit: unit,
    date: date,
    createdAt: DateTime(2026, 1, 1),
  );
}

List<Crop> _crops() => const [
      Crop(id: 'cafe', name: 'CafÃ©', icon: 'â˜•', color: '#6D4C41'),
      Crop(id: 'platano', name: 'PlÃ¡tano', icon: 'ðŸŒ', color: '#F9A825'),
    ];

void main() {
  final now = DateTime(2026, 6, 15);

  group('Regla 1 â€” Gasto excesivo', () {
    test('dispara cuando mes actual > 2Ã— promedio histÃ³rico', () {
      final txns = [
        // HistÃ³rico manual de obra 100/mes x 3 meses
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 1, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 2, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 3, 10), category: 'mano_obra'),
        // Mes actual: 300 > 2*100
        _txn(type: TransactionType.expense, amount: 300, date: DateTime(2026, 6, 10), category: 'mano_obra'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(
        alerts.any((a) => a.rule == AlertRule.excessiveSpending),
        isTrue,
        reason: 'debe dispararse excess spend',
      );
    });

    test('NO dispara si el gasto mes actual estÃ¡ dentro de 2Ã—', () {
      final txns = [
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 1, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 2, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 3, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 150, date: DateTime(2026, 6, 10), category: 'mano_obra'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(
        alerts.where((a) => a.rule == AlertRule.excessiveSpending),
        isEmpty,
        reason: '150 no supera 2Ã—100',
      );
    });

    test(
        'NO dispara si un solo mes tuvo muchos movimientos puntuales '
        '(promedio MENSUAL, no por transacciÃ³n)', () {
      final txns = [
        // Enero: 4 movimientos puntuales que suman 1000. Febrero: un solo gasto de 100.
        _txn(type: TransactionType.expense, amount: 250, date: DateTime(2026, 1, 2), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 250, date: DateTime(2026, 1, 8), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 250, date: DateTime(2026, 1, 15), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 250, date: DateTime(2026, 1, 22), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 2, 10), category: 'mano_obra'),
        // Mes actual: 500. Por transacciÃ³n el promedio serÃ­a 220 â†’ dispararÃ­a
        // (100>2Ã—220). Por mes el promedio es 550 â†’ no debe disparar.
        _txn(type: TransactionType.expense, amount: 500, date: DateTime(2026, 6, 10), category: 'mano_obra'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(
        alerts.where((a) => a.rule == AlertRule.excessiveSpending),
        isEmpty,
        reason: '500 estÃ¡ dentro de 2Ã—550 (promedio mensual)',
      );
    });
  });

  group('Regla 2 â€” Sin ingresos', () {
    test('dispara si la Ãºltima venta tiene >= 60 dÃ­as', () {
      final txns = [
        _txn(
          type: TransactionType.income,
          amount: 500,
          date: DateTime(2026, 3, 1),
          category: 'venta_cafe',
        ),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(alerts.any((a) => a.rule == AlertRule.noIncome), isTrue);
    });

    test('NO dispara si hubo venta reciente', () {
      final txns = [
        _txn(
          type: TransactionType.income,
          amount: 500,
          date: DateTime(2026, 6, 1),
          category: 'venta_cafe',
        ),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(alerts.where((a) => a.rule == AlertRule.noIncome), isEmpty);
    });
  });

  group('Regla 3 â€” Balance negativo 3+ meses', () {
    test('dispara con 3 meses consecutivos de pÃ©rdida', () {
      final txns = [
        _txn(type: TransactionType.expense, amount: 500, date: DateTime(2026, 4, 10)),
        _txn(type: TransactionType.expense, amount: 500, date: DateTime(2026, 5, 10)),
        _txn(type: TransactionType.expense, amount: 500, date: DateTime(2026, 6, 10)),
        _txn(type: TransactionType.income, amount: 100, date: DateTime(2026, 4, 15)),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(alerts.any((a) => a.rule == AlertRule.consecutiveLosses), isTrue);
    });

    test('NO dispara con solo 2 meses de pÃ©rdida', () {
      final txns = [
        _txn(type: TransactionType.expense, amount: 500, date: DateTime(2026, 6, 10)),
        _txn(type: TransactionType.expense, amount: 500, date: DateTime(2026, 5, 10)),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(alerts.where((a) => a.rule == AlertRule.consecutiveLosses), isEmpty);
    });
  });

  group('Regla 4 â€” Precio bajo', () {
    test('dispara si la media de precio/kg de los Ãºltimos 30 dÃ­as es menor a la histÃ³rica', () {
      // 10 kg cada venta: histÃ³rico 100.000/kg, reciente 40.000/kg.
      final txns = [
        _txn(type: TransactionType.income, amount: 1000000, quantity: 10, unit: 'kg', date: DateTime(2026, 1, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 1000000, quantity: 10, unit: 'kg', date: DateTime(2026, 2, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 1000000, quantity: 10, unit: 'kg', date: DateTime(2026, 3, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 400000, quantity: 10, unit: 'kg', date: DateTime(2026, 6, 1), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 400000, quantity: 10, unit: 'kg', date: DateTime(2026, 6, 8), category: 'venta_cafe'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(alerts.any((a) => a.rule == AlertRule.lowPrice), isTrue);
    });

    test('NO dispara si la media reciente de precio/kg es mayor o igual', () {
      // 10 kg cada venta: histÃ³rico 50.000/kg, reciente 60.000/kg.
      final txns = [
        _txn(type: TransactionType.income, amount: 500000, quantity: 10, unit: 'kg', date: DateTime(2026, 1, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 500000, quantity: 10, unit: 'kg', date: DateTime(2026, 2, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 500000, quantity: 10, unit: 'kg', date: DateTime(2026, 3, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 600000, quantity: 10, unit: 'kg', date: DateTime(2026, 6, 1), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 600000, quantity: 10, unit: 'kg', date: DateTime(2026, 6, 8), category: 'venta_cafe'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(alerts.where((a) => a.rule == AlertRule.lowPrice), isEmpty);
    });

    test('normaliza por unidad: arroba (12.5 kg) y saco (70 kg)', () {
      // Venta en kg a 100.000/kg (histÃ³rico) y una reciente en ARROBA que
      // equivale a 40.000/kg â†’ debe disparar.
      final txns = [
        _txn(type: TransactionType.income, amount: 1000000, quantity: 10, unit: 'kg', date: DateTime(2026, 1, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 1000000, quantity: 10, unit: 'kg', date: DateTime(2026, 2, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 1000000, quantity: 10, unit: 'kg', date: DateTime(2026, 3, 10), category: 'venta_cafe'),
        // 1 arroba a $500.000 = 500.000 / 12.5 = 40.000/kg.
        _txn(type: TransactionType.income, amount: 500000, quantity: 1, unit: 'arroba', date: DateTime(2026, 6, 1), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 500000, quantity: 1, unit: 'arroba', date: DateTime(2026, 6, 8), category: 'venta_cafe'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(alerts.any((a) => a.rule == AlertRule.lowPrice), isTrue);
    });

    test('ignora subvenciones y ventas sin cantidad: solo compara ventas con volumen', () {
      final txns = [
        _txn(type: TransactionType.income, amount: 1000000, quantity: 10, unit: 'kg', date: DateTime(2026, 1, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 1000000, quantity: 10, unit: 'kg', date: DateTime(2026, 2, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 1000000, quantity: 10, unit: 'kg', date: DateTime(2026, 3, 10), category: 'venta_cafe'),
        // Ventas recientes menoresâ€¦
        _txn(type: TransactionType.income, amount: 600000, quantity: 10, unit: 'kg', date: DateTime(2026, 6, 1), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 600000, quantity: 10, unit: 'kg', date: DateTime(2026, 6, 8), category: 'venta_cafe'),
        // â€¦pero una subvenciÃ³n reciente y una venta sin cantidad NO deben
        // contar para el promedio de precio/kg.
        _txn(type: TransactionType.income, amount: 9000000, date: DateTime(2026, 6, 12), category: 'subvenciones'),
        _txn(type: TransactionType.income, amount: 9999999, date: DateTime(2026, 6, 13), category: 'venta_cafe'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(
        alerts.any((a) => a.rule == AlertRule.lowPrice),
        isTrue,
        reason: '60.000/kg reciente < 100.000/kg histÃ³rico; ni subvenciÃ³n ni venta sin cantidad deben mezclarse',
      );
    });

    test('dispara con umbral manual cuando se vende por debajo (precio/kg)', () {
      final txns = [
        // 3 ventas de 10kg: una reciente a $20.000/kg con umbral $80.000.
        _txn(type: TransactionType.income, amount: 500000, quantity: 10, unit: 'kg', date: DateTime(2026, 1, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 500000, quantity: 10, unit: 'kg', date: DateTime(2026, 2, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 200000, quantity: 10, unit: 'kg', date: DateTime(2026, 6, 1), category: 'venta_cafe'),
      ];
      final alerts = AlertService(now: now)
          .evaluate(txns, _crops(), _es, manualThresholdPerKg: 80000);
      expect(alerts.any((a) => a.rule == AlertRule.lowPrice), isTrue);
      expect(alerts.any((a) => a.id == 'low_price_manual'), isTrue);
    });

    test('NO dispara con umbral manual si todo se vende arriba', () {
      final txns = [
        _txn(type: TransactionType.income, amount: 1000000, quantity: 10, unit: 'kg', date: DateTime(2026, 1, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 1000000, quantity: 10, unit: 'kg', date: DateTime(2026, 2, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 1000000, quantity: 10, unit: 'kg', date: DateTime(2026, 6, 1), category: 'venta_cafe'),
      ];
      final alerts = AlertService(now: now)
          .evaluate(txns, _crops(), _es, manualThresholdPerKg: 80000);
      expect(alerts.where((a) => a.id == 'low_price_manual'), isEmpty);
    });
  });

  group('Regla 5 â€” Cultivo deficitario', () {
    test('dispara ROI < -30% en un cultivo', () {
      final txns = [
        _txn(type: TransactionType.expense, amount: 1000, date: DateTime(2026, 1, 10), cropId: 'cafe'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(alerts.any((a) => a.rule == AlertRule.deficitCrop), isTrue);
    });

    test('NO dispara con ROI >= -30%', () {
      final txns = [
        _txn(type: TransactionType.expense, amount: 1000, date: DateTime(2026, 1, 10), cropId: 'cafe'),
        _txn(type: TransactionType.income, amount: 800, date: DateTime(2026, 2, 10), cropId: 'cafe'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(alerts.where((a) => a.rule == AlertRule.deficitCrop), isEmpty);
    });

    test('aviso sin cultivo cita cuÃ¡ntos registros estÃ¡n sin asignar', () {
      final txns = [
        // 3 registros sin cultivo (2 gastos + 1 venta) que no se recuperan.
        _txn(type: TransactionType.expense, amount: 1000, date: DateTime(2026, 1, 10)),
        _txn(type: TransactionType.expense, amount: 500, date: DateTime(2026, 2, 10)),
        _txn(type: TransactionType.income, amount: 100, date: DateTime(2026, 3, 1)),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      final deficit = alerts.firstWhere((a) => a.rule == AlertRule.deficitCrop);
      expect(deficit.message, contains('3'));
      expect(deficit.message, contains(r'$'));
      expect(deficit.suggestion, contains('3'));
    });

    test('aviso de pÃ©rdidas cita el ROI y enuncia el problema con nÃºmeros', () {
      final txns = [
        _txn(type: TransactionType.expense, amount: 1000, date: DateTime(2026, 1, 10), cropId: 'cafe'),
        _txn(type: TransactionType.income, amount: 150, date: DateTime(2026, 2, 10), cropId: 'cafe'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      final deficit = alerts.firstWhere((a) => a.rule == AlertRule.deficitCrop);
      expect(deficit.title, contains('ROI'));
      expect(deficit.title, contains('%'));
      expect(deficit.message.toLowerCase(), contains('el problema'));
      expect(deficit.message.toLowerCase(), contains('invertiste'));
      expect(deficit.message, contains(r'$'));
      expect(deficit.suggestion, isNotEmpty);
    });
  });

  group('Lenguaje claro en todas las alertas', () {
    final scenarios = <String, List<Transaction>>{
      'gasto excesivo': [
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 1, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 2, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 3, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 300, date: DateTime(2026, 6, 10), category: 'mano_obra'),
      ],
      'sin ingresos': [
        _txn(type: TransactionType.income, amount: 500, date: DateTime(2026, 3, 1), category: 'venta_cafe'),
      ],
      'balance negativo': [
        _txn(type: TransactionType.expense, amount: 500, date: DateTime(2026, 4, 10)),
        _txn(type: TransactionType.expense, amount: 500, date: DateTime(2026, 5, 10)),
        _txn(type: TransactionType.expense, amount: 500, date: DateTime(2026, 6, 10)),
        _txn(type: TransactionType.income, amount: 100, date: DateTime(2026, 4, 15)),
      ],
      'precio bajo': [
        _txn(type: TransactionType.income, amount: 1000000, quantity: 10, unit: 'kg', date: DateTime(2026, 1, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 1000000, quantity: 10, unit: 'kg', date: DateTime(2026, 2, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 1000000, quantity: 10, unit: 'kg', date: DateTime(2026, 3, 10), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 400000, quantity: 10, unit: 'kg', date: DateTime(2026, 6, 1), category: 'venta_cafe'),
        _txn(type: TransactionType.income, amount: 400000, quantity: 10, unit: 'kg', date: DateTime(2026, 6, 8), category: 'venta_cafe'),
      ],
      'cultivo deficitario': [
        _txn(type: TransactionType.expense, amount: 1000, date: DateTime(2026, 1, 10), cropId: 'cafe'),
      ],
    };

    test('toda alerta enuncia el problema con nÃºmeros y sugerencia accionable', () {
      for (final entry in scenarios.entries) {
        final alerts = AlertService(now: now).evaluate(entry.value, _crops(), _es);
        expect(alerts, isNotEmpty, reason: 'escenario "${entry.key}" debe disparar');
        for (final a in alerts) {
          expect(a.title.trim(), isNotEmpty,
              reason: 'tÃ­tulo de ${a.rule}');
          expect(a.suggestion.trim(), isNotEmpty,
              reason: 'sugerencia de ${a.rule}');
          final detail = '${a.title} ${a.message}';
          expect(
            RegExp(r'\d|%').hasMatch(detail),
            isTrue,
            reason: '${a.rule} debe citar nÃºmeros ($detail)',
          );
        }
      }
    });
  });

  group('Regla 6-8 â€” Nivel 2 (fase, conciliaciÃ³n, siembra reciente)', () {
    List<Crop> cropsWithPhases() => const [
          Crop(
            id: 'cafe',
            name: 'CafÃ©',
            phase: CropPhase.establecimiento,
          ),
          Crop(
            id: 'platano',
            name: 'PlÃ¡tano',
            phase: CropPhase.produccion,
          ),
          Crop(
            id: 'tomate',
            name: 'Tomate',
            cycle: CropCycle.anual,
          ),
        ];

    Harvest harvest({required String cropId, required double amount,
        required DateTime date, String unit = 'kg'}) {
      return Harvest(
        id: 'h_${cropId}_${date.millisecondsSinceEpoch}',
        cropId: cropId,
        date: date,
        amount: amount,
        unit: unit,
      );
    }

    Sowing sowing({required String id, required String cropId,
        required DateTime date}) {
      return Sowing(id: id, cropId: cropId, date: date, plants: 100);
    }

    test('establecimiento/renovaciÃ³n emite aviso info, NO deficit danger', () {
      // Cultivo en establecimiento con pÃ©rdida: no debe marcar peligro.
      final txns = [
        _txn(type: TransactionType.expense, amount: 1000,
            date: DateTime(2026, 1, 10), cropId: 'cafe'),
      ];
      final alerts =
          AlertService(now: now).evaluate(txns, cropsWithPhases(), _es);
      expect(alerts.any((a) => a.rule == AlertRule.cropEstablishment), isTrue);
      expect(alerts.any((a) => a.rule == AlertRule.deficitCrop), isFalse,
          reason: 'en establecimiento no se marca pÃ©rdida de producciÃ³n');
    });

    test('producciÃ³n mantiene deficit danger', () {
      final txns = [
        _txn(type: TransactionType.expense, amount: 1000,
            date: DateTime(2026, 1, 10), cropId: 'platano'),
      ];
      final alerts =
          AlertService(now: now).evaluate(txns, cropsWithPhases(), _es);
      expect(alerts.any((a) => a.rule == AlertRule.deficitCrop), isTrue);
      expect(alerts.any((a) => a.rule == AlertRule.cropEstablishment), isFalse);
    });

    test('cultivo anual (producciÃ³n) mantiene deficit danger', () {
      final txns = [
        _txn(type: TransactionType.expense, amount: 1000,
            date: DateTime(2026, 1, 10), cropId: 'tomate'),
      ];
      final alerts =
          AlertService(now: now).evaluate(txns, cropsWithPhases(), _es);
      expect(alerts.any((a) => a.rule == AlertRule.deficitCrop), isTrue);
    });

    test('conciliaciÃ³n dispara si vendiÃ³ >1.1x lo cosechado (12 meses)', () {
      final txns = [
        _txn(type: TransactionType.income, amount: 1000000, quantity: 150,
            unit: 'kg', date: DateTime(2026, 6, 1), category: 'venta_cafe',
            cropId: 'cafe'),
      ];
      final harvests = [
        harvest(cropId: 'cafe', amount: 100, date: DateTime(2026, 5, 1)),
      ];
      final alerts = AlertService(now: now)
          .evaluate(txns, _crops(), _es, harvests: harvests);
      expect(alerts.any((a) => a.rule == AlertRule.harvestVsSales), isTrue);
    });

    test('conciliaciÃ³n NO dispara dentro del margen', () {
      final txns = [
        _txn(type: TransactionType.income, amount: 1000000, quantity: 100,
            unit: 'kg', date: DateTime(2026, 6, 1), category: 'venta_cafe',
            cropId: 'cafe'),
      ];
      final harvests = [
        harvest(cropId: 'cafe', amount: 100, date: DateTime(2026, 5, 1)),
      ];
      final alerts = AlertService(now: now)
          .evaluate(txns, _crops(), _es, harvests: harvests);
      expect(alerts.where((a) => a.rule == AlertRule.harvestVsSales), isEmpty);
    });

    test('siembra reciente (dentro de 15 dÃ­as) emite aviso info', () {
      final sowings = [
        sowing(id: 's1', cropId: 'cafe', date: DateTime(2026, 6, 10)),
      ];
      final alerts = AlertService(now: now)
          .evaluate([], _crops(), _es, sowings: sowings);
      expect(alerts.any((a) => a.rule == AlertRule.cropRecentlyPlanted), isTrue);
    });

    test('siembra fuera de 15 dÃ­as NO emite aviso', () {
      final sowings = [
        sowing(id: 's1', cropId: 'cafe', date: DateTime(2026, 5, 1)),
      ];
      final alerts = AlertService(now: now)
          .evaluate([], _crops(), _es, sowings: sowings);
      expect(
          alerts.where((a) => a.rule == AlertRule.cropRecentlyPlanted), isEmpty);
    });
  });

  group('A1 â€” R6 excluye cosechas perdidas', () {
    Harvest harvest({required String cropId, required double amount,
        required DateTime date, HarvestDestination destination = HarvestDestination.vendido}) {
      return Harvest(
        id: 'h_${cropId}_${date.millisecondsSinceEpoch}_${destination.name}',
        cropId: cropId,
        date: date,
        amount: amount,
        destination: destination,
      );
    }

    test('cosecha con destino pÃ©rdida NO respalda ventas', () {
      final txns = [
        _txn(type: TransactionType.income, amount: 1000000, quantity: 150,
            unit: 'kg', date: DateTime(2026, 6, 1), category: 'venta_cafe',
            cropId: 'cafe'),
      ];
      final harvests = [
        harvest(cropId: 'cafe', amount: 100, date: DateTime(2026, 5, 1)),
        harvest(cropId: 'cafe', amount: 80, date: DateTime(2026, 5, 20),
            destination: HarvestDestination.perdida),
      ];
      final alerts = AlertService(now: now)
          .evaluate(txns, _crops(), _es, harvests: harvests);
      expect(alerts.any((a) => a.rule == AlertRule.harvestVsSales), isTrue,
          reason: '150 vendidos > 1.1x(100 respaldados); la pÃ©rdida no cuenta');
    });

    test('solo cosechas perdidas NO respaldan ventas (R6 no dispara)', () {
      final txns = [
        _txn(type: TransactionType.income, amount: 1000000, quantity: 150,
            unit: 'kg', date: DateTime(2026, 6, 1), category: 'venta_cafe',
            cropId: 'cafe'),
      ];
      final harvests = [
        harvest(cropId: 'cafe', amount: 200, date: DateTime(2026, 5, 1),
            destination: HarvestDestination.perdida),
      ];
      final alerts = AlertService(now: now)
          .evaluate(txns, _crops(), _es, harvests: harvests);
      expect(
          alerts.where((a) => a.rule == AlertRule.harvestVsSales), isEmpty,
          reason: 'sin respaldo real (pÃ©rdida) la conciliaciÃ³n se calla');
    });

    test('almacenado SÃ respalda las ventas', () {
      final txns = [
        _txn(type: TransactionType.income, amount: 1000000, quantity: 200,
            unit: 'kg', date: DateTime(2026, 6, 1), category: 'venta_cafe',
            cropId: 'cafe'),
      ];
      final harvests = [
        harvest(cropId: 'cafe', amount: 150, date: DateTime(2026, 5, 1),
            destination: HarvestDestination.almacenado),
        harvest(cropId: 'cafe', amount: 50, date: DateTime(2026, 5, 2),
            destination: HarvestDestination.perdida),
      ];
      final alerts = AlertService(now: now)
          .evaluate(txns, _crops(), _es, harvests: harvests);
      expect(alerts.any((a) => a.rule == AlertRule.harvestVsSales), isTrue,
          reason: 'vendido 200 > 1.1x150 almacenado (la pÃ©rdida no cuenta)');
    });
  });

  group('C â€” R1 compara contra el mismo mes calendario histÃ³rico', () {
    test('estacionalidad recurrente NO dispara falsa alarma', () {
      final txns = [
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2025, 6, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2024, 6, 10), category: 'mano_obra'),
        // Meses "flojos" en el promedio global hunden la media.
        _txn(type: TransactionType.expense, amount: 10, date: DateTime(2026, 1, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 10, date: DateTime(2026, 2, 10), category: 'mano_obra'),
        // Junio 2026 = 150: 1.5x su propio junio habitual, pero 2.7x el promedio global.
        _txn(type: TransactionType.expense, amount: 150, date: DateTime(2026, 6, 10), category: 'mano_obra'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(
          alerts.where((a) => a.rule == AlertRule.excessiveSpending), isEmpty,
          reason: '150 estÃ¡ dentro de 2x el junio histÃ³rico (100)');
    });

    test('detecta el exceso respecto al mismo mes, aunque el promedio global lo oculte', () {
      final txns = [
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2025, 6, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2024, 6, 10), category: 'mano_obra'),
        // Marzos pesados en el promedio global.
        _txn(type: TransactionType.expense, amount: 1000, date: DateTime(2026, 3, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 1000, date: DateTime(2025, 3, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 300, date: DateTime(2026, 6, 10), category: 'mano_obra'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(alerts.any((a) => a.rule == AlertRule.excessiveSpending), isTrue,
          reason: '300 > 2x el junio histÃ³rico (100)');
    });

    test('fallback al promedio global cuando hay < 2 meses-dato del mismo mes', () {
      final txns = [
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2025, 6, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 3, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 100, date: DateTime(2026, 2, 10), category: 'mano_obra'),
        _txn(type: TransactionType.expense, amount: 300, date: DateTime(2026, 6, 10), category: 'mano_obra'),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(alerts.any((a) => a.rule == AlertRule.excessiveSpending), isTrue,
          reason: 'con 1 solo junio histÃ³rico se usa la media global (100)');
    });
  });

  group('B â€” Ventas sin cantidad', () {
    Transaction sale({required double amount, DateTime? date, double? qty}) => _txn(
          type: TransactionType.income,
          amount: amount,
          quantity: qty,
          date: date ?? DateTime(2026, 6, 1),
          category: 'venta_cafe',
        );

    test('3+ ventas sin cantidad en 90 dÃ­as dispara INFO', () {
      final txns = [
        sale(amount: 500000, date: DateTime(2026, 5, 1)),
        sale(amount: 300000, date: DateTime(2026, 6, 1)),
        sale(amount: 200000, date: DateTime(2026, 6, 10)),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      final found = alerts.where((a) => a.rule == AlertRule.missingQuantity);
      expect(found, isNotEmpty);
      expect(found.first.severity, AlertSeverity.info);
    });

    test('menos de 3 ventas sin cantidad NO dispara', () {
      final txns = [
        sale(amount: 500000, date: DateTime(2026, 5, 1)),
        sale(amount: 300000, date: DateTime(2026, 6, 1), qty: 50),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(
          alerts.where((a) => a.rule == AlertRule.missingQuantity), isEmpty);
    });

    test('ventas con cantidad NO dispara', () {
      final txns = [
        sale(amount: 500000, date: DateTime(2026, 5, 1), qty: 50),
        sale(amount: 300000, date: DateTime(2026, 6, 1), qty: 30),
        sale(amount: 200000, date: DateTime(2026, 6, 10), qty: 20),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(
          alerts.where((a) => a.rule == AlertRule.missingQuantity), isEmpty);
    });

    test('ventas sin cantidad fuera de 90 dÃ­as NO dispara', () {
      final txns = [
        sale(amount: 500000, date: DateTime(2026, 1, 10)),
        sale(amount: 300000, date: DateTime(2026, 2, 10)),
        sale(amount: 200000, date: DateTime(2026, 3, 1)),
      ];
      final alerts = AlertService(now: now).evaluate(txns, _crops(), _es);
      expect(
          alerts.where((a) => a.rule == AlertRule.missingQuantity), isEmpty);
    });
  });
}
