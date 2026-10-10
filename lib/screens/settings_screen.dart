import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/currencies.dart';
import '../providers/transaction_provider.dart';
import '../services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _farmName;
  late final TextEditingController _threshold;
  late final TextEditingController _cajaMenor;
  late final TextEditingController _sacoKg;
  String _currency = 'COP';
  String _language = 'es';
  bool _exportingBackup = false;
  bool _restoringBackup = false;

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
    // A2: siempre hay un número (70 es la norma), así que el campo nunca
    // arranca vacío — es un "ajústalo", no un "opcional".
    _sacoKg = TextEditingController(text: _num(s.sacoKg));
  }

  /// Formatea sin el ".0" que sueltan los doubles, y con coma si el
  /// separador decimal del aparato es el de siempre.
  static String _num(double v) => v % 1 == 0 ? v.toInt().toString() : '$v';

  @override
  void dispose() {
    _farmName.dispose();
    _threshold.dispose();
    _cajaMenor.dispose();
    _sacoKg.dispose();
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
    // A2: no se puede dejar sin número. Campo vacío o ilegible = no se
    // cambia (se conserva el que ya había) — nunca un 0 que partiría todos
    // los kg a la mitad.
    final sacoText = _sacoKg.text.trim().replaceAll(',', '.');
    final saco = (double.tryParse(sacoText) ?? 0) > 0
        ? double.parse(sacoText)
        : null;

    await tx.updateSettings(tx.settings.copyWith(
      farmName: _farmName.text.trim().isEmpty
          ? tx.settings.farmName
          : _farmName.text.trim(),
      currency: _currency,
      language: _language,
      lowPriceThresholdPerKg: threshold,
      cajaMenorMensual: caja,
      sacoKg: saco,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settingsSavedMsg),
      ),
    );
  }

  // ---- Respaldo (P1) ----

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Genera el JSON del respaldo y lo comparte para que el productor lo
  /// guarde donde quiera (misma mecánica que exportar PDF/Excel).
  Future<void> _exportBackup() async {
    final l10n = AppLocalizations.of(context)!;
    final tx = context.read<TransactionProvider>();
    setState(() => _exportingBackup = true);
    try {
      final json = tx.exportBackupJson();
      final now = DateTime.now();
      final fileName =
          'cafecal-respaldo-${now.toIso8601String().substring(0, 10)}.json';
      final result = await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(json)),
            mimeType: 'application/json',
            name: fileName,
          ),
        ],
        subject: l10n.backupShareSubject,
      ));
      if (!mounted) return;
      if (result.status != ShareResultStatus.dismissed) {
        _snack(l10n.backupExportDoneMsg);
      }
    } catch (e) {
      _snack(l10n.exportError('$e'));
    } finally {
      if (mounted) setState(() => _exportingBackup = false);
    }
  }

  /// Elige un archivo .json, lo valida y, si el productor confirma, lo
  /// fusiona con lo que ya tiene. Un archivo inválido o cancelado no rompe
  /// nada: solo se avisa con un mensaje claro.
  Future<void> _restoreBackup() async {
    final l10n = AppLocalizations.of(context)!;
    final tx = context.read<TransactionProvider>();
    setState(() => _restoringBackup = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      // Cerró el selector sin elegir: no hay nada que restaurar.
      if (picked == null || picked.files.isEmpty) return;

      final bytes = picked.files.first.bytes;
      if (bytes == null) {
        _snack(l10n.backupInvalidFile);
        return;
      }

      final BackupPayload payload;
      try {
        payload = decodeBackup(utf8.decode(bytes));
      } on BackupFormatException catch (e) {
        _snack(switch (e.kind) {
          BackupErrorKind.versionNoSoportada => l10n.backupUnsupportedVersion,
          BackupErrorKind.formatoDesconocido => l10n.backupUnknownFormat,
          _ => l10n.backupInvalidFile,
        });
        return;
      } on FormatException {
        // Bytes que ni siquiera son texto UTF-8.
        _snack(l10n.backupInvalidFile);
        return;
      }

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.backupConfirmTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.backupConfirmMessage([
                l10n.backupCountCrops(payload.conteo.cultivos),
                l10n.backupCountSowings(payload.conteo.siembras),
                l10n.backupCountHarvests(payload.conteo.cosechas),
                l10n.backupCountEmployees(payload.conteo.empleados),
                l10n.movementsCount(payload.conteo.movimientos),
              ].join(', '))),
              if (tx.backupFromOtherAccount(payload)) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.backupAccountDiffers,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.backupConfirmAccept),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      final summary = await tx.importBackup(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.backupSummary(
                  summary.agregados.total, summary.omitidos.total)),
              if (summary.huerfanos > 0)
                Text(l10n.backupOrphans(summary.huerfanos)),
            ],
          ),
        ),
      );
    } catch (_) {
      _snack(l10n.backupRestoreError);
    } finally {
      if (mounted) setState(() => _restoringBackup = false);
    }
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
            controller: _sacoKg,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.sacoKgLabel,
              helperText: l10n.sacoKgHelper,
              prefixIcon: const Icon(Icons.shopping_bag_outlined),
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
          const Divider(height: 32),
          Text(
            l10n.backupSectionTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.backupSectionSubtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _exportingBackup ? null : _exportBackup,
            icon: const Icon(Icons.save_alt),
            label: Text(l10n.backupExport),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _restoringBackup ? null : _restoreBackup,
            icon: const Icon(Icons.settings_backup_restore),
            label: Text(l10n.backupRestore),
          ),
        ],
        ),
        ),
      ),
    );
  }
}