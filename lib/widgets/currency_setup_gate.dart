import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/currencies.dart';
import '../providers/transaction_provider.dart';

/// La pregunta que va **antes de todo dato**: ¿en qué moneda trabajás?
///
/// Aparece una sola vez y solo en una cuenta que todavía no tiene ni cultivo
/// ni registro. No es un desplegable escondido dentro del formulario de
/// registro: la moneda no se puede cambiar después, así que merece un momento
/// propio y deliberado — no una casilla que se llena sin mirar a medio
/// formulario.
///
/// Si se cierra sin elegir, no se registra nada. El valor por defecto (COP)
/// sería irreversible y dejaría a un productor boliviano anotando en pesos
/// para siempre; por eso la elección es obligatoria, no opcional.
class CurrencySetupGate extends StatefulWidget {
  /// Se llama al confirmar, después de guardar la moneda en Ajustes.
  final VoidCallback onChosen;

  const CurrencySetupGate({super.key, required this.onChosen});

  @override
  State<CurrencySetupGate> createState() => _CurrencySetupGateState();
}

class _CurrencySetupGateState extends State<CurrencySetupGate> {
  late String _currency;

  @override
  void initState() {
    super.initState();
    _currency = context.read<TransactionProvider>().settings.currency;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final info = currencyInfo(_currency);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.all(24),
          shrinkWrap: true,
          children: [
            const SizedBox(height: 32),
            Text('☕', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 20),
            Text(
              l10n.currencyGateTitle,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(l10n.currencyGateBody),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _currency,
              // `isExpanded` + elipsis: los nombres de moneda no desbordan en
              // pantallas angostas ni en el viewport de pruebas. En el
              // celular se ven enteros.
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.currencyLabel,
                border: const OutlineInputBorder(),
              ),
              // Sin `prefixIcon`: el desplegable vive en una columna estrecha
              // (480 px) y el ícono le comía 60 px que los nombres de moneda
              // necesitan para no desbordar.
              items: supportedCurrencies
                  .map((c) => DropdownMenuItem(
                        value: c.code,
                        child: Text(
                          '${c.symbol} ${c.name} (${c.code})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v ?? 'COP'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _confirm,
              child: Text(
                l10n.currencyGateCta('${info.name} (${info.code})'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.currencyGateRequired,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Guarda y cierra. `updateSettings` primero pisa el estado local y luego
  /// guarda en el almacén local, así que no depende de la red: sin conexión
  /// la elección también queda puesta.
  Future<void> _confirm() async {
    final tx = context.read<TransactionProvider>();
    await tx.updateSettings(tx.settings.copyWith(currency: _currency));
    if (!mounted) return;
    widget.onChosen();
  }
}
