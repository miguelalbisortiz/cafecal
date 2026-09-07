import 'package:flutter/foundation.dart';

import '../models/crop.dart';
import '../models/harvest.dart';
import '../models/sowing.dart';
import '../models/transaction.dart';
import '../services/supabase_service.dart';
import 'transaction_provider.dart';

class SyncProvider extends ChangeNotifier {
  final TransactionProvider _txProvider;
  bool _syncing = false;
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
    if (_syncing) return;

    _syncing = true;
    _error = false;
    _lastSyncError = null;
    notifyListeners();

    try {
      await _pushLocal(supabase);
      await _pullRemote(supabase);
      await _txProvider.markAllSynced();
    } catch (e) {
      _error = true;
      _lastSyncError = e.toString();
      debugPrint('[SyncProvider] error: $e');
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> _pushLocal(SupabaseService supabase) async {
    final pending = _txProvider.pendingSync();
    if (pending.isEmpty) return;

    for (final t in pending) {
      if (t.deleted) {
        await _deleteRemote(supabase, t.id);
      } else {
        await _upsertRemote(supabase, t);
      }
    }

    for (final c in _txProvider.crops.where((c) => c.pendingSync)) {
      await _upsertRemoteCrop(supabase, c);
    }

    for (final h in _txProvider.harvests.where((h) => h.pendingSync)) {
      await _upsertRemoteHarvest(supabase, h);
    }

    for (final s in _txProvider.sowings.where((s) => s.pendingSync)) {
      await _upsertRemoteSowing(supabase, s);
    }
  }

  Future<void> _upsertRemote(SupabaseService supabase, Transaction t) async {
    final user = supabase.client.auth.currentUser;
    if (user == null) return;
    await supabase.client.from('transactions').upsert({
      'id': t.id,
      'user_id': user.id,
      'crop_id': t.cropId,
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
      'harvest_id': t.harvestId,
      'sowing_id': t.sowingId,
    }, onConflict: 'id');
  }

  Future<void> _deleteRemote(SupabaseService supabase, String id) async {
    await supabase.client.from('transactions').delete().eq('id', id);
  }

  Future<void> _upsertRemoteCrop(SupabaseService supabase, Crop c) async {
    final user = supabase.client.auth.currentUser;
    if (user == null) return;
    if (_isDefaultCrop(c)) return; // los defaults existen vía trigger
    await supabase.client.from('crops').upsert({
      'id': c.id,
      'user_id': user.id,
      'name': c.name,
      'icon': c.icon,
      'color': c.color,
      'phase': c.phase.name,
      'cycle': c.cycle.name,
      'default_unit': c.defaultUnit,
      'area_ha': c.areaHa,
      'live_plants': c.livePlants,
    }, onConflict: 'id');
  }

  Future<void> _upsertRemoteHarvest(SupabaseService supabase, Harvest h) async {
    final user = supabase.client.auth.currentUser;
    if (user == null) return;
    await supabase.client.from('harvests').upsert({
      'id': h.id,
      'user_id': user.id,
      'crop_id': h.cropId,
      'amount': h.amount,
      'unit': h.unit,
      'destination': h.destination.name,
      'harvest_date': h.date.toIso8601String().substring(0, 10),
    }, onConflict: 'id');
  }

  Future<void> _upsertRemoteSowing(SupabaseService supabase, Sowing s) async {
    final user = supabase.client.auth.currentUser;
    if (user == null) return;
    await supabase.client.from('sowings').upsert({
      'id': s.id,
      'user_id': user.id,
      'crop_id': s.cropId,
      'kind': s.kind.name,
      'plants': s.plants,
      'area_ha': s.areaHa,
      'lost_plants': s.lostPlants,
      'reason': s.reason,
      'sowing_date': s.date.toIso8601String().substring(0, 10),
    }, onConflict: 'id');
  }

  Future<void> _pullRemote(SupabaseService supabase) async {
    final user = supabase.client.auth.currentUser;
    if (user == null) return;

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

    final localIds = _txProvider.transactions.map((t) => t.id).toSet();
    final remoteMapped = (remoteTx as List)
        .map((e) => _remoteToTransaction(e as Map<String, dynamic>))
        .where((t) => !localIds.contains(t.id))
        .toList();

    if (remoteMapped.isNotEmpty) {
      _txProvider.mergeRemote(remoteMapped);
    }

    final cropLocalIds = _txProvider.crops.map((c) => c.id).toSet();
    final remoteCropMapped = (remoteCrops as List)
        .map((e) => _remoteToCrop(e as Map<String, dynamic>))
        .where((c) => !cropLocalIds.contains(c.id))
        .toList();
    if (remoteCropMapped.isNotEmpty) {
      _txProvider.mergeRemoteCrops(remoteCropMapped);
    }

    final harvestLocalIds = _txProvider.harvests.map((h) => h.id).toSet();
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
  }

  Transaction _remoteToTransaction(Map<String, dynamic> row) {
    return Transaction.fromJson({
      'id': row['id'] as String,
      'crop_id': row['crop_id'] as String?,
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
    });
  }

  Crop _remoteToCrop(Map<String, dynamic> row) {
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

  bool _isDefaultCrop(Crop c) =>
      c.id == 'cafe' || c.id == 'platano' || c.id == 'otro';
}
