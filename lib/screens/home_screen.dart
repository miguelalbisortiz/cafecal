import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../models/currencies.dart';
import '../services/next_step_service.dart';
import '../widgets/alerts_banner.dart';
import '../widgets/cash_box_card.dart';
import '../widgets/category_breakdown.dart';
import '../widgets/monthly_trend_chart.dart';
import '../widgets/next_step_card.dart';
import '../widgets/summary_card.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncProvider>().sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    final l10n = AppLocalizations.of(context)!;
    final tx = context.watch<TransactionProvider>();
    final onboarding = needsOnboarding(tx.crops, tx.sowings);

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
          body: onboarding
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

  /// Vista única del onboarding: las dos cards de primer paso y nada más.
  Widget _buildOnboarding() {
    return WelcomeOnboardingCard(
      onRegisterCrop: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CropsScreen()),
      ),
      onRegisterSowing: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SowingScreen()),
      ),
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
      case NextStepType.harvest:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HarvestScreen()),
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

    final monthExpenses = tx.totalExpenses(year: year, month: month);
    final monthIncomes = tx.totalIncomes(year: year, month: month);
    final monthBalance = monthIncomes - monthExpenses;
    final yearExpenses = tx.totalExpenses(year: year);
    final yearIncomes = tx.totalIncomes(year: year);
    final yearBalance = yearIncomes - yearExpenses;
    final monthLabel = '${l10n.monthFull[month - 1]} $year';

    // Monedas efectivas por período
    final monthCurrency = _effectiveCurrency(
        tx.sumByCurrency(TransactionType.income, year: year, month: month),
        tx.sumByCurrency(TransactionType.expense, year: year, month: month));
    final yearCurrency = _effectiveCurrency(
        tx.sumByCurrency(TransactionType.income, year: year),
        tx.sumByCurrency(TransactionType.expense, year: year));
    final hasMixedMonth = monthCurrency == null;
    final hasMixedYear = yearCurrency == null;
    final effectiveMonthCurrency = monthCurrency ?? tx.settings.currency;
    final effectiveYearCurrency = yearCurrency ?? tx.settings.currency;

    return RefreshIndicator(
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
          NextStepCard(
            onAction: _onNextStep,
            onOpenGuide: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            ),
          ),
          AlertsBanner(alerts: alerts.bySeverity),
          if (hasMixedMonth)
            _MixedCurrencyBanner(
              currencies: {
                ...tx.sumByCurrency(TransactionType.income, year: year, month: month).keys,
                ...tx.sumByCurrency(TransactionType.expense, year: year, month: month).keys,
              },
            ),
          _SectionHeader(title: l10n.sectionThisMonth),
          const SizedBox(height: 12),
          _threeCards(l10n, monthIncomes, monthExpenses, monthBalance,
              effectiveMonthCurrency, tx.settings.locale),
          // Caja menor del mes en curso (se oculta sin monto configurado).
          const CashBoxCard(),
          const SizedBox(height: 24),
          if (hasMixedYear)
            _MixedCurrencyBanner(
              currencies: {
                ...tx.sumByCurrency(TransactionType.income, year: year).keys,
                ...tx.sumByCurrency(TransactionType.expense, year: year).keys,
              },
            ),
          _SectionHeader(title: l10n.sectionInYear(year)),
          const SizedBox(height: 12),
          _threeCards(l10n, yearIncomes, yearExpenses, yearBalance,
              effectiveYearCurrency, tx.settings.locale),
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
        ),
        ),
      ),
    );
  }

  /// Si todas las transacciones del período son una moneda → esa moneda.
  /// Si hay mixtas → null (el caller usa settings.currency como fallback).
  String? _effectiveCurrency(
      Map<String, double> incomeByCur, Map<String, double> expenseByCur) {
    final all = {...incomeByCur.keys, ...expenseByCur.keys};
    if (all.length == 1) return all.first;
    if (all.isEmpty) return null;
    return null;
  }

  Widget _threeCards(AppLocalizations l10n, double incomes, double expenses,
      double balance, String currency, String locale) {
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

class _MixedCurrencyBanner extends StatelessWidget {
  final Set<String> currencies;

  const _MixedCurrencyBanner({required this.currencies});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final labels = currencies.map((c) {
      final info = currencyInfo(c);
      return '${info.symbol} ${info.code}';
    }).join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: scheme.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${l10n.currencyMixedHint(currencies.length)}: $labels',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}