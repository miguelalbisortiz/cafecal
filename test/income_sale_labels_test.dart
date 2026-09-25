import 'package:flutter_test/flutter_test.dart';

import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/categories.dart';
import 'package:mi_cafetal/models/crop.dart';

AppLocalizations get _es => stringsFor('es');

void main() {
  const crops = [
    Crop(id: 'cafe', name: 'Café'),
    Crop(id: 'platano', name: 'Plátano'),
  ];

  group('incomeGroupKey — agrupación de ingresos en desgloses', () {
    test('la venta con cultivo se agrupa aparte por cultivo', () {
      expect(incomeGroupKey(kIncomeCategorySale, 'cafe'), 'venta|cafe');
      expect(incomeGroupKey(kIncomeCategorySale, 'platano'), 'venta|platano');
    });

    test('venta sin cultivo, claves legadas y gastos quedan tal cual', () {
      expect(incomeGroupKey(kIncomeCategorySale, null), 'venta');
      expect(incomeGroupKey(kIncomeCategorySale, ''), 'venta');
      expect(incomeGroupKey('venta_cafe', 'cafe'), 'venta_cafe');
      expect(incomeGroupKey('venta_otro', 'cafe'), 'venta_otro');
      expect(incomeGroupKey('subvenciones', 'cafe'), 'subvenciones');
      expect(incomeGroupKey('fertilizante', 'cafe'), 'fertilizante');
    });
  });

  group('etiquetas de ingreso (es)', () {
    test('incomeCategory: clave nueva y legadas', () {
      expect(_es.incomeCategory(kIncomeCategorySale), 'Venta');
      expect(_es.incomeCategory('venta_cafe'), 'Venta café');
      expect(_es.incomeCategory('venta_platano'), 'Venta plátano');
      expect(_es.incomeCategory('subvenciones'), 'Subvenciones y apoyos');
    });

    test('incomeSaleLabel: con cultivo "Venta {cultivo}", sin cultivo "Venta"',
        () {
      expect(_es.incomeSaleLabel(null), 'Venta');
      expect(_es.incomeSaleLabel(''), 'Venta');
      expect(_es.incomeSaleLabel('Plátano'), 'Venta Plátano');
    });

    test('incomeGroupLabel resuelve el cultivo del grupo', () {
      expect(_es.incomeGroupLabel('venta|cafe', crops), 'Venta Café');
      expect(_es.incomeGroupLabel('venta|platano', crops), 'Venta Plátano');
      // Cultivo borrado → "Venta" a secas, nunca la clave cruda.
      expect(_es.incomeGroupLabel('venta|inexistente', crops), 'Venta');
      // Legadas y otras categorías pasan tal cual.
      expect(_es.incomeGroupLabel('venta_cafe', crops), 'Venta café');
      expect(_es.incomeGroupLabel('subvenciones', crops),
          'Subvenciones y apoyos');
    });

    test('cropOf / cropNameOf', () {
      expect(cropOf(crops, 'cafe')?.name, 'Café');
      expect(cropOf(crops, null), isNull);
      expect(cropOf(crops, 'x'), isNull);
      expect(cropNameOf(crops, 'platano'), 'Plátano');
      expect(cropNameOf(crops, 'x'), isNull);
    });
  });

  group('isSaleCategory — detección de ventas (alertas e insights)', () {
    test('cubre la clave nueva y las legadas', () {
      expect(isSaleCategory(kIncomeCategorySale), isTrue);
      expect(isSaleCategory('venta_cafe'), isTrue);
      expect(isSaleCategory('venta_platano'), isTrue);
      expect(isSaleCategory('venta_otro'), isTrue);
    });

    test('no confunde otros ingresos ni gastos con ventas', () {
      expect(isSaleCategory('subvenciones'), isFalse);
      expect(isSaleCategory('fertilizante'), isFalse);
      expect(isSaleCategory('mano_obra'), isFalse);
    });
  });

  group('incomeCategories — opciones del dropdown al registrar', () {
    test('empieza por Venta y no ofrece las claves legadas al inicio', () {
      final keys = incomeCategories.map((c) => c.key).toList();
      expect(keys.first, kIncomeCategorySale);
      expect(keys.indexOf(kIncomeCategorySale),
          lessThan(keys.indexOf('subvenciones')));
      expect(keys.indexOf('subvenciones'), lessThan(keys.indexOf('venta_otro')));
      // Las legadas siguen presentes para icono/color de datos viejos.
      expect(keys, containsAll(['venta_cafe', 'venta_platano']));
    });
  });
}
