import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainingHistoryDetailPage extends StatelessWidget {
  const TrainingHistoryDetailPage({super.key, required this.session});

  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context) {
    final lat = (session['latitude'] as num?)?.toDouble();
    final lng = (session['longitude'] as num?)?.toDouble();
    final searched = DateTime.tryParse(session['searched_at']?.toString() ?? '')?.toLocal();
    final buried = DateTime.tryParse(session['find_buried_at']?.toString() ?? '')?.toLocal();
    return Scaffold(
      appBar: AppBar(title: const Text('Gjennomført trening')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session['material_type'] ?? 'Trening', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _row('Søkt', searched == null ? '-' : DateFormat('dd.MM.yyyy HH:mm').format(searched)),
                  _row('Nedgravd', buried == null ? '-' : DateFormat('dd.MM.yyyy HH:mm').format(buried)),
                  _row('Notater', session['notes']),
                  if (lat != null && lng != null) _row('Koordinat', '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'),
                ],
              ),
            ),
          ),
          if (lat != null && lng != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: FlutterMap(
                  options: MapOptions(initialCenter: LatLng(lat, lng), initialZoom: 17),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'no.afgruppen.afd.sokshund'),
                    MarkerLayer(markers: [Marker(point: LatLng(lat, lng), width: 44, height: 44, child: const Icon(Icons.location_on, size: 42))]),
                  ],
                ),
              ),
            ),
          ],
          if (session['photo_path'] != null) ...[
            const SizedBox(height: 12),
            FutureBuilder<String>(
              future: Supabase.instance.client.storage.from('sokshund-training-media').createSignedUrl(session['photo_path'].toString(), 3600),
              builder: (_, s) {
                if (!s.hasData) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(s.data!, width: double.infinity, height: 280, fit: BoxFit.cover),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, Object? value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
            Expanded(child: Text(value == null || value.toString().trim().isEmpty ? '-' : value.toString())),
          ],
        ),
      );
}
