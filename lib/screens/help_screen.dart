import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../providers/transaction_provider.dart';
import '../widgets/terminology_guide.dart';

/// Casos de finca que ofrece la Ayuda. El identificador se guarda tal cual en
/// la preferencia `help_case`, así que no se renombra.
class HelpCase {
  static const selling = 'selling';
  static const starting = 'starting';
  static const renew = 'renew';
  static const workers = 'workers';

  static const all = [selling, starting, renew, workers];

  static bool isValid(String? value) => all.contains(value);
}

/// Sección "Ayuda": enseña a operar la app según cómo esté la finca hoy.
///
/// Tres pestañas — Empezar, Rutina y Entender — con cuatro casos de ejemplo.
/// No lee los datos de la finca ni muestra cifras propias: los ejemplos usan
/// números redondos y «tu moneda», para servir en cualquier país.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final GlobalKey _detailKey = GlobalKey();
  String? _selected;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    final saved = context.read<TransactionProvider>().helpCase;
    _selected = HelpCase.isValid(saved) ? saved : null;
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _selectCase(String value) {
    setState(() => _selected = value);
    context.read<TransactionProvider>().setHelpCase(value);
    // El camino se abre debajo de las tarjetas: se lleva la vista hasta él para
    // que tocar una tarjeta se sienta como abrir algo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final detail = _detailKey.currentContext;
      if (detail == null) return;
      Scrollable.ensureVisible(
        detail,
        duration: const Duration(milliseconds: 250),
        alignment: 0.05,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.helpTitle,
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.helpTabStart),
            Tab(text: l10n.helpTabRoutine),
            Tab(text: l10n.helpTabUnderstand),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: TabBarView(
            controller: _tabs,
            children: [
              _startTab(context, l10n),
              _routineTab(context, l10n),
              _understandTab(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Empezar ----

  Widget _startTab(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final cases = _cases(l10n);
    final selected = _selected == null ? null : cases[_selected];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.helpStartTitle,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.helpStartSubtitle,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 20),
        _SectionTitle(text: l10n.helpStartQuestion),
        const SizedBox(height: 8),
        for (final content in cases.values) ...[
          _CaseTile(
            content: content,
            selected: content.id == _selected,
            onTap: () => _selectCase(content.id),
          ),
          const SizedBox(height: 8),
        ],
        if (selected != null) ...[
          const SizedBox(height: 12),
          KeyedSubtree(key: _detailKey, child: _CaseDetail(content: selected)),
        ],
        const SizedBox(height: 16),
        Text(
          l10n.helpStartNote,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.4,
            fontStyle: FontStyle.italic,
            color: scheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Map<String, _CaseContent> _cases(AppLocalizations l10n) {
    return {
      HelpCase.selling: _CaseContent(
        id: HelpCase.selling,
        icon: Icons.sell_outlined,
        title: l10n.helpCaseSellingTitle,
        description: l10n.helpCaseSellingDesc,
        intro: l10n.helpSellingIntro,
        steps: [
          l10n.helpSellingStep1,
          l10n.helpSellingStep2,
          l10n.helpSellingStep3,
          l10n.helpSellingStep4,
        ],
        exampleTitle: l10n.helpSellingExampleTitle,
        exampleRows: [
          l10n.helpSellingExample1,
          l10n.helpSellingExample2,
          l10n.helpSellingExample3,
        ],
        notes: [l10n.helpSellingClosing, l10n.helpSellingMulti],
      ),
      HelpCase.starting: _CaseContent(
        id: HelpCase.starting,
        icon: Icons.spa_outlined,
        title: l10n.helpCaseStartingTitle,
        description: l10n.helpCaseStartingDesc,
        intro: l10n.helpStartingIntro,
        steps: [
          l10n.helpStartingStep1,
          l10n.helpStartingStep2,
          l10n.helpStartingStep3,
          l10n.helpStartingStep4,
        ],
        exampleTitle: l10n.helpStartingExampleTitle,
        exampleRows: [
          l10n.helpStartingExample1,
          l10n.helpStartingExample2,
          l10n.helpStartingExample3,
          l10n.helpStartingExample4,
        ],
        notes: const [],
      ),
      HelpCase.renew: _CaseContent(
        id: HelpCase.renew,
        icon: Icons.eco_outlined,
        title: l10n.helpCaseRenewTitle,
        description: l10n.helpCaseRenewDesc,
        intro: l10n.helpRenewIntro,
        steps: [
          l10n.helpRenewStep1,
          l10n.helpRenewStep2,
          l10n.helpRenewStep3,
        ],
        exampleTitle: l10n.helpRenewExampleTitle,
        exampleRows: [
          l10n.helpRenewExample1,
          l10n.helpRenewExample2,
          l10n.helpRenewExample3,
        ],
        notes: const [],
      ),
      HelpCase.workers: _CaseContent(
        id: HelpCase.workers,
        icon: Icons.groups_outlined,
        title: l10n.helpCaseWorkersTitle,
        description: l10n.helpCaseWorkersDesc,
        intro: l10n.helpWorkersCaseIntro,
        steps: [
          l10n.helpWorkersStep1,
          l10n.helpWorkersStep2,
          l10n.helpWorkersStep3,
          l10n.helpWorkersStep4,
        ],
        exampleTitle: l10n.helpWorkersExampleTitle,
        exampleRows: [
          l10n.helpWorkersExample1,
          l10n.helpWorkersExample2,
          l10n.helpWorkersExample3,
        ],
        notes: const [],
      ),
    };
  }

  // ---- Rutina ----

  Widget _routineTab(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final rows = [
      (
        l10n.helpRoutineRow1When,
        l10n.helpRoutineRow1What,
        l10n.helpRoutineRow1Where
      ),
      (
        l10n.helpRoutineRow2When,
        l10n.helpRoutineRow2What,
        l10n.helpRoutineRow2Where
      ),
      (
        l10n.helpRoutineRow3When,
        l10n.helpRoutineRow3What,
        l10n.helpRoutineRow3Where
      ),
      (
        l10n.helpRoutineRow4When,
        l10n.helpRoutineRow4What,
        l10n.helpRoutineRow4Where
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.helpRoutineTitle,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.helpRoutineIntro,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoutineRow(
                when: l10n.helpRoutineWhen,
                what: l10n.helpRoutineWhat,
                where: l10n.helpRoutineWhere,
                header: true,
                scheme: scheme,
              ),
              const Divider(height: 18),
              for (var i = 0; i < rows.length; i++) ...[
                _RoutineRow(
                  when: rows[i].$1,
                  what: rows[i].$2,
                  where: rows[i].$3,
                  header: false,
                  scheme: scheme,
                ),
                if (i < rows.length - 1) const Divider(height: 18),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13.5, height: 1.4),
                  children: [
                    TextSpan(
                      text: '${l10n.helpRoutineGoldenTitle} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: l10n.helpRoutineGolden),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.helpRoutineTwiceTitle,
                style:
                    const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _Bullet(text: l10n.helpRoutineTwice1),
              _Bullet(text: l10n.helpRoutineTwice2),
              _Bullet(text: l10n.helpRoutineTwice3),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ---- Entender ----

  Widget _understandTab(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final terms = <(String, String)>[
      (l10n.glossaryIncomeTerm, l10n.glossaryIncomeDef),
      (l10n.glossaryExpenseTerm, l10n.glossaryExpenseDef),
      (l10n.glossaryBalanceTerm, l10n.glossaryBalanceDef),
      (l10n.glossaryCostPerKgTerm, l10n.glossaryCostPerKgDef),
      (l10n.glossaryMarginTerm, l10n.glossaryMarginDef),
      (l10n.glossaryYieldAreaTerm, l10n.glossaryYieldAreaDef),
      (l10n.glossaryYieldPlantTerm, l10n.glossaryYieldPlantDef),
      (l10n.glossaryRoiTerm, l10n.glossaryRoiDef),
      (l10n.glossaryPaybackTerm, l10n.glossaryPaybackDef),
      (l10n.glossaryCashBoxTerm, l10n.glossaryCashBoxDef),
    ];
    final troubles = <(String, String)>[
      (l10n.helpTrouble1Title, l10n.helpTrouble1Body),
      (l10n.helpTrouble2Title, l10n.helpTrouble2Body),
      (l10n.helpTrouble3Title, l10n.helpTrouble3Body),
      (l10n.helpTrouble4Title, l10n.helpTrouble4Body),
      (l10n.helpTrouble5Title, l10n.helpTrouble5Body),
      (l10n.helpTrouble6Title, l10n.helpTrouble6Body),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.helpDictTitle,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.helpDictIntro,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < terms.length; i++) ...[
                _DefRow(term: terms[i].$1, definition: terms[i].$2),
                if (i < terms.length - 1) const Divider(height: 18),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.helpUnitsTitle,
                style:
                    const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.helpUnitsBody,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.helpDictCurrencyTitle,
                style:
                    const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.helpDictCurrencyBody,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SectionTitle(text: l10n.helpTroubleTitle),
        const SizedBox(height: 8),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < troubles.length; i++) ...[
                _DefRow(
                  term: troubles[i].$1,
                  definition: troubles[i].$2,
                ),
                if (i < troubles.length - 1) const Divider(height: 18),
              ],
              const SizedBox(height: 12),
              Text(
                l10n.helpTroubleFooter,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => showTerminologyGuide(context),
          icon: const Icon(Icons.school_outlined, size: 18),
          label: Text(l10n.helpDictSeeAll),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Contenido de un caso: pasos numerados y un ejemplo con números redondos.
class _CaseContent {
  final String id;
  final IconData icon;
  final String title;
  final String description;
  final String intro;
  final List<String> steps;
  final String exampleTitle;
  final List<String> exampleRows;
  final List<String> notes;

  const _CaseContent({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.intro,
    required this.steps,
    required this.exampleTitle,
    required this.exampleRows,
    required this.notes,
  });
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
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
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

/// Tarjeta de un caso en la portada. La elegida se marca con borde y check.
class _CaseTile extends StatelessWidget {
  final _CaseContent content;
  final bool selected;
  final VoidCallback onTap;

  const _CaseTile({
    required this.content,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                content.icon,
                size: 22,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content.description,
                      style: const TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle, size: 20, color: scheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// El camino del caso elegido: intro, pasos numerados y ejemplo.
class _CaseDetail extends StatelessWidget {
  final _CaseContent content;

  const _CaseDetail({required this.content});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.intro,
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < content.steps.length; i++)
            _NumberedStep(index: i + 1, text: content.steps[i]),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.exampleTitle,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                for (final row in content.exampleRows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      row,
                      style: const TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  l10n.helpExampleNote,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          for (final note in content.notes) ...[
            const SizedBox(height: 10),
            Text(
              note,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: scheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NumberedStep extends StatelessWidget {
  final int index;
  final String text;

  const _NumberedStep({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: scheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  final String when;
  final String what;
  final String where;
  final bool header;
  final ColorScheme scheme;

  const _RoutineRow({
    required this.when,
    required this.what,
    required this.where,
    required this.header,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: header ? 12.5 : 13,
      height: 1.35,
      fontWeight: header ? FontWeight.bold : FontWeight.w600,
      color: header ? scheme.onSurface.withOpacity(0.7) : null,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: Text(when, style: style)),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Text(
            what,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              fontWeight: header ? FontWeight.bold : FontWeight.normal,
              color: header ? scheme.onSurface.withOpacity(0.7) : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Text(
            where,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              fontWeight: header ? FontWeight.bold : FontWeight.w600,
              color: header ? scheme.onSurface.withOpacity(0.7) : scheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: scheme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DefRow extends StatelessWidget {
  final String term;
  final String definition;

  const _DefRow({required this.term, required this.definition});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          term,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          definition,
          style: const TextStyle(fontSize: 13, height: 1.35),
        ),
      ],
    );
  }
}
