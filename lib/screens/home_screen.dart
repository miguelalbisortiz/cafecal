import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/sync_provider.dart';
import '../utils/format.dart';

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
    // Primer sync al entrar (si hay conexión).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncProvider>().sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final sync = context.watch<SyncProvider>();

    final monthExpenses = tx.totalExpenses(month: DateTime.now().month, year: DateTime.now().year);
    final monthIncomes = tx.totalIncomes(month: DateTime.now().month, year: DateTime.now().year);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Cafetal', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Sincronizar',
            icon: sync.syncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: sync.syncing ? null : () => context.read<SyncProvider>().sync(),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') context.read<AuthProvider>().signOut();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
            ],
          ),
        ],
      ),
      body: switch (_tab) {
        0 => _buildDashboard(context, monthExpenses, monthIncomes),
        1 => _buildRegistro(context),
        _ => _buildDashboard(context, monthExpenses, monthIncomes),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Resumen'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Registrar'),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, double expenses, double incomes) {
    final tx = context.watch<TransactionProvider>();
    final now = DateTime.now();
    final yearExpenses = tx.totalExpenses(year: now.year);
    final yearIncomes = tx.totalIncomes(year: now.year);
    final balance = yearIncomes - yearExpenses;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Mi Cafetal', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Egresos del mes',
                value: expenses,
                color: Colors.red,
                icon: Icons.trending_down,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Ingresos del mes',
                value: incomes,
                color: Colors.green,
                icon: Icons.trending_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          label: 'Balance del año',
          value: balance,
          color: balance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
          icon: balance >= 0 ? Icons.savings : Icons.warning,
        ),
        const SizedBox(height: 12),
        Text('Registros ($yearExpenses egresos / $yearIncomes ingresos)'),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.add_circle, color: Colors.brown),
            title: const Text('Registrar un gasto o ingreso'),
            subtitle: const Text('Toma 10 segundos'),
            onTap: () => setState(() => _tab = 1),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistro(BuildContext context) {
    return const Center(
      child: Text('Formulario de registro — Fase 2'),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(formatMoney(context, value),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}