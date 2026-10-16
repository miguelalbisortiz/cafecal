import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/farm_alert.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/alert_service.dart';

/// hueco 1 de la revisión: las cuatro pantallas (Inicio, Reportes, PDF y
/// Excel) llamaban al motor a su manera. Inicio pasaba la caja mensual, el
/// precio mínimo y el peso del saco; los otros tres no, y PDF/Excel además
/// le pasaban solo el período exportado. El mismo informe podía decir
/// «Sin recomendaciones» con el banner encendido en la portada.
///
/// [evaluateAlerts] es el único punto de entrada y estos tests fijan lo que
/// tiene que arrastrar siempre.
AppLocalizations get _es => stringsFor('es');

const List<Crop> _crops = [Crop(id: 'cafe', name: 'Café')];

Transaction _txn({
  required TransactionType type,
  required double amount,
  required DateTime date,
  String category = 'otro',
  double? quantity,
  String? unit,
}) =>
    Transaction(
      id: '${type.name}_${amount}_${date.millisecondsSinceEpoch}',
      type: type,
      category: category,
      amount: amount,
      quantity: quantity,
      unit: unit,
      date: date,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  final now = DateTime(2026, 6, 15);

  List<FarmAlert> run(
    List<Transaction> txns,
    FarmSettings settings,
  ) =>
      evaluateAlerts(
        transactions: txns,
        crops: _crops,
        l10n: _es,
        settings: settings,
        now: now,
      );

  group('evaluateAlerts · arrastra los ajustes', () {
    final ventaBarata = [
      _txn(
          type: TransactionType.income,
          amount: 50000,
          date: DateTime(2026, 6, 3),
          category: 'venta_cafe',
          quantity: 1,
          unit: 'kg'),
    ];

    test('el precio mínimo por kilo de Ajustes llega al motor', () {
      final conUmbral =
          run(ventaBarata, const FarmSettings(lowPriceThresholdPerKg: 80000));
      expect(conUmbral.any((a) => a.id == 'low_price_manual'), isTrue,
          reason: 'sin pasar el umbral, la regla 4 manual no puede salir');
    });

    test('sin umbral configurado la regla se calla (null → oculto)', () {
      final sinUmbral = run(ventaBarata, const FarmSettings());
      expect(sinUmbral.any((a) => a.id == 'low_price_manual'), isFalse);
    });

    test('la caja mensual de Ajustes llega al motor', () {
      final gastoDeJornal = [
        _txn(
            type: TransactionType.expense,
            amount: 700,
            date: DateTime(2026, 6, 5),
            category: 'mano_obra'),
      ];
      final conCaja = run(gastoDeJornal, const FarmSettings(cajaMenorMensual: 600));
      expect(conCaja.any((a) => a.id == 'cash_box'), isTrue,
          reason: '700 sobre un aporte de 600 tiene que avisar');

      final sinCaja = run(gastoDeJornal, const FarmSettings());
      expect(sinCaja.any((a) => a.id == 'cash_box'), isFalse,
          reason: 'sin aporte la regla no se puede calcular');
    });

    test('el peso real del saco cambia el precio por kg', () {
      // 50.000 por un saco: a 70 kg sale 714/kg (bajo 750 → avisa),
      // a 60 kg sale 833/kg (ya no avisa). El número lo pone Ajustes.
      final ventaEnSaco = [
        _txn(
            type: TransactionType.income,
            amount: 50000,
            date: DateTime(2026, 6, 3),
            category: 'venta_cafe',
            quantity: 1,
            unit: 'saco'),
      ];
      const umbral = FarmSettings(lowPriceThresholdPerKg: 750);

      expect(
          run(ventaEnSaco, umbral.copyWith(sacoKg: 70))
              .any((a) => a.id == 'low_price_manual'),
          isTrue);
      expect(
          run(ventaEnSaco, umbral.copyWith(sacoKg: 60))
              .any((a) => a.id == 'low_price_manual'),
          isFalse,
          reason: 'con el costal más pesado el mismo saco ya no es barato');
    });
  });

  group('evaluateAlerts · la ventana es el histórico completo', () {
    test('las ventas fuera del mes actual también se evalúan', () {
      final historico = [
        _txn(
            type: TransactionType.income,
            amount: 1000,
            date: DateTime(2026, 1, 10),
            category: 'venta_cafe',
            quantity: 1,
            unit: 'kg'),
        _txn(
            type: TransactionType.income,
            amount: 1000,
            date: DateTime(2026, 2, 10),
            category: 'venta_cafe',
            quantity: 1,
            unit: 'kg'),
        _txn(
            type: TransactionType.income,
            amount: 1000,
            date: DateTime(2026, 3, 10),
            category: 'venta_cafe',
            quantity: 1,
            unit: 'kg'),
        _txn(
            type: TransactionType.income,
            amount: 400,
            date: DateTime(2026, 6, 1),
            category: 'venta_cafe',
            quantity: 1,
            unit: 'kg'),
        _txn(
            type: TransactionType.income,
            amount: 400,
            date: DateTime(2026, 6, 8),
            category: 'venta_cafe',
            quantity: 1,
            unit: 'kg'),
      ];
      final soloJunio = historico
          .where((t) => t.date.month == 6)
          .toList();

      expect(run(historico, const FarmSettings()).any((a) => a.id == 'low_price'),
          isTrue,
          reason: 'con todo el histórico el promedio se puede comparar');

      // Esto es exactamente lo que hacían el PDF y el Excel: solo el mes
      // exportado. Cinco ventas se reducían a dos y la regla se caía.
      expect(run(soloJunio, const FarmSettings()).any((a) => a.id == 'low_price'),
          isFalse,
          reason: 'recortar al período es lo que rompía el informe');
    });
  });
}
