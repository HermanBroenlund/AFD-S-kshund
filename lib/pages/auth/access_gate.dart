import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/home_page.dart';

class AccessGate extends StatelessWidget {
  const AccessGate({super.key});

  Future<Map<String, dynamic>?> _loadProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;
    return await client
        .from('profiles')
        .select('id,full_name,email,role,is_active,can_access_sokshund')
        .eq('id', user.id)
        .maybeSingle();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final profile = snapshot.data;
        final allowed = profile != null &&
            profile['is_active'] == true &&
            profile['can_access_sokshund'] == true;
        if (allowed) return HomePage(profile: profile);

        return Scaffold(
          appBar: AppBar(title: const Text('AFD Søkshund')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 54),
                  const SizedBox(height: 16),
                  const Text(
                    'Du er logget inn, men har ikke tilgang til AFD Søkshund.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () async => Supabase.instance.client.auth.signOut(),
                    child: const Text('LOGG UT'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
