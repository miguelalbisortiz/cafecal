import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/screens/movements_screen.dart';
import 'package:mi_cafetal/services/local_store.dart';

/// La notación de las cifras sigue al **idioma**: quien pone la app en inglés
/// lee los números en inglés — también la plata.
///
/// Antes había un campo aparte (`locale`) que nadie editaba, así que se quedaba
/// clavado en `es_CO`: con el idioma en inglés salían las fechas y los conteos
/// en inglés, pero los montos con la notación del español.
///
/// Se prueba sobre la pantalla de verdad (con su formateador), no sobre el
/// formateador suelto: una guarda que no atraviesa el camino real no prueba
/// nada.

Future<TransactionProvider> _provider(String language) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final tx = TransactionProvider(LocalStore(prefs));
  await tx.updateSettings(FarmSettings(language: language));
  await tx.addTransaction(
      type: TransactionType.income,
      category: 'venta_cafe',
      amount: 1500,
      date: DateTime(2026, 9, 1));
  return tx;
}

/// Como en `main.dart`: el idioma de los ajustes manda en la app.
Widget _wrap(TransactionProvider tx, Widget home) => MultiProvider(
      providers: [ChangeNotifierProvider<TransactionProvider>.value(value: tx)],
      child: MaterialApp(
        locale: Locale(tx.settings.language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

Future<void> _pumpMovements(WidgetTester tester, TransactionProvider tx) async {
  await tester.pumpWidget(_wrap(tx, const Scaffold(body: MovementsScreen())));
  await tester.pumpAndSettle();
}

void main() {
  test('los ajustes viejos se curan al leerlos: manda el idioma', () {
    // El `locale` guardado por una versión anterior ya no se lee: con el idioma
    // en inglés, la notación es inglesa aunque el archivo diga `es_CO`.
    final viejo = FarmSettings.fromJson(const {
      'language': 'en',
      'locale': 'es_CO',
    });

    expect(viejo.numberLocale, 'en_US');
    expect(const FarmSettings().numberLocale, 'es_CO');
  });

  testWidgets('con la app en español la plata se lee en español',
      (tester) async {
    final tx = await _provider('es');
    await _pumpMovements(tester, tx);

    expect(find.text('COP 1.500'), findsWidgets,
        reason: 'en español el separador de miles es el punto');
    expect(find.text('COP 1,500'), findsNothing);
  });

  testWidgets('con la app en inglés la plata también', (tester) async {
    final tx = await _provider('en');
    await _pumpMovements(tester, tx);

    expect(find.text('COP 1,500'), findsWidgets,
        reason: 'en inglés el separador de miles es la coma');
    expect(find.text('COP 1.500'), findsNothing,
        reason: 'la notación del español no debe asomar en una app en inglés');
  });
}
