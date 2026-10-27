import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/crop.dart';
import '../models/employee.dart';
import '../models/harvest.dart';
import '../models/settings.dart';
import '../models/sowing.dart';
import '../models/terreno.dart';
import '../models/transaction.dart';

class LocalStore {
  static const _kTransactions = 'transactions_v1';
  static const _kCrops = 'crops_v1';
  static const _kSettings = 'settings_v1';
  static const _kSyncedAt = 'synced_at_v1';
  static const _kHarvests = 'harvests_v1';
  static const _kSowings = 'sowings_v1';
  static const _kEmployees = 'employees_v1';
  static const _kTerrenos = 'terrenos_v1';
  static const _kSettingsDirty = 'settings_dirty_v1';
  static const _kDeletedCrops = 'deleted_crops_v1';
  static const _kDeletedSowings = 'deleted_sowings_v1';
  static const _kDeletedHarvests = 'deleted_harvests_v1';
  static const _kDeletedEmployees = 'deleted_employees_v1';
  static const _kDeletedTerrenos = 'deleted_terrenos_v1';
  static const _kCohortSyncRepair = 'cohort_sync_repair_v1';
  static const _kHelpCase = 'help_case_v1';

  static const _allKeys = [
    _kTransactions,
    _kCrops,
    _kSettings,
    _kSyncedAt,
    _kHarvests,
    _kSowings,
    _kEmployees,
    _kTerrenos,
    _kSettingsDirty,
    _kDeletedCrops,
    _kDeletedSowings,
    _kDeletedHarvests,
    _kDeletedEmployees,
    _kDeletedTerrenos,
    _kHelpCase,
  ];

  /// ¿Ya se re-subieron las siembras creadas antes de que el payload llevara
  /// el reemplazo y el puntero de cohorte? Es por equipo, no por cuenta.
  bool cohortSyncRepairDone() =>
      _prefs.getBool(_key(_kCohortSyncRepair)) ?? false;

  Future<void> markCohortSyncRepairDone() =>
      _prefs.setBool(_key(_kCohortSyncRepair), true);

  final SharedPreferences _prefs;
  String? _uid;

  /// Aísla los datos locales por usuario (H1): con [uid] cada clave lleva el
  /// sufijo `_<uid>`; sin uid se usan las claves legacy (comportamiento
  /// anterior, usado por los tests y el arranque sin sesión).
  LocalStore(this._prefs, {String? uid}) : _uid = _normalizeUid(uid);

  /// Usuario cuyo namespace está activo (null = datos legacy/sin sesión).
  /// Lo usan el export/import de respaldo para comparar cuentas.
  String? get uid => _uid;

  static String? _normalizeUid(String? uid) =>
      (uid == null || uid.isEmpty) ? null : uid;

  /// Crea el store, y si ya hay sesión de [uid], migra las claves legacy
  /// (pre-H1) a su namespace para no perder datos locales existentes.
  static Future<LocalStore> create({String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs, uid: uid);
    await store._migrateLegacyIfNeeded();
    return store;
  }

  String _key(String base) => _uid == null ? base : '${base}_$_uid';

  /// Cambia el usuario activo (login/logout) y migra en una sola pasada.
  Future<void> bindUser(String? uid) async {
    final next = _normalizeUid(uid);
    if (next == _uid) return;
    _uid = next;
    await _migrateLegacyIfNeeded();
  }

  Future<void> _migrateLegacyIfNeeded() async {
    if (_uid == null) return;
    final settingsKey = _key(_kSettings);
    if (_prefs.getString(settingsKey) == null) {
      final raw = _prefs.getString(_kSettings);
      if (raw != null && raw.isNotEmpty) {
        await _prefs.setString(settingsKey, raw);
        await _prefs.remove(_kSettings);
      }
    }
  }

  // ---- Transactions ----

  List<Transaction> loadTransactions() {
    final raw = _prefs.getString(_key(_kTransactions));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Transaction.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final raw = jsonEncode(transactions.map((t) => t.toJson()).toList());
    await _prefs.setString(_key(_kTransactions), raw);
  }

  // ---- Crops ----

  List<Crop> loadCrops() {
    final raw = _prefs.getString(_key(_kCrops));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final seen = <String>{};
      // C4: deduplicar por id, nunca por nombre. Dos cultivos distintos
      // pueden llamarse igual y borrar uno por nombre dejaba sus siembras y
      // cosechas huérfanas sin que nadie lo notara.
      return list
          .map((e) => Crop.fromJson((e as Map).cast<String, dynamic>()))
          .where((c) => seen.add(c.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCrops(List<Crop> crops) async {
    final raw = jsonEncode(crops.map((c) => c.toJson()).toList());
    await _prefs.setString(_key(_kCrops), raw);
  }

  // ---- Cultivos borrados (pendientes de borrar en la BD) ----
  //
  // El borrado de cultivos no se propaga solo: si se olvidara, el pull volvería
  // a traer el cultivo. Estos ids son la "tombstone" que hay que subir antes de
  // poder olvidarlos.

  List<String> loadDeletedCrops() {
    final raw = _prefs.getString(_key(_kDeletedCrops));
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDeletedCrops(List<String> ids) async {
    await _prefs.setString(_key(_kDeletedCrops), jsonEncode(ids));
  }

  // ---- Lápidas de siembras, cosechas, trabajadores y terrenos ----
  //
  // Mismo motivo que las de cultivo: el pull solo inserta ids nuevos, así que
  // sin subir el borrado lo borrado volvería en la siguiente pasada.

  List<String> loadDeletedSowings() => _loadIds(_kDeletedSowings);
  Future<void> saveDeletedSowings(List<String> ids) =>
      _saveIds(_kDeletedSowings, ids);

  List<String> loadDeletedHarvests() => _loadIds(_kDeletedHarvests);
  Future<void> saveDeletedHarvests(List<String> ids) =>
      _saveIds(_kDeletedHarvests, ids);

  List<String> loadDeletedEmployees() => _loadIds(_kDeletedEmployees);
  Future<void> saveDeletedEmployees(List<String> ids) =>
      _saveIds(_kDeletedEmployees, ids);

  List<String> loadDeletedTerrenos() => _loadIds(_kDeletedTerrenos);
  Future<void> saveDeletedTerrenos(List<String> ids) =>
      _saveIds(_kDeletedTerrenos, ids);

  List<String> _loadIds(String key) {
    final raw = _prefs.getString(_key(key));
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveIds(String key, List<String> ids) async {
    await _prefs.setString(_key(key), jsonEncode(ids));
  }

  // ---- Harvests ----

  List<Harvest> loadHarvests() {
    final raw = _prefs.getString(_key(_kHarvests));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Harvest.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHarvests(List<Harvest> harvests) async {
    final raw = jsonEncode(harvests.map((h) => h.toJson()).toList());
    await _prefs.setString(_key(_kHarvests), raw);
  }

  // ---- Sowings ----

  List<Sowing> loadSowings() {
    final raw = _prefs.getString(_key(_kSowings));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Sowing.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSowings(List<Sowing> sowings) async {
    final raw = jsonEncode(sowings.map((s) => s.toJson()).toList());
    await _prefs.setString(_key(_kSowings), raw);
  }

  // ---- Employees ----

  List<Employee> loadEmployees() {
    final raw = _prefs.getString(_key(_kEmployees));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Employee.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEmployees(List<Employee> employees) async {
    final raw = jsonEncode(employees.map((e) => e.toJson()).toList());
    await _prefs.setString(_key(_kEmployees), raw);
  }

  // ---- Terrenos ----

  List<Terreno> loadTerrenos() {
    final raw = _prefs.getString(_key(_kTerrenos));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Terreno.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      // Un terreno corrupto no puede tumbar el arranque de la app entera:
      // peor caso, se empieza sin terrenos y se vuelven a crear.
      return [];
    }
  }

  Future<void> saveTerrenos(List<Terreno> terrenos) async {
    final raw = jsonEncode(terrenos.map((t) => t.toJson()).toList());
    await _prefs.setString(_key(_kTerrenos), raw);
  }

  // ---- Settings ----

  FarmSettings loadSettings() {
    final raw = _prefs.getString(_key(_kSettings));
    if (raw == null || raw.isEmpty) return const FarmSettings();
    try {
      return FarmSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const FarmSettings();
    }
  }

  Future<void> saveSettings(FarmSettings settings) async {
    await _prefs.setString(_key(_kSettings), jsonEncode(settings.toJson()));
  }

  /// Ajustes locales modificados y aún no subidos.
  ///
  /// Se guarda aparte del modelo para no tocar su `toJson` (que también
  /// alimenta al sync remoto). Sin esta marca, un dispositivo recién
  /// instalado subiría ajustes por defecto y pisaría la caja menor ajena.
  bool loadSettingsDirty() => _prefs.getBool(_key(_kSettingsDirty)) ?? false;

  Future<void> saveSettingsDirty(bool value) async {
    await _prefs.setBool(_key(_kSettingsDirty), value);
  }

  // ---- Sync timestamp ----

  DateTime? loadSyncedAt() {
    final raw = _prefs.getString(_key(_kSyncedAt));
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveSyncedAt(DateTime time) async {
    await _prefs.setString(_key(_kSyncedAt), time.toIso8601String());
  }

  // ---- Ayuda: caso elegido ----

  /// Caso de la Ayuda que el usuario eligió la última vez (`selling`,
  /// `starting`, `renew` o `workers`). Es solo una preferencia de pantalla:
  /// no se sincroniza ni se exporta.
  String? loadHelpCase() {
    final raw = _prefs.getString(_key(_kHelpCase));
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  Future<void> saveHelpCase(String value) async {
    await _prefs.setString(_key(_kHelpCase), value);
  }

  // ---- Clear (logout) ----

  Future<void> clearAll() async {
    for (final base in _allKeys) {
      await _prefs.remove(_key(base));
    }
  }
}