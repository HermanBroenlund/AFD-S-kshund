import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/location_service.dart';

class TrainingFindPage extends StatefulWidget {
  const TrainingFindPage({super.key, this.existing});

  final Map<String, dynamic>? existing;

  @override
  State<TrainingFindPage> createState() => _TrainingFindPageState();
}

class _TrainingFindPageState extends State<TrainingFindPage> {
  final type = TextEditingController();
  final notes = TextEditingController();
  XFile? photo;
  LatLng? selectedPosition;
  DateTime buriedAt = DateTime.now();
  bool satellite = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    type.text = widget.existing?['material_type'] ?? '';
    notes.text = widget.existing?['notes'] ?? '';
    if (widget.existing != null) {
      selectedPosition = LatLng(
        (widget.existing!['latitude'] as num).toDouble(),
        (widget.existing!['longitude'] as num).toDouble(),
      );
      buriedAt = DateTime.tryParse(widget.existing!['buried_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    type.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.existing == null ? 'Nytt treningsfunn' : 'Rediger treningsfunn')),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
            TextField(controller: type, decoration: const InputDecoration(labelText: 'Type / kategori')),
            const SizedBox(height: 10),
            TextField(controller: notes, maxLines: 4, decoration: const InputDecoration(labelText: 'Notat om nedgravingen')),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Dato og tid for nedgraving'),
              subtitle: Text(DateFormat('dd.MM.yyyy HH:mm').format(buriedAt)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: chooseDateTime,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: usePhonePosition,
                    icon: const Icon(Icons.my_location),
                    label: const Text('BRUK MOBILPOSISJON'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Eller trykk direkte i kartet for å velge posisjon:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 330,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: selectedPosition ?? const LatLng(59.9139, 10.7522),
                        initialZoom: selectedPosition == null ? 10 : 16,
                        onTap: (_, p) => setState(() => selectedPosition = p),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: satellite
                              ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'no.afgruppen.afd.sokshund',
                        ),
                        if (selectedPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: selectedPosition!,
                                width: 44,
                                height: 44,
                                child: const Icon(Icons.location_on, size: 42),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(10),
                        elevation: 2,
                        child: IconButton(
                          tooltip: satellite ? 'Vanlig kart' : 'Flyfoto',
                          onPressed: () => setState(() => satellite = !satellite),
                          icon: Icon(satellite ? Icons.map_outlined : Icons.satellite_alt),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (selectedPosition != null)
              Text(
                'Valgt posisjon: ${selectedPosition!.latitude.toStringAsFixed(6)}, ${selectedPosition!.longitude.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () async {
                final p = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 88);
                if (p != null) setState(() => photo = p);
              },
              icon: const Icon(Icons.camera_alt),
              label: Text(photo == null ? 'TA BILDE AV NEDGRAVING' : 'NYTT BILDE'),
            ),
            const SizedBox(height: 10),
            if (photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(photo!.path), height: 220, fit: BoxFit.cover),
              )
            else if (widget.existing?['photo_path'] != null)
              _StoredImage(path: widget.existing!['photo_path'] as String),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: busy ? null : save,
              child: Text(busy ? 'LAGRER...' : 'LAGRE'),
            ),
            if (widget.existing != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: busy ? null : delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('SLETT FUNN'),
              ),
            ],
            ],
          ),
        ),
      );

  Future<void> usePhonePosition() async {
    try {
      final p = await LocationService().current();
      setState(() => selectedPosition = LatLng(p.latitude, p.longitude));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kunne ikke hente posisjon: $e')));
    }
  }

  Future<void> chooseDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: buriedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(buriedAt));
    if (t == null) return;
    setState(() => buriedAt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> save() async {
    if (type.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Legg inn type / kategori.')));
      return;
    }
    if (selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Velg posisjon i kartet eller bruk mobilens posisjon.')));
      return;
    }
    setState(() => busy = true);
    try {
      final client = Supabase.instance.client;
      String? photoPath = widget.existing?['photo_path'] as String?;
      if (photo != null) {
        photoPath = 'training/${DateTime.now().millisecondsSinceEpoch}.${photo!.name.split('.').last.toLowerCase()}';
        await client.storage.from('sokshund-training-media').uploadBinary(
              photoPath,
              await photo!.readAsBytes(),
              fileOptions: const FileOptions(upsert: false),
            );
      }
      final values = {
        'material_type': type.text.trim(),
        'notes': notes.text.trim(),
        'latitude': selectedPosition!.latitude,
        'longitude': selectedPosition!.longitude,
        'photo_path': photoPath,
        'buried_at': buriedAt.toUtc().toIso8601String(),
        'created_by': client.auth.currentUser!.id,
        'updated_at': DateTime.now().toIso8601String(),
      };
      String id;
      if (widget.existing == null) {
        final row = await client.from('sokshund_training_finds').insert(values).select('id').single();
        id = row['id'] as String;
        await client.from('sokshund_calendar_events').insert({
          'event_type': 'training_find',
          'title': 'Treningsfunn: ${type.text.trim()}',
          'starts_at': values['buried_at'],
          'linked_table': 'sokshund_training_finds',
          'linked_id': id,
          'created_by': client.auth.currentUser!.id,
        });
      } else {
        id = widget.existing!['id'] as String;
        await client.from('sokshund_training_finds').update(values).eq('id', id);
        await client
            .from('sokshund_calendar_events')
            .update({
              'title': 'Treningsfunn: ${type.text.trim()}',
              'starts_at': values['buried_at'],
            })
            .eq('linked_table', 'sokshund_training_finds')
            .eq('linked_id', id)
            .eq('event_type', 'training_find');
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Slette treningsfunn?'),
        content: const Text('Historikk fra treninger som allerede er gjennomført beholdes.'),
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
      final id = widget.existing!['id'] as String;
      await client
          .from('sokshund_calendar_events')
          .delete()
          .eq('linked_table', 'sokshund_training_finds')
          .eq('linked_id', id);
      await client.from('sokshund_training_finds').delete().eq('id', id);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class _StoredImage extends StatelessWidget {
  const _StoredImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
        future: Supabase.instance.client.storage.from('sokshund-training-media').createSignedUrl(path, 3600),
        builder: (_, s) {
          if (!s.hasData) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(s.data!, height: 220, fit: BoxFit.cover),
          );
        },
      );
}
