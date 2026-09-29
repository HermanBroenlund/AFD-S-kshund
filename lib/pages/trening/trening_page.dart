import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'training_find_page.dart';
import 'use_training_find_page.dart';

class TreningPage extends StatefulWidget {
  const TreningPage({super.key});

  @override
  State<TreningPage> createState() => _TreningPageState();
}

class _TreningPageState extends State<TreningPage> {
  bool satellite = false;

  Future<List<Map<String, dynamic>>> load() => Supabase.instance.client
      .from('sokshund_training_finds')
      .select()
      .order('buried_at', ascending: false)
      .then((v) => List<Map<String, dynamic>>.from(v));

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
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrainingFindPage()),
            );
            setState(() {});
          },
          icon: const Icon(Icons.add_location_alt),
          label: const Text('Nytt treningsfunn'),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: load(),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snap.data ?? [];
            final center = rows.isNotEmpty
                ? LatLng(
                    (rows.first['latitude'] as num).toDouble(),
                    (rows.first['longitude'] as num).toDouble(),
                  )
                : const LatLng(59.9139, 10.7522);

            return Stack(
              children: [
                Positioned.fill(
                  child: FlutterMap(
                    key: ValueKey('training-map-${rows.length}-$satellite'),
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: rows.isNotEmpty ? 14 : 10,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: satellite
                            ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'no.afgruppen.afd.sokshund',
                      ),
                      MarkerLayer(
                        markers: rows.map((r) {
                          final date = DateTime.tryParse(r['buried_at']?.toString() ?? '');
                          final labelDate = date == null ? '-' : DateFormat('dd.MM.yy').format(date.toLocal());
                          final category = (r['material_type'] ?? 'Funn').toString().trim().isEmpty
                              ? 'Funn'
                              : r['material_type'].toString().trim();
                          return Marker(
                            point: LatLng(
                              (r['latitude'] as num).toDouble(),
                              (r['longitude'] as num).toDouble(),
                            ),
                            width: 112,
                            height: 72,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UseTrainingFindPage(find: r),
                                  ),
                                );
                                if (mounted) setState(() {});
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.94),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.black26),
                                      boxShadow: const [
                                        BoxShadow(blurRadius: 3, color: Colors.black26),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          category,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                                        ),
                                        Text(labelDate, style: const TextStyle(fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.location_on, size: 28),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(12),
                    elevation: 3,
                    child: IconButton(
                      tooltip: satellite ? 'Vanlig kart' : 'Flyfoto',
                      onPressed: () => setState(() => satellite = !satellite),
                      icon: Icon(satellite ? Icons.map_outlined : Icons.satellite_alt),
                    ),
                  ),
                ),
                if (rows.isEmpty)
                  const Positioned(
                    left: 20,
                    right: 20,
                    top: 24,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text(
                          'Ingen treningsfunn er registrert ennå. Trykk «Nytt treningsfunn» for å legge inn det første.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            );
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
    await client.from('sokshund_calendar_events').insert({
      'event_type': 'training',
      'title': title.text.trim(),
      'notes': notes.text.trim(),
      'starts_at': DateTime(date.year, date.month, date.day, 12).toIso8601String(),
      'created_by': client.auth.currentUser!.id,
    });
  }
}
