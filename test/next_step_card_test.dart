import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:mi_cafetal/services/next_step_service.dart';
import 'package:mi_cafetal/widgets/next_step_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TransactionProvider> makeProvider() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return TransactionProvider(LocalStore(prefs));
  }

  Future<void> pumpCard(
    WidgetTester tester,
    TransactionProvider provider, {
    void Function(NextStepType type)? onAction,
    VoidCallback? onOpenGuide,
  }) async {
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NextStepCard(
            onAction: onAction ?? (_) {},
            onOpenGuide: onOpenGuide ?? () {},
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  final l10n = stringsFor('es');

  testWidgets('cuenta nueva (solo cultivos por defecto) guía a configurar el cultivo', (tester) async {
    final provider = await makeProvider();
    await pumpCard(tester, provider);

    expect(find.text(l10n.nextStepCropSetupTitle), findsOneWidget);
    expect(find.text(l10n.nextStepAction), findsOneWidget);
  });

  testWidgets('avanza gastos → cosecha → venta → se oculta', (tester) async {
    final provider = await makeProvider();
    await pumpCard(tester, provider);

    await provider.addTransaction(
      type: TransactionType.expense,
      category: 'cosecha',
      amount: 50000,
    );
    await tester.pump();
    expect(find.text(l10n.nextStepCropSetupTitle), findsNothing);
    expect(find.text(l10n.nextStepHarvestTitle), findsOneWidget);

    await provider.addHarvest(
      amount: 100,
      unit: 'kg',
      date: DateTime.now(),
      destination: HarvestDestination.almacenado,
    );
    await tester.pump();
    expect(find.text(l10n.nextStepSaleTitle), findsOneWidget);

    await provider.addTransaction(
      type: TransactionType.income,
      category: 'venta_cafe',
      amount: 120000,
    );
    await tester.pump();
    expect(find.text(l10n.nextStepTitle), findsNothing);
    expect(find.text(l10n.nextStepAction), findsNothing);
  });

  testWidgets('el botón dispara la acción del paso correcto', (tester) async {
    final provider = await makeProvider();
    NextStepType? tapped;
    await pumpCard(tester, provider, onAction: (t) => tapped = t);

    await tester.tap(find.text(l10n.nextStepAction));
    expect(tapped, NextStepType.crop);
  });

  testWidgets('el link "Ver guía completa" dispara el callback de guía', (tester) async {
    final provider = await makeProvider();
    var opened = false;
    await pumpCard(tester, provider, onOpenGuide: () => opened = true);

    expect(find.text(l10n.nextStepGuideLink), findsOneWidget);
    await tester.tap(find.text(l10n.nextStepGuideLink));
    expect(opened, isTrue);
  });
}