import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/screens/assign_crops_screen.dart';
import 'package:mi_cafetal/screens/crops_screen.dart';
import 'package:mi_cafetal/screens/register_screen.dart';
import 'package:mi_cafetal/screens/sowing_screen.dart';
import 'package:mi_cafetal/widgets/new_crop_dialog.dart';

import 'helpers/l2_common.dart';

/// L2.2 — nombres repetidos (decisión C4): el diálogo resuelve la ambigüedad
/// y las pantallas ya no vuelven a "matchear" por nombre.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDialogHost(
    WidgetTester tester,
    List<Crop> crops,
    void Function(NewCropResult?) onResult,
  ) async {
    await tester.pumpWidget(plainApp(Scaffold(
      body: Center(
        child: Builder(builder: (context) => ElevatedButton(
          onPressed: () => showDialog<NewCropResult>(
            context: context,
            builder: (_) => NewCropDialog(crops: crops),
          ).then(onResult),
          child: const Text('abrir'),
        )),
      ),
    )));
    await tester.pumpAndSettle();
  }

  Finder dropdownWithNewOption() => find.byWidgetPredicate((w) =>
      w is DropdownButton<String> &&
      (w.items ?? const []).any((i) => i.value == '__new__'));

  group('NewCropDialog', () {
    testWidgets('nombre repetido ofrece las tres salidas', (tester) async {
      NewCropResult? result;
      await pumpDialogHost(
          tester, [const Crop(id: 'a', name: 'Café')], (r) => result = r);

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      // Distinto de 'Café' solo en mayúsculas: tiene que seguir contando.
      await submitNewCrop(tester, 'café');

      expect(result, isNull,
          reason: 'el diálogo no puede decidir por el usuario');
      expect(find.byType(NewCropDialog), findsOneWidget);
      expect(find.text(es.newCropDuplicateTitle), findsOneWidget);
      expect(find.text(es.newCropDuplicateBody('café')), findsOneWidget);
      expect(find.text(es.newCropUseExisting), findsOneWidget);
      expect(find.text(es.newCropCreateAnother), findsOneWidget);
      expect(find.text(es.cancel), findsOneWidget);
    });

    testWidgets('"usar el que ya tienes" devuelve el id existente',
        (tester) async {
      NewCropResult? result;
      await pumpDialogHost(
          tester, [const Crop(id: 'a', name: 'Café')], (r) => result = r);

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await submitNewCrop(tester, 'CAFÉ');
      await tester.tap(inNewCrop(find.text(es.newCropUseExisting)));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.existingId, 'a');
      expect(result!.isNew, isFalse);
    });

    testWidgets('"crear otro igual" devuelve un cultivo nuevo', (tester) async {
      NewCropResult? result;
      await pumpDialogHost(
          tester, [const Crop(id: 'a', name: 'Café')], (r) => result = r);

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await submitNewCrop(tester, 'Café');
      await tester.tap(inNewCrop(find.text(es.newCropCreateAnother)));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.isNew, isTrue);
      expect(result!.existingId, isNull);
      expect(result!.name, 'Café');
    });

    testWidgets('cancelar cierra sin decidir', (tester) async {
      NewCropResult? result;
      await pumpDialogHost(
          tester, [const Crop(id: 'a', name: 'Café')], (r) => result = r);

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await submitNewCrop(tester, 'Café');
      await tester.tap(inNewCrop(find.text(es.cancel)));
      await tester.pumpAndSettle();

      expect(result, isNull);
      expect(find.byType(NewCropDialog), findsNothing);
    });

    testWidgets('nombre nuevo crea directo, sin segunda pregunta',
        (tester) async {
      NewCropResult? result;
      await pumpDialogHost(tester, [const Crop(id: 'a', name: 'Café')],
          (r) => result = r);

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await submitNewCrop(tester, 'Plátano');

      expect(find.byType(NewCropDialog), findsNothing);
      expect(find.text(es.newCropDuplicateTitle), findsNothing);
      expect(result, isNotNull);
      expect(result!.isNew, isTrue);
      expect(result!.name, 'Plátano');
    });
  });

  group('las pantallas resuelven por existingId', () {
    testWidgets('Siembras: usar el existente no crea otro cultivo',
        (tester) async {
      bigScreen(tester);
      final provider = await makeTx();
      await provider.addCrop('Plátano');
      final cafe1 = await provider.addCrop('Café');
      await provider.addCrop('Café');
      expect(provider.crops, hasLength(3));

      await tester.pumpWidget(appWith(provider, const SowingScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(es.sowingAdd));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(es.sowingNewCropOption).last);
      await tester.pumpAndSettle();
      await submitNewCrop(tester, 'café');
      expect(find.byType(NewCropDialog), findsOneWidget,
          reason: 'debe preguntar en lugar de fusionar en silencio');
      await tester.tap(inNewCrop(find.text(es.newCropUseExisting)));
      await tester.pumpAndSettle();

      expect(provider.crops, hasLength(3),
          reason: 'elegir el existente no debe crear un cuarto cultivo');

      await tester.enterText(find.byType(TextFormField).first, '100');
      await tester.tap(find.text(es.add).last);
      await tester.pumpAndSettle();

      expect(provider.sowings, hasLength(1));
      expect(provider.sowings.single.cropId, cafe1.id);
    });

    testWidgets('Siembras: "crear otro igual" sí crea un cultivo nuevo',
        (tester) async {
      bigScreen(tester);
      final provider = await makeTx();
      await provider.addCrop('Café');
      expect(provider.crops, hasLength(1));

      await tester.pumpWidget(appWith(provider, const SowingScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(es.sowingAdd));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(es.sowingNewCropOption).last);
      await tester.pumpAndSettle();
      await submitNewCrop(tester, 'café');
      await tester.tap(inNewCrop(find.text(es.newCropCreateAnother)));
      await tester.pumpAndSettle();

      expect(provider.crops, hasLength(2),
          reason: 'la decisión de repetir nombre ahora es del usuario');

      await tester.enterText(find.byType(TextFormField).first, '100');
      await tester.tap(find.text(es.add).last);
      await tester.pumpAndSettle();

      expect(provider.sowings.single.cropId, provider.crops.last.id);
    });

    testWidgets('Registro: usa el id existente sin duplicar', (tester) async {
      bigScreen(tester);
      final provider = await makeTx();
      final cafe1 = await provider.addCrop('Café');
      await provider.addCrop('Café');

      await tester.pumpWidget(
          appWith(provider, const Scaffold(body: RegisterScreen())));
      await tester.pumpAndSettle();

      await tester.tap(dropdownWithNewOption());
      await tester.pumpAndSettle();
      await tester.tap(find.text(es.cropNewOption).last);
      await tester.pumpAndSettle();
      await submitNewCrop(tester, 'CAFÉ');
      await tester.tap(inNewCrop(find.text(es.newCropUseExisting)));
      await tester.pumpAndSettle();

      expect(provider.crops, hasLength(2),
          reason: 'sin id no habría forma de saber cuál de los dos "Café"');

      await tester.enterText(find.byType(TextFormField).at(1), '1000');
      await tester.tap(find.text(es.saveRecord));
      await tester.pumpAndSettle();

      expect(provider.transactions, hasLength(1));
      expect(provider.transactions.single.cropId, cafe1.id);
    });

    testWidgets('Asignar: usa el id existente sin duplicar', (tester) async {
      bigScreen(tester);
      final provider = await makeTx();
      await provider.addTransaction(
        type: TransactionType.expense,
        category: 'fertilizante',
        amount: 500000,
        description: 'Abono',
        date: DateTime(2026, 9, 1),
      );
      final cafe1 = await provider.addCrop('Café');
      await provider.addCrop('Café');

      await tester.pumpWidget(appWith(provider, Scaffold(
        body: Center(
          child: Builder(builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AssignCropsScreen())),
            child: const Text('abrir'),
          )),
        ),
      )));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(es.assignCropsNewCrop).last);
      await tester.pumpAndSettle();
      await submitNewCrop(tester, 'café');
      await tester.tap(inNewCrop(find.text(es.newCropUseExisting)));
      await tester.pumpAndSettle();

      expect(provider.crops, hasLength(2));

      await tester.tap(find.text(es.assignCropsSave));
      await tester.pumpAndSettle();

      expect(provider.transactions.single.cropId, cafe1.id);
    });
  });

  group('lista de Cultivos', () {
    testWidgets('con nombres distintos no añade subtítulo', (tester) async {
      bigScreen(tester);
      final provider = await makeTx();
      await provider.addCrop('Café');
      await provider.addCrop('Plátano');

      await tester.pumpWidget(appWith(provider, const CropsScreen()));
      await tester.pumpAndSettle();

      expect(find.text(es.cropLotTag(1)), findsNothing);
      expect(find.text(es.cropLotTag(2)), findsNothing);
      expect(find.text(es.cropLotTag(3)), findsNothing);
    });

    testWidgets('con el nombre repetido cada fila se distingue', (tester) async {
      bigScreen(tester);
      final provider = await makeTx();
      await provider.addCrop('Plátano');
      await provider.addCrop('Café', areaHa: 0.4);
      await provider.addCrop('Café');

      await tester.pumpWidget(appWith(provider, const CropsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('0,4 ha'), findsOneWidget,
          reason: 'el que tiene área se distingue por su área');
      expect(find.text(es.cropLotTag(2)), findsOneWidget,
          reason: 'sin área se usa el ordinal');
      expect(find.text(es.cropLotTag(1)), findsNothing,
          reason: 'Plátano no está repetido: no lleva etiqueta');
      expect(find.text(es.cropLotTag(3)), findsNothing);
    });
  });
}
