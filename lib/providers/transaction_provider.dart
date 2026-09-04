import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/crop.dart';
import '../models/settings.dart';
import '../models/transaction.dart';
import '../services/local_store.dart';

class TransactionProvider extends ChangeNotifier {
  static const _uuid = Uuid();

  final LocalStore _store;
  List<Transaction> _transactions = [];
  List<Crop> _crops = [];
  FarmSettings _settings = const FarmSettings();

  TransactionProvider(this._store) {
    _transactions = _store.loadTransactions();
    _crops = _store.loadCrops();
    _settings = _store.loadSettings();
  }

  List<Transaction> get transactions => _transactions;
  List<Crop> get crops => _crops;
  FarmSettings get settings => _settings;

  /// Transacciones del período actual (por defecto: año en curso).
  List<Transaction> transactionsInYear(int year) {
    return _transactions
        .where((t) => t.date.year == year && !t.deleted)
        .toList();
  }

  List<Transaction> transactionsInMonth(int year, int month) {
    return _transactions
        .where((t) => !t.deleted && t.date.year == year && t.date.month == month)
        .toList();
  }

  double totalExpenses({int? year, int? month}) =>
      _sumBy(_transactions, TransactionType.expense, year: year, month: month);

  double totalIncomes({int? year, int? month}) =>
      _sumBy(_transactions, TransactionType.income, year: year, month: month);

  double _sumBy(List<Transaction> source, TransactionType type,
      {int? year, int? month}) {
    double sum = 0;
    for (final t in source) {
      if (t.deleted || t.type != type) continue;
      if (year != null && t.date.year != year) continue;
      if (month != null && (t.date.year != year || t.date.month != month)) {
        continue;
      }
      sum += t.amount;
    }
    return sum;
  }

  List<Transaction> where(
      {TransactionType? type,
      String? category,
      String? cropId,
      int? year,
      int? month}) {
    return _transactions.where((t) {
      if (t.deleted) return false;
      if (type != null && t.type != type) return false;
      if (category != null && t.category != category) return false;
      if (cropId != null && t.cropId != cropId) return false;
      if (year != null && t.date.year != year) return false;
      if (month != null && (t.date.year != year || t.date.month != month)) {
        return false;
      }
      return true;
    }).toList();
  }

  // ---- CRUD local ----

  Future<Transaction> addTransaction({
    required TransactionType type,
    required String category,
    required double amount,
    String? cropId,
    String description = '',
    DateTime? date,
    String currency = 'COP',
  }) async {
    final txn = Transaction(
      id: _uuid.v4(),
      cropId: cropId,
      type: type,
      category: category,
      amount: amount,
      currency: currency,
      description: description,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now().toUtc(),
      pendingSync: true,
    );
    _transactions = [..._transactions, txn];
    await _store.saveTransactions(_transactions);
    notifyListeners();
    return txn;
  }

  Future<void> updateTransaction(Transaction updated) async {
    final idx = _transactions.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    final list = [..._transactions];
    list[idx] = updated.copyWith(pendingSync: true);
    _transactions = list;
    await _store.saveTransactions(_transactions);
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    final list = [..._transactions];
    final idx = list.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    list[idx] = list[idx].copyWith(deleted: true, pendingSync: true);
    _transactions = list;
    await _store.saveTransactions(_transactions);
    notifyListeners();
  }

  // ---- Crops ----

  Future<Crop> addCrop(String name, {String icon = '🌱', String color = '#2E7D32'}) async {
    final crop = Crop(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      color: color,
      pendingSync: true,
    );
    _crops = [..._crops, crop];
    await _store.saveCrops(_crops);
    notifyListeners();
    return crop;
  }

  Future<void> deleteCrop(String id) async {
    _crops = _crops.where((c) => c.id != id).toList();
    await _store.saveCrops(_crops);
    notifyListeners();
  }

  // ---- Settings ----

  Future<void> updateSettings(FarmSettings settings) async {
    _settings = settings;
    await _store.saveSettings(settings);
    notifyListeners();
  }

  // ---- Sync helpers ----

  void replaceAllFromSync(List<Transaction> remote, List<Crop> remoteCrops) {
    _transactions = remote;
    _crops = remoteCrops;
    _store.saveTransactions(remote);
    _store.saveCrops(remoteCrops);
    notifyListeners();
  }

  List<Transaction> pendingSync() =>
      _transactions.where((t) => t.pendingSync).toList();

  Future<void> markAllSynced() async {
    _transactions = _transactions
        .where((t) => !t.deleted)
        .map((t) => t.copyWith(pendingSync: false))
        .toList();
    _crops =
        _crops.map((c) => c.copyWith(pendingSync: false)).toList();
    await _store.saveTransactions(_transactions);
    await _store.saveCrops(_crops);
    notifyListeners();
  }

  void mergeRemote(List<Transaction> remoteTransactions) {
    final existing = _transactions.map((t) => t.id).toSet();
    _transactions = [
      ..._transactions,
      ...remoteTransactions.where((t) => !existing.contains(t.id)),
    ];
    _store.saveTransactions(_transactions);
    notifyListeners();
  }

  void mergeRemoteCrops(List<Crop> remoteCrops) {
    final existing = _crops.map((c) => c.id).toSet();
    _crops = [
      ..._crops,
      ...remoteCrops.where((c) => !existing.contains(c.id)),
    ];
    _store.saveCrops(_crops);
    notifyListeners();
  }
}