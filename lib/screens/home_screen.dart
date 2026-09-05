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
import '../widgets/alerts_banner.dart';
import '../widgets/category_breakdown.dart';
import '../widgets/monthly_trend_chart.dart';
import '../widgets/summary_card.dart';
import 'movements_screen.dart';
import 'register_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

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
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'report', child: Text(l10n.menuReport)),
                  PopupMenuItem(value: 'settings', child: Text(l10n.menuSettings)),
                  const PopupMenuDivider(),
                  PopupMenuItem(value: 'logout', child: Text(l10n.menuLogout)),
                ],
              ),
            ],
          ),
          body: wide
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
          bottomNavigationBar: wide
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
        1 => const RegisterScreen(),
        2 => const MovementsScreen(),
        _ => _buildDashboard(),
      };

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

    void goRegister() => setState(() => _tab = 1);

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
          AlertsBanner(alerts: alerts.bySeverity),
          _SectionHeader(title: l10n.sectionThisMonth),
          const SizedBox(height: 12),
          _threeCards(l10n, monthIncomes, monthExpenses, monthBalance),
          const SizedBox(height: 24),
          _SectionHeader(title: l10n.sectionInYear(year)),
          const SizedBox(height: 12),
          _threeCards(l10n, yearIncomes, yearExpenses, yearBalance),
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
                onAddTap: goRegister,
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
                onAddTap: goRegister,
              ),
            ),
          ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _threeCards(
      AppLocalizations l10n, double incomes, double expenses, double balance) {
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
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SummaryCard(
            label: l10n.expensesLabel,
            value: expenses,
            color: negative,
            icon: Icons.trending_down,
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