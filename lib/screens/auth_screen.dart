import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    if (_isRegister) {
      final result =
          await auth.signUp(_emailController.text, _passwordController.text);
      if (!mounted) return;
      if (result == SignUpResult.emailConfirmationRequired) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.authCreatedMsg),
            duration: const Duration(seconds: 6),
          ),
        );
        setState(() => _isRegister = false);
      } else if (result == SignUpResult.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? l10n.authCreateError)),
        );
      }
      return;
    }
    final ok = await auth.signIn(_emailController.text, _passwordController.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? l10n.authSignInError)),
      );
    }
  }

  Future<void> _enterGuestMode() async {
    final auth = context.read<AuthProvider>();
    final tx = context.read<TransactionProvider>();
    if (tx.transactions.isEmpty) {
      await _seedDemoData(tx);
    }
    await auth.signInAsGuest();
  }

  Future<void> _seedDemoData(TransactionProvider tx) async {
    final now = DateTime.now();
    final sales = [3200000, 2750000, 2900000, 2400000, 3100000, 2650000];
    for (var i = 0; i < sales.length; i++) {
      await tx.addTransaction(
        type: TransactionType.income,
        category: 'Venta de café',
        cropId: 'cafe',
        amount: sales[i].toDouble(),
        description: 'Venta de café ',
        date: DateTime(now.year, now.month - i, 1),
      );
    }
    await tx.addTransaction(
      type: TransactionType.income,
      category: 'Venta de plátano',
      cropId: 'platano',
      amount: 2500000,
      description: 'Venta de plátano',
      date: DateTime(now.year, now.month - 2, 1),
    );
    final exp = <List<Object?>>[
      [DateTime(now.year, now.month - 1, 1), 'Fertilizantes', 'cafe', 450000],
      [DateTime(now.year, now.month - 2, 1), 'Mano de obra', 'cafe', 700000],
      [DateTime(now.year, now.month - 2, 1), 'Mano de obra', 'cafe', 620000],
      [DateTime(now.year, now.month - 3, 1), 'Herramientas', 'platano', 300000],
      [DateTime(now.year, now.month - 4, 1), 'Transporte', null, 180000],
      [DateTime(now.year, now.month - 5, 1), 'Insumos', 'cafe', 350000],
    ];
    for (final e in exp) {
      await tx.addTransaction(
        type: TransactionType.expense,
        category: e[1] as String,
        cropId: e[2] as String?,
        amount: (e[3] as int).toDouble(),
        date: e[0] as DateTime,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.coffee,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        l10n.appTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isRegister
                            ? l10n.authSubtitleSignup
                            : l10n.authSubtitleWelcome,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n.authEmailLabel,
                          prefixIcon: const Icon(Icons.mail_outline),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => v != null && v.contains('@')
                            ? null
                            : l10n.authInvalidEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: l10n.authPasswordLabel,
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => v != null && v.length >= 6
                            ? null
                            : l10n.authPasswordTooShort,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          auth.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isRegister
                                ? l10n.authCreateAccount
                                : l10n.authSignIn),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: auth.isLoading
                            ? null
                            : () => setState(() => _isRegister = !_isRegister),
                        child: Text(_isRegister
                            ? l10n.authHaveAccount
                            : l10n.authNoAccount),
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: auth.isLoading ? null : _enterGuestMode,
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: Text(l10n.authGuest),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          l10n.authGuestHint,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}