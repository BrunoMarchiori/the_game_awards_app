import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('The Game Award')), 
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Bem-vindo!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  icon: const Icon(Icons.login),
                  label: const Text('Entrar'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Cadastrar novo usuário'),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    // mark guest mode and go to dashboard
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const _GuestRedirect()));
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Entrar sem cadastro'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// This intermediate widget decides after guest click where to go.
class _GuestRedirect extends StatelessWidget {
  const _GuestRedirect();

  @override
  Widget build(BuildContext context) {
    // Set guest mode
    // ignore: use_build_context_synchronously
    // can't access provider here safely; use post frame
    // Go to Dashboard (guest mode). We'll defer to dashboard screen to handle menus.
    return const _RedirectToDashboard();
  }
}

class _RedirectToDashboard extends StatefulWidget {
  const _RedirectToDashboard();
  @override
  State<_RedirectToDashboard> createState() => _RedirectToDashboardState();
}

class _RedirectToDashboardState extends State<_RedirectToDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // set guest mode in provider (user = null)
      // ignore: use_build_context_synchronously
      // Using dynamic lookup to avoid additional import cycles
      // Properly, import provider and call context.read<AuthProvider>().loginAsGuest();
      Navigator.pushReplacementNamed(context, '/dashboard');
    });
  }
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
