import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/settings.dart';
import '../providers/transaction_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _farmName;
  String _currency = 'COP';

  static const _currencies = [
    ('COP', 'Peso colombiano (COP)'),
    ('USD', 'Dólar (USD)'),
    ('EUR', 'Euro (EUR)'),
  ];

  @override
  void initState() {
    super.initState();
    final s = context.read<TransactionProvider>().settings;
    _farmName = TextEditingController(text: s.farmName);
    _currency = s.currency;
  }

  @override
  void dispose() {
    _farmName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final tx = context.read<TransactionProvider>();
    await tx.updateSettings(FarmSettings(
      farmName: _farmName.text.trim().isEmpty
          ? tx.settings.farmName
          : _farmName.text.trim(),
      currency: _currency,
      locale: tx.settings.locale,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración guardada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _farmName,
            decoration: const InputDecoration(
              labelText: 'Nombre de la finca',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _currency,
            decoration: const InputDecoration(
              labelText: 'Moneda',
              border: OutlineInputBorder(),
            ),
            items: _currencies
                .map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2)))
                .toList(),
            onChanged: (v) => setState(() => _currency = v ?? 'COP'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}