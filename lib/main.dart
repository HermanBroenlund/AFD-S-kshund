import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'pages/auth/login_page.dart';
import 'pages/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isConfigured) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabasePublishableKey);
  }
  runApp(const AfdSokshundApp());
}

class AfdSokshundApp extends StatelessWidget {
  const AfdSokshundApp({super.key});
  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isConfigured) {
      return MaterialApp(theme: buildAfdTheme(), home: const _ConfigMissingPage());
    }
    final supabase = Supabase.instance.client;
    return MaterialApp(
      title: 'AFD Søkshund',
      debugShowCheckedModeBanner: false,
      theme: buildAfdTheme(),
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (_, __) => supabase.auth.currentSession == null ? const LoginPage() : const HomePage(),
      ),
    );
  }
}

class _ConfigMissingPage extends StatelessWidget {
  const _ConfigMissingPage();
  @override
  Widget build(BuildContext context) => const Scaffold(body: SafeArea(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Supabase er ikke konfigurert. Start appen med --dart-define=SUPABASE_URL=... og --dart-define=SUPABASE_PUBLISHABLE_KEY=...')))));
}
