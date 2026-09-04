import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/crop.dart';
import '../models/settings.dart';
import '../models/transaction.dart';

class LocalStore {
  static const _kTransactions = 'transactions_v1';
  static const _kCrops = 'crops_v1';
  static const _kSettings = 'settings_v1';
  static const _kSyncedAt = 'synced_at_v1';

  final SharedPreferences _prefs;

  LocalStore(this._prefs);

  static Future<LocalStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStore(prefs);
  }

  // ---- Transactions ----

  List<Transaction> loadTransactions() {
    final raw = _prefs.getString(_kTransactions);
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
    await _prefs.setString(_kTransactions, raw);
  }

  // ---- Crops ----

  List<Crop> loadCrops() {
    final raw = _prefs.getString(_kCrops);
    if (raw == null || raw.isEmpty) return List.of(defaultCrops);
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Crop.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return List.of(defaultCrops);
    }
  }

  Future<void> saveCrops(List<Crop> crops) async {
    final raw = jsonEncode(crops.map((c) => c.toJson()).toList());
    await _prefs.setString(_kCrops, raw);
  }

  // ---- Settings ----

  FarmSettings loadSettings() {
    final raw = _prefs.getString(_kSettings);
    if (raw == null || raw.isEmpty) return const FarmSettings();
    try {
      return FarmSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const FarmSettings();
    }
  }

  Future<void> saveSettings(FarmSettings settings) async {
    await _prefs.setString(_kSettings, jsonEncode(settings.toJson()));
  }

  // ---- Sync timestamp ----

  DateTime? loadSyncedAt() {
    final raw = _prefs.getString(_kSyncedAt);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveSyncedAt(DateTime time) async {
    await _prefs.setString(_kSyncedAt, time.toIso8601String());
  }

  // ---- Clear (logout) ----

  Future<void> clearAll() async {
    await _prefs.remove(_kTransactions);
    await _prefs.remove(_kCrops);
    await _prefs.remove(_kSettings);
    await _prefs.remove(_kSyncedAt);
  }
}