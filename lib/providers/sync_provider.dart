import 'package:flutter/foundation.dart';

import '../models/crop.dart';
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
    });
  }

  Crop _remoteToCrop(Map<String, dynamic> row) {
    return Crop.fromJson({
      'id': row['id'] as String,
      'name': row['name'] as String,
      'icon': (row['icon'] as String?) ?? '🌱',
      'color': (row['color'] as String?) ?? '#2E7D32',
      'pending_sync': false,
    });
  }

  bool _isDefaultCrop(Crop c) => c.id == 'cafe' || c.id == 'platano';
}