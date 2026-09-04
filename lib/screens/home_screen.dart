import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../widgets/alerts_banner.dart';
import '../widgets/category_breakdown.dart';
import '../widgets/monthly_trend_chart.dart';
import '../widgets/summary_card.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mi Cafetal App',
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
              tooltip: 'Sincronizar',
              icon: const Icon(Icons.sync),
              onPressed: () => context.read<SyncProvider>().sync(),
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') context.read<AuthProvider>().signOut();
              if (v == 'report') Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportScreen()));
              if (v == 'settings') Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Text('Reporte')),
              PopupMenuItem(value: 'settings', child: Text('Configuración')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
            ],
          ),
        ],
      ),
      body: switch (_tab) {
        0 => _buildDashboard(),
        1 => const RegisterScreen(),
        _ => _buildDashboard(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Resumen',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Registrar',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final tx = context.watch<TransactionProvider>();
    final alerts = context.watch<AlertProvider>();
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    final monthExpenses = tx.totalExpenses(year: year, month: month);
    final monthIncomes = tx.totalIncomes(year: year, month: month);
    final yearExpenses = tx.totalExpenses(year: year);
    final yearIncomes = tx.totalIncomes(year: year);
    final balance = yearIncomes - yearExpenses;

    return RefreshIndicator(
      onRefresh: () => context.read<SyncProvider>().sync(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
Text(
                'Resumen',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              AlertsBanner(alerts: alerts.bySeverity),
              const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  label: 'Gastos del mes',
                  value: monthExpenses,
                  color: Colors.red,
                  icon: Icons.trending_down,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  label: 'Ingresos del mes',
                  value: monthIncomes,
                  color: Colors.green,
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SummaryCard(
            label: 'Balance del año $year',
            value: balance,
            color: balance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
            icon: balance >= 0 ? Icons.savings : Icons.warning_amber,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  MonthlyTrendChart(year: year),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CategoryBreakdown(year: year, month: month, type: TransactionType.expense),
            ),
          ),
          if (yearExpenses > 0 || yearIncomes > 0) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CategoryBreakdown(year: year, type: TransactionType.income),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.brown),
              title: const Text('Registrar un gasto o ingreso'),
              subtitle: const Text('Toma 10 segundos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _tab = 1),
            ),
          ),
        ],
      ),
    );
  }
}