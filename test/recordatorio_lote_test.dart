// El recordatorio del lote.
//
// Registrar un gasto de lote dejaba `_cropId` en null, y el
// `copyWith(lastCropId: null)` limpia el recordatorio a propósito. El lote no
// se guardaba en ningún sitio, así que el SIGUIENTE gasto compartido arrancaba
// en "Costos comunes" y dejaba de repartirse por hectáreas. Sin aviso, sin
// color, sin nada: el agricultor solo veía que el desplegable venía vacío.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/register_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> makeProvider() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return TransactionProvider(LocalStore(prefs));
  }

  Future<void> pumpRegistrar(WidgetTester tester, TransactionProvider tx,
      {TransactionType? initialType}) async {
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: tx,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: RegisterScreen(initialType: initialType)),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('un gasto de lote deja el lote puesto la próxima vez',
      (tester) async {
    final tx = await makeProvider();
    final lote = await tx.addTerreno('Lote de arriba');

    // Exactamente lo que hace Registrar al guardar un gasto de lote:
    // cultivo en null, lote puesto.
    await tx.updateSettings(
        tx.settings.copyWith(lastCropId: null, lastTerrenoId: lote.id));

    await pumpRegistrar(tester, tx);

    expect(find.text(lote.name), findsWidgets,
        reason: 'el lote elegido no se preselecciona: el siguiente gasto '
            'compartido arrancaría en "Costos comunes" y dejaría de '
            'repartirse por hectáreas');
  });

  testWidgets('si el lote ya no existe no se preselecciona nada raro',
      (tester) async {
    final tx = await makeProvider();
    final lote = await tx.addTerreno('Lote que se va');
    await tx.updateSettings(
        tx.settings.copyWith(lastCropId: null, lastTerrenoId: lote.id));
    await tx.deleteTerreno(lote.id);

    await pumpRegistrar(tester, tx);

    // Sin terrenos el desplegable no ofrece el grupo de lotes, y el hint
    // tiene que ser el de costos comunes, no el del lote fantasma.
    expect(find.text(lote.name), findsNothing);
  });

  testWidgets('un ingreso nunca arranca con lote puesto', (tester) async {
    final tx = await makeProvider();
    final lote = await tx.addTerreno('Lote de arriba');
    await tx.updateSettings(
        tx.settings.copyWith(lastCropId: null, lastTerrenoId: lote.id));

    // Un ingreso no tiene lote: es de un cultivo o de la finca entera.
    // Preseleccionarlo aquí metería un terrenoId en una venta.
    await pumpRegistrar(tester, tx, initialType: TransactionType.income);

    // En un desplegable cerrado solo se construye el ítem ELEGIDO. Si el
    // lote viniera puesto, su nombre aparecería pintado.
    expect(find.text(lote.name), findsNothing,
        reason: 'un ingreso no puede arrancar con un lote elegido');
  });

  test('FarmSettings guarda y devuelve el lote recordado', () {
    const base = FarmSettings();
    expect(base.lastTerrenoId, isNull,
        reason: 'respaldos viejos sin la clave → null, como siempre');

    final conLote = base.copyWith(lastCropId: null, lastTerrenoId: 't1');
    expect(conLote.lastTerrenoId, 't1');
    expect(conLote.lastCropId, isNull,
        reason: 'son mutuamente excluyentes: elegir lote limpia el cultivo');

    final json = conLote.toJson();
    expect(json['last_terreno_id'], 't1');
    expect(FarmSettings.fromJson(json).lastTerrenoId, 't1');

    // Sin centinela no se podría vaciar, y vaciar es lo que hace falta
    // cuando cambia de idea.
    final sinLote = conLote.copyWith(lastTerrenoId: null);
    expect(sinLote.lastTerrenoId, isNull);
    expect(sinLote.toJson().containsKey('last_terreno_id'), isFalse,
        reason: 'null no se serializa: la regla de la casa es null → oculto');
  });
}
