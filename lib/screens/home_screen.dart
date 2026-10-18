import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../models/crop.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../services/currency_conversion.dart';
import '../services/currency_totals.dart';
import '../services/next_step_service.dart';
import '../services/period_delta.dart';
import '../utils/format.dart';
import '../widgets/alerts_banner.dart';
import '../widgets/cash_box_card.dart';
import '../widgets/category_breakdown.dart';
import '../widgets/crop_editor_dialog.dart';
import '../widgets/currency_breakdown.dart';
import '../widgets/currency_setup_gate.dart';
import '../widgets/monthly_trend_chart.dart';
import '../widgets/next_step_card.dart';
import '../widgets/period_totals.dart';
import '../widgets/summary_card.dart';
import '../widgets/summary_empty_card.dart';
import '../widgets/welcome_onboarding_card.dart';
import 'movements_screen.dart';
import 'register_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'sowing_screen.dart';
import 'harvest_screen.dart';
import 'crops_screen.dart';
import 'workers_screen.dart';
import 'help_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  TransactionType? _registerInitialType;

  /// E6 · la puerta se queda abierta hasta que él toca [Entrar] (G3).
  ///
  /// Sin esto, agregar el primer cultivo la cerraría sola y lo expulsaría al
  /// tablero: quien tiene café, plátano y mango no podría montarlos seguidos.
  ///
  /// Solo tiene sentido para quien **entró con la finca vacía**; el usuario
  /// existente ni ve la puerta, así que esto no lo toca.
  bool _gatePending = true;

  /// Se captura una sola vez, al primer build: si la finca estaba vacía al
  /// abrir la app. Sin esto, el primer cultivo creado durante la sesión
  /// (que ya levanta `needsOnboarding`) cerraría la puerta por atrás.
  bool? _enteredEmpty;

  /// Moneda única · la pregunta se queda abierta hasta que él elige.
  ///
  /// Se cierra solo con la elección, no con el primer registro: si se
  /// cerrara al guardar un movimiento, un segundo dispositivo volvería a
  /// preguntar ya sin dato que ofrecer.
  bool _currencyChosen = false;

  /// Último error mostrado en pantalla: evita repetir el SnackBar en cada
  /// notifyListeners del mismo fallo (los iconos se redibujan muchas veces).
  String? _shownError;

  late final SyncProvider _sync;

  @override
  void initState() {
    super.initState();
    _sync = context.read<SyncProvider>();
    _sync.addListener(_watchSync);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sync.sync();
    });
  }

  @override
  void dispose() {
    // El provider es global: hay que soltar el listener al salir.
    _sync.removeListener(_watchSync);
    super.dispose();
  }

  /// Muestra el error de sync apenas termina la pasada (una sola vez).
  void _watchSync() {
    if (_sync.syncing || !_sync.hasError) return;
    final error = _sync.lastSyncError ?? '';
    if (error == _shownError) return;
    _shownError = error;
    _showSyncError(error);
  }

  void _showSyncError(String? detail) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            detail == null || detail.isEmpty
                ? l10n.syncFailed
                : '${l10n.syncFailed}: $detail',
          ),
          action: SnackBarAction(
            label: l10n.syncRetry,
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: () => context.read<SyncProvider>().sync(),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    final l10n = AppLocalizations.of(context)!;
    final tx = context.watch<TransactionProvider>();
    // E6 · la puerta (G3): se queda hasta que él toca [Entrar], pero solo si
    // la finca estaba vacía al abrir la app. Quien ya cultivaba no la ve.
    _enteredEmpty ??= needsOnboarding(tx.crops, tx.sowings);
    final onboarding = _gatePending && _enteredEmpty == true;

    // Moneda única · la pregunta solo existe en una cuenta que todavía no
    // tiene ni cultivo ni registro. Quien ya trabaja no la ve nunca, y
    // nadie que ya tiene datos se le vuelve a preguntar.
    final needsCurrency = !_currencyChosen &&
        tx.crops.isEmpty &&
        !tx.transactions.any((t) => !t.deleted);

    // Al recuperarse de un error, se olvida para que el siguiente vuelva a avisar.
    if (!sync.hasError && _shownError != null) _shownError = null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              l10n.appTitleFull,
              style:
                  GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
            ),
            actions: [
              if (sync.syncing)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (sync.hasError)
                IconButton(
                  tooltip: l10n.syncErrorTooltip,
                  icon: Icon(
                    Icons.cloud_off,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _showSyncError(sync.lastSyncError),
                )
              else
                IconButton(
                  tooltip: l10n.syncTooltip,
                  icon: const Icon(Icons.sync),
                  onPressed: () => context.read<SyncProvider>().sync(),
                ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'logout') context.read<AuthProvider>().signOut();
                  if (v == 'report') Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportScreen()));
                  if (v == 'settings') Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  if (v == 'sowings') Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SowingScreen()));
                  if (v == 'harvests') Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HarvestScreen()));
                  if (v == 'crops') Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CropsScreen()));
                  if (v == 'workers') Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorkersScreen()));
                  if (v == 'help') Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpScreen()));
                },
                itemBuilder: (_) => [
                  if (!onboarding) ...[
                    PopupMenuItem(
                      value: 'report',
                      child: ListTile(
                        leading: const Icon(Icons.bar_chart_outlined),
                        title: Text(l10n.menuReport),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'crops',
                      child: ListTile(
                        leading: const Icon(Icons.grass_outlined),
                        title: Text(l10n.menuCrops),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'sowings',
                      child: ListTile(
                        leading: const Icon(Icons.eco_outlined),
                        title: Text(l10n.menuSowings),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    // Cosechas oculta del menú (2026-09-24): el pequeño
                    // agricultor produce y vende sin almacenar, no usa esta
                    // pantalla. El resto de la feature sigue intacta (reportes,
                    // alertas, sync). Para restaurar: descomentar el bloque.
                    // PopupMenuItem(
                    //   value: 'harvests',
                    //   child: ListTile(
                    //     leading: const Icon(Icons.agriculture_outlined),
                    //     title: Text(l10n.menuHarvests),
                    //     dense: true,
                    //     contentPadding: EdgeInsets.zero,
                    //   ),
                    // ),
                    PopupMenuItem(
                      value: 'workers',
                      child: ListTile(
                        leading: const Icon(Icons.people_outline),
                        title: Text(l10n.menuWorkers),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                  ],
                  PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: Text(l10n.menuSettings),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'help',
                    child: ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: Text(l10n.menuHelp),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: const Icon(Icons.logout_outlined),
                      title: Text(l10n.menuLogout),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: needsCurrency
              ? CurrencySetupGate(
                  onChosen: () => setState(() => _currencyChosen = true),
                )
              : onboarding
              ? _buildOnboarding()
              : wide
                  ? Row(
                      children: [
                        NavigationRail(
                          selectedIndex: _tab,
                          onDestinationSelected: (i) =>
                              setState(() => _tab = i),
                          labelType: NavigationRailLabelType.all,
                          destinations: [
                            NavigationRailDestination(
                              icon: const Icon(Icons.dashboard_outlined),
                              selectedIcon: const Icon(Icons.dashboard),
                              label: Text(l10n.tabOverview),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.add_circle_outline),
                              selectedIcon: const Icon(Icons.add_circle),
                              label: Text(l10n.tabRegister),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.history_outlined),
                              selectedIcon: const Icon(Icons.history),
                              label: Text(l10n.tabHistory),
                            ),
                          ],
                        ),
                        const VerticalDivider(width: 1, thickness: 1),
                        Expanded(child: _body()),
                      ],
                    )
                  : _body(),
          bottomNavigationBar: (wide || onboarding)
              ? null
              : NavigationBar(
                  selectedIndex: _tab,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.dashboard_outlined),
                      selectedIcon: const Icon(Icons.dashboard),
                      label: l10n.tabOverview,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.add_circle_outline),
                      selectedIcon: const Icon(Icons.add_circle),
                      label: l10n.tabRegister,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.history_outlined),
                      selectedIcon: const Icon(Icons.history),
                      label: l10n.tabHistory,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _body() => switch (_tab) {
        0 => _buildDashboard(),
        1 => RegisterScreen(initialType: _registerInitialType),
        2 => const MovementsScreen(),
        _ => _buildDashboard(),
      };

  /// E6 · la puerta **"¿Qué cultivás?"**.
  ///
  /// No empuja al tablero: quien agrega un cultivo vuelve a la lista para
  /// seguir agregando (G3). Recién cuando toca [Entrar] se cierra.
  ///
  /// [Completar datos…] crea el cultivo con lo mínimo y le abre el editor
  /// completo. Como el cultivo ya existe, lo que cambie ahí es **una sola
  /// escritura** — no el addCrop + updateCrop que C5 ya había corregido.
  Widget _buildOnboarding() {
    final tx = context.read<TransactionProvider>();

    Future<Crop> crear(WelcomeCropDraft d) => tx.addCrop(
          d.name,
          icon: d.icon,
          plantedAt: d.plantedAt,
          // E6 · la misma regla que el editor, en un solo lugar. H2: aquí no
          // manda ningún umbral de años — la puerta no le pregunta por la
          // primera cosecha, así que nace en "Sin dar" y la primera
          // cosecha registrada es la que lo promueve.
          phase:
              deducePhaseOnCreate(cycle: CropCycle.perenne),
          cycle: CropCycle.perenne,
        );

    return WelcomeOnboardingCard(
      crops: tx.crops,
      onAdd: (d) => crear(d),
      onComplete: (d) async {
        final crop = await crear(d);
        if (!mounted) return;
        final form = await showDialog<CropFormData>(
          context: context,
          builder: (_) => CropEditorDialog(
            crop: crop,
            existingNames: tx.crops.map((c) => c.name).toList(),
            // E6-a: el cultivo acaba de nacer en la puerta; el editor es
            // para completarlo, no para editarlo.
            recienCreado: true,
          ),
        );
        if (form == null || !mounted) return;
        await tx.updateCrop(crop.copyWith(
          name: form.name,
          icon: form.icon,
          color: form.color,
          phase: form.phase,
          cycle: form.cycle,
          defaultUnit: form.defaultUnit,
          areaHa: form.areaHa,
          livePlants: form.livePlants,
          establishmentCost: form.establishmentCost,
          currency: form.currency,
          plantedAt: form.plantedAt,
          expectedYieldPerHa: form.expectedYieldPerHa,
          primerCosechaEsperada: form.primerCosechaEsperada,
        ));
      },
      onEdit: (crop, d) => tx.updateCrop(crop.copyWith(
        name: d.name,
        icon: d.icon,
        plantedAt: d.plantedAt,
      )),
      onEnter: () => setState(() => _gatePending = false),
    );
  }

  /// Abre la pestaña Registrar, prefijando Gasto/Ingreso si el próximo paso lo
  /// requiere. El prefijo se descarta tras montarse la pantalla para no
  /// condicionar las siguientes visitas.
  void _goRegister([TransactionType? initialType]) {
    setState(() {
      _registerInitialType = initialType;
      _tab = 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _registerInitialType = null);
    });
  }

  void _onNextStep(NextStepType type) {
    switch (type) {
      case NextStepType.crop:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CropsScreen()),
        );
        break;
      case NextStepType.sowing:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SowingScreen()),
        );
        break;
      case NextStepType.expenses:
        _goRegister(TransactionType.expense);
        break;
      case NextStepType.sale:
        _goRegister(TransactionType.income);
        break;
    }
  }

  Widget _buildDashboard() {
    final tx = context.watch<TransactionProvider>();
    final alerts = context.watch<AlertProvider>();
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    final monthLabel = '${l10n.monthFull[month - 1]} $year';

    // A — totales por moneda: nunca se suman monedas distintas.
    final monthTotals =
        PeriodCurrencyTotals.fromRecords(tx.where(year: year, month: month));
    final yearTotals = PeriodCurrencyTotals.fromRecords(tx.where(year: year));

    // A2 · sin ni un movimiento registrado no se pintan tres "$0": eso
    // presentaría como *medido* algo que es *no registrado*.
    final hasAnyRecord = tx.transactions.any((t) => !t.deleted);

    // B · el mes en curso contra el mismo tramo de días del mes anterior.
    final comparison = hasAnyRecord
        ? _monthComparison(tx, monthTotals, now, l10n, tx.settings.numberLocale)
        : null;

    // B — la conversión llega sola, sin bloquear la pantalla: mientras no
    // haya tasa (o si falta alguna) se muestran los totales por moneda.
    return PeriodTotalsBuilder(
      totals: monthTotals,
      targetCurrency: tx.settings.currency,
      builder: (context, monthConverted) => PeriodTotalsBuilder(
        totals: yearTotals,
        targetCurrency: tx.settings.currency,
        builder: (context, yearConverted) => RefreshIndicator(
          onRefresh: () => context.read<SyncProvider>().sync(),
          child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.tabOverview,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _PeriodChip(label: monthLabel),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasAnyRecord) ...[
            // A2 · guía primero: sin datos, lo que sirve es decir qué hacer.
            NextStepCard(
              onAction: _onNextStep,
              onOpenGuide: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              ),
            ),
            AlertsBanner(alerts: alerts.bySeverity),
            _SectionHeader(title: l10n.sectionThisMonth),
            const SizedBox(height: 12),
            SummaryEmptyCard(onRegister: _goRegister),
          ] else ...[
            // A1 · lo primero que se ve es la plata: el objetivo de la app
            // no puede quedar debajo del pliegue de la pantalla.
            _SectionHeader(title: l10n.sectionThisMonth),
            const SizedBox(height: 12),
            _totalsBlock(l10n, tx, monthTotals, monthConverted,
                comparison: comparison),
            // Caja del mes en curso: un solo pote para jornales y gastos
            // chicos (se oculta sin aporte configurado).
            const CashBoxCard(),
            const SizedBox(height: 16),
            // Avisar que algo necesita atención pesa más que sugerir qué
            // registrar: por eso las alertas van antes de la guía.
            AlertsBanner(alerts: alerts.bySeverity),
            NextStepCard(
              onAction: _onNextStep,
              onOpenGuide: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: l10n.sectionInYear(year)),
          const SizedBox(height: 12),
          _totalsBlock(l10n, tx, yearTotals, yearConverted),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MonthlyTrendChart(year: year),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CategoryBreakdown(
                year: year,
                month: month,
                type: TransactionType.expense,
                periodLabel: monthLabel,
                onAddTap: _goRegister,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CategoryBreakdown(
                year: year,
                month: month,
                type: TransactionType.income,
                periodLabel: monthLabel,
                onAddTap: _goRegister,
              ),
            ),
          ),
          ],
          ],
        ),
        ),
      ),
    ),
        ),
    );
  }

  /// Resumen de un período: las tres tarjetas de siempre cuando hay una
  /// sola moneda (o cuando ya se pudo convertir), o los totales de cada
  /// moneda por separado cuando **no** hay tasa disponible.
  ///
  /// [comparison] solo llega para el mes en curso: lleva el delta contra el
  /// mes anterior y el pie que explica con qué se compara. El bloque del año
  /// no lo recibe (comparar un año por correr contra el anterior entero
  /// tendría el mismo sesgo que B1).
  Widget _totalsBlock(AppLocalizations l10n, TransactionProvider tx,
      PeriodCurrencyTotals totals, ConvertedPeriodTotals? converted,
      {MonthComparison? comparison}) {
    if (totals.isMixed && converted == null) {
      // A3 · moneda mixta sin tasa: se listan los totales de cada moneda y
      // no se pinta ninguna comparación — cruzaría meses en monedas
      // distintas y el porcentaje sería falso.
      return CurrencyBreakdown(
        incomes: totals.incomes,
        expenses: totals.expenses,
        l10n: l10n,
        locale: tx.settings.numberLocale,
      );
    }

    final incomes = converted?.incomes ??
        totals.incomes.values.fold<double>(0, (a, b) => a + b);
    final expenses = converted?.expenses ??
        totals.expenses.values.fold<double>(0, (a, b) => a + b);
    final currency = converted?.currency ??
        (totals.currencies.length == 1
            ? totals.currencies.first
            : tx.settings.currency);
    final balance = incomes - expenses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _threeCards(l10n, incomes, expenses, balance, currency,
            tx.settings.numberLocale,
            comparison: comparison),
        if (comparison != null) ...[
          const SizedBox(height: 6),
          _comparisonNote(comparison),
        ],
        if (converted != null) ...[
          const SizedBox(height: 8),
          _convertedNote(l10n, tx, converted),
        ],
      ],
    );
  }

  /// Pie de la fila de tarjetas: dice con qué se compara, para que
  /// "bajaron 18%" no se lea como si el mes anterior estuviera entero.
  Widget _comparisonNote(MonthComparison c) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.compare_arrows, size: 13, color: onSurface.withOpacity(0.6)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            c.note,
            style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.6)),
          ),
        ),
      ],
    );
  }

  /// B · comparación del mes en curso contra el mes anterior **recortado al
  /// mismo tramo de días** (B1). Devuelve `null` cuando no hay con qué
  /// comparar: entonces no se pinta ninguna línea.
  MonthComparison? _monthComparison(TransactionProvider tx,
      PeriodCurrencyTotals current, DateTime now, AppLocalizations l10n,
      String locale) {
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    final previous = PeriodCurrencyTotals.fromRecords(
        sameDayWindow(tx.where(year: prevYear, month: prevMonth), now));
    return buildMonthComparison(
      current: current,
      previous: previous,
      locale: locale,
      monthName: l10n.monthFull[prevMonth - 1],
      l10n: l10n,
    );
  }

  /// Aviso de que el total va al cambio de hoy y de que cada movimiento
  /// sigue guardado en la moneda en que se registró.
  Widget _convertedNote(
      AppLocalizations l10n, TransactionProvider tx, ConvertedPeriodTotals c) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.currencyConvertedTotal(
              c.currency,
              formatAmount(c.result,
                  currency: c.currency, locale: tx.settings.numberLocale),
            ),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.currencyRateNote,
            style: TextStyle(fontSize: 11, color: scheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }

  Widget _threeCards(AppLocalizations l10n, double incomes, double expenses,
      double balance, String currency, String locale,
      {MonthComparison? comparison}) {
    final scheme = Theme.of(context).colorScheme;
    final noData = incomes == 0 && expenses == 0;
    final positive = scheme.primary;
    final negative = scheme.error;
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            label: l10n.incomeLabel,
            value: incomes,
            color: positive,
            icon: Icons.trending_up,
            currency: currency,
            locale: locale,
            deltaText: comparison?.incomeText,
            deltaSignal: comparison?.incomeSignal,
            comparisonLabel: comparison?.vsLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SummaryCard(
            label: l10n.expensesLabel,
            value: expenses,
            color: negative,
            icon: Icons.trending_down,
            currency: currency,
            locale: locale,
            deltaText: comparison?.expenseText,
            deltaSignal: comparison?.expenseSignal,
            comparisonLabel: comparison?.vsLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SummaryCard(
            label: l10n.resultLabel,
            value: balance,
            color: noData
                ? Colors.grey
                : balance >= 0
                    ? positive
                    : negative,
            highlighted: !noData,
            icon: noData
                ? Icons.remove
                : balance >= 0
                    ? Icons.savings
                    : Icons.warning_amber,
            currency: currency,
            locale: locale,
            deltaText: comparison?.resultText,
            deltaSignal: comparison?.resultSignal,
            comparisonLabel: comparison?.vsLabel,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;

  const _PeriodChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
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
