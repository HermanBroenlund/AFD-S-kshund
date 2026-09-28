import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'training_find_page.dart';

class TreningPage extends StatefulWidget {
  const TreningPage({super.key});
  @override
  State<TreningPage> createState() => _TreningPageState();
}

class _TreningPageState extends State<TreningPage> {
  Future<List<Map<String,dynamic>>> load() => Supabase.instance.client
      .from('training_finds').select().order('buried_at', ascending: false)
      .then((v) => List<Map<String,dynamic>>.from(v));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Trening'),
      actions: [
        IconButton(
          tooltip: 'Legg trening i kalender',
          onPressed: addTrainingEvent,
          icon: const Icon(Icons.event_available),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainingFindPage()));
        setState(() {});
      },
      icon: const Icon(Icons.add_location_alt),
      label: const Text('Nytt treningsfunn'),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: load(),
      builder: (_, snap) {
        final rows = snap.data ?? [];
        return Column(children: [
          Expanded(
            flex: 3,
            child: FlutterMap(
              options: const MapOptions(initialCenter: LatLng(59.9139, 10.7522), initialZoom: 10),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'no.afgruppen.afd.sokshund'),
                MarkerLayer(
                  markers: rows.map((r) => Marker(
                    point: LatLng((r['latitude'] as num).toDouble(), (r['longitude'] as num).toDouble()),
                    width: 42,
                    height: 42,
                    child: const Icon(Icons.location_on, size: 40),
                  )).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final r = rows[i];
                return ListTile(
                  title: Text(r['material_type'] ?? 'Treningsfunn'),
                  subtitle: Text((r['buried_at'] ?? '').toString()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => TrainingFindPage(existing: r)));
                    setState(() {});
                  },
                );
              },
            ),
          ),
        ]);
      },
    ),
  );

  Future<void> addTrainingEvent() async {
    final title = TextEditingController();
    final notes = TextEditingController();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Planlegg trening / gjøremål'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Tittel')),
            const SizedBox(height: 8),
            TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notat')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Avbryt')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lagre')),
        ],
      ),
    );
    if (save != true || title.text.trim().isEmpty) return;
    final client = Supabase.instance.client;
    await client.from('calendar_events').insert({
      'event_type': 'training',
      'title': title.text.trim(),
      'notes': notes.text.trim(),
      'starts_at': DateTime(date.year, date.month, date.day, 12).toIso8601String(),
      'created_by': client.auth.currentUser!.id,
    });
  }
}
