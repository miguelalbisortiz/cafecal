import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/crop.dart';

/// Lo mínimo que la puerta pide para montar un cultivo: **su nombre**, el
/// icono con que lo va a reconocer y, si quiere, la fecha de plantación.
///
/// Nada de esto lo adivina la app — ni la especie, ni la fecha, ni un umbral
/// de producción. Es el mismo trato que E4 dio a la meta de rendimiento y E5
/// a la fecha de primera cosecha: **su dato, no una tabla ajena**.
class WelcomeCropDraft {
  final String name;
  final String icon;
  final DateTime? plantedAt;

  const WelcomeCropDraft({
    required this.name,
    required this.icon,
    this.plantedAt,
  });
}

/// Puerta de entrada: **"¿Qué cultivás?"**.
///
/// E6 · antes preguntaba en vocabulario de la app ("¿siembra o cultivo?"),
/// que un caficultor no tiene por qué entender. Ahora le pregunta en el suyo:
/// qué tiene plantado en la finca.
///
/// **No pre-lista especies.** Una lista con Café y Plátano asumiría la finca
/// de quien la abre: al que solo tiene plátano le sobraría Café, y peor aún,
/// podría tocarlo sin querer y quedarle un cultivo que no tiene. La lista es
/// **suya**: empieza vacía y la llena él.
///
/// **Se queda abierta hasta que él toca [Entrar]** (G3): quien tiene café,
/// plátano y mango los monta seguidos, sin que la app lo expulse al tablero
/// tras el primero.
///
/// Sin migración, sin tocar modelo ni sync: la puerta solo se muestra con la
/// finca vacía (`needsOnboarding`), así que los usuarios existentes no ven
/// nada distinto.
class WelcomeOnboardingCard extends StatelessWidget {
  /// Cultivos ya montados. Vacío cuando la puerta se abre la primera vez.
  final List<Crop> crops;

  /// E6 · crea el cultivo con lo mínimo y **se queda en la lista**.
  final ValueChanged<WelcomeCropDraft> onAdd;

  /// E6 · [Completar datos…]: crea el cultivo y le deja el editor abierto
  /// para seguir. Una sola escritura: si no toca nada más, no se guarda dos
  /// veces.
  final ValueChanged<WelcomeCropDraft> onComplete;

  /// E6 · corrige un cultivo ya listado (nombre, icono o fecha) sin pasar
  /// por el editor completo.
  final void Function(Crop crop, WelcomeCropDraft draft) onEdit;

  /// Salir de la puerta hacia la app.
  final VoidCallback onEnter;

  const WelcomeOnboardingCard({
    super.key,
    required this.crops,
    required this.onAdd,
    required this.onComplete,
    required this.onEdit,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final vacia = crops.isEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.welcomeTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.welcomeSubtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: scheme.onPrimaryContainer.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 16),
                // La lista es suya. Si todavía no hay nada se dice con
                // palabras suaves: no es un error, es el punto de partida.
                if (vacia)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surface.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.grass_outlined,
                            size: 20, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.welcomeEmptyList,
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // H10 (patrón de la casa): icono + texto, nunca solo color.
                  ...crops.map(
                    (c) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(c.icon)),
                        title: Text(
                          c.name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        // Icono además de texto: la fila es "esto ya está",
                        // no un estado que dependa de mirar un color.
                        trailing: Icon(Icons.check_circle_outline,
                            color: scheme.primary),
                        onTap: () => _openDraft(context, crop: c),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                _addTile(
                  context: context,
                  scheme: scheme,
                  l10n: l10n,
                  label:
                      vacia ? l10n.welcomeAddFirst : l10n.welcomeAddMore,
                  onTap: () => _openDraft(context),
                ),
                // La puerta no se cierra sola: quien agregó algo ya puede
                // entrar, y quien no, no tendría adónde ir.
                if (!vacia) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onEnter,
                    child: Text(l10n.welcomeEnter),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _addTile({
    required BuildContext context,
    required ColorScheme scheme,
    required AppLocalizations l10n,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.add, size: 24, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  /// Abre la ficha corta (G1): nombre + icono + fecha opcional.
  ///
  /// Nada se guarda sin avisar: si cancela, no se crea ni se cambia nada.
  Future<void> _openDraft(BuildContext context, {Crop? crop}) async {
    final r = await showDialog<_DraftResult>(
      context: context,
      builder: (_) => _ShortCropSheet(existing: crop),
    );
    if (r == null) return;
    if (crop != null) {
      onEdit(crop, r.draft);
    } else if (r.completo) {
      onComplete(r.draft);
    } else {
      onAdd(r.draft);
    }
  }
}

/// Lo que devuelve la ficha corta: el cultivo tal cual lo escribió, y si
/// pidió seguir completándolo o darse por satisfecho.
class _DraftResult {
  final WelcomeCropDraft draft;
  final bool completo;

  const _DraftResult(this.draft, {required this.completo});
}

/// Ficha corta: **lo mínimo para que exista el cultivo** y nada más.
///
/// La fecha es opcional y no insiste (G4). Quien quiera el cultivo completo
/// tiene su salida: **[Completar datos…]**.
class _ShortCropSheet extends StatefulWidget {
  /// Si viene, se corrige un cultivo de la lista en lugar de crear uno.
  final Crop? existing;

  const _ShortCropSheet({this.existing});

  @override
  State<_ShortCropSheet> createState() => _ShortCropSheetState();
}

class _ShortCropSheetState extends State<_ShortCropSheet> {
  /// Iconos de apariencia pura: ninguno trae datos, umbrales ni referencias.
  /// Sirven para que la lista se parezca a su finca y la reconozca de un
  /// vistazo — no son una tabla de especies.
  static const _icons = ['🌱', '☕', '🍌', '🌽', '🥭', '🥑', '🍋'];

  late final TextEditingController _name;
  late String _icon;
  DateTime? _plantedAt;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _icon = e?.icon ?? _icons.first;
    _plantedAt = e?.plantedAt;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _plantedAt ?? hoy,
      firstDate: DateTime(1950, 1, 1),
      lastDate: hoy,
    );
    if (!mounted || elegida == null) return;
    setState(() =>
        _plantedAt = DateTime(elegida.year, elegida.month, elegida.day));
  }

  void _submit({required bool completo}) {
    final l10n = AppLocalizations.of(context)!;
    final n = _name.text.trim();
    if (n.isEmpty) {
      setState(() => _error = l10n.cropNameRequired);
      return;
    }
    Navigator.pop(
      context,
      _DraftResult(
        WelcomeCropDraft(name: n, icon: _icon, plantedAt: _plantedAt),
        // Quien ya tiene el cultivo listado no necesita "completar datos":
        // lo corrige y ya.
        completo: completo && widget.existing == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final editando = widget.existing != null;

    return AlertDialog(
      title: Text(editando ? l10n.editCropTitle : l10n.welcomeTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                labelText: l10n.cropNameLabel,
                errorText: _error,
                prefixIcon: const Icon(Icons.grass_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.welcomeIconLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final i in _icons)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _icon = i),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == _icon
                            ? scheme.primaryContainer
                            : scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: i == _icon
                              ? scheme.primary
                              : scheme.outlineVariant,
                          width: i == _icon ? 2 : 1,
                        ),
                      ),
                      child: Text(i, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.plantedAtLabel,
                  helperText: l10n.helpPlantedAtShort,
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  suffixIcon: _plantedAt == null
                      ? null
                      : IconButton(
                          tooltip: l10n.plantedAtClear,
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () =>
                              setState(() => _plantedAt = null),
                        ),
                  border: const OutlineInputBorder(),
                ),
                child: Text(
                  _plantedAt == null
                      ? l10n.plantedAtEmpty
                      : MaterialLocalizations.of(context)
                          .formatShortDate(_plantedAt!),
                  style: _plantedAt == null
                      ? TextStyle(color: Theme.of(context).hintColor)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        // Salir hacia el editor completo. No se ofrece a quien ya tiene el
        // cultivo listado: ahí se corrige y ya.
        if (!editando)
          TextButton(
            onPressed: () => _submit(completo: true),
            child: Text(l10n.welcomeComplete),
          ),
        FilledButton(
          onPressed: () => _submit(completo: false),
          child: Text(editando ? l10n.edit : l10n.welcomeDone),
        ),
      ],
    );
  }
}
