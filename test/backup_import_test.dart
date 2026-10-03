import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/employee.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/models/settings.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/models/transaction.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/backup_service.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({LocalStore store, TransactionProvider provider})> newProvider(
      {String? uid}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs, uid: uid);
    return (store: store, provider: TransactionProvider(store));
  }

  /// Construye un payload pasando por el encoder real (roundtrip).
  BackupPayload payload({
    List<Crop> crops = const [],
    List<Sowing> sowings = const [],
    List<Harvest> harvests = const [],
    List<Employee> employees = const [],
    List<Transaction> transactions = const [],
    FarmSettings settings = const FarmSettings(),
    String cuenta = '',
  }) =>
      decodeBackup(encodeBackup(
        crops: crops,
        sowings: sowings,
        harvests: harvests,
        employees: employees,
        transactions: transactions,
        settings: settings,
        uid: cuenta,
        now: DateTime(2026, 10, 3),
      ));

  Transaction sale({String id = 't1', String? cropId, String? sowingId}) =>
      Transaction(
        id: id,
        cropId: cropId,
        sowingId: sowingId,
        type: TransactionType.income,
        category: 'venta_cafe',
        amount: 100,
        date: DateTime(2026, 9, 2),
        createdAt: DateTime(2026, 9, 2),
      );

  group('P1 — fusión por id', () {
    test('no pisa lo existente y lo nuevo entra con pendingSync', () async {
      final p = await newProvider();
      // Un cultivo local ya registrado con su nombre definitivo.
      p.provider
          .mergeRemoteCrops(const [Crop(id: 'c1', name: 'Café local')]);

      final summary = await p.provider.importBackup(payload(
        crops: const [
          Crop(id: 'c1', name: 'Café del archivo'),
          Crop(id: 'c2', name: 'Plátano'),
        ],
      ));

      expect(p.provider.crops.first.name, 'Café local',
          reason: 'el id ya existente no se pisa');
      final nuevo = p.provider.crops.firstWhere((c) => c.id == 'c2');
      expect(nuevo.name, 'Plátano');
      expect(nuevo.pendingSync, isTrue,
          reason: 'lo importado hay que subirlo');
      expect(summary.agregados.cultivos, 1);
      expect(summary.omitidos.cultivos, 1);
      expect(p.provider.crops, hasLength(2));
    });

    test('cultivos repetidos dentro del archivo solo entran una vez',
        () async {
      final p = await newProvider();

      final summary = await p.provider.importBackup(payload(crops: const [
        Crop(id: 'c1', name: 'Café'),
        Crop(id: 'c1', name: 'Café repetido'),
      ]));

      expect(p.provider.crops, hasLength(1));
      expect(p.provider.crops.single.name, 'Café');
      expect(summary.agregados.cultivos, 1);
      expect(summary.omitidos.cultivos, 1);
    });

    test('trabajadores, siembras, cosechas y movimientos también se fusionan',
        () async {
      final p = await newProvider();
      await p.store.saveEmployees(
          [const Employee(id: 'e1', name: 'Pedro', dayRate: 50000)]);
      final provider = TransactionProvider(p.store);

      final summary = await provider.importBackup(payload(
        employees: const [
          Employee(id: 'e1', name: 'Pedro del archivo', dayRate: 99999),
          Employee(id: 'e2', name: 'María'),
        ],
        sowings: [
          Sowing(
              id: 's1',
              cropId: 'c1',
              date: DateTime(2026, 1, 1),
              plants: 100),
        ],
        harvests: [
          Harvest(
              id: 'h1',
              cropId: 'c1',
              date: DateTime(2026, 9, 1),
              amount: 50),
        ],
        transactions: [sale()],
      ));

      expect(provider.employees.first.name, 'Pedro',
          reason: 'el trabajador local no se pisa');
      expect(provider.employees.last.pendingSync, isTrue);
      expect(provider.sowings.single.pendingSync, isTrue);
      expect(provider.harvests.single.pendingSync, isTrue);
      expect(provider.transactions.single.pendingSync, isTrue);
      expect(summary.agregados.empleados, 1);
      expect(summary.omitidos.empleados, 1);
      expect(summary.agregados.siembras, 1);
      expect(summary.agregados.cosechas, 1);
      expect(summary.agregados.movimientos, 1);
      expect(provider.crops, isEmpty,
          reason: 'una siembra sin cultivo se importa igual, sin enlazar');
    });

    test('importa y persiste en el store', () async {
      final p = await newProvider();
      await p.provider.importBackup(payload(
        crops: const [Crop(id: 'c1', name: 'Café')],
        transactions: [sale()],
      ));

      final reload = TransactionProvider(p.store);
      expect(reload.crops.single.id, 'c1');
      expect(reload.transactions.single.id, 't1');
    });
  });

  group('P1 — huérfanos', () {
    test('se cuentan pero no se descarta ningún dato', () async {
      final p = await newProvider();

      final summary = await p.provider.importBackup(payload(
        sowings: [
          Sowing(
              id: 's1',
              cropId: 'no-existe',
              date: DateTime(2026, 1, 1),
              plants: 100),
        ],
        harvests: [
          Harvest(
              id: 'h1',
              cropId: 'tampoco-existe',
              date: DateTime(2026, 9, 1),
              amount: 50),
        ],
        transactions: [
          sale(cropId: 'nada', sowingId: 'ninguna'),
        ],
      ));

      // 1 siembra + 1 cosecha + 2 referencias del movimiento.
      expect(summary.huerfanos, 4);
      expect(p.provider.sowings, hasLength(1),
          reason: 'la siembra huérfana se importa, no se tira');
      expect(p.provider.harvests, hasLength(1));
      expect(p.provider.transactions, hasLength(1));
      expect(p.provider.transactions.single.cropId, 'nada');
    });

    test('una referencia que sí existe en el archivo no cuenta como huérfana',
        () async {
      final p = await newProvider();

      final summary = await p.provider.importBackup(payload(
        crops: const [Crop(id: 'c1', name: 'Café')],
        transactions: [sale(cropId: 'c1')],
      ));

      expect(summary.huerfanos, 0);
      expect(summary.agregados.movimientos, 1);
    });
  });

  group('P1 — ajustes y cuenta', () {
    test('importar ajustes deja settingsDirty activo', () async {
      final p = await newProvider();
      expect(p.provider.settingsDirty, isFalse);

      final summary = await p.provider.importBackup(
          payload(settings: const FarmSettings(farmName: 'Finca Vieja')));

      expect(summary.ajustesImportados, isTrue);
      expect(p.provider.settings.farmName, 'Finca Vieja');
      expect(p.provider.settingsDirty, isTrue,
          reason: 'los ajustes restaurados tienen que subir');
      expect(p.store.loadSettingsDirty(), isTrue,
          reason: 'la marca debe persistir en el store');
    });

    test('si los ajustes no cambian, no se marcan como pendientes', () async {
      final p = await newProvider();

      final summary =
          await p.provider.importBackup(payload(settings: const FarmSettings()));

      expect(summary.ajustesImportados, isFalse);
      expect(p.provider.settingsDirty, isFalse);
    });

    test('un respaldo de otra cuenta solo avisa, la fusión procede', () async {
      final p = await newProvider(uid: 'uid-local');

      final summary = await p.provider.importBackup(payload(
        cuenta: 'uid-otra',
        crops: const [Crop(id: 'c1', name: 'Café')],
      ));

      expect(summary.cuentaDistinta, isTrue);
      expect(p.provider.crops, hasLength(1),
          reason: 'el aviso no bloquea la restauración');
    });

    test('mismo cuenta o exportado sin sesión no avisan', () async {
      final p = await newProvider(uid: 'uid-local');

      final misma = await p.provider
          .importBackup(payload(cuenta: 'uid-local', crops: const [
        Crop(id: 'c1', name: 'Café'),
      ]));
      expect(misma.cuentaDistinta, isFalse);

      final sinSesion = await p.provider
          .importBackup(payload(cuenta: '', crops: const [
        Crop(id: 'c2', name: 'Plátano'),
      ]));
      expect(sinSesion.cuentaDistinta, isFalse);
    });
  });

  group('P1 — exportar', () {
    test('exportBackupJson hace roundtrip por decodeBackup', () async {
      final p = await newProvider(uid: 'uid-1');
      await p.provider.addCrop('Café');
      await p.provider.addSowing(
          cropId: null, date: DateTime(2026, 1, 1), plants: 50);
      await p.provider.addTransaction(
        type: TransactionType.expense,
        category: 'fertilizante',
        amount: 200,
      );

      final respaldo = decodeBackup(p.provider.exportBackupJson(
          uid: 'uid-1', now: DateTime(2026, 10, 3, 12)));

      expect(respaldo.cuenta, 'uid-1');
      expect(respaldo.conteo.cultivos, 1);
      expect(respaldo.conteo.siembras, 1);
      expect(respaldo.conteo.movimientos, 1);
      expect(respaldo.exportadoEn, DateTime(2026, 10, 3, 12));
    });
  });
}
