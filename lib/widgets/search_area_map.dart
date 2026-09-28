import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SearchAreaMap extends StatefulWidget {
  const SearchAreaMap({super.key, required this.points, required this.onChanged});
  final List<LatLng> points;
  final ValueChanged<List<LatLng>> onChanged;
  @override
  State<SearchAreaMap> createState() => _SearchAreaMapState();
}

class _SearchAreaMapState extends State<SearchAreaMap> {
  bool satellite = false;
  late List<LatLng> points;
  @override
  void initState() { super.initState(); points = [...widget.points]; }

  @override
  Widget build(BuildContext context) {
    final closed = points.length >= 3 ? [...points, points.first] : points;
    return Column(children: [
      Row(children: [
        ChoiceChip(label: const Text('Kart'), selected: !satellite, onSelected: (_) => setState(() => satellite = false)),
        const SizedBox(width: 8),
        ChoiceChip(label: const Text('Flyfoto'), selected: satellite, onSelected: (_) => setState(() => satellite = true)),
        const Spacer(),
        TextButton.icon(onPressed: points.isEmpty ? null : () { setState(() => points.clear()); widget.onChanged(points); }, icon: const Icon(Icons.delete_outline), label: const Text('Nullstill')),
      ]),
      SizedBox(
        height: 360,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(59.9139, 10.7522),
              initialZoom: 13,
              onTap: (_, latLng) { setState(() => points.add(latLng)); widget.onChanged([...points]); },
            ),
            children: [
              TileLayer(
                urlTemplate: satellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'no.afgruppen.afd.sokshund',
              ),
              if (closed.length >= 2) PolylineLayer(polylines: [Polyline(points: closed, strokeWidth: 4)]),
              MarkerLayer(markers: points.asMap().entries.map((e) => Marker(point: e.value, width: 32, height: 32, child: CircleAvatar(radius: 12, child: Text('${e.key + 1}', style: const TextStyle(fontSize: 11)))).toList()),
            ],
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text('Trykk i kartet for å legge til grensepunkter. ${points.length} punkt registrert.', style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
