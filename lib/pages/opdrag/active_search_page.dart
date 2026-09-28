import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/search_models.dart';
import '../../repositories/search_repository.dart';
import '../../services/location_service.dart';
import 'finding_page.dart';

class ActiveSearchPage extends StatefulWidget {
  const ActiveSearchPage({super.key, required this.draft, required this.weather});
  final SearchDraft draft;
  final WeatherSnapshot weather;
  @override
  State<ActiveSearchPage> createState() => _ActiveSearchPageState();
}

class _ActiveSearchPageState extends State<ActiveSearchPage> {
  final repo = SearchRepository(Supabase.instance.client);
  final location = LocationService();
  String? searchId;
  bool paused = false;
  bool busy = true;
  Position? current;
  final track = <LatLng>[];
  StreamSubscription<Position>? sub;

  @override
  void initState() { super.initState(); _start(); }
  Future<void> _start() async {
    try {
      searchId = await repo.startSearch(draft: widget.draft, weather: widget.weather);
      sub = location.stream().listen((p) async {
        current = p;
        if (!paused && searchId != null) {
          setState(() => track.add(LatLng(p.latitude, p.longitude)));
          await repo.addTrackPoint(searchId!, lat: p.latitude, lng: p.longitude, accuracy: p.accuracy, source: 'handler');
        } else if (mounted) { setState(() {}); }
      });
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  void dispose() { sub?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final boundary = widget.draft.area.length >= 3 ? [...widget.draft.area, widget.draft.area.first] : widget.draft.area;
    return Scaffold(
      appBar: AppBar(title: const Text('Aktivt søk')),
      body: busy ? const Center(child: CircularProgressIndicator()) : Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Wrap(spacing: 14, runSpacing: 4, children: [
            Text('${widget.weather.temperatureC?.toStringAsFixed(1) ?? '-'} °C'),
            Text('Vind ${widget.weather.windSpeedMs?.toStringAsFixed(1) ?? '-'} m/s'),
            Text('RH ${widget.weather.humidityPercent?.toStringAsFixed(0) ?? '-'} %'),
          ]),
        ),
        Expanded(child: FlutterMap(
          options: MapOptions(initialCenter: widget.draft.area.first, initialZoom: 15),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'no.afgruppen.afd.sokshund'),
            PolylineLayer(polylines: [
              Polyline(points: boundary, strokeWidth: 4),
              if (track.length >= 2) Polyline(points: track, strokeWidth: 4),
            ]),
            if (current != null) MarkerLayer(markers: [Marker(point: LatLng(current!.latitude, current!.longitude), width: 44, height: 44, child: const Icon(Icons.person_pin_circle, size: 42))]),
          ],
        )),
        SafeArea(top: false, child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: togglePause, icon: Icon(paused ? Icons.play_arrow : Icons.pause), label: Text(paused ? 'FORTSETT' : 'PAUSE'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(onPressed: takeAreaPhoto, icon: const Icon(Icons.camera_alt), label: const Text('TA BILDE'))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: searchId == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => FindingPage(searchId: searchId!))), icon: const Icon(Icons.add_location_alt), label: const Text('REGISTRER FUNN'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(onPressed: complete, icon: const Icon(Icons.stop_circle_outlined), label: const Text('AVSLUTT SØK'))),
            ]),
          ]),
        )),
      ]),
    );
  }

  Future<void> togglePause() async {
    if (searchId == null) return;
    if (paused) await repo.resume(searchId!); else await repo.pause(searchId!);
    setState(() => paused = !paused);
  }

  Future<void> takeAreaPhoto() async {
    if (searchId == null) return;
    final file = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 88);
    if (file == null) return;
    final p = await location.current();
    final ext = file.name.split('.').last.toLowerCase();
    await repo.uploadSearchAreaPhoto(searchId!, await file.readAsBytes(), ext, lat: p.latitude, lng: p.longitude);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bildet er lagret som bilde av søksområdet.')));
  }

  Future<void> complete() async {
    if (searchId == null) return;
    final c = TextEditingController();
    final summary = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Avslutt søk'),
      content: TextField(controller: c, maxLines: 6, decoration: const InputDecoration(labelText: 'Beskrivelse av søket')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Avbryt')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Avslutt'))],
    ));
    if (summary == null) return;
    await repo.complete(searchId!, summary);
    await sub?.cancel();
    if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }
}
