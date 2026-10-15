import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/farm_alert.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/alert_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **Fase 3 — la cascada.** Tres efectos que venían del mismo hueco: nadie
/// entraba a `addHarvest`, así que la cosecha no existía.
///
/// 1. **fase congelada** en `establecimiento` → el déficit >30% se reportaba
///    `info` en vez de `danger`;
/// 2. **alerta 13** («ya debería estar rindiendo») que no se podía apagar;
/// 3. **regla 5** sin datos con los que subir de severidad.
///
/// Los tres se arreglan con un solo hecho: la cosecha derivada de la venta ya
/// cuenta como cosecha. Estos tests los comprueban de punta a punta — proveedor
/// real y motor de alertas real, no sustitutos.
AppLocalizations get _es => stringsFor('es');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ahora = DateTime(2026, 10, 20);
  final delAno = DateTime(2026, 10, 5);

  Future<TransactionProvider> build() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return TransactionProvider(LocalStore(prefs));
  }

  Future<void> gastar(TransactionProvider p, String cropId, {double monto = 1000}) =>
      p.addTransaction(
        type: TransactionType.expense,
        category: 'fertilizante',
        amount: monto,
        cropId: cropId,
        date: delAno,
      );

  Future<Transaction> vender(
    TransactionProvider p,
    String cropId, {
    double monto = 150000,
    double kg = 50,
  }) =>
      p.addTransaction(
        type: TransactionType.income,
        category: kIncomeCategorySale,
        amount: monto,
        cropId: cropId,
        quantity: kg,
        unit: 'kg',
        date: delAno,
      );

  List<FarmAlert> avisos(TransactionProvider p) => AlertService(now: ahora)
      .evaluate(p.transactions, p.crops, _es, harvests: p.harvests);

  List<FarmAlert> regla13(List<FarmAlert> todos) => todos
      .where((a) => a.rule == AlertRule.firstHarvestOverdue)
      .toList();

  group('Efecto 1 · la fase deja de estar congelada', () {
    test('una venta con cultivo y kilos pone al cultivo en producción', () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      expect(crop.phase, CropPhase.establecimiento,
          reason: 'así sale un cultivo nuevo: es el punto de partida');

      await vender(p, crop.id);

      expect(p.crops.single.phase, CropPhase.produccion,
          reason: 'la regla de siempre, disparada por la cosecha derivada');
      expect(p.crops.single.pendingSync, isTrue,
          reason: 'y la fase viaja al servidor como siempre');
    });

    test('una cuenta que ya vendía se arregla al abrir la app', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs);

      // Deja en el disco exactamente lo que deja la app actual: cultivo en
      // `establecimiento`, una venta con kilos… y ninguna cosecha, porque
      // nadie pasó por `addHarvest`.
      final vieja = TransactionProvider(store);
      final crop = await vieja.addCrop('Café');
      await vender(vieja, crop.id);
      await vieja.updateCrop(
        vieja.crops.single.copyWith(phase: CropPhase.establecimiento),
      );
      expect(vieja.crops.single.phase, CropPhase.establecimiento,
          reason: 'este es el estado que hoy está congelado en producción');

      // Otra tanda de arranque, mismo disco.
      final p = TransactionProvider(store);

      expect(p.crops.single.phase, CropPhase.produccion,
          reason: 'no hace falta que toque nada: al abrir se arregla solo');
    });

    test('la promoción queda guardada: al recargar sigue en producción',
        () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      await vender(p, crop.id);

      await p.reloadFromCache();

      expect(p.crops.single.phase, CropPhase.produccion);
    });

    test('renovación no se toca: sigue siendo decisión de él', () async {
      final p = await build();
      await p.addCrop('Vid', phase: CropPhase.renovacion);
      await vender(p, p.crops.single.id);

      expect(p.crops.single.phase, CropPhase.renovacion,
          reason: 'solo se promueve desde establecimiento');
    });

    test('borrar la venta no devuelve la fase: nunca retrocede', () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      final venta = await vender(p, crop.id);
      expect(p.crops.single.phase, CropPhase.produccion);

      await p.deleteTransaction(venta.id);

      expect(p.crops.single.phase, CropPhase.produccion,
          reason: 'un cultivo que ya produjo no vuelve a estar por sembrar');
    });
  });

  group('Efecto 2 · la alerta 13 se apaga sola', () {
    test('antes de vender avisa; con la venta deja de avisar', () async {
      final p = await build();
      final crop = await p.addCrop(
        'Café',
        primerCosechaEsperada: DateTime(2026, 3, 1),
      );

      expect(regla13(avisos(p)), hasLength(1),
          reason: 'la fecha pasó y todavía no cosechó');

      await vender(p, crop.id);

      expect(regla13(avisos(p)), isEmpty,
          reason: 'la cosecha derivada SÍ es cosecha: ya no le queda nada '
              'que avisar — se apaga sola, sin descarte ni paso nuevo');
    });

    test('un cultivo sin fecha sigue sin avisar', () async {
      final p = await build();
      await p.addCrop('Café');
      await vender(p, p.crops.single.id);

      expect(regla13(avisos(p)), isEmpty);
    });
  });

  group('Efecto 3 · el déficit sube de info a danger', () {
    test('un cultivo que ya vendió reporta la pérdida como peligro', () async {
      final p = await build();
      final crop = await p.addCrop('Café'); // establecimiento por defecto

      await gastar(p, crop.id, monto: 1000);
      await vender(p, crop.id, monto: 100, kg: 5); // -90 %

      expect(p.crops.single.phase, CropPhase.produccion,
          reason: 'la venta es la que saca al cultivo de establecimiento');

      final a = avisos(p);

      expect(a.any((x) => x.rule == AlertRule.cropEstablishment), isFalse,
          reason: 'ese era el aviso `info` de «aún en establecimiento»');
      expect(
        a.any((x) =>
            x.rule == AlertRule.deficitCrop &&
            x.severity == AlertSeverity.danger),
        isTrue,
        reason: 'ahora sí se reporta como pérdida de producción',
      );
    });

    test('mismo gasto y misma venta, pero sin kilos: no se deriva nada',
        () async {
      final p = await build();
      final crop = await p.addCrop('Café');

      await gastar(p, crop.id, monto: 1000);
      await p.addTransaction(
        type: TransactionType.income,
        category: kIncomeCategorySale,
        amount: 100,
        cropId: crop.id,
        // Sin kilos: no hay cosecha que derivar → la fase no sube.
        date: delAno,
      );

      expect(p.harvests, isEmpty);
      expect(p.crops.single.phase, CropPhase.establecimiento);
      expect(
        avisos(p).any((x) => x.rule == AlertRule.cropEstablishment),
        isTrue,
        reason: 'el dato a medias no debe mover la fase',
      );
    });
  });

  // Un lote arrancado de nuevo **empieza de cero**: la fase vuelve a
  // `establecimiento` (`sowing_screen.dart:388-403`) y las cosechas de antes,
  // que son hechos y no se borran, no pueden devolverlo a producción en la
  // apertura siguiente.
  group('Frontera de plantación · lo arrancado no vuelve solo a producción', () {
    test('arranque nuevo: se queda en establecimiento con cosechas viejas',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs);

      final vieja = TransactionProvider(store);
      final crop = await vieja.addCrop('Café');
      await vender(vieja, crop.id); // cosecha derivada del 5/10
      expect(vieja.crops.single.phase, CropPhase.produccion);

      // El arranque nuevo: siembra **después** de esa cosecha y la fase
      // vuelve a `establecimiento`, igual que lo hace la pantalla de siembra.
      await vieja.addSowing(
        cropId: crop.id,
        date: DateTime(2026, 10, 15),
        plants: 200,
      );
      await vieja.updateCrop(
        vieja.crops.single.copyWith(phase: CropPhase.establecimiento),
      );

      // Otra tanda de arranque, mismo disco.
      final p = TransactionProvider(store);

      expect(p.crops.single.phase, CropPhase.establecimiento,
          reason: 'lo arrancó de nuevo: las cosechas viejas son de la '
              'plantación anterior y no lo pueden devolver a producción');
    });

    test('siembra anterior a la cosecha: se arregla al abrir, como siempre',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs);

      final vieja = TransactionProvider(store);
      final crop = await vieja.addCrop('Café');
      // La siembra es de antes de esa cosecha: sigue siendo el mismo lote.
      await vieja.addSowing(
        cropId: crop.id,
        date: DateTime(2026, 1, 10),
        plants: 300,
      );
      await vender(vieja, crop.id); // 5/10 — posterior a la siembra
      await vieja.updateCrop(
        vieja.crops.single.copyWith(phase: CropPhase.establecimiento),
      );

      final p = TransactionProvider(store);

      expect(p.crops.single.phase, CropPhase.produccion,
          reason: 'produjo después de esa siembra: es el mismo lote, y la '
              'cuenta vieja sin fase resuelta no puede quedarse atascada');
    });

    test('vender después del arranque vuelve a promoverlo', () async {
      final p = await build();
      final crop = await p.addCrop('Café');
      await vender(p, crop.id); // 5/10
      await p.addSowing(
        cropId: crop.id,
        date: DateTime(2026, 10, 15),
        plants: 200,
      );
      await p.updateCrop(
        p.crops.single.copyWith(phase: CropPhase.establecimiento),
      );
      expect(p.crops.single.phase, CropPhase.establecimiento);

      // Ya volvió a producir tras el arranque.
      await p.addTransaction(
        type: TransactionType.income,
        category: kIncomeCategorySale,
        amount: 80000,
        cropId: crop.id,
        quantity: 25,
        unit: 'kg',
        date: DateTime(2026, 10, 18),
      );

      expect(p.crops.single.phase, CropPhase.produccion,
          reason: 'produjo después del arranque: ahí sí manda el hecho');
    });
  });
}
