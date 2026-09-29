import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'training_find_page.dart';

class UseTrainingFindPage extends StatefulWidget {
  const UseTrainingFindPage({super.key, required this.find});

  final Map<String, dynamic> find;

  @override
  State<UseTrainingFindPage> createState() => _UseTrainingFindPageState();
}

class _UseTrainingFindPageState extends State<UseTrainingFindPage> {
  final notes = TextEditingController();
  DateTime searchedAt = DateTime.now();
  bool busy = false;

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.find;
    final pos = LatLng((f['latitude'] as num).toDouble(), (f['longitude'] as num).toDouble());
    final buried = DateTime.tryParse(f['buried_at']?.toString() ?? '')?.toLocal();
    return Scaffold(
      appBar: AppBar(title: const Text('Bruk funn')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f['material_type'] ?? 'Treningsfunn', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Nedgravd: ${buried == null ? '-' : DateFormat('dd.MM.yyyy HH:mm').format(buried)}'),
                  if ((f['notes'] ?? '').toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(f['notes'].toString()),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: FlutterMap(
                options: MapOptions(initialCenter: pos, initialZoom: 17),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'no.afgruppen.afd.sokshund',
                  ),
                  MarkerLayer(markers: [Marker(point: pos, width: 44, height: 44, child: const Icon(Icons.location_on, size: 42))]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (f['photo_path'] != null) _StoredTrainingImage(path: f['photo_path'] as String),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.search),
            title: const Text('Når ble funnet søkt?'),
            subtitle: Text(DateFormat('dd.MM.yyyy HH:mm').format(searchedAt)),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: chooseDateTime,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: notes,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Notater fra treningen'),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: busy ? null : saveTraining,
            icon: const Icon(Icons.save_outlined),
            label: Text(busy ? 'LAGRER...' : 'LAGRE GJENNOMFØRT TRENING'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TrainingFindPage(existing: widget.find)),
                    );
                    if (mounted) Navigator.pop(context);
                  },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('REDIGER FUNN'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : deleteFind,
            icon: const Icon(Icons.delete_outline),
            label: const Text('SLETT FUNN'),
          ),
        ],
      ),
    );
  }

  Future<void> chooseDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: searchedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(searchedAt));
    if (t == null) return;
    setState(() => searchedAt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> saveTraining() async {
    setState(() => busy = true);
    try {
      final client = Supabase.instance.client;
      final f = widget.find;
      await client.from('sokshund_training_sessions').insert({
        'training_find_id': f['id'],
        'material_type': f['material_type'],
        'find_buried_at': f['buried_at'],
        'latitude': f['latitude'],
        'longitude': f['longitude'],
        'photo_path': f['photo_path'],
        'searched_at': searchedAt.toUtc().toIso8601String(),
        'notes': notes.text.trim(),
        'created_by': client.auth.currentUser!.id,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Treningen er lagret i historikken.')));
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> deleteFind() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Slette treningsfunn?'),
        content: const Text('Gjennomførte treninger som allerede ligger i historikken beholdes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Avbryt')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Slett')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => busy = true);
    try {
      final client = Supabase.instance.client;
      final id = widget.find['id'] as String;
      await client.from('sokshund_calendar_events').delete().eq('linked_table', 'sokshund_training_finds').eq('linked_id', id);
      await client.from('sokshund_training_finds').delete().eq('id', id);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class _StoredTrainingImage extends StatelessWidget {
  const _StoredTrainingImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
        future: Supabase.instance.client.storage.from('sokshund-training-media').createSignedUrl(path, 3600),
        builder: (_, s) {
          if (!s.hasData) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(s.data!, height: 260, width: double.infinity, fit: BoxFit.cover),
          );
        },
      );
}
