import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/currencies.dart';
import '../providers/transaction_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _farmName;
  late final TextEditingController _threshold;
  late final TextEditingController _cajaMenor;
  String _currency = 'COP';
  String _language = 'es';

  @override
  void initState() {
    super.initState();
    final s = context.read<TransactionProvider>().settings;
    _farmName = TextEditingController(text: s.farmName);
    _currency = s.currency;
    _language = s.language;
    _threshold = TextEditingController(
      text: s.lowPriceThresholdPerKg == null
          ? ''
          : (s.lowPriceThresholdPerKg! % 1 == 0
              ? s.lowPriceThresholdPerKg!.toInt().toString()
              : s.lowPriceThresholdPerKg.toString()),
    );
    _cajaMenor = TextEditingController(
      text: s.cajaMenorMensual == null
          ? ''
          : (s.cajaMenorMensual! % 1 == 0
              ? s.cajaMenorMensual!.toInt().toString()
              : s.cajaMenorMensual.toString()),
    );
  }

  @override
  void dispose() {
    _farmName.dispose();
    _threshold.dispose();
    _cajaMenor.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final tx = context.read<TransactionProvider>();
    final l10n = AppLocalizations.of(context)!;

    final thresholdText = _threshold.text.trim().replaceAll(',', '.');
    final threshold =
        thresholdText.isEmpty ? null : double.tryParse(thresholdText);
    final cajaText = _cajaMenor.text.trim().replaceAll(',', '.');
    final caja = cajaText.isEmpty ? null : double.tryParse(cajaText);

    await tx.updateSettings(tx.settings.copyWith(
      farmName: _farmName.text.trim().isEmpty
          ? tx.settings.farmName
          : _farmName.text.trim(),
      currency: _currency,
      language: _language,
      lowPriceThresholdPerKg: threshold,
      cajaMenorMensual: caja,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settingsSavedMsg),
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
              labelText: l10n.currencyDisplayLabel,
              helperText: l10n.currencyDisplayHelper,
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
          const SizedBox(height: 16),
          TextField(
            controller: _threshold,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.lowPriceThresholdLabel,
              helperText: l10n.lowPriceThresholdHelper,
              prefixIcon: const Icon(Icons.trending_down),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cajaMenor,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.cashBoxLabel,
              helperText: l10n.cashBoxHelp,
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: Text(l10n.saveButton),
          ),
        ],
        ),
        ),
      ),
    );
  }
}