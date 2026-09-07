import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/crop.dart';
import '../models/harvest.dart';
import '../models/settings.dart';
import '../models/sowing.dart';
import '../models/transaction.dart';
import '../services/local_store.dart';

class TransactionProvider extends ChangeNotifier {
  static const _uuid = Uuid();

  final LocalStore _store;
  List<Transaction> _transactions = [];
  List<Crop> _crops = [];
  FarmSettings _settings = const FarmSettings();
  List<Harvest> _harvests = [];
  List<Sowing> _sowings = [];

  TransactionProvider(this._store) {
    _transactions = _store.loadTransactions();
    _crops = _store.loadCrops();
    _settings = _store.loadSettings();
    _harvests = _store.loadHarvests();
    _sowings = _store.loadSowings();
  }

  List<Transaction> get transactions => _transactions;
  List<Crop> get crops => _crops;
  FarmSettings get settings => _settings;
  List<Harvest> get harvests => _harvests;
  List<Sowing> get sowings => _sowings;

  List<Harvest> harvestsFor(String? cropId, {DateTime? from, DateTime? to}) {
    return _harvests.where((h) {
      if (cropId != null && h.cropId != cropId) return false;
      if (from != null && h.date.isBefore(from)) return false;
      if (to != null && h.date.isAfter(to)) return false;
      return true;
    }).toList();
  }

  List<Sowing> sowingsFor(String? cropId, {DateTime? from, DateTime? to}) {
    return _sowings.where((s) {
      if (cropId != null && s.cropId != cropId) return false;
      if (from != null && s.date.isBefore(from)) return false;
      if (to != null && s.date.isAfter(to)) return false;
      return true;
    }).toList();
  }

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
    String? currency,
    double? quantity,
    String? unit,
    String? client,
    String? provider,
    String? harvestId,
    String? sowingId,
  }) async {
    final txn = Transaction(
      id: _uuid.v4(),
      cropId: cropId,
      type: type,
      category: category,
      amount: amount,
      currency: currency ?? _settings.currency,
      description: description,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now().toUtc(),
      pendingSync: true,
      quantity: quantity,
      unit: unit,
      client: client,
      provider: provider,
      harvestId: harvestId,
      sowingId: sowingId,
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

  Future<void> updateCrop(Crop crop) async {
    final idx = _crops.indexWhere((c) => c.id == crop.id);
    if (idx == -1) return;
    final list = [..._crops];
    list[idx] = crop.copyWith(pendingSync: true);
    _crops = list;
    await _store.saveCrops(_crops);
    notifyListeners();
  }

  Future<void> deleteCrop(String id) async {
    _crops = _crops.where((c) => c.id != id).toList();
    await _store.saveCrops(_crops);
    notifyListeners();
  }

  // ---- Harvards ----

  Future<Harvest> addHarvest({
    String? cropId,
    required DateTime date,
    required double amount,
    String unit = 'kg',
    HarvestDestination destination = HarvestDestination.vendido,
  }) async {
    final harvest = Harvest(
      id: _uuid.v4(),
      cropId: cropId,
      date: date,
      amount: amount,
      unit: unit,
      destination: destination,
      pendingSync: true,
    );
    _harvests = [..._harvests, harvest];
    await _store.saveHarvests(_harvests);
    notifyListeners();
    return harvest;
  }

  Future<void> updateHarvest(Harvest updated) async {
    final idx = _harvests.indexWhere((h) => h.id == updated.id);
    if (idx == -1) return;
    final list = [..._harvests];
    list[idx] = updated.copyWith(pendingSync: true);
    _harvests = list;
    await _store.saveHarvests(_harvests);
    notifyListeners();
  }

  Future<void> deleteHarvest(String id) async {
    _harvests = _harvests.where((h) => h.id != id).toList();
    await _store.saveHarvests(_harvests);
    notifyListeners();
  }

  // ---- Sowings ----

  Future<Sowing> addSowing({
    String? cropId,
    required DateTime date,
    SowingKind kind = SowingKind.siembra,
    required int plants,
    double? areaHa,
    int? lostPlants,
    String? reason,
  }) async {
    final sowing = Sowing(
      id: _uuid.v4(),
      cropId: cropId,
      date: date,
      kind: kind,
      plants: plants,
      areaHa: areaHa,
      lostPlants: lostPlants,
      reason: reason,
      pendingSync: true,
    );
    _sowings = [..._sowings, sowing];
    await _store.saveSowings(_sowings);
    await _recomputeCropsFromSowings();
    notifyListeners();
    return sowing;
  }

  Future<void> updateSowing(Sowing updated) async {
    final idx = _sowings.indexWhere((s) => s.id == updated.id);
    if (idx == -1) return;
    final list = [..._sowings];
    list[idx] = updated.copyWith(pendingSync: true);
    _sowings = list;
    await _store.saveSowings(_sowings);
    await _recomputeCropsFromSowings();
    notifyListeners();
  }

  Future<void> deleteSowing(String id) async {
    _sowings = _sowings.where((s) => s.id != id).toList();
    await _store.saveSowings(_sowings);
    await _recomputeCropsFromSowings();
    notifyListeners();
  }

  /// Recomputa livePlants/areaHa de cada cultivo a partir de sus siembras
  /// en orden cronológico, persistiendo los cambios con pendingSync true.
  Future<void> _recomputeCropsFromSowings() async {
    final updates = recomputeCropState(_sowings);
    if (updates.isEmpty) return;
    var changed = false;
    final list = [..._crops];
    for (var i = 0; i < list.length; i++) {
      final c = list[i];
      final u = updates[c.id];
      if (u == null) continue;
      list[i] = c.copyWith(
        livePlants: u.livePlants,
        areaHa: u.areaHa ?? c.areaHa,
        pendingSync: true,
      );
      changed = true;
    }
    if (changed) {
      _crops = list;
      await _store.saveCrops(_crops);
    }
  }

  // ---- Settings ----

  Future<void> updateSettings(FarmSettings settings) async {
    _settings = settings;
    await _store.saveSettings(settings);
    notifyListeners();
  }

  /// Convierte todos los registros a otra moneda usando la tasa recibida
  /// y los marca como pendientes de sincronizar.
  Future<void> convertAllToCurrency(String newCurrency, double factor) async {
    _transactions = _transactions
        .map((t) => t.copyWith(
              amount: t.amount * factor,
              currency: newCurrency,
              pendingSync: true,
            ))
        .toList();
    await _store.saveTransactions(_transactions);
    notifyListeners();
  }

  // ---- Sync helpers ----

  void replaceAllFromSync(List<Transaction> remote, List<Crop> remoteCrops,
      {List<Harvest>? remoteHarvests, List<Sowing>? remoteSowings}) {
    _transactions = remote;
    _crops = remoteCrops;
    if (remoteHarvests != null) _harvests = remoteHarvests;
    if (remoteSowings != null) _sowings = remoteSowings;
    _store.saveTransactions(remote);
    _store.saveCrops(remoteCrops);
    _store.saveHarvests(_harvests);
    _store.saveSowings(_sowings);
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
    _harvests =
        _harvests.map((h) => h.copyWith(pendingSync: false)).toList();
    _sowings =
        _sowings.map((s) => s.copyWith(pendingSync: false)).toList();
    await _store.saveTransactions(_transactions);
    await _store.saveCrops(_crops);
    await _store.saveHarvests(_harvests);
    await _store.saveSowings(_sowings);
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

  void mergeRemoteHarvests(List<Harvest> remoteHarvests) {
    final existing = _harvests.map((h) => h.id).toSet();
    _harvests = [
      ..._harvests,
      ...remoteHarvests.where((h) => !existing.contains(h.id)),
    ];
    _store.saveHarvests(_harvests);
    notifyListeners();
  }

  void mergeRemoteSowings(List<Sowing> remoteSowings) {
    final existing = _sowings.map((s) => s.id).toSet();
    _sowings = [
      ..._sowings,
      ...remoteSowings.where((s) => !existing.contains(s.id)),
    ];
    _store.saveSowings(_sowings);
    notifyListeners();
  }
}
