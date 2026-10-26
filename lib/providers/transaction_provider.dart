import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/categories.dart';
import '../models/crop.dart';
import '../models/employee.dart';
import '../models/harvest.dart';
import '../models/settings.dart';
import '../models/sowing.dart';
import '../models/terreno.dart';
import '../models/transaction.dart';
import '../services/backup_service.dart';
import '../services/derived_harvests.dart';
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
  List<Terreno> _terrenos = [];
  bool _settingsDirty = false;

  /// Ids de cultivos borrados localmente que **aún no se han borrado en la
  /// BD**. Mientras estén aquí, el pull no debe revivirlos (se habrían ido sin
  /// borrar, porque `crops` solo se hace `upsert`).
  List<String> _deletedCrops = [];

  /// Mismo criterio para las otras cuatro entidades: el pull solo inserta ids
  /// nuevos, así que sin lápida el borrado volvería en la pasada siguiente.
  List<String> _deletedSowings = [];
  List<String> _deletedHarvests = [];
  List<String> _deletedEmployees = [];
  List<String> _deletedTerrenos = [];

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
    _terrenos = _store.loadTerrenos();
    _settingsDirty = _store.loadSettingsDirty();
    _deletedCrops = _store.loadDeletedCrops();
    _deletedSowings = _store.loadDeletedSowings();
    _deletedHarvests = _store.loadDeletedHarvests();
    _deletedEmployees = _store.loadDeletedEmployees();
    _deletedTerrenos = _store.loadDeletedTerrenos();
    // Etapa A · antes que nada: los datos viejos se leen como reemplazo para
    // que las cohortes no muevan ningún número (D9).
    if (_normalizeLegacyCohortsInMemory()) {
      unawaited(_recomputeCropsFromSowings());
    }
    // Tanda 4 · primera vez con un aporte configurado: el historial arranca
    // este mes. Sin historial no hay forma de saber qué regía antes, y
    // reconstruirlo sería inventar.
    _seedCashHistory();
    // P3 · Cuentas que **ya vendían** antes de que la cosecha se dedujera de
    // la venta: en el disco su fase sigue congelada en `establecimiento`
    // porque nadie pasó por `addHarvest`. Se promueve aquí, al abrir, sin
    // esperar a que toque algo.
    if (_promotePhasesInMemory()) _store.saveCrops(_crops);
    // §1 de la auditoría: las siembras que ya subieron antes de que el payload
    // llevara el reemplazo y el puntero quedaron `pendingSync: false` y no se
    // reenviarían nunca. Se re-suben una sola vez por equipo.
    unawaited(repairCohortUpload());
  }

  /// Solo para tests: el store que respalda este provider.
  @visibleForTesting
  LocalStore get store => _store;

  /// Una vez por equipo: marca para subir las siembras que tienen datos de
  /// cohorte y ya estaban sincronizadas. Sin esto, el arreglo del payload no
  /// alcanza a los registros viejos.
  @visibleForTesting
  Future<void> repairCohortUpload() async {
    if (_store.cohortSyncRepairDone()) return;
    var changed = false;
    final list = [..._sowings];
    for (var i = 0; i < list.length; i++) {
      final s = list[i];
      final tieneCohorte = s.replacesPlants != null ||
          s.replacesAreaHa != null ||
          s.cohortSowingId != null;
      if (!tieneCohorte || s.pendingSync) continue;
      list[i] = s.copyWith(pendingSync: true);
      changed = true;
    }
    if (changed) {
      _sowings = list;
      await _store.saveSowings(_sowings);
    }
    await _store.markCohortSyncRepairDone();
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
    _terrenos = _store.loadTerrenos();
    // La marca dirty vive en el namespace: al cambiar de cuenta había que
    // recargarla, o el estado del equipo anterior mandaba sobre el nuevo.
    _settingsDirty = _store.loadSettingsDirty();
    // Igual que la dirty: si no se recarga, un cultivo borrado en la cuenta
    // anterior reviviría aquí (o se borraría sin querer en otra).
    _deletedCrops = _store.loadDeletedCrops();
    _deletedSowings = _store.loadDeletedSowings();
    _deletedHarvests = _store.loadDeletedHarvests();
    _deletedEmployees = _store.loadDeletedEmployees();
    _deletedTerrenos = _store.loadDeletedTerrenos();
    // Etapa A · misma pasada que al construir; aquí sí se puede esperar el
    // recálculo antes de seguir.
    if (_normalizeLegacyCohortsInMemory()) {
      await _recomputeCropsFromSowings();
    }
    _seedCashHistory();
    await reconcilePhaseFromHarvests();
    notifyListeners();
  }

  List<Transaction> get transactions => _transactions;
  List<Crop> get crops => _crops;
  FarmSettings get settings => _settings;
  List<Sowing> get sowings => _sowings;
  List<Employee> get employees => _employees;

  /// **Lo que la app sabe que se cosechó**: las guardadas a mano + las que se
  /// deducen de las ventas que él ya anotó («cosecha derivada de la venta»).
  ///
  /// Reportes, alertas, la ficha del cultivo y el PDF/Excel leen por aquí, y
  /// por eso todos ellos se enteran a la vez sin tocar uno por uno.
  ///
  /// **No se guarda nada**: `deriveHarvests` se recalcula en cada lectura, así
  /// que si él corrige o borra una venta, el dato se arregla solo — y una
  /// cosecha no puede revivir como zombi en el pull. Por lo mismo este getter
  /// **nunca** es el que se sube ni el que se respalda: eso es
  /// [storedHarvests].
  List<Harvest> get harvests => [
        ..._harvests,
        ...deriveHarvests(
          transactions: _transactions,
          manualHarvests: _harvests,
        ),
      ];

  /// Las cosechas **guardadas** en disco, sin derivar: exactamente las que
  /// él anotó.
  ///
  /// Este es el que usan el **sync** (subir / faltar / borrar) y el
  /// **respaldo**. Subir una derivada sería publicar un cálculo que no es
  /// dato, y el `mergeRemoteHarvests` la reviviría si la venta dejara de
  /// existir.
  List<Harvest> get storedHarvests => _harvests;

  /// Los terrenos de la finca. Lista vacía = no se usan: la app se comporta
  /// exactamente igual que antes de que existieran.
  List<Terreno> get terrenos => _terrenos;

  /// Cultivos borrados localmente pendientes de borrar en la BD. Se expone
  /// para que [SyncProvider] pueda subir los borrados.
  List<String> get deletedCrops => _deletedCrops;
  List<String> get deletedSowings => _deletedSowings;
  List<String> get deletedHarvests => _deletedHarvests;
  List<String> get deletedEmployees => _deletedEmployees;
  List<String> get deletedTerrenos => _deletedTerrenos;

  /// Cosechas **guardadas** (no derivadas) de un cultivo o rango.
  ///
  /// Su único uso es **vincular un gasto** con una cosecha, y ahí solo sirve
  /// lo que él anotó a mano: una derivada no se muestra como tal en ninguna
  /// pantalla, y su existencia cuelca de la venta — si la borra, el gasto
  /// quedaría enlazado a un enlace roto.
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
    String? terrenoId,
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
    double? deductionQty,
    String? deductionReason,
    bool paid = true,
    String? task,
    double? harvestedKg,
    double? equivalentKg,
    String? cohortSowingId,
  }) async {
    final txn = Transaction(
      id: _uuid.v4(),
      cropId: cropId,
      // (b) · el lote solo llega cuando el gasto sirve a varios cultivos del
      // mismo terreno; con null el movimiento es el de siempre.
      terrenoId: terrenoId,
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
      deductionQty: deductionQty,
      deductionReason: deductionReason,
      paid: paid,
      task: task,
      harvestedKg: harvestedKg,
      equivalentKg: equivalentKg,
      // Etapa B · lote al que se atribuyen los kilos del jornal (null = sin
      // lote). Es una medida, no un reparto de la venta.
      cohortSowingId: cohortSowingId,
    );
    _transactions = [..._transactions, txn];
    await _store.saveTransactions(_transactions);
    // Una venta que entra con cultivo y kilos crea cosecha derivada: la fase
    // del cultivo tiene que subir en el mismo acto.
    await reconcilePhaseFromHarvests();
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
    // Corregir una venta (más kilos, otro cultivo) puede crear o destruir la
    // cosecha derivada; la fase se recalcula igual, nunca retrocede.
    await reconcilePhaseFromHarvests();
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
  /// producción solo, al dar la primera cosecha (ver
  /// [reconcilePhaseFromHarvests]);
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
    double? expectedYieldPerHa,
    DateTime? primerCosechaEsperada,
    String? terrenoId,
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
      expectedYieldPerHa: expectedYieldPerHa,
      primerCosechaEsperada: primerCosechaEsperada,
      terrenoId: terrenoId,
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
    await reconcilePhaseFromHarvests();
    notifyListeners();
    return harvest;
  }

  /// P3 · Fase automática: un cultivo que ya dio cosecha está en producción.
  ///
  /// La regla **no cambió**: solo se promueve desde `establecimiento`, nunca
  /// al revés, y `renovacion` sigue siendo una decisión de él. Lo que cambió
  /// es **dónde se dispara**, y por eso este método existe:
  ///
  /// antes la única puerta era `addHarvest`, a la que hoy nadie entra. La
  /// cosecha puede salir **deducida de la venta**, así que la condición mira
  /// [harvests] —guardadas + derivadas— y no `_harvests`, y se corre en cada
  /// lugar donde pueden aparecer cosechas:
  ///
  /// * al abrir la app y al recargar (cuentas que ya vendían antes);
  /// * al agregar o editar un movimiento;
  /// * al importar un respaldo;
  /// * al bajar datos de otro equipo (el pull).
  ///
  /// Igual que [_recomputeCropsFromSowings], persiste con `pendingSync: true`
  /// para que la fase viaje al servidor. Es idempotente: una vez promovido el
  /// cultivo deja de cumplir la condición, y nunca hay dos guardados seguidos.
  Future<void> reconcilePhaseFromHarvests() async {
    if (!_promotePhasesInMemory()) return;
    await _store.saveCrops(_crops);
    notifyListeners();
  }

  /// Lo puro de la promoción: muta [_crops] en memoria y dice si cambió algo.
  ///
  /// Está aparte porque los caminos de entrada síncrona (`replaceAllFromSync`,
  /// y el `notifyListeners` que trae cada `mergeRemote*` del pull) no pueden
  /// esperar un `await`: necesitan la fase bien **antes** de avisar.
  bool _promotePhasesInMemory() {
    // Última siembra por cultivo. Lo que se arrancó de nuevo empezó de cero
    // (`sowing_screen.dart:388-403` vuelve la fase a `establecimiento`) y las
    // cosechas de antes son de la plantación anterior. Son hechos y no se
    // borran, pero tampoco deben devolverlo a producción en la apertura
    // siguiente — que es lo que pasaba: la regla "tiene alguna cosecha" era
    // cierta una sola vez y falsa después.
    final ultimaSiembra = <String, DateTime>{};
    for (final s in _sowings) {
      final id = s.cropId;
      if (id == null) continue;
      final prev = ultimaSiembra[id];
      if (prev == null || s.date.isAfter(prev)) ultimaSiembra[id] = s.date;
    }

    final conCosecha = <String>{};
    for (final h in harvests) {
      final cropId = h.cropId;
      if (cropId == null) continue;
      if (!_esDeEstaPlantacion(h.date, ultimaSiembra[cropId])) continue;
      conCosecha.add(cropId);
    }
    if (conCosecha.isEmpty) return false;

    final list = [..._crops];
    var changed = false;
    for (var i = 0; i < list.length; i++) {
      final c = list[i];
      if (c.phase != CropPhase.establecimiento) continue;
      if (!conCosecha.contains(c.id)) continue;
      list[i] = c.copyWith(phase: CropPhase.produccion, pendingSync: true);
      changed = true;
    }
    if (!changed) return false;
    _crops = list;
    return true;
  }

  /// ¿Esta cosecha le corresponde a la plantación que el cultivo tiene hoy?
  ///
  /// La fase dice el **presente**; las cosechas son **histórico**. Un lote
  /// que produjo en 2023 las tiene aunque hoy lo hayas arrancado de nuevo,
  /// y sin esta frontera eso bastaba para devolverlo a producción.
  ///
  /// Sin siembra registrada no hay frontera posible: cuenta todo, como
  /// siempre. Una cuenta vieja que ya vendía no puede quedarse atascada en
  /// `establecimiento` por no tener la siembra anotada.
  bool _esDeEstaPlantacion(DateTime cosecha, DateTime? ultimaSiembra) =>
      ultimaSiembra == null || !cosecha.isBefore(ultimaSiembra);

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

    // E1 · lo que entra es lo neto. Si la venta ya tiene un descuento
    // registrado (el comprador descontó impureza o humedad), el bruto menos
    // ese descuento es lo que se paga — el monto deja de ser simplemente
    // "cantidad cosechada × precio".
    //
    // La unidad del descuento es la de la venta, que es la de la cosecha, así
    // que las dos cantidades siempre hablan lo mismo: no se descuentan kilos
    // de una venta hecha en racimos.
    final deduction = linked?.deductionQty;
    final double netQty = (deduction == null || deduction <= 0)
        ? harvest.amount
        : (harvest.amount - deduction).clamp(0.0, double.infinity).toDouble();
    final amount = netQty * price;
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
    if (!_deletedHarvests.contains(id)) {
      _deletedHarvests = [..._deletedHarvests, id];
      await _store.saveDeletedHarvests(_deletedHarvests);
    }
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
    int? replacesPlants,
    double? replacesAreaHa,
    String? cohortSowingId,
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
      replacesPlants: replacesPlants,
      replacesAreaHa: replacesAreaHa,
      cohortSowingId: cohortSowingId,
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
    if (!_deletedSowings.contains(id)) {
      _deletedSowings = [..._deletedSowings, id];
      await _store.saveDeletedSowings(_deletedSowings);
    }
    _sowings = _sowings.where((s) => s.id != id).toList();
    // Etapa A · las siembras que apuntaban a esta cohorte se quedan sin
    // puntero: el reemplazo deja de restar y la resiembra cae por fecha. Se
    // marcan pendientes para que la corrección suba.
    _sowings = _sowings
        .map((s) => s.cohortSowingId == id
            ? s.copyWith(cohortSowingId: null, pendingSync: true)
            : s)
        .toList();
    await _store.saveSowings(_sowings);
    // B5: desvincular transacciones que referencian esta siembra
    // Etapa B · los jornales que atribuían kilos a este lote se quedan «sin
    // lote»: el dato no se reasigna a otro lote ni se borra. En la nube lo
    // hace la FK (`on delete set null`); en el disco hay que dejarlo igual.
    _transactions = _transactions
        .map((t) => t.sowingId == id || t.cohortSowingId == id
            ? t.copyWith(
                sowingId: t.sowingId == id ? null : t.sowingId,
                cohortSowingId:
                    t.cohortSowingId == id ? null : t.cohortSowingId,
                pendingSync: true,
              )
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
      // Solo se marca para subir si los números cambian de verdad. Antes se
      // marcaba siempre: cada pull re-subía todos los cultivos y podía pisar
      // una edición del otro equipo sin motivo.
      final area = u.areaHa ?? c.areaHa;
      if (c.livePlants == u.livePlants && c.areaHa == area) continue;
      list[i] = c.copyWith(
        livePlants: u.livePlants,
        areaHa: area,
        pendingSync: true,
      );
      changed = true;
    }
    if (changed) {
      _crops = list;
      await _store.saveCrops(_crops);
    }
  }

  /// Etapa A · interpreta los datos viejos como reemplazo, en memoria y una
  /// sola vez (D9).
  ///
  /// Sin esto, dos siembras viejas se leerían como dos cohortes y el total del
  /// cultivo subiría. Idempotente: en cuanto una fila queda tocada deja de
  /// estar en `null` y no se vuelve a procesar. Devuelve `true` si tocó algo
  /// (quien llama decide si recalcula y espera).
  bool _normalizeLegacyCohortsInMemory() {
    final r = normalizeLegacyCohorts(_sowings);
    if (!r.changed) return false;
    _sowings = r.sowings;
    unawaited(_store.saveSowings(_sowings));
    return true;
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
    if (!_deletedEmployees.contains(id)) {
      _deletedEmployees = [..._deletedEmployees, id];
      await _store.saveDeletedEmployees(_deletedEmployees);
    }
    _employees = _employees.where((e) => e.id != id).toList();
    await _store.saveEmployees(_employees);
    notifyListeners();
  }

  // ---- Terrenos ----

  /// Crea un terreno y, si se marcaron cultivos, los mete dentro.
  ///
  /// Las casillas mandan: lo que está marcado entra. Los cultivos que ya
  /// estaban en otro terreno se **mueven** aquí — es mover una cosa de un
  /// lado a otro de la finca, no duplicarla.
  Future<Terreno> addTerreno(
    String name, {
    double? areaHa,
    double? lat,
    double? lng,
    DateTime? locatedAt,
    List<String> cropIds = const [],
  }) async {
    final terreno = Terreno(
      id: _uuid.v4(),
      name: name.trim(),
      areaHa: areaHa,
      lat: lat,
      lng: lng,
      locatedAt: locatedAt,
      pendingSync: true,
    );
    _terrenos = [..._terrenos, terreno];
    await _store.saveTerrenos(_terrenos);
    await _asignarCultivos(terreno.id, cropIds);
    notifyListeners();
    return terreno;
  }

  Future<void> updateTerreno(Terreno updated) async {
    final idx = _terrenos.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    final list = [..._terrenos];
    list[idx] = updated.copyWith(pendingSync: true);
    _terrenos = list;
    await _store.saveTerrenos(_terrenos);
    notifyListeners();
  }

  /// Edita el terreno y vuelve a aplicar la lista marcada de cultivos.
  ///
  /// Misma semántica que al crear: lo marcado queda dentro, lo que estaba y
  /// se desmarcó sale.
  Future<void> updateTerrenoWithCrops(
    Terreno updated,
    List<String> cropIds,
  ) async {
    await updateTerreno(updated);
    await _asignarCultivos(updated.id, cropIds);
    notifyListeners();
  }

  /// Borra el terreno. **No se borra nada con él.**
  ///
  /// Sus cultivos quedan sin terreno (`terreno_id = null`) y sus gastos vuelven
  /// a ser comunes — exactamente lo que hace la BD con `on delete set null`.
  /// La finca del productor se queda igual, un nivel más arriba: él quitó una
  /// etiqueta, no arrancó café.
  Future<void> deleteTerreno(String id) async {
    if (!_deletedTerrenos.contains(id)) {
      _deletedTerrenos = [..._deletedTerrenos, id];
      await _store.saveDeletedTerrenos(_deletedTerrenos);
    }
    _terrenos = _terrenos.where((t) => t.id != id).toList();
    await _store.saveTerrenos(_terrenos);

    final afectados = _crops.any((c) => c.terrenoId == id);
    if (afectados) {
      _crops = [
        for (final c in _crops)
          if (c.terrenoId == id)
            c.copyWith(terrenoId: null, pendingSync: true)
          else
            c,
      ];
      await _store.saveCrops(_crops);
    }
    notifyListeners();
  }

  /// Deja exactamente [cropIds] dentro de [terrenoId] y saca a los demás.
  ///
  /// Solo toca a los que están en juego: los que ya estaban marcados no se
  /// reescriben, y los que pertenecen a otro terreno y no se marcaron aquí
  /// **se quedan donde están** — desmarcar en este terreno no debería
  /// desalojar a un cultivo que nunca vino de este lado.
  Future<void> _asignarCultivos(String terrenoId, List<String> cropIds) async {
    final dentro = cropIds.toSet();
    var huboCambio = false;
    final lista = _crops.map((c) {
      final quiere = dentro.contains(c.id);
      final esta = c.terrenoId == terrenoId;
      if (quiere == esta) return c;
      huboCambio = true;
      return c.copyWith(
        terrenoId: quiere ? terrenoId : null,
        pendingSync: true,
      );
    }).toList();
    if (!huboCambio) return;
    _crops = lista;
    await _store.saveCrops(_crops);
  }

  // ---- Settings ----

  /// Siembra el historial del aporte cuando todavía está vacío.
  ///
  /// Solo el mes en curso y solo una vez: los meses anteriores a la
  /// configuración no tienen presupuesto y no suman ni restan.
  void _seedCashHistory() {
    final aporte = _settings.cajaMensualEfectiva;
    if (aporte == null) return;
    if (_settings.cashBudgetHistory.isNotEmpty) return;
    final history = <String, double>{
      cashBudgetMonthKey(DateTime.now()): aporte,
    };
    _settings = _settings.copyWith(cashBudgetHistory: history);
    _settingsDirty = true;
    unawaited(_store.saveSettings(_settings));
    unawaited(_store.saveSettingsDirty(true));
  }

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
        terrenos: _terrenos,
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
  /// El orden es terrenos → crops → siembras → cosechas → trabajadores →
  /// movimientos → ajustes. Las referencias que no apuntan a nada ni local ni
  /// en el archivo se importan igual, sin enlazar, y solo se cuentan en
  /// [BackupSummary.huerfanos]: no se descartan datos del productor.
  Future<BackupSummary> importBackup(BackupPayload payload) async {
    var agregados = BackupCounts.cero;
    var omitidos = BackupCounts.cero;

    // 1) Terrenos — antes que los cultivos: un cultivo del archivo apunta a
    //    un terreno por id y esa lista tiene que estar completa.
    final terrenoAdd = _fuse(_terrenos, payload.terrenos, (t) => t.id,
        (t) => t.copyWith(pendingSync: true));
    if (terrenoAdd.added.isNotEmpty) {
      _terrenos = [..._terrenos, ...terrenoAdd.added];
      await _store.saveTerrenos(_terrenos);
    }
    agregados += BackupCounts(terrenos: terrenoAdd.added.length);
    omitidos += BackupCounts(terrenos: terrenoAdd.omitidos);

    // 2) Cultivos — misma deduplicación por id que `LocalStore.loadCrops`.
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

    // Etapa A · lo importado también se normaliza: un respaldo viejo con dos
    // siembras no puede mover los números al volver a entrar.
    if (_normalizeLegacyCohortsInMemory()) {
      await _recomputeCropsFromSowings();
    }

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
      // Etapa B · un puntero a un lote que no está (ni aquí ni en el archivo)
      // se importa igual y queda «sin lote»; se cuenta para avisar.
      if (t.cohortSowingId != null &&
          !sowingIds.contains(t.cohortSowingId)) {
        huerfanos++;
      }
    }

    // Un respaldo puede traer ventas que este equipo nunca vio: la fase se
    // recalcula con ellas ya dentro.
    await reconcilePhaseFromHarvests();

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
    // En memoria antes de guardar: el `saveCrops` de abajo persiste la fase
    // ya promovida, así que no hace falta un segundo escritor.
    _promotePhasesInMemory();
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
    _terrenos = _terrenos
        .map((t) => failed(t.id) ? t : t.copyWith(pendingSync: false))
        .toList();
    // Mismo criterio que con los movimientos: solo se olvidan los borrados de
    // cultivo que SÍ llegaron. Si se descartaran los fallidos, el pull los
    // resucitaría desde el remoto.
    _deletedCrops = _deletedCrops.where(failed).toList();
    _deletedSowings = _deletedSowings.where(failed).toList();
    _deletedHarvests = _deletedHarvests.where(failed).toList();
    _deletedEmployees = _deletedEmployees.where(failed).toList();
    _deletedTerrenos = _deletedTerrenos.where(failed).toList();
    await _store.saveTransactions(_transactions);
    await _store.saveCrops(_crops);
    await _store.saveHarvests(_harvests);
    await _store.saveSowings(_sowings);
    await _store.saveEmployees(_employees);
    await _store.saveTerrenos(_terrenos);
    await _store.saveDeletedCrops(_deletedCrops);
    await _store.saveDeletedSowings(_deletedSowings);
    await _store.saveDeletedHarvests(_deletedHarvests);
    await _store.saveDeletedEmployees(_deletedEmployees);
    await _store.saveDeletedTerrenos(_deletedTerrenos);
    notifyListeners();
  }

  void mergeRemote(List<Transaction> remoteTransactions) {
    // El pull también trae ediciones de filas que ya existen. Reemplaza solo
    // si lo local está sincronizado: una edición sin subir no se pisa.
    final byId = {for (final t in _transactions) t.id: t};
    for (final r in remoteTransactions) {
      final local = byId[r.id];
      if (local == null || !local.pendingSync) byId[r.id] = r;
    }
    _transactions = byId.values.toList();
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

    // Mismo criterio que los movimientos: el remoto reemplaza si lo local ya
    // está subido; los borrados pendientes no reviven.
    final pendingDeletes = _deletedCrops.toSet();
    final byId = {for (final c in _crops) c.id: c};
    for (final r in remoteCrops) {
      if (pendingDeletes.contains(r.id)) continue;
      final local = byId[r.id];
      if (local == null || !local.pendingSync) byId[r.id] = r;
    }
    _crops = byId.values.toList();
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
    final pendingDeletes = _deletedHarvests.toSet();
    final byId = {for (final h in _harvests) h.id: h};
    for (final r in remoteHarvests) {
      if (pendingDeletes.contains(r.id)) continue;
      final local = byId[r.id];
      if (local == null || !local.pendingSync) byId[r.id] = r;
    }
    _harvests = byId.values.toList();
    _store.saveHarvests(_harvests);
    notifyListeners();
  }

  void mergeRemoteSowings(List<Sowing> remoteSowings) {
    final pendingDeletes = _deletedSowings.toSet();
    final byId = {for (final s in _sowings) s.id: s};
    for (final r in remoteSowings) {
      if (pendingDeletes.contains(r.id)) continue;
      final local = byId[r.id];
      if (local == null || !local.pendingSync) byId[r.id] = r;
    }
    _sowings = byId.values.toList();
    _store.saveSowings(_sowings);
    // Etapa A · el pull puede traer cohortes nuevas: los cultivos afectados
    // tienen que quedar recalculados. Un puntero que todavía no llegó se
    // conserva tal cual (no se anula).
    unawaited(_recomputeCropsFromSowings());
    notifyListeners();
  }

  void mergeRemoteEmployees(List<Employee> remoteEmployees) {
    final pendingDeletes = _deletedEmployees.toSet();
    final byId = {for (final e in _employees) e.id: e};
    final names = _employees.map((e) => e.name.trim().toLowerCase()).toSet();
    for (final r in remoteEmployees) {
      if (pendingDeletes.contains(r.id)) continue;
      final local = byId[r.id];
      final key = r.name.trim().toLowerCase();
      if (local == null) {
        if (names.contains(key)) continue;
        byId[r.id] = r;
        names.add(key);
      } else if (!local.pendingSync) {
        byId[r.id] = r;
        names.add(key);
      }
    }
    _employees = byId.values.toList();
    _store.saveEmployees(_employees);
    notifyListeners();
  }

  /// Fusiona los terrenos que trae el pull.
  ///
  /// Deduplica por id **y** por nombre (normalizado): a diferencia de los
  /// cultivos — donde dos "Café" son dos lotes reales y no hay que juntarlos —,
  /// dos terrenos con el mismo nombre son el mismo pedazo de tierra visto desde
  /// otro equipo, y dejarlos separados partiría la finca en dos.
  void mergeRemoteTerrenos(List<Terreno> remoteTerrenos) {
    final pendingDeletes = _deletedTerrenos.toSet();
    final byId = {for (final t in _terrenos) t.id: t};
    final names = _terrenos.map((t) => t.name.trim().toLowerCase()).toSet();
    for (final r in remoteTerrenos) {
      if (pendingDeletes.contains(r.id)) continue;
      final local = byId[r.id];
      final key = r.name.trim().toLowerCase();
      if (local == null) {
        if (names.contains(key)) continue;
        byId[r.id] = r;
        names.add(key);
      } else if (!local.pendingSync) {
        byId[r.id] = r;
        names.add(key);
      }
    }
    _terrenos = byId.values.toList();
    _store.saveTerrenos(_terrenos);
    notifyListeners();
  }
}
