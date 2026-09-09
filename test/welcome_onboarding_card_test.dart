import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/widgets/welcome_onboarding_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpCard(WidgetTester tester,
      {void Function()? onExistingFarm,
      void Function()? onNewSowing,
      void Function()? onOpenGuide}) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: WelcomeOnboardingCard(
          onExistingFarm: onExistingFarm ?? () {},
          onNewSowing: onNewSowing ?? () {},
          onOpenGuide: onOpenGuide ?? () {},
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('muestra las dos opciones de entrada', (tester) async {
    await pumpCard(tester);
    final l10n = AppLocalizations.of(
        tester.element(find.byType(WelcomeOnboardingCard)))!;

    expect(find.text(l10n.welcomeTitle), findsOneWidget);
    expect(find.text(l10n.welcomeExistingTitle), findsOneWidget);
    expect(find.text(l10n.welcomeExistingAction), findsOneWidget);
    expect(find.text(l10n.welcomeNewTitle), findsOneWidget);
    expect(find.text(l10n.welcomeNewAction), findsOneWidget);
  });

  testWidgets('opción "ya tengo plantas" dispara su callback', (tester) async {
    var opened = false;
    await pumpCard(tester, onExistingFarm: () => opened = true);
    final l10n = AppLocalizations.of(
        tester.element(find.byType(WelcomeOnboardingCard)))!;

    await tester.tap(find.text(l10n.welcomeExistingAction));
    expect(opened, isTrue);
  });

  testWidgets('opción "registrar siembra" dispara su callback', (tester) async {
    var opened = false;
    await pumpCard(tester, onNewSowing: () => opened = true);
    final l10n = AppLocalizations.of(
        tester.element(find.byType(WelcomeOnboardingCard)))!;

    await tester.tap(find.text(l10n.welcomeNewAction));
    expect(opened, isTrue);
  });

  testWidgets('el link de guía dispara su callback', (tester) async {
    var opened = false;
    await pumpCard(tester, onOpenGuide: () => opened = true);
    final l10n = AppLocalizations.of(
        tester.element(find.byType(WelcomeOnboardingCard)))!;

    expect(find.text(l10n.nextStepGuideLink), findsOneWidget);
    await tester.tap(find.text(l10n.nextStepGuideLink));
    expect(opened, isTrue);
  });
}