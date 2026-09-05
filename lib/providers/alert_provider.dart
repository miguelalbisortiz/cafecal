import 'package:flutter/foundation.dart';

import '../l10n/strings.dart';
import '../models/farm_alert.dart';
import '../services/alert_service.dart';
import 'transaction_provider.dart';

class AlertProvider extends ChangeNotifier {
  final TransactionProvider _transactions;
  final AlertService _service;

  List<FarmAlert> _alerts = [];

  AlertProvider(this._transactions, {AlertService? service})
      : _service = service ?? const AlertService() {
    _recompute();
    _transactions.addListener(_recompute);
  }

  List<FarmAlert> get alerts => _alerts;

  List<FarmAlert> get bySeverity {
    final copy = [..._alerts]..sort(
        (a, b) => b.severity.index.compareTo(a.severity.index));
    return copy;
  }

  void _recompute() {
    _alerts = _service.evaluate(
      _transactions.transactions,
      _transactions.crops,
      stringsFor(_transactions.settings.language),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _transactions.removeListener(_recompute);
    super.dispose();
  }
}