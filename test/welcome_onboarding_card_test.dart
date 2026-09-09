import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/widgets/welcome_onboarding_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpCard(WidgetTester tester,
      {void Function()? onRegisterCrop,
      void Function()? onRegisterSowing}) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: WelcomeOnboardingCard(
          onRegisterCrop: onRegisterCrop ?? () {},
          onRegisterSowing: onRegisterSowing ?? () {},
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('muestra las dos cards de primer paso', (tester) async {
    await pumpCard(tester);
    final l10n = AppLocalizations.of(
        tester.element(find.byType(WelcomeOnboardingCard)))!;

    expect(find.text(l10n.welcomeTitle), findsOneWidget);
    expect(find.text(l10n.welcomeExistingTitle), findsOneWidget);
    expect(find.text(l10n.welcomeNewTitle), findsOneWidget);
    expect(find.text(l10n.welcomeHint), findsOneWidget);
  });

  testWidgets('card "registrar cultivo" dispara su callback', (tester) async {
    var opened = false;
    await pumpCard(tester, onRegisterCrop: () => opened = true);
    final l10n = AppLocalizations.of(
        tester.element(find.byType(WelcomeOnboardingCard)))!;

    await tester.tap(find.text(l10n.welcomeExistingTitle));
    expect(opened, isTrue);
  });

  testWidgets('card "registrar siembra" dispara su callback', (tester) async {
    var opened = false;
    await pumpCard(tester, onRegisterSowing: () => opened = true);
    final l10n = AppLocalizations.of(
        tester.element(find.byType(WelcomeOnboardingCard)))!;

    await tester.tap(find.text(l10n.welcomeNewTitle));
    expect(opened, isTrue);
  });
}