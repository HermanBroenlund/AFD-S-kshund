import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserAccessPage extends StatefulWidget {
  const UserAccessPage({super.key});
  @override
  State<UserAccessPage> createState() => _UserAccessPageState();
}

class _UserAccessPageState extends State<UserAccessPage> {
  bool busy = false;

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await Supabase.instance.client
        .from('profiles')
        .select('id,full_name,email,role,is_active,can_access_sokshund')
        .order('full_name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _invite() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Legg til bruker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Navn')),
            const SizedBox(height: 10),
            TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-post')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Avbryt')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Legg til')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => busy = true);
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'invite-user',
        body: {'name': name.text.trim(), 'email': email.text.trim(), 'app': 'sokshund'},
      );
      if (!mounted) return;
      final data = res.data;
      final msg = data is Map && data['error'] != null
          ? data['error'].toString()
          : 'Brukertilgang er oppdatert.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _setAccess(Map<String, dynamic> row, bool value) async {
    await Supabase.instance.client
        .from('profiles')
        .update({'can_access_sokshund': value, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', row['id']);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tilganger')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy ? null : _invite,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('NY BRUKER'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _load(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final row = rows[i];
              return SwitchListTile(
                title: Text((row['full_name'] ?? row['email'] ?? 'Bruker').toString()),
                subtitle: Text((row['email'] ?? '').toString()),
                value: row['can_access_sokshund'] == true,
                onChanged: row['is_active'] == true ? (v) => _setAccess(row, v) : null,
              );
            },
          );
        },
      ),
    );
  }
}
