import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/crop.dart';
import '../models/harvest.dart';
import '../models/settings.dart';
import '../models/sowing.dart';
import '../models/transaction.dart';

class LocalStore {
  static const _kTransactions = 'transactions_v1';
  static const _kCrops = 'crops_v1';
  static const _kSettings = 'settings_v1';
  static const _kSyncedAt = 'synced_at_v1';
  static const _kHarvests = 'harvests_v1';
  static const _kSowings = 'sowings_v1';

  static const _allKeys = [
    _kTransactions,
    _kCrops,
    _kSettings,
    _kSyncedAt,
    _kHarvests,
    _kSowings,
  ];

  final SharedPreferences _prefs;
  String? _uid;

  /// Aísla los datos locales por usuario (H1): con [uid] cada clave lleva el
  /// sufijo `_<uid>`; sin uid se usan las claves legacy (comportamiento
  /// anterior, usado por los tests y el arranque sin sesión).
  LocalStore(this._prefs, {String? uid}) : _uid = _normalizeUid(uid);

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
    for (final base in _allKeys) {
      final raw = _prefs.getString(base);
      if (raw == null || raw.isEmpty) continue;
      if (_prefs.getString(_key(base)) != null) continue;
      await _prefs.setString(_key(base), raw);
      await _prefs.remove(base);
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
    if (raw == null || raw.isEmpty) return List.of(defaultCrops);
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final seen = <String>{};
      return list
          .map((e) => Crop.fromJson((e as Map).cast<String, dynamic>()))
          .where((c) => seen.add(c.name.trim().toLowerCase()))
          .toList();
    } catch (_) {
      return List.of(defaultCrops);
    }
  }

  Future<void> saveCrops(List<Crop> crops) async {
    final raw = jsonEncode(crops.map((c) => c.toJson()).toList());
    await _prefs.setString(_key(_kCrops), raw);
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

  // ---- Sync timestamp ----

  DateTime? loadSyncedAt() {
    final raw = _prefs.getString(_key(_kSyncedAt));
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveSyncedAt(DateTime time) async {
    await _prefs.setString(_key(_kSyncedAt), time.toIso8601String());
  }

  // ---- Clear (logout) ----

  Future<void> clearAll() async {
    for (final base in _allKeys) {
      await _prefs.remove(_key(base));
    }
  }
}