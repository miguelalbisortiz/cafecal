import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Diálogo para crear un cultivo nuevo. Devuelve el nombre si se creó
/// (o el existente que ya coincida) y `null` si se canceló.
class NewCropDialog extends StatefulWidget {
  final List<String> existingNames;

  const NewCropDialog({super.key, required this.existingNames});

  @override
  State<NewCropDialog> createState() => _NewCropDialogState();
}

class _NewCropDialogState extends State<NewCropDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final n = _controller.text.trim();
    if (n.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.cropNameRequired);
      return;
    }
    final dup = widget.existingNames
        .where((e) => e.toLowerCase() == n.toLowerCase())
        .toList();
    if (dup.isNotEmpty) {
      Navigator.pop(context, dup.first);
      return;
    }
    Navigator.pop(context, n);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.newCropDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.cropNameLabel,
          errorText: _error,
          prefixIcon: const Icon(Icons.grass_outlined),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.add)),
      ],
    );
  }
}