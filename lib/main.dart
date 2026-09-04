import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/alert_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/local_store.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.instance.init();
  final store = await LocalStore.create();
  runApp(MiCafetalApp(store: store));
}

class MiCafetalApp extends StatelessWidget {
  final LocalStore store;

  const MiCafetalApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final txProvider = TransactionProvider(store);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(store)),
        ChangeNotifierProvider(create: (_) => txProvider),
        ChangeNotifierProvider(
          create: (_) => SyncProvider(txProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => AlertProvider(txProvider),
        ),
      ],
      child: MaterialApp(
        title: 'Mi Cafetal',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(ThemeMode.light),
        darkTheme: _buildTheme(ThemeMode.dark),
        home: const AuthGate(),
      ),
    );
  }

  ThemeData _buildTheme(ThemeMode mode) {
    final scheme =
        (mode == ThemeMode.dark ? Brightness.dark : Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6D4C41),
        brightness: scheme,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isLoggedIn ? const HomeScreen() : const AuthScreen();
  }
}