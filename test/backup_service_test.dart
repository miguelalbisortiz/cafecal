import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/employee.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/services/backup_service.dart';

void main() {
  final crops = [
    const Crop(id: 'c1', name: 'Café'),
    const Crop(id: 'c2', name: 'Plátano'),
  ];
  final sowings = [
    Sowing(id: 's1', cropId: 'c1', date: DateTime(2026, 1, 1), plants: 1200),
  ];
  final harvests = [
    Harvest(id: 'h1', cropId: 'c1', date: DateTime(2026, 9, 1), amount: 50),
  ];
  final employees = [const Employee(id: 'e1', name: 'Pedro', dayRate: 60000)];
  final transactions = [
    Transaction(
      id: 't1',
      cropId: 'c1',
      type: TransactionType.income,
      category: 'venta_cafe',
      amount: 250000,
      date: DateTime(2026, 9, 2),
      createdAt: DateTime(2026, 9, 2),
      pendingSync: true,
    ),
  ];
  const settings = FarmSettings(
    farmName: 'El Recuerdo',
    currency: 'COP',
    cajaMenorMensual: 500000,
  );

  String build() => encodeBackup(
        crops: crops,
        sowings: sowings,
        harvests: harvests,
        employees: employees,
        transactions: transactions,
        settings: settings,
        uid: 'uid-1',
        now: DateTime(2026, 10, 3, 8, 30),
      );

  group('encode/decode roundtrip', () {
    test('conserva colecciones, ajustes, cuenta y fecha', () {
      final payload = decodeBackup(build());

      expect(payload.cuenta, 'uid-1');
      expect(payload.exportadoEn, DateTime(2026, 10, 3, 8, 30));
      expect(payload.crops.map((c) => c.id).toList(), ['c1', 'c2']);
      expect(payload.sowings.single.plants, 1200);
      expect(payload.harvests.single.amount, 50);
      expect(payload.employees.single.name, 'Pedro');
      expect(payload.transactions.single.amount, 250000);
      expect(payload.settings.farmName, 'El Recuerdo');
      expect(payload.settings.cajaMenorMensual, 500000);
    });

    test('el envelope trae formato, versión y conteos correctos', () {
      final map = jsonDecode(build()) as Map<String, dynamic>;

      expect(map['formato'], kBackupFormat);
      expect(map['version'], kBackupVersion);
      expect(map['exportadoEn'], '2026-10-03T08:30:00.000');
      expect(map['cuenta'], 'uid-1');
      expect(map['conteo'], {
        'cultivos': 2,
        'siembras': 1,
        'cosechas': 1,
        'empleados': 1,
        'movimientos': 1,
      });
      expect(decodeBackup(build()).conteo,
          const BackupCounts(
              cultivos: 2,
              siembras: 1,
              cosechas: 1,
              empleados: 1,
              movimientos: 1));
    });

    test('un respaldo vacío también se puede leer', () {
      final payload = decodeBackup(encodeBackup(
        crops: const [],
        sowings: const [],
        harvests: const [],
        employees: const [],
        transactions: const [],
        settings: const FarmSettings(),
        now: DateTime(2026, 10, 3),
      ));

      expect(payload.cuenta, '');
      expect(payload.exportadoEn, DateTime(2026, 10, 3));
      expect(payload.conteo.total, 0);
      expect(payload.crops, isEmpty);
    });

    test('no exporta la cola de sincronización', () {
      final map = jsonDecode(build()) as Map<String, dynamic>;

      expect(map.containsKey('deleted_crops_v1'), isFalse);
      expect(map.containsKey('settings_dirty_v1'), isFalse);
      expect(map.containsKey('synced_at_v1'), isFalse);
    });
  });

  group('decode rechaza lo que no es un respaldo', () {
    test('JSON malformado', () {
      expect(() => decodeBackup('{esto no es json'),
          throwsA(isA<FormatException>()));
      expect(() => decodeBackup('[1, 2, 3]'), throwsA(isA<FormatException>()));
      expect(() => decodeBackup(''), throwsA(isA<FormatException>()));
    });

    test('formato distinto', () {
      final map = jsonDecode(build()) as Map<String, dynamic>;
      map['formato'] = 'otro-formato';

      expect(
        () => decodeBackup(jsonEncode(map)),
        throwsA(isA<BackupFormatException>().having(
            (e) => e.kind, 'kind', BackupErrorKind.formatoDesconocido)),
      );
    });

    test('versión distinta de 1', () {
      for (final version in [0, 2, 99]) {
        final map = jsonDecode(build()) as Map<String, dynamic>;
        map['version'] = version;

        expect(
          () => decodeBackup(jsonEncode(map)),
          throwsA(isA<BackupFormatException>().having(
              (e) => e.kind, 'kind', BackupErrorKind.versionNoSoportada)),
          reason: 'la versión $version no debe restaurarse a ciegas',
        );
      }
    });

    test('falta una colección', () {
      final map = jsonDecode(build()) as Map<String, dynamic>;
      map.remove('movimientos');

      expect(
        () => decodeBackup(jsonEncode(map)),
        throwsA(isA<BackupFormatException>()
            .having((e) => e.kind, 'kind', BackupErrorKind.incompleto)
            .having((e) => e.message, 'message', contains('movimientos'))),
      );
    });

    test('faltan los ajustes', () {
      final map = jsonDecode(build()) as Map<String, dynamic>;
      map.remove('ajustes');

      expect(
        () => decodeBackup(jsonEncode(map)),
        throwsA(isA<BackupFormatException>()
            .having((e) => e.kind, 'kind', BackupErrorKind.incompleto)),
      );
    });

    test('un registro dañado no se importa a medias', () {
      final map = jsonDecode(build()) as Map<String, dynamic>;
      // Un cultivo sin id: inválido, pero el resto del archivo es bueno.
      (map['cultivos'] as List).add({'name': 'Sin id'});

      expect(
        () => decodeBackup(jsonEncode(map)),
        throwsA(isA<BackupFormatException>()
            .having((e) => e.kind, 'kind', BackupErrorKind.malformado)),
      );
    });
  });

  group('mergeBackupSettings', () {
    test('un valor del archivo manda sobre el local', () {
      final merged = mergeBackupSettings(
        const FarmSettings(farmName: 'Local', currency: 'COP'),
        const FarmSettings(farmName: 'Del archivo', currency: 'USD'),
      );

      expect(merged.farmName, 'Del archivo');
      expect(merged.currency, 'USD');
    });

    test('los valores por defecto del archivo no borran lo local', () {
      final merged = mergeBackupSettings(
        const FarmSettings(
            farmName: 'Local',
            currency: 'USD',
            lowPriceThresholdPerKg: 8000,
            cajaMenorMensual: 900000,
            sacoKg: 60),
        const FarmSettings(), // todo por defecto / nulo
      );

      expect(merged.farmName, 'Local');
      expect(merged.currency, 'USD');
      expect(merged.lowPriceThresholdPerKg, 8000);
      expect(merged.cajaMenorMensual, 900000);
      // Un respaldo anterior a A2 manda 70 (el default): no debe
      // reventar su costal de 60 kg.
      expect(merged.sacoKg, 60);
    });

    test('el peso del archivo manda si no es el default', () {
      final merged = mergeBackupSettings(
        const FarmSettings(sacoKg: 70),
        const FarmSettings(sacoKg: 60),
      );
      expect(merged.sacoKg, 60);
    });
  });
}
