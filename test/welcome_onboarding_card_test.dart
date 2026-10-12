import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/widgets/welcome_onboarding_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Registra lo que la puerta le devuelve a HomeScreen.
  late List<WelcomeCropDraft> anadidos;
  late List<WelcomeCropDraft> completados;
  late List<(Crop, WelcomeCropDraft)> editados;
  late bool entro;

  Future<void> pumpCard(WidgetTester tester, {List<Crop> crops = const []}) async {
    anadidos = [];
    completados = [];
    editados = [];
    entro = false;

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: WelcomeOnboardingCard(
          crops: crops,
          onAdd: anadidos.add,
          onComplete: completados.add,
          onEdit: (crop, draft) => editados.add((crop, draft)),
          onEnter: () => entro = true,
        ),
      ),
    ));
    await tester.pump();
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(WelcomeOnboardingCard)))!;

  testWidgets('finca vacía: lista vacía y ninguna especie inventada',
      (tester) async {
    await pumpCard(tester);
    final l10n = l10nOf(tester);

    expect(find.text(l10n.welcomeTitle), findsOneWidget);
    expect(find.text(l10n.welcomeSubtitle), findsOneWidget);

    // La lista es SUYA: empieza vacía, sin Café ni Plátano prestados.
    expect(find.text(l10n.welcomeEmptyList), findsOneWidget);
    expect(find.text(l10n.welcomeAddFirst), findsOneWidget);
    expect(find.text('Café'), findsNothing);
    expect(find.text('Plátano'), findsNothing);

    // Sin nada todavía no hay adónde entrar (G3 abre recién con ≥1).
    expect(find.text(l10n.welcomeEnter), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('con cultivos: los lista y ofrece salir a la app', (tester) async {
    await pumpCard(tester, crops: const [
      Crop(id: 'a', name: 'Café', icon: '☕'),
      Crop(id: 'b', name: 'Plátano', icon: '🍌'),
    ]);
    final l10n = l10nOf(tester);

    expect(find.text('Café'), findsOneWidget);
    expect(find.text('Plátano'), findsOneWidget);
    expect(find.text(l10n.welcomeEmptyList), findsNothing);
    expect(find.text(l10n.welcomeAddMore), findsOneWidget);
    expect(find.text(l10n.welcomeEnter), findsOneWidget);
  });

  testWidgets('[Agregar el primero] abre la ficha corta y crea con lo mínimo',
      (tester) async {
    await pumpCard(tester);
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.welcomeAddFirst));
    await tester.pumpAndSettle();

    // Ficha corta (G1): nombre obligatorio, icono y fecha opcional.
    expect(find.text(l10n.welcomeTitle), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(l10n.welcomeDone), findsOneWidget);
    expect(find.text(l10n.welcomeComplete), findsOneWidget);

    // Cancelar no crea nada.
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(anadidos, isEmpty);
    expect(completados, isEmpty);

    // Ahora sí: nombre + Listo.
    await tester.tap(find.text(l10n.welcomeAddFirst));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Café  ');
    await tester.tap(find.text(l10n.welcomeDone));
    await tester.pumpAndSettle();

    expect(anadidos, hasLength(1));
    expect(completados, isEmpty);
    expect(anadidos.single.name, 'Café');
    expect(anadidos.single.icon, '🌱'); // el primer icono de la tira
    expect(anadidos.single.plantedAt, isNull); // G4: la fecha no insiste
  });

  testWidgets('el nombre es obligatorio', (tester) async {
    await pumpCard(tester);
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.welcomeAddFirst));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text(l10n.welcomeDone));
    await tester.pumpAndSettle();

    expect(anadidos, isEmpty);
    expect(find.text(l10n.cropNameRequired), findsOneWidget);

    // Al escribir, el error se retira solo.
    await tester.enterText(find.byType(TextField), 'Maíz');
    await tester.pump();
    expect(find.text(l10n.cropNameRequired), findsNothing);

    await tester.tap(find.text(l10n.welcomeDone));
    await tester.pumpAndSettle();
    expect(anadidos.single.name, 'Maíz');
  });

  testWidgets('[Completar datos…] sale por onComplete, no por onAdd',
      (tester) async {
    await pumpCard(tester);
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.welcomeAddFirst));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mango');
    await tester.tap(find.text(l10n.welcomeComplete));
    await tester.pumpAndSettle();

    expect(anadidos, isEmpty);
    expect(completados, hasLength(1));
    expect(completados.single.name, 'Mango');
  });

  testWidgets('toca un cultivo de la lista y lo corrige en la ficha',
      (tester) async {
    await pumpCard(tester, crops: const [
      Crop(id: 'a', name: 'Café', icon: '☕'),
    ]);
    final l10n = l10nOf(tester);

    await tester.tap(find.text('Café'));
    await tester.pumpAndSettle();

    // Ya no es "crear": es corregir.
    expect(find.text(l10n.editCropTitle), findsOneWidget);
    expect(find.text(l10n.welcomeComplete), findsNothing);

    await tester.enterText(find.byType(TextField), 'Café caturra');
    await tester.tap(find.text(l10n.edit));
    await tester.pumpAndSettle();

    expect(editados, hasLength(1));
    expect(editados.single.$1.id, 'a');
    expect(editados.single.$2.name, 'Café caturra');
    expect(anadidos, isEmpty);
  });

  testWidgets('[Entrar a la app] dispara onEnter', (tester) async {
    await pumpCard(tester, crops: const [
      Crop(id: 'a', name: 'Café', icon: '☕'),
    ]);
    final l10n = l10nOf(tester);

    expect(entro, isFalse);
    await tester.tap(find.text(l10n.welcomeEnter));
    expect(entro, isTrue);
  });
}
