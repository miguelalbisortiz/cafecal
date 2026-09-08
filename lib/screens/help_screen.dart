import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/generated/app_localizations.dart';
import '../widgets/terminology_guide.dart';

/// Sección "Ayuda": la guía de primeros pasos dentro de la app (es/en),
/// con casos A/B, dónde entrar cada dato, unidades y glosario.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.helpTitle,
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(title: l10n.helpSectionGuide),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.helpIntro,
                        style: const TextStyle(
                            fontSize: 14, height: 1.4)),
                    const SizedBox(height: 8),
                    Text(
                      l10n.helpIntroPromesa,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: scheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Section(title: l10n.helpWhereTitle),
              _Card(
                child: _WhereTable(
                  rows: [
                    (l10n.helpRowOverview, l10n.tabOverview),
                    (l10n.helpRowCrops, l10n.menuCrops),
                    (l10n.helpRowSowings, l10n.menuSowings),
                    (l10n.helpRowHarvests, l10n.menuHarvests),
                    (l10n.helpRowExpenses,
                        '${l10n.tabRegister} (${l10n.expenseTypeLabel})'),
                    (l10n.helpRowIncome,
                        '${l10n.tabRegister} (${l10n.incomeTypeLabel})'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Section(title: l10n.helpFlowTitle),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.helpFlowIntro,
                        style: const TextStyle(fontSize: 13, height: 1.4)),
                    const SizedBox(height: 12),
                    _FlowSteps(items: [
                      (l10n.helpFlowStep1Title, l10n.helpFlowStep1Body,
                          Icons.grass_outlined),
                      (l10n.helpFlowStep2Title, l10n.helpFlowStep2Body,
                          Icons.spa_outlined),
                      (l10n.helpFlowStep3Title, l10n.helpFlowStep3Body,
                          Icons.trending_down_outlined),
                      (l10n.helpFlowStep4Title, l10n.helpFlowStep4Body,
                          Icons.inventory_2_outlined),
                      (l10n.helpFlowStep5Title, l10n.helpFlowStep5Body,
                          Icons.sell_outlined),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      l10n.helpFlowHint,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Section(title: l10n.helpCaseTitle),
              _Card(
                child: _StepsCard(
                  title: l10n.helpCaseATitle,
                  steps: [
                    l10n.helpCaseA1,
                    l10n.helpCaseA2,
                    l10n.helpCaseA3,
                    l10n.helpCaseA4,
                  ],
                  endNote: l10n.helpCaseAEnd,
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: _StepsCard(
                  title: l10n.helpCaseBTitle,
                  steps: [
                    l10n.helpCaseB1,
                    l10n.helpCaseB2,
                    l10n.helpCaseB3,
                    l10n.helpCaseB4,
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Section(title: l10n.helpUnitsTitle),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.helpUnitsBody,
                        style: const TextStyle(
                            fontSize: 13, height: 1.4)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        const _UnitChip('kg'),
                        _UnitChip(l10n.unitArroba),
                        _UnitChip(l10n.unitSaco),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Section(title: l10n.helpPerHaTitle),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.helpPerHaIntro,
                        style: const TextStyle(fontSize: 13, height: 1.4)),
                    const SizedBox(height: 12),
                    _DefList(items: [
                      (l10n.helpPerHaTitleYield, l10n.helpPerHaYield),
                      (l10n.helpPerHaTitleVentas, l10n.helpPerHaRevenue),
                      (l10n.helpPerHaTitleGastos, l10n.helpPerHaCost),
                      (l10n.helpPerHaTitleMargen, l10n.helpPerHaMargin),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      l10n.helpPerHaWhy,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Section(title: l10n.helpPaybackTitle),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.helpPaybackIntro,
                        style: const TextStyle(fontSize: 13, height: 1.4)),
                    const SizedBox(height: 12),
                    _DefList(items: [
                      (l10n.helpPaybackTitlePercent, l10n.helpPaybackPercent),
                      (l10n.helpPaybackTitleYears, l10n.helpPaybackYears),
                      (l10n.helpPaybackTitleNotLoss, l10n.helpPaybackNotLoss),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Section(title: l10n.helpGlossaryTitle),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.helpGlossaryBody,
                        style: const TextStyle(
                            fontSize: 13, height: 1.4)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => showTerminologyGuide(context),
                      icon: const Icon(Icons.school_outlined, size: 18),
                      label: Text(l10n.helpGlossaryFinance),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Section(title: l10n.helpCommonTitle),
              _Card(
                child: _DefList(items: [
                  (l10n.helpCommonAmount, l10n.helpCommonAmountFix),
                  (l10n.helpCommonAssigned, l10n.helpCommonAssignedFix),
                  (l10n.helpCommonType, l10n.helpCommonTypeFix),
                  (l10n.helpCommonCurrency, l10n.helpCommonCurrencyFix),
                  (l10n.helpCommonArea, l10n.helpCommonAreaFix),
                ]),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;

  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _WhereTable extends StatelessWidget {
  final List<(String, String)> rows;

  const _WhereTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final (situation, destination) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_right_alt,
                    size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(situation,
                          style: const TextStyle(
                              fontSize: 13, height: 1.3)),
                      Text(
                        destination,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DefList extends StatelessWidget {
  final List<(String, String)> items;

  const _DefList({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final (title, body) in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: scheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StepsCard extends StatelessWidget {
  final String title;
  final List<String> steps;
  final String? endNote;

  const _StepsCard({required this.title, required this.steps, this.endNote});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(steps[i],
                      style: const TextStyle(
                          fontSize: 13, height: 1.35)),
                ),
              ],
            ),
          ),
        if (endNote != null)
          Text(
            endNote!,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              fontStyle: FontStyle.italic,
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
      ],
    );
  }
}

class _UnitChip extends StatelessWidget {
  final String label;

  const _UnitChip(this.label);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _FlowSteps extends StatelessWidget {
  final List<(String, String, IconData)> items;

  const _FlowSteps({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: scheme.primaryContainer,
                child: Icon(
                  items[i].$3,
                  size: 14,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}. ${items[i].$1}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      items[i].$2,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: scheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (i < items.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Icon(
                Icons.arrow_downward,
                size: 16,
                color: scheme.primary.withOpacity(0.4),
              ),
            ),
        ],
      ],
    );
  }
}