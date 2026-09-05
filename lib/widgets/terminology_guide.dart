import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

class TerminologyEntry {
  final String term;
  final String definition;

  const TerminologyEntry(this.term, this.definition);
}

List<TerminologyEntry> buildGlossary(AppLocalizations l10n) {
  return [
    TerminologyEntry(
      l10n.glossaryRoiTerm,
      l10n.glossaryRoiDef,
    ),
    TerminologyEntry(
      l10n.glossaryBalanceTerm,
      l10n.glossaryBalanceDef,
    ),
    TerminologyEntry(
      l10n.glossaryMarginTerm,
      l10n.glossaryMarginDef,
    ),
    TerminologyEntry(
      l10n.glossaryRatioTerm,
      l10n.glossaryRatioDef,
    ),
    TerminologyEntry(
      l10n.glossaryAvgTerm,
      l10n.glossaryAvgDef,
    ),
  ];
}

/// Abre el glosario de términos financieros que usa la app.
/// [highlight] ordena primero el término relacionado con la sección que lo abrió.
Future<void> showTerminologyGuide(BuildContext context, {String? highlight}) {
  final l10n = AppLocalizations.of(context)!;
  final entries = [...buildGlossary(l10n)];
  if (highlight != null) {
    entries.sort((a, b) {
      final aMatch = a.term.toLowerCase().contains(highlight.toLowerCase());
      final bMatch = b.term.toLowerCase().contains(highlight.toLowerCase());
      return (bMatch ? 1 : 0) - (aMatch ? 1 : 0);
    });
  }

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.school_outlined),
          const SizedBox(width: 10),
          Expanded(child: Text(l10n.glossaryTitle)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 20),
          itemBuilder: (context, index) {
            final e = entries[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.term,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  e.definition,
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.glossaryGotIt),
        ),
      ],
    ),
  );
}