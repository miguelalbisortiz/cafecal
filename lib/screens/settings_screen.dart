import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/currencies.dart';
import '../models/settings.dart';
import '../providers/transaction_provider.dart';
import '../services/currency_rates_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _farmName;
  String _currency = 'COP';
  String _language = 'es';
  bool _converting = false;

  final _rates = CurrencyRatesService();

  @override
  void initState() {
    super.initState();
    final s = context.read<TransactionProvider>().settings;
    _farmName = TextEditingController(text: s.farmName);
    _currency = s.currency;
    _language = s.language;
  }

  @override
  void dispose() {
    _farmName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final tx = context.read<TransactionProvider>();
    final current = tx.settings.currency;
    final l10n = AppLocalizations.of(context)!;

    if (_currency != current) {
      setState(() => _converting = true);
      try {
        final factor =
            await _rates.fetchRate(current, _currency);
        await tx.convertAllToCurrency(_currency, factor);
      } catch (_) {
        if (!mounted) return;
        setState(() => _currency = current);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.rateErrorMsg),
          ),
        );
        return;
      } finally {
        if (mounted) setState(() => _converting = false);
      }
    }

    await tx.updateSettings(FarmSettings(
      farmName: _farmName.text.trim().isEmpty
          ? tx.settings.farmName
          : _farmName.text.trim(),
      currency: _currency,
      locale: tx.settings.locale,
      language: _language,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_currency != current
            ? l10n.currencyChangedMsg(_currency)
            : l10n.settingsSavedMsg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuSettings)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _farmName,
            decoration: InputDecoration(
              labelText: l10n.farmNameLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _currency,
            decoration: InputDecoration(
              labelText: l10n.currencyLabel,
              border: const OutlineInputBorder(),
            ),
            items: supportedCurrencies
                .map((c) => DropdownMenuItem(
                    value: c.code, child: Text('${c.name} (${c.code})')))
                .toList(),
            onChanged: (v) => setState(() => _currency = v ?? 'COP'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _language,
            decoration: InputDecoration(
              labelText: l10n.languageLabel,
              border: const OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'es', child: Text('Español')),
              DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: (v) => setState(() => _language = v ?? 'es'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _converting ? null : _save,
            icon: _converting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_converting ? l10n.converting : l10n.saveButton),
          ),
        ],
        ),
        ),
      ),
    );
  }
}