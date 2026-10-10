import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/categories.dart';
import '../models/crop.dart';
import '../models/employee.dart';
import '../models/harvest.dart';
import '../models/settings.dart';
import '../models/sowing.dart';
import '../models/transaction.dart';
import '../services/backup_service.dart';
import '../services/local_store.dart';

class TransactionProvider extends ChangeNotifier {
  static const _uuid = Uuid();

  final LocalStore _store;
  List<Transaction> _transactions = [];
  List<Crop> _crops = [];
  FarmSettings _settings = const FarmSettings();
  List<Harvest> _harvests = [];
  List<Sowing> _sowings = [];
  List<Employee> _employees = [];
  bool _settingsDirty = false;

  /// Ids de cultivos borrados localmente que **aún no se han borrado en la
  /// BD**. Mientras estén aquí, el pull no debe revivirlos (se habrían ido sin
  /// borrar, porque `crops` solo se hace `upsert`).
  List<String> _deletedCrops = [];

  /// Se dispara tras un alta/edición/borrado local de un movimiento, para que
  /// [SyncProvider] lo suba en el momento en lugar de esperar a abrir la app
  /// o a tocar ⟳. Es una función y no una referencia directa al proveedor
  /// para no crear un ciclo entre los dos notifiers.
  void Function()? onLocalChange;

  TransactionProvider(this._store) {
    _transactions = _store.loadTransactions();
    _crops = _store.loadCrops();
    _settings = _store.loadSettings();
    _harvests = _store.loadHarvests();
    _sowings = _store.loadSowings();
    _employees = _store.loadEmployees();
    _settingsDirty = _store.loadSettingsDirty();
    _deletedCrops = _store.loadDeletedCrops();
  }

  /// Recarga todo el estado desde el namespace activo del store. Se invoca
  /// tras un cambio de usuario (login) para no exponer datos de otra cuenta.
  Future<void> reloadFromCache() async {
    _transactions = _store.loadTransactions();
    _crops = _store.loadCrops();
    _settings = _store.loadSettings();
    _harvests = _store.loadHarvests();
    _sowings = _store.loadSowings();
    _employees = _store.loadEmployees();
    // La marca dirty vive en el namespace: al cambiar de cuenta había que
    // recargarla, o el estado del equipo anterior mandaba sobre el nuevo.
    _settingsDirty = _store.loadSettingsDirty();
    // Igual que la dirty: si no se recarga, un cultivo borrado en la cuenta
    // anterior reviviría aquí (o se borraría sin querer en otra).
    _deletedCrops = _store.loadDeletedCrops();
    notifyListeners();
  }

  List<Transaction> get transactions => _transactions;
  List<Crop> get crops => _crops;
  FarmSettings get settings => _settings;
  List<Harvest> get harvests => _harvests;
  List<Sowing> get sowings => _sowings;
  List<Employee> get employees => _employees;

  /// Cultivos borrados localmente pendientes de borrar en la BD. Se expone
  /// para que [SyncProvider] pueda subir los borrados.
  List<String> get deletedCrops => _deletedCrops;

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

  /// Total de gastos del período **en una sola moneda**.
  ///
  /// Devuelve `null` cuando el conjunto mezcla dos o más monedas: un total
  /// así sería una suma de pesos con dólares (una cifra falsa). En ese caso
  /// usa [sumByCurrency], que separa cada moneda con su código.
  ///
  /// Con una sola moneda (o sin registros) devuelve la suma de siempre.
  double? totalExpenses({int? year, int? month}) =>
      _totalOf(TransactionType.expense, year: year, month: month);

  /// Total de ingresos del período **en una sola moneda**.
  ///
  /// Igual que [totalExpenses]: `null` si el período mezcla monedas, para que
  /// jamás se pueda pintar un total global cruzando monedas distintas. El
  /// desglose correcto está en [sumByCurrency].
  double? totalIncomes({int? year, int? month}) =>
      _totalOf(TransactionType.income, year: year, month: month);

  /// Suma del [type] filtrando por año/mes. Devuelve `null` en cuanto aparece
  /// una segunda moneda: así ninguna llamada puede colar un total mezclado.
  double? _totalOf(TransactionType type, {int? year, int? month}) {
    double sum = 0;
    final currencies = <String>{};
    for (final t in _transactions) {
      if (t.deleted || t.type != type) continue;
      if (year != null && t.date.year != year) continue;
      if (month != null && (t.date.year != year || t.date.month != month)) {
        continue;
      }
      currencies.add(t.currency);
      if (currencies.length > 1) return null;
      sum += t.amount;
    }
    return sum;
  }

  /// Suma montos agrupados por moneda para un tipo dado.
  Map<String, double> sumByCurrency(TransactionType type,
      {int? year, int? month}) {
    final result = <String, double>{};
    for (final t in _transactions) {
      if (t.deleted || t.type != type) continue;
      if (year != null && t.date.year != year) continue;
      if (month != null && (t.date.year != year || t.date.month != month)) {
        continue;
      }
      result[t.currency] = (result[t.currency] ?? 0) + t.amount;
    }
    return result;
  }

  /// Número de monedas distintas en un conjunto de transacciones.
  int currencyCount(List<Transaction> transactions) {
    return transactions.where((t) => !t.deleted).map((t) => t.currency).toSet().length;
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
    double? pricePerUnit,
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
      pricePerUnit: pricePerUnit,
      client: client,
      provider: provider,
      harvestId: harvestId,
      sowingId: sowingId,
    );
    _transactions = [..._transactions, txn];
    await _store.saveTransactions(_transactions);
    notifyListeners();
    onLocalChange?.call();
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
    onLocalChange?.call();
  }

  Future<void> deleteTransaction(String id) async {
    final list = [..._transactions];
    final idx = list.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    list[idx] = list[idx].copyWith(deleted: true, pendingSync: true);
    _transactions = list;
    await _store.saveTransactions(_transactions);
    notifyListeners();
    onLocalChange?.call();
  }

  // ---- Crops ----

  /// Crea el cultivo con el formulario completo en **una sola escritura**.
  ///
  /// Antes la pantalla de Cultivos tenía que llamar a `addCrop` y luego a
  /// `updateCrop`, lo que guardaba dos veces, avisaba dos veces (y disparaba
  /// el auto-sync dos veces) y dejaba una ventana con el cultivo a medias.
  ///
  /// La fase por defecto es [CropPhase.establecimiento], no producción: quien
  /// lo crea desde una puerta de solo nombre (siembra, registro, asignación)
  /// todavía no tiene una sola cosecha que lo demuestre. Se promueve a
  /// producción solo, al dar la primera cosecha (ver [_promotePhaseOnHarvest]);
  /// el formulario completo de Cultivos sigue poniendo la fase a mano.
  Future<Crop> addCrop(
    String name, {
    String icon = '🌱',
    String color = '#2E7D32',
    String? currency,
    CropPhase phase = CropPhase.establecimiento,
    CropCycle cycle = CropCycle.perenne,
    String? defaultUnit,
    double? areaHa,
    int? livePlants,
    double? establishmentCost,
    DateTime? plantedAt,
  }) async {
    final crop = Crop(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      color: color,
      currency: currency,
      phase: phase,
      cycle: cycle,
      defaultUnit: defaultUnit,
      areaHa: areaHa,
      livePlants: livePlants,
      establishmentCost: establishmentCost,
      plantedAt: plantedAt,
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

  /// F3 · Suma de los gastos de siembra **iniciales** de [cropId], sin las
  /// resiembras.
  ///
  /// Es el número con el que se auto-rellena *Inversión total* en el editor de
  /// cultivo cuando el campo viene vacío: el productor no tiene que escribir
  /// dos veces lo mismo. Las resiembras quedan fuera a propósito — son
  /// recambio, no dejar el cultivo listo — aunque sí cuentan para el costo
  /// por kilo.
  ///
  /// Devuelve `null` si no hay ningún gasto: `null` → oculto, nunca 0.
  double? initialSowingCost(String cropId) {
    // Tipo de cada siembra del cultivo, para poder apartar las resiembras.
    final kindBySowingId = <String, SowingKind>{
      for (final s in _sowings)
        if (s.cropId == cropId) s.id: s.kind,
    };
    double? sum;
    for (final t in _transactions) {
      if (t.deleted || t.type != TransactionType.expense) continue;
      if (t.cropId != cropId) continue;
      // Es gasto de siembra por categoría o por traer su sowingId: los mismos
      // dos caminos que `report_harvest_metrics` cuenta para el costo por kilo.
      if (t.category != kExpenseCategorySowing && t.sowingId == null) continue;
      if (t.sowingId != null &&
          kindBySowingId[t.sowingId] == SowingKind.resiembra) {
        continue;
      }
      sum = (sum ?? 0) + t.amount;
    }
    return sum;
  }

  Future<void> deleteCrop(String id) async {
    // Antes de nada: los ids de las siembras y cosechas que se van a borrar.
    // Los movimientos guardan harvest_id/sowing_id, y si quedaran apuntando a
    // una fila borrada la BD rechazaría la subida por clave foránea.
    final sowingIds =
        _sowings.where((s) => s.cropId == id).map((s) => s.id).toSet();
    final harvestIds =
        _harvests.where((h) => h.cropId == id).map((h) => h.id).toSet();

    _crops = _crops.where((c) => c.id != id).toList();
    // Queda anotado: `crops` solo se hace upsert, así que sin esta marca el
    // siguiente pull traería el cultivo de vuelta. Se borra de la BD en el
    // próximo sync y solo entonces se olvida (si falla, se reintenta).
    if (!_deletedCrops.contains(id)) {
      _deletedCrops = [..._deletedCrops, id];
      await _store.saveDeletedCrops(_deletedCrops);
    }
    await _store.saveCrops(_crops);
    // B1-B3: limpiar datos vinculados al cultivo eliminado
    _sowings = _sowings.where((s) => s.cropId != id).toList();
    await _store.saveSowings(_sowings);
    _harvests = _harvests.where((h) => h.cropId != id).toList();
    await _store.saveHarvests(_harvests);
    // Los movimientos se quedan (son dinero), pero sin enlaces rotos.
    _transactions = [
      for (final t in _transactions)
        t.cropId == id ||
                sowingIds.contains(t.sowingId) ||
                harvestIds.contains(t.harvestId)
            ? t.copyWith(
                cropId: t.cropId == id ? null : t.cropId,
                harvestId:
                    harvestIds.contains(t.harvestId) ? null : t.harvestId,
                sowingId: sowingIds.contains(t.sowingId) ? null : t.sowingId,
                pendingSync: true,
              )
            : t,
    ];
    await _store.saveTransactions(_transactions);
    notifyListeners();
  }

  // ---- Harvards ----

  Future<Harvest> addHarvest({
    String? cropId,
    required DateTime date,
    required double amount,
    String unit = 'kg',
    HarvestDestination destination = HarvestDestination.vendido,
    int? workers,
    double? equivalentKg,
  }) async {
    final harvest = Harvest(
      id: _uuid.v4(),
      cropId: cropId,
      date: date,
      amount: amount,
      unit: unit,
      destination: destination,
      pendingSync: true,
      workers: workers,
      equivalentKg: equivalentKg,
    );
    _harvests = [..._harvests, harvest];
    await _store.saveHarvests(_harvests);
    await _promotePhaseOnHarvest(cropId);
    notifyListeners();
    return harvest;
  }

  /// P3 · Fase automática: un cultivo que ya dio cosecha está en producción.
  ///
  /// Solo se promueve **desde** `establecimiento`: nunca al revés y nunca toca
  /// `renovacion`, que sigue siendo una decisión del usuario. Como después de
  /// promover ya no cumple la condición, la operación es idempotente.
  Future<void> _promotePhaseOnHarvest(String? cropId) async {
    if (cropId == null) return;
    final idx = _crops.indexWhere(
        (c) => c.id == cropId && c.phase == CropPhase.establecimiento);
    if (idx == -1) return;
    final list = [..._crops];
    list[idx] =
        list[idx].copyWith(phase: CropPhase.produccion, pendingSync: true);
    _crops = list;
    await _store.saveCrops(_crops);
    notifyListeners();
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

  /// F1 · Venta ligada a la cosecha.
  ///
  /// Si la cosecha está en [HarvestDestination.vendido] y trae precio, crea —o
  /// actualiza si ya existía— la venta correspondiente:
  /// `importe = cantidad × precio`. La venta hereda la moneda del cultivo y
  /// lleva `quantity`/`unit`/`pricePerUnit`, que es lo que el precio por kilo
  /// y la alerta de "ventas sin kilos" esperan encontrar.
  ///
  /// Si el destino es [HarvestDestination.perdida], la venta ligada se borra:
  /// no se puede vender una pérdida. Con destino `vendido` pero **sin precio**
  /// no se inventa la venta, pero tampoco se borra la que ya exista — sacar
  /// dinero de los libros por editar un campo sería peor que dejarlo.
  ///
  /// Solo puede haber ingresos con `harvestId` porque nacen de aquí: el
  /// registro manual anula ese id en los ingresos (`register_screen.dart:285`),
  /// así que toda venta con `harvestId` es de la app. Los gastos de recolección
  /// comparten el mismo id y `report_harvest_metrics.dart` los aparta con
  /// `isExpense`, así que el costo por kilo no se afecta.
  Future<Transaction?> reconcileHarvestSale({
    required Harvest harvest,
    double? pricePerUnit,
    String description = '',
  }) async {
    Transaction? linked;
    for (final t in _transactions) {
      if (!t.deleted &&
          t.type == TransactionType.income &&
          t.harvestId == harvest.id) {
        linked = t;
        break;
      }
    }

    final sells = harvest.destination == HarvestDestination.vendido;
    final price =
        (pricePerUnit != null && pricePerUnit > 0) ? pricePerUnit : null;

    if (!sells) {
      if (linked != null) await deleteTransaction(linked.id);
      return null;
    }
    // Sin precio no hay con qué calcular el importe: se deja como está.
    if (price == null) return linked;

    final amount = harvest.amount * price;
    if (linked != null) {
      final updated = linked.copyWith(
        cropId: harvest.cropId,
        amount: amount,
        date: harvest.date,
        quantity: harvest.amount,
        unit: harvest.unit,
        pricePerUnit: price,
      );
      await updateTransaction(updated);
      return updated;
    }

    String? currency;
    for (final c in _crops) {
      if (c.id == harvest.cropId) {
        currency = c.currency;
        break;
      }
    }
    return addTransaction(
      type: TransactionType.income,
      category: kIncomeCategorySale,
      cropId: harvest.cropId,
      amount: amount,
      currency: currency,
      description: description,
      date: harvest.date,
      quantity: harvest.amount,
      unit: harvest.unit,
      pricePerUnit: price,
      harvestId: harvest.id,
    );
  }

  /// B1 · Al borrar la cosecha se va también la venta que la app creó a partir
  /// de ella: si la cosecha ya no existe, la venta también era un error. Los
  /// gastos de recolección **no** se borran — esa plata ya salió y sigue
  /// siendo cierta; solo pierden el vínculo (B4).
  Future<void> deleteHarvest(String id) async {
    _harvests = _harvests.where((h) => h.id != id).toList();
    await _store.saveHarvests(_harvests);
    _transactions = _transactions.map((t) {
      if (t.harvestId != id) return t;
      if (t.type == TransactionType.income && !t.deleted) {
        return t.copyWith(deleted: true, harvestId: null, pendingSync: true);
      }
      // B4: desvincular transacciones que referencian esta cosecha
      return t.copyWith(harvestId: null, pendingSync: true);
    }).toList();
    await _store.saveTransactions(_transactions);
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
    // B5: desvincular transacciones que referencian esta siembra
    _transactions = _transactions
        .map((t) => t.sowingId == id
            ? t.copyWith(sowingId: null, pendingSync: true)
            : t)
        .toList();
    await _store.saveTransactions(_transactions);
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

  // ---- Employees ----

  Future<Employee> addEmployee(String name, {double? dayRate}) async {
    final employee = Employee(
      id: _uuid.v4(),
      name: name.trim(),
      dayRate: dayRate,
      pendingSync: true,
    );
    _employees = [..._employees, employee];
    await _store.saveEmployees(_employees);
    notifyListeners();
    return employee;
  }

  Future<void> updateEmployee(Employee updated) async {
    final idx = _employees.indexWhere((e) => e.id == updated.id);
    if (idx == -1) return;
    final list = [..._employees];
    list[idx] = updated.copyWith(pendingSync: true);
    _employees = list;
    await _store.saveEmployees(_employees);
    notifyListeners();
  }

  /// Borra el trabajador de la lista. Los jornales históricos conservan el
  /// nombre como snapshot en `transactions.provider` → no se tocan.
  Future<void> deleteEmployee(String id) async {
    _employees = _employees.where((e) => e.id != id).toList();
    await _store.saveEmployees(_employees);
    notifyListeners();
  }

  // ---- Settings ----

  Future<void> updateSettings(FarmSettings settings) async {
    _settings = settings;
    _settingsDirty = true;
    await _store.saveSettings(settings);
    await _store.saveSettingsDirty(true);
    notifyListeners();
  }

  /// Ajustes con cambios locales aún no subidos.
  bool get settingsDirty => _settingsDirty;

  /// Subida correcta: ya no hay nada local pendiente.
  Future<void> markSettingsSynced() async {
    if (!_settingsDirty) return;
    _settingsDirty = false;
    await _store.saveSettingsDirty(false);
    notifyListeners();
  }

  /// Aplica los ajustes remotos. Solo se llama cuando no hay cambios
  /// locales pendientes, para que un dispositivo nuevo no pise la caja
  /// menor configurada en otro.
  void applyRemoteSettings(FarmSettings remote) {
    if (_settingsDirty) return;
    _settings = remote;
    _store.saveSettings(remote);
    notifyListeners();
  }

  // ---- Respaldo (P1) ----

  /// Serializa todos los datos del usuario como JSON de respaldo.
  ///
  /// Solo entran datos del productor (`settings`, cultivos, siembras,
  /// cosechas, trabajadores y movimientos): la cola de sincronización
  /// (`deleted_crops_v1`, `settings_dirty_v1`, `synced_at_v1`) se queda fuera,
  /// porque es estado interno de la app y no suyo.
  String exportBackupJson({String? uid, DateTime? now}) => encodeBackup(
        crops: _crops,
        sowings: _sowings,
        harvests: _harvests,
        employees: _employees,
        transactions: _transactions,
        settings: _settings,
        uid: uid ?? _store.uid ?? '',
        now: now,
      );

  /// true si el respaldo salió de otra cuenta. Es solo un aviso para el
  /// diálogo: la fusión procede igual, que restaurar en local es válido
  /// también sin sesión.
  bool backupFromOtherAccount(BackupPayload payload) =>
      payload.cuenta.isNotEmpty && payload.cuenta != _store.uid;

  /// Fusiona un respaldo sobre el estado actual **por id**: lo que ya existe
  /// se conserva tal cual (no se pisa), lo nuevo entra con `pendingSync: true`
  /// y **nada se borra**. Devuelve el resumen para que la UI avise.
  ///
  /// El orden es crops → siembras → cosechas → trabajadores → movimientos →
  /// ajustes. Las referencias que no apuntan a nada ni local ni en el archivo
  /// se importan igual, sin enlazar, y solo se cuentan en
  /// [BackupSummary.huerfanos]: no se descartan datos del productor.
  Future<BackupSummary> importBackup(BackupPayload payload) async {
    var agregados = BackupCounts.cero;
    var omitidos = BackupCounts.cero;

    // 1) Cultivos — misma deduplicación por id que `LocalStore.loadCrops`.
    final cropAdd = _fuse(
        _crops, payload.crops, (c) => c.id, (c) => c.copyWith(pendingSync: true));
    if (cropAdd.added.isNotEmpty) {
      _crops = [..._crops, ...cropAdd.added];
      await _store.saveCrops(_crops);
    }
    agregados += BackupCounts(cultivos: cropAdd.added.length);
    omitidos += BackupCounts(cultivos: cropAdd.omitidos);

    // 2) Siembras.
    final sowingAdd = _fuse(_sowings, payload.sowings, (s) => s.id,
        (s) => s.copyWith(pendingSync: true));
    if (sowingAdd.added.isNotEmpty) {
      _sowings = [..._sowings, ...sowingAdd.added];
      await _store.saveSowings(_sowings);
    }
    agregados += BackupCounts(siembras: sowingAdd.added.length);
    omitidos += BackupCounts(siembras: sowingAdd.omitidos);

    // 3) Cosechas.
    final harvestAdd = _fuse(_harvests, payload.harvests, (h) => h.id,
        (h) => h.copyWith(pendingSync: true));
    if (harvestAdd.added.isNotEmpty) {
      _harvests = [..._harvests, ...harvestAdd.added];
      await _store.saveHarvests(_harvests);
    }
    agregados += BackupCounts(cosechas: harvestAdd.added.length);
    omitidos += BackupCounts(cosechas: harvestAdd.omitidos);

    // 4) Trabajadores.
    final employeeAdd = _fuse(_employees, payload.employees, (e) => e.id,
        (e) => e.copyWith(pendingSync: true));
    if (employeeAdd.added.isNotEmpty) {
      _employees = [..._employees, ...employeeAdd.added];
      await _store.saveEmployees(_employees);
    }
    agregados += BackupCounts(empleados: employeeAdd.added.length);
    omitidos += BackupCounts(empleados: employeeAdd.omitidos);

    // 5) Movimientos.
    final txnAdd = _fuse(_transactions, payload.transactions, (t) => t.id,
        (t) => t.copyWith(pendingSync: true));
    if (txnAdd.added.isNotEmpty) {
      _transactions = [..._transactions, ...txnAdd.added];
      await _store.saveTransactions(_transactions);
    }
    agregados += BackupCounts(movimientos: txnAdd.added.length);
    omitidos += BackupCounts(movimientos: txnAdd.omitidos);

    // 6) Ajustes — fusión sin borrar: un valor con contenido del archivo
    // manda, un valor por defecto o nulo no pisa lo ya configurado aquí.
    final merged = mergeBackupSettings(_settings, payload.settings);
    var ajustesImportados = false;
    if (jsonEncode(merged.toJson()) != jsonEncode(_settings.toJson())) {
      _settings = merged;
      _settingsDirty = true;
      await _store.saveSettings(_settings);
      // Para que los ajustes restaurados suban en el próximo sync.
      await _store.saveSettingsDirty(true);
      ajustesImportados = true;
    }

    // Huérfanos: referencias del archivo que no existen ni aquí ni en el
    // propio archivo. Se cuentan para avisar; los datos se importan igual.
    final cropIds = _crops.map((c) => c.id).toSet();
    final sowingIds = _sowings.map((s) => s.id).toSet();
    final harvestIds = _harvests.map((h) => h.id).toSet();
    var huerfanos = 0;
    for (final s in payload.sowings) {
      if (s.cropId != null && !cropIds.contains(s.cropId)) huerfanos++;
    }
    for (final h in payload.harvests) {
      if (h.cropId != null && !cropIds.contains(h.cropId)) huerfanos++;
    }
    for (final t in payload.transactions) {
      if (t.cropId != null && !cropIds.contains(t.cropId)) huerfanos++;
      if (t.sowingId != null && !sowingIds.contains(t.sowingId)) huerfanos++;
      if (t.harvestId != null && !harvestIds.contains(t.harvestId)) huerfanos++;
    }

    notifyListeners();
    return BackupSummary(
      agregados: agregados,
      omitidos: omitidos,
      huerfanos: huerfanos,
      cuentaDistinta: backupFromOtherAccount(payload),
      ajustesImportados: ajustesImportados,
    );
  }

  /// Une `incoming` sobre `current` por id, sin pisar nada: devuelve solo lo
  /// nuevo (marcado con `markPending`, que en la práctica le pone
  /// `pendingSync: true`) y cuántos incoming traían un id que ya existía — ya
  /// fuera local o repetido dentro del propio archivo.
  static ({List<T> added, int omitidos}) _fuse<T>(
    List<T> current,
    List<T> incoming,
    String Function(T) idOf,
    T Function(T) markPending,
  ) {
    final seen = {for (final item in current) idOf(item)};
    final added = <T>[];
    var omitidos = 0;
    for (final item in incoming) {
      if (!seen.add(idOf(item))) {
        omitidos++;
        continue;
      }
      added.add(markPending(item));
    }
    return (added: added, omitidos: omitidos);
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

  /// Marca como sincronizado todo lo que **sí** llegó al servidor.
  ///
  /// [skip] son los ids que fallaron al subir: conservan `pendingSync` y se
  /// vuelven a intentar en el próximo sync. Sin esta lista, un fallo parcial
  /// dejaba los registros locales en un estado inconsistente.
  Future<void> markAllSynced({Set<String> skip = const {}}) async {
    final failed = skip.contains;
    // Los borrados que no llegaron se conservan: si se descartaran aquí,
    // el pull los resucitaría desde el remoto.
    _transactions = _transactions
        .where((t) => !t.deleted || failed(t.id))
        .map((t) => failed(t.id) ? t : t.copyWith(pendingSync: false))
        .toList();
    _crops = _crops
        .map((c) => failed(c.id) ? c : c.copyWith(pendingSync: false))
        .toList();
    _harvests = _harvests
        .map((h) => failed(h.id) ? h : h.copyWith(pendingSync: false))
        .toList();
    _sowings = _sowings
        .map((s) => failed(s.id) ? s : s.copyWith(pendingSync: false))
        .toList();
    _employees = _employees
        .map((e) => failed(e.id) ? e : e.copyWith(pendingSync: false))
        .toList();
    // Mismo criterio que con los movimientos: solo se olvidan los borrados de
    // cultivo que SÍ llegaron. Si se descartaran los fallidos, el pull los
    // resucitaría desde el remoto.
    _deletedCrops = _deletedCrops.where(failed).toList();
    await _store.saveTransactions(_transactions);
    await _store.saveCrops(_crops);
    await _store.saveHarvests(_harvests);
    await _store.saveSowings(_sowings);
    await _store.saveEmployees(_employees);
    await _store.saveDeletedCrops(_deletedCrops);
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

  /// Fusiona los cultivos que trae el pull.
  ///
  /// Deduplica **solo por id, nunca por nombre**: dos cultivos distintos pueden
  /// llamarse igual y descartar el remoto dejaba sus siembras, cosechas y
  /// ventas sin cultivo. Antes valía el nombre porque los cultivos por defecto
  /// vivían con ids fijos (`cafe`) mientras la BD los tenía con uuid; eso se
  /// resuelve ahora en [_adoptLegacyCrops], que adopta el id remoto de verdad.
  void mergeRemoteCrops(List<Crop> remoteCrops) {
    _adoptLegacyCrops(remoteCrops);

    final existingIds = _crops.map((c) => c.id).toSet();
    // Los borrados pendientes no reviven: quizá todavía no hayan llegado a la
    // BD, y sin esta marca el pull los devolvería tal cual.
    final pendingDeletes = _deletedCrops.toSet();
    _crops = [
      ..._crops,
      ...remoteCrops.where(
        (c) => !existingIds.contains(c.id) && !pendingDeletes.contains(c.id),
      ),
    ];
    _store.saveCrops(_crops);
    notifyListeners();
  }

  /// Los cultivos por defecto antiguos (`cafe`, `platano`, `otro`) convivían con
  /// el mismo cultivo ya creado en la BD: eran dos filas para lo mismo. Si el
  /// remoto trae el mismo nombre con otro id, es el mismo cultivo: se re-apuntan
  /// las siembras, cosechas y movimientos locales al id remoto y se descarta el
  /// local. Así no hace falta deduplicar por nombre, que además borraba cultivos
  /// distintos con igual nombre y dejaba sus datos huérfanos.
  void _adoptLegacyCrops(List<Crop> remoteCrops) {
    if (!_crops.any((c) => legacyCropIds.contains(c.id))) return;

    final remoteByName = <String, Crop>{
      for (final r in remoteCrops) r.name.trim().toLowerCase(): r,
    };
    final pendingDeletes = _deletedCrops.toSet();
    final adopt = <String, String>{};
    for (final c in _crops) {
      if (!legacyCropIds.contains(c.id)) continue;
      final remote = remoteByName[c.name.trim().toLowerCase()];
      if (remote == null || remote.id == c.id) continue;
      // Un cultivo remoto pendiente de borrado no sirve como destino.
      if (pendingDeletes.contains(remote.id)) continue;
      adopt[c.id] = remote.id;
    }
    if (adopt.isEmpty) return;

    _sowings = [
      for (final s in _sowings)
        adopt.containsKey(s.cropId)
            ? s.copyWith(cropId: adopt[s.cropId], pendingSync: true)
            : s,
    ];
    _harvests = [
      for (final h in _harvests)
        adopt.containsKey(h.cropId)
            ? h.copyWith(cropId: adopt[h.cropId], pendingSync: true)
            : h,
    ];
    // Se re-marcan pendientes: en la BD siguen con `crop_id` a null (o con el
    // id legado) y hay que subirlos de nuevo con el id bueno.
    _transactions = [
      for (final t in _transactions)
        adopt.containsKey(t.cropId)
            ? t.copyWith(cropId: adopt[t.cropId], pendingSync: true)
            : t,
    ];
    _crops = _crops.where((c) => !adopt.containsKey(c.id)).toList();

    _store.saveSowings(_sowings);
    _store.saveHarvests(_harvests);
    _store.saveTransactions(_transactions);
    _store.saveCrops(_crops);
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

  void mergeRemoteEmployees(List<Employee> remoteEmployees) {
    final existingIds = _employees.map((e) => e.id).toSet();
    final existingNames = _employees
        .map((e) => e.name.trim().toLowerCase())
        .toSet();
    _employees = [
      ..._employees,
      ...remoteEmployees.where(
        (e) =>
            !existingIds.contains(e.id) &&
            !existingNames.contains(e.name.trim().toLowerCase()),
      ),
    ];
    _store.saveEmployees(_employees);
    notifyListeners();
  }
}
