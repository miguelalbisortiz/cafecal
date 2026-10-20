import 'package:flutter/foundation.dart';

import '../models/crop.dart';
import '../models/employee.dart';
import '../models/harvest.dart';
import '../models/settings.dart';
import '../models/sowing.dart';
import '../models/terreno.dart';
import '../models/transaction.dart';
import '../services/supabase_service.dart';
import 'transaction_provider.dart';

/// Resultado de una pasada de push: qué falló y por qué.
///
/// Cada entidad se sube de forma aislada (`try/catch` propio): una fila
/// problemática NO aborta el resto. Sin esto, un solo registro con un
/// `crop_id` legado dejaba la cuenta entera vacía y había que "corregir
/// cada vez que se subían datos".
class _PushOutcome {
  final Set<String> failedIds = {};
  final List<String> errors = [];

  void fail(String label, Object e, {String? id}) {
    if (id != null) failedIds.add(id);
    errors.add('$label: ${_describe(e)}');
    debugPrint('[SyncProvider] $label: $e');
  }

  static String _describe(Object e) {
    final s = e.toString();
    if (s.contains('PGRST204') || s.contains('42703')) {
      return 'falta una columna en la base de datos (aplica las migraciones)';
    }
    if (s.contains('23503')) return 'falta un registro relacionado';
    if (s.contains('22P02')) return 'identificador con formato inválido';
    if (s.contains('JWT') || s.contains('401') || s.contains('403')) {
      return 'sesión expirada, vuelve a entrar';
    }
    return s;
  }
}

/// Una unidad de subida aislable. Si [run] falla, solo se reporta esta
/// etapa: las demás se siguen intentando igual que antes.
@immutable
class PushStage {
  const PushStage({
    required this.table,
    required this.label,
    required this.run,
    this.id,
  });

  /// Tabla de destino. Su orden en [SyncProvider.buildPushStages] es el que
  /// exigen las claves foráneas; se expone para poder testearlo.
  final String table;

  /// Nombre legible del error si esta etapa falla.
  final String label;

  /// Id del registro local, para no marcarlo como sincronizado si falla.
  final String? id;

  final Future<void> Function() run;
}

final _uuidRe = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

bool _isUuid(String? v) => v != null && _uuidRe.hasMatch(v);

/// Devuelve [v] solo si es un uuid válido; cualquier id legado ('cafe')
/// se convierte en `null` para no violar la FK de la columna.
String? _uuidOrNull(String? v) => _isUuid(v) ? v : null;

class SyncProvider extends ChangeNotifier {
  final TransactionProvider _txProvider;
  bool _syncing = false;

  /// Un sync pedido mientras otro está corriendo no se descarta: se repite
  /// al terminar. Sin esto, registrar dos movimientos seguidos dejaba el
  /// segundo sin subir hasta el próximo ⟳ manual.
  bool _syncPending = false;

  bool _error = false;
  String? _lastSyncError;

  SyncProvider(this._txProvider);

  bool get syncing => _syncing;
  bool get hasError => _error;
  String? get lastSyncError => _lastSyncError;

  /// Empuja cambios locales pendientes y tira del remoto.
  /// La clave publishable + RLS protege los datos por usuario.
  Future<void> sync() async {
    final supabase = SupabaseService.instance;
    if (!supabase.isConfigured) {
      // Modo offline sin backend: nada que sincronizar.
      return;
    }
    if (!supabase.isAuthenticated) return;
    if (_syncing) {
      // Ya hay una pasada en marcha: no la interrumpimos, repetimos al final
      // para que lo recién registrado termine subido sin tocar ⟳ otra vez.
      _syncPending = true;
      return;
    }

    _syncing = true;
    _error = false;
    _lastSyncError = null;
    notifyListeners();

    try {
      final outcome = await _pushLocal(supabase);

      // El pull va aparte: aunque falle el push, queremos lo remoto.
      try {
        await _pullRemote(supabase);
      } catch (e) {
        outcome.errors.add('No se pudo leer lo remoto: ${_PushOutcome._describe(e)}');
        debugPrint('[SyncProvider] pull: $e');
      }

      // Solo lo que SÍ subió se marca como sincronizado; lo fallido queda
      // pendiente y se reintenta en el próximo sync.
      await _txProvider.markAllSynced(skip: outcome.failedIds);

      if (outcome.errors.isNotEmpty) {
        _error = true;
        _lastSyncError = outcome.errors.join('\n');
      }
    } catch (e) {
      _error = true;
      _lastSyncError = e.toString();
      debugPrint('[SyncProvider] error: $e');
    } finally {
      _syncing = false;
      notifyListeners();
    }

    // Las peticiones anotadas durante la pasada se atienden ahora.
    if (_syncPending) {
      _syncPending = false;
      await sync();
    }
  }

  /// Construye la secuencia de subida. El orden lo imponen las FK de la BD,
  /// no la interfaz:
  ///
  ///   settings (raíz) → terrenos (raíz) → crops (puede apuntar a un
  ///   terreno) → sowings/harvests (usan crops) → employees (sin FK)
  ///   → transactions (usa crops/sowings/harvests)
  ///
  /// Antes las transacciones iban primero y explotaban con
  /// `transactions_crop_id_fkey` porque el cultivo todavía no existía.
  @visibleForTesting
  List<PushStage> buildPushStages(SupabaseService supabase) {
    // Ids legados ('cafe') que la columna uuid no puede recibir: se omiten
    // sin marcarlos como fallo, porque nunca serían insertables tal cual.
    for (final c in _txProvider.crops.where((c) => !_isUuid(c.id))) {
      debugPrint('[SyncProvider] cultivo con id no-uuid omitido: ${c.id}');
    }

    final stages = <PushStage>[
      PushStage(
        table: 'settings',
        label: 'Ajustes',
        run: () => _upsertRemoteSettings(supabase),
      ),
      // Antes que los cultivos: `crops.terreno_id` es FK, y subir un cultivo
      // apuntando a un terreno que todavía no existe en la BD da error de
      // foreign key (el mismo motivo por el que iban primero que las
      // transacciones).
      // Solo lo que cambió.
      //
      // Sin este filtro la caché entera se re-subía en cada sync: un equipo
      // que solo abría la app volvía a escribir sus filas viejas y pisaba lo
      // que el otro equipo había actualizado mientras tanto. `markAllSynced`
      // es la única fuente de verdad de "esto ya está en la BD".
      //
      // Lo que baja del pull NO vuelve a subir: `mergeRemote*` lo añade tal
      // cual, con el `pending_sync` que trae de la BD.
      //
      // `deletedCrops` no pasa por aquí: son ids sueltos y `markAllSynced`
      // ya los depura (solo quedan los que fallaron).
      for (final t in _txProvider.terrenos.where((t) => t.pendingSync))
        PushStage(
          table: 'terrenos',
          label: 'Terreno "${t.name}"',
          id: t.id,
          run: () => _upsertRemoteTerreno(supabase, t),
        ),
      for (final c in _txProvider.crops
          .where((c) => _isUuid(c.id) && c.pendingSync))
        PushStage(
          table: 'crops',
          label: 'Cultivo "${c.name}"',
          id: c.id,
          run: () => _upsertRemoteCrop(supabase, c),
        ),
      // El borrado viaja con los cultivos: sin subirlo, el pull lo reviviría
      // (crops solo se hace upsert). Los ids no-uuid se omiten: nunca estuvieron
      // en la BD y `crop_id` es uuid, así que esa consulta daría error.
      for (final id in _txProvider.deletedCrops.where(_isUuid))
        PushStage(
          table: 'crops',
          label: 'Borrado de cultivo',
          id: id,
          run: () => _deleteRemoteCrop(supabase, id),
        ),
      for (final s in _txProvider.sowings.where((s) => s.pendingSync))
        PushStage(
          table: 'sowings',
          label: 'Siembra',
          id: s.id,
          run: () => _upsertRemoteSowing(supabase, s),
        ),
      // Solo las GUARDADAS: una derivada no es dato que subir, es un cálculo
      // que se vuelve a hacer en cada lectura. Ver `storedHarvests`.
      for (final h in _txProvider.storedHarvests.where((h) => h.pendingSync))
        PushStage(
          table: 'harvests',
          label: 'Cosecha',
          id: h.id,
          run: () => _upsertRemoteHarvest(supabase, h),
        ),
      for (final e in _txProvider.employees.where((e) => e.pendingSync))
        PushStage(
          table: 'employees',
          label: 'Trabajador "${e.name}"',
          id: e.id,
          run: () => _upsertRemoteEmployee(supabase, e),
        ),
      for (final t in _txProvider.transactions.where((t) => t.pendingSync))
        PushStage(
          table: 'transactions',
          label: t.deleted ? 'Borrado de movimiento' : 'Movimiento',
          id: t.id,
          run: t.deleted
              ? () => _deleteRemote(supabase, t.id)
              : () => _upsertRemote(supabase, t),
        ),
    ];
    return stages;
  }

  Future<_PushOutcome> _pushLocal(SupabaseService supabase) async {
    final o = _PushOutcome();
    for (final stage in buildPushStages(supabase)) {
      await _guard(o, stage.label, id: stage.id, run: stage.run);
    }
    return o;
  }

  Future<void> _guard(
    _PushOutcome o,
    String label, {
    String? id,
    required Future<void> Function() run,
  }) async {
    try {
      await run();
    } catch (e) {
      o.fail(label, e, id: id);
    }
  }

  /// ¿Toca subir `settings`? Solo si el usuario cambió algo.
  ///
  /// Un equipo recién instalado arranca con los defaults de [FarmSettings] y
  /// `settingsDirty = false`; subirlos tapaba el valor real del otro equipo.
  /// El 2026-10-01 eso borró `caja_menor_mensual` (30.000.000 → null): el push
  /// corría antes del pull y solo la bajada estaba protegida. La misma guarda
  /// evita ahora la subida.
  @visibleForTesting
  static bool shouldPushSettings(bool settingsDirty) => settingsDirty;

  Future<void> _upsertRemoteSettings(SupabaseService supabase) async {
    final user = supabase.client.auth.currentUser;
    if (user == null) return;
    if (!shouldPushSettings(_txProvider.settingsDirty)) return;
    await supabase.client.from('settings').upsert(
          buildSettingsPayload(_txProvider.settings, user.id),
          onConflict: 'user_id',
        );
    await _txProvider.markSettingsSynced();
  }

  /// Payload que sale hacia `settings`.
  ///
  /// Va completo, con las tres columnas nulas incluidas: si un valor no está
  /// configurado, se quiere reflejar así en la BD y no dejar el anterior.
  @visibleForTesting
  Map<String, dynamic> buildSettingsPayload(FarmSettings s, String userId) => {
        'user_id': userId,
        'farm_name': s.farmName,
        'currency': s.currency,
        'locale': s.numberLocale,
        'language': s.language,
        'last_crop_id': s.lastCropId,
        'low_price_threshold_per_kg': s.lowPriceThresholdPerKg,
        'caja_menor_mensual': s.cajaMenorMensual,
        // E3 · va completo (incluido null) por la misma razón que caja: si el
        // productor vació el campo, hay que reflejarlo en la BD y no dejar
        // pisado el valor anterior.
        'presupuesto_obra_mensual': s.presupuestoObraMensual,
        // A2: nunca null, así que siempre sale el peso del saco.
        'saco_kg': s.sacoKg,
      };

  /// Payload que sale hacia `transactions`.
  ///
  /// Los ids referenciados pasan por [_uuidOrNull]: los datos legados guardan
  /// `crop_id: 'cafe'` y una FK a la columna uuid rechazaría la fila entera
  /// (error 22P02), lo que volvía a tumbar todo el push.
  @visibleForTesting
  Map<String, dynamic> buildTransactionPayload(Transaction t, String userId) =>
      {
        'id': t.id,
        'user_id': userId,
        'crop_id': _uuidOrNull(t.cropId),
        // (b) · el lote al que sirve el gasto. Va completa, incluida null, por
        // la misma razón que `task`: si el productor cambia un gasto de "del
        // café" a "del lote", hay que reflejarlo y no dejar pisado el valor.
        'terreno_id': _uuidOrNull(t.terrenoId),
        'type': t.type.serialize,
        'category': t.category,
        'amount': t.amount,
        'currency': t.currency,
        'description': t.description,
        'txn_date': t.date.toIso8601String().substring(0, 10),
        'created_at': t.createdAt.toUtc().toIso8601String(),
        'quantity': t.quantity,
        'unit': t.unit,
        'price_per_unit': t.pricePerUnit,
        'client': t.client,
        'provider': t.provider,
        'harvest_id': _uuidOrNull(t.harvestId),
        'sowing_id': _uuidOrNull(t.sowingId),
        // E1 · la venta real. `paid` nunca es null (la columna es not null),
        // por eso sale con ?? true.
        'deduction_qty': t.deductionQty,
        'deduction_reason': t.deductionReason,
        'paid': t.paid,
        // E3 · la labor. Va completa (incluida null) por la misma razón que
        // los demás nullable: si el productor le quitó la labor a un jornal,
        // hay que reflejarlo y no dejar pisado el valor anterior.
        'task': t.task,
        // Tanda 2 · los kilos recolectados. Va completa, incluida null: si se
        // omitiera, el pull dejaría el valor anterior y un jornal que dejó de
        // medir seguiría midiendo. Nunca 0: null es «no medido».
        'harvested_kg': t.harvestedKg,
      };

  Future<void> _upsertRemote(SupabaseService supabase, Transaction t) async {
    final user = supabase.client.auth.currentUser;
    if (user == null) return;
    await supabase.client
        .from('transactions')
        .upsert(buildTransactionPayload(t, user.id), onConflict: 'id');
  }

  Future<void> _deleteRemote(SupabaseService supabase, String id) async {
    await supabase.client.from('transactions').delete().eq('id', id);
  }

  /// Borra un cultivo en la BD junto con las siembras y cosechas que lo usan.
  ///
  /// El orden es el contrario al del resto: primero los hijos, después el
  /// cultivo. Las FK de `sowings.crop_id` y `harvests.crop_id` son
  /// `on delete set null`, así que si se borrara el cultivo primero quedarían
  /// con `crop_id` a null y ya no coincidirían con el id que buscamos,
  /// dejando filas que el pull devolvería como huérfanas.
  ///
  /// Los movimientos **no** se borran: localmente se quedan como "sin cultivo"
  /// y vuelven a subirse con `crop_id` null.
  Future<void> _deleteRemoteCrop(SupabaseService supabase, String id) async {
    await supabase.client.from('sowings').delete().eq('crop_id', id);
    await supabase.client.from('harvests').delete().eq('crop_id', id);
    await supabase.client.from('crops').delete().eq('id', id);
  }

  /// Payload que sale hacia `crops`. Incluye `currency`: sin esa columna en
  /// la BD, Postgrest respondía PGRST204 y se caía la subida completa.
  @visibleForTesting
  Map<String, dynamic> buildCropPayload(Crop c, String userId) => {
        'id': c.id,
        'user_id': userId,
        'name': c.name,
        'icon': c.icon,
        'color': c.color,
        'phase': c.phase.name,
        'cycle': c.cycle.name,
        'default_unit': c.defaultUnit,
        'area_ha': c.areaHa,
        'live_plants': c.livePlants,
        'establishment_cost': c.establishmentCost,
        'currency': c.currency,
        // C1: si falta la columna, Postgrest responde PGRST204 y se cae la
        // subida completa (mismo caso que `currency` — ver migración).
        'planted_at': c.plantedAt?.toIso8601String().substring(0, 10),
        // E4: ídem — la migración 202610110003 va ANTES del deploy.
        'expected_yield_kg_ha': c.expectedYieldPerHa,
        // E5: ídem — la migración 202610110004 va ANTES del deploy.
        'primer_cosecha_esperada':
            c.primerCosechaEsperada?.toIso8601String().substring(0, 10),
        // W1: ídem — la migración 202610120001 va ANTES del deploy. Omitir
        // esta columna tumbaría TODA la subida de cultivos con PGRST204.
        'terreno_id': c.terrenoId,
      };

  Future<void> _upsertRemoteCrop(SupabaseService supabase, Crop c) async {
    final user = supabase.client.auth.currentUser;
    if (user == null) return;
    await supabase.client
        .from('crops')
        .upsert(buildCropPayload(c, user.id), onConflict: 'id');
  }

  @visibleForTesting
  Map<String, dynamic> buildHarvestPayload(Harvest h, String userId) => {
        'id': h.id,
        'user_id': userId,
        'crop_id': _uuidOrNull(h.cropId),
        'amount': h.amount,
        'unit': h.unit,
        'destination': h.destination.name,
        'harvest_date': h.date.toIso8601String().substring(0, 10),
        'workers': h.workers,
        'equivalent_kg': h.equivalentKg,
      };

  Future<void> _upsertRemoteHarvest(SupabaseService supabase, Harvest h) async {
    final user = supabase.client.auth.currentUser;
    if (user == null) return;
    await supabase.client
        .from('harvests')
        .upsert(buildHarvestPayload(h, user.id), onConflict: 'id');
  }

  @visibleForTesting
  Map<String, dynamic> buildSowingPayload(Sowing s, String userId) => {
        'id': s.id,
        'user_id': userId,
        'crop_id': _uuidOrNull(s.cropId),
        'kind': s.kind.name,
        'plants': s.plants,
        'area_ha': s.areaHa,
        'lost_plants': s.lostPlants,
        'reason': s.reason,
        'sowing_date': s.date.toIso8601String().substring(0, 10),
      };

  Future<void> _upsertRemoteSowing(SupabaseService supabase, Sowing s) async {
    final user = supabase.client.auth.currentUser;
    if (user == null) return;
    await supabase.client
        .from('sowings')
        .upsert(buildSowingPayload(s, user.id), onConflict: 'id');
  }

  Future<void> _upsertRemoteEmployee(SupabaseService supabase, Employee e) async {
    final user = supabase.client.auth.currentUser;
    if (user == null) return;
    await supabase.client.from('employees').upsert({
      'id': e.id,
      'user_id': user.id,
      'name': e.name,
      'day_rate': e.dayRate,
    }, onConflict: 'id');
  }

  /// Payload que sale hacia `terrenos`.
  ///
  /// Los tres campos de ubicación viajan **siempre**, aunque sean `null`:
  /// omitir una columna que existe en la BD responde PGRST204 y tumba la
  /// subida entera (mismo caso que `currency` y `terreno_id`). Y un terreno
  /// sin ubicar sube con `null`, no con `0` — un `0` diría que el lote
  /// está en el ecuador y el meridiano de Greenwich.
  @visibleForTesting
  Map<String, dynamic> buildTerrenoPayload(Terreno t, String userId) => {
        'id': t.id,
        'user_id': userId,
        'name': t.name,
        'area_ha': t.areaHa,
        'lat': t.lat,
        'lng': t.lng,
        'located_at': t.locatedAt?.toIso8601String(),
      };

  Future<void> _upsertRemoteTerreno(SupabaseService supabase, Terreno t) async {
    final user = supabase.client.auth.currentUser;
    if (user == null) return;
    await supabase.client
        .from('terrenos')
        .upsert(buildTerrenoPayload(t, user.id), onConflict: 'id');
  }

  Future<void> _pullRemote(SupabaseService supabase) async {
    final user = supabase.client.auth.currentUser;
    if (user == null) return;

    // Ajustes: solo si no hay cambios locales pendientes. Si no, un
    // dispositivo recién instalado pisaría la caja menor del otro.
    if (!_txProvider.settingsDirty) {
      final remoteSettings = await supabase.client
          .from('settings')
          .select()
          .eq('user_id', user.id);
      if (remoteSettings.isNotEmpty) {
        _txProvider.applyRemoteSettings(
            FarmSettings.fromJson(remoteSettings.first));
      }
    }

    final remoteTerrenos = await supabase.client
        .from('terrenos')
        .select()
        .eq('user_id', user.id);

    final remoteTx = await supabase.client
        .from('transactions')
        .select()
        .eq('user_id', user.id);
    final remoteCrops =
        await supabase.client.from('crops').select().eq('user_id', user.id);
    final remoteHarvests = await supabase.client
        .from('harvests')
        .select()
        .eq('user_id', user.id);
    final remoteSowings = await supabase.client
        .from('sowings')
        .select()
        .eq('user_id', user.id);
    final remoteEmployees = await supabase.client
        .from('employees')
        .select()
        .eq('user_id', user.id);

    final localIds = _txProvider.transactions.map((t) => t.id).toSet();
    final remoteMapped = (remoteTx as List)
        .map((e) => remoteToTransaction(e as Map<String, dynamic>))
        .where((t) => !localIds.contains(t.id))
        .toList();

    if (remoteMapped.isNotEmpty) {
      _txProvider.mergeRemote(remoteMapped);
    }

    // Los terrenos entran antes que los cultivos: un cultivo remoto puede
    // traer un `terreno_id` que esta cuenta aún no tiene local, y la lista
    // de terrenos tiene que estar completa para poder mostrarlo.
    final terrenoLocalIds = _txProvider.terrenos.map((t) => t.id).toSet();
    final remoteTerrenoMapped = (remoteTerrenos as List)
        .map((e) => remoteToTerreno(e as Map<String, dynamic>))
        .where((t) => !terrenoLocalIds.contains(t.id))
        .toList();
    if (remoteTerrenoMapped.isNotEmpty) {
      _txProvider.mergeRemoteTerrenos(remoteTerrenoMapped);
    }

    final cropLocalIds = _txProvider.crops.map((c) => c.id).toSet();
    final remoteCropMapped = (remoteCrops as List)
        .map((e) => remoteToCrop(e as Map<String, dynamic>))
        .where((c) => !cropLocalIds.contains(c.id))
        .toList();
    if (remoteCropMapped.isNotEmpty) {
      _txProvider.mergeRemoteCrops(remoteCropMapped);
    }

    // Ids **guardados**: las derivadas viven en memoria y su id sintético
    // (der_venta_…) jamás va a coincidir con uno remoto, así que meterlas
    // aquí solo ensuciaría el conjunto.
    final harvestLocalIds =
        _txProvider.storedHarvests.map((h) => h.id).toSet();
    final remoteHarvestMapped = (remoteHarvests as List)
        .map((e) => _remoteToHarvest(e as Map<String, dynamic>))
        .where((h) => !harvestLocalIds.contains(h.id))
        .toList();
    if (remoteHarvestMapped.isNotEmpty) {
      _txProvider.mergeRemoteHarvests(remoteHarvestMapped);
    }

    final sowingLocalIds = _txProvider.sowings.map((s) => s.id).toSet();
    final remoteSowingMapped = (remoteSowings as List)
        .map((e) => _remoteToSowing(e as Map<String, dynamic>))
        .where((s) => !sowingLocalIds.contains(s.id))
        .toList();
    if (remoteSowingMapped.isNotEmpty) {
      _txProvider.mergeRemoteSowings(remoteSowingMapped);
    }

    final employeeLocalIds = _txProvider.employees.map((e) => e.id).toSet();
    final remoteEmployeeMapped = (remoteEmployees as List)
        .map((e) => _remoteToEmployee(e as Map<String, dynamic>))
        .where((e) => !employeeLocalIds.contains(e.id))
        .toList();
    if (remoteEmployeeMapped.isNotEmpty) {
      _txProvider.mergeRemoteEmployees(remoteEmployeeMapped);
    }

    // Último, después de **todos** los merges (cultivos incluidos): una venta
    // remota puede haber puesto un cultivo en producción, y eso hay que
    // guardarlo ya — si no, el próximo pull lo volvería a traer en
    // `establecimiento` y la regla 5 seguiría diciendo `info`.
    await _txProvider.reconcilePhaseFromHarvests();
  }

  /// Terreno que baja del pull. `lat`/`lng`/`located_at` pueden venir
  /// nulos — un terreno sin ubicación llega sin ellos y se queda sin
  /// ubicación acá, lo contrario de que la app le invente un punto en
  /// (0, 0).
  @visibleForTesting
  Terreno remoteToTerreno(Map<String, dynamic> row) {
    return Terreno.fromJson({
      'id': row['id'] as String,
      'name': row['name'] as String,
      'area_ha': (row['area_ha'] as num?)?.toDouble(),
      // Postgrest devuelve `timestamptz` como ISO 8601, que es justo lo
      // que lee `Terreno.fromJson`. `numeric` llega como num.
      'lat': (row['lat'] as num?)?.toDouble(),
      'lng': (row['lng'] as num?)?.toDouble(),
      'located_at': row['located_at'] as String?,
      'pending_sync': false,
    });
  }

  /// Fila de `transactions` → [Transaction]. Pública para poder probar que lo
  /// que baja de Supabase conserva todo (mismo motivo que [remoteToCrop]).
  @visibleForTesting
  Transaction remoteToTransaction(Map<String, dynamic> row) {
    return Transaction.fromJson({
      'id': row['id'] as String,
      'crop_id': row['crop_id'] as String?,
      // Respaldos anteriores a la migración 202610160002 no traen la clave
      // → null → el movimiento sigue siendo de siempre.
      'terreno_id': row['terreno_id'] as String?,
      'type': row['type'] as String,
      'category': row['category'] as String,
      'amount': (row['amount'] as num).toDouble(),
      'currency': (row['currency'] as String?) ?? 'COP',
      'description': (row['description'] as String?) ?? '',
      'date': (row['txn_date'] as String),
      'created_at': (row['created_at'] as String),
      'pending_sync': false,
      'deleted': false,
      'quantity': (row['quantity'] as num?)?.toDouble(),
      'unit': row['unit'] as String?,
      'price_per_unit': (row['price_per_unit'] as num?)?.toDouble(),
      'client': row['client'] as String?,
      'provider': row['provider'] as String?,
      'harvest_id': row['harvest_id'] as String?,
      'sowing_id': row['sowing_id'] as String?,
      'deduction_qty': (row['deduction_qty'] as num?)?.toDouble(),
      'deduction_reason': row['deduction_reason'] as String?,
      'paid': (row['paid'] as bool?) ?? true,
      'task': row['task'] as String?,
      // Tanda 2 · filas anteriores a la migración no traen la clave → null.
      'harvested_kg': (row['harvested_kg'] as num?)?.toDouble(),
    });
  }

  /// Fila de `crops` → [Crop]. Pública para poder probar que lo que baja de
  /// Supabase conserva todo (mismo motivo que [buildCropPayload]).
  @visibleForTesting
  Crop remoteToCrop(Map<String, dynamic> row) {
    return Crop.fromJson({
      'id': row['id'] as String,
      'name': row['name'] as String,
      'icon': (row['icon'] as String?) ?? '🌱',
      'color': (row['color'] as String?) ?? '#2E7D32',
      'pending_sync': false,
      'phase': row['phase'] as String?,
      'cycle': row['cycle'] as String?,
      'default_unit': row['default_unit'] as String?,
      'area_ha': (row['area_ha'] as num?)?.toDouble(),
      'live_plants': (row['live_plants'] as num?)?.toInt(),
      'establishment_cost': (row['establishment_cost'] as num?)?.toDouble(),
      'currency': row['currency'] as String?,
      'planted_at': row['planted_at'] as String?,
      'expected_yield_kg_ha':
          (row['expected_yield_kg_ha'] as num?)?.toDouble(),
      // E5: el respaldo anterior a la migración no trae la clave → null.
      'primer_cosecha_esperada': row['primer_cosecha_esperada'] as String?,
      // W1: respaldo anterior a la migración 202610120001 no trae la clave
      // → null → el cultivo queda sin terreno, igual que siempre.
      'terreno_id': row['terreno_id'] as String?,
    });
  }

  Harvest _remoteToHarvest(Map<String, dynamic> row) {
    return Harvest.fromJson({
      'id': row['id'] as String,
      'crop_id': row['crop_id'] as String?,
      'date': (row['harvest_date'] as String),
      'amount': (row['amount'] as num).toDouble(),
      'unit': (row['unit'] as String?) ?? 'kg',
      'destination': (row['destination'] as String?) ?? 'vendido',
      'pending_sync': false,
      'workers': (row['workers'] as num?)?.toInt(),
      'equivalent_kg': (row['equivalent_kg'] as num?)?.toDouble(),
    });
  }

  Employee _remoteToEmployee(Map<String, dynamic> row) {
    return Employee.fromJson({
      'id': row['id'] as String,
      'name': row['name'] as String,
      'day_rate': (row['day_rate'] as num?)?.toDouble(),
      'pending_sync': false,
    });
  }

  Sowing _remoteToSowing(Map<String, dynamic> row) {
    return Sowing.fromJson({
      'id': row['id'] as String,
      'crop_id': row['crop_id'] as String?,
      'date': (row['sowing_date'] as String),
      'kind': (row['kind'] as String?) ?? 'siembra',
      'plants': (row['plants'] as num).toInt(),
      'area_ha': (row['area_ha'] as num?)?.toDouble(),
      'lost_plants': (row['lost_plants'] as num?)?.toInt(),
      'reason': row['reason'] as String?,
      'pending_sync': false,
    });
  }
}
