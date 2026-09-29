import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/report_export_service.dart';

class ReportDetailPage extends StatefulWidget {
  const ReportDetailPage({super.key, required this.searchId});

  final String searchId;

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  late final Future<_ReportBundle> future = _load();
  bool exporting = false;

  Future<_ReportBundle> _load() async {
    final client = Supabase.instance.client;
    final report = await client
        .from('sokshund_searches')
        .select('*, sokshund_dogs(name), sokshund_weather_snapshots(*), sokshund_findings(*, sokshund_finding_photos(*)), sokshund_search_photos(*), sokshund_search_track_points(*)')
        .eq('id', widget.searchId)
        .single();
    String? handler;
    final handlerId = report['handler_id']?.toString();
    if (handlerId != null) {
      final p = await client.from('profiles').select('full_name').eq('id', handlerId).maybeSingle();
      handler = p?['full_name']?.toString();
    }
    return _ReportBundle(report: report, handlerName: handler);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Rapport')),
        body: FutureBuilder<_ReportBundle>(
          future: future,
          builder: (_, s) {
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            final bundle = s.data!;
            final r = bundle.report;
            final exporter = ReportExportService(Supabase.instance.client);
            final findings = List<Map<String, dynamic>>.from(r['sokshund_findings'] ?? const []);
            final photos = List<Map<String, dynamic>>.from(r['sokshund_search_photos'] ?? const []);
            final weatherRows = List<Map<String, dynamic>>.from(r['sokshund_weather_snapshots'] ?? const []);
            final weather = weatherRows.isEmpty ? <String, dynamic>{} : weatherRows.first;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(exporter.reportName(r), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: exporting ? null : () => _exportPdf(exporter, bundle),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('PDF'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: exporting ? null : () => _exportWord(exporter, bundle),
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('WORD'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Oppdrag',
                  children: [
                    _Info('Firma', r['company_name']),
                    _Info('Organisasjonsnummer', r['organization_number']),
                    _Info('Kontaktperson', r['contact_name']),
                    _Info('E-post', r['contact_email']),
                    _Info('Telefon', r['contact_phone']),
                  ],
                ),
                _Section(
                  title: 'Gjennomføring',
                  children: [
                    _Info('Hund', (r['sokshund_dogs'] as Map?)?['name']),
                    _Info('Fører', bundle.handlerName),
                    _Info('Planlagt dato', _date(r['planned_date'])),
                    _Info('Start', _dateTime(r['started_at'])),
                    _Info('Avsluttet', _dateTime(r['completed_at'])),
                    _Info('Beskrivelse av søket', r['summary']),
                    _Info('Plan / notat', r['notes']),
                  ],
                ),
                _Section(
                  title: 'Vær ved oppstart',
                  children: [
                    _Info('Temperatur', _unit(weather['temperature_c'], '°C')),
                    _Info('Vind', _unit(weather['wind_speed_ms'], 'm/s')),
                    _Info('Vindretning', _unit(weather['wind_direction_deg'], '°')),
                    _Info('Luftfuktighet', _unit(weather['humidity_percent'], '%')),
                    _Info('Lufttrykk', _unit(weather['air_pressure_hpa'], 'hPa')),
                    _Info('Nedbør', _unit(weather['precipitation_mm'], 'mm')),
                  ],
                ),
                _SearchMap(report: r),
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('Bilder fra søksområdet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...photos.map((p) => _PrivateImage(bucket: 'sokshund-search-media', path: p['storage_path'].toString())),
                ],
                const SizedBox(height: 14),
                Text('Registrerte funn', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (findings.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Ingen registrerte funn.'))),
                ...findings.asMap().entries.map((entry) {
                  final i = entry.key;
                  final f = entry.value;
                  final fPhotos = List<Map<String, dynamic>>.from(f['sokshund_finding_photos'] ?? const []);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Funn ${i + 1}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          _Info('Tid', _dateTime(f['found_at'])),
                          _Info('Koordinat', '${f['latitude']}, ${f['longitude']}'),
                          _Info('Beskrivelse', f['description']),
                          _Info('Håndtering', _handling(f['handling'])),
                          if (fPhotos.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...fPhotos.map((p) => _PrivateImage(bucket: 'sokshund-search-media', path: p['storage_path'].toString())),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      );

  Future<void> _exportPdf(ReportExportService exporter, _ReportBundle bundle) async {
    setState(() => exporting = true);
    try {
      await exporter.sharePdf(bundle.report, handlerName: bundle.handlerName);
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> _exportWord(ReportExportService exporter, _ReportBundle bundle) async {
    setState(() => exporting = true);
    try {
      await exporter.shareDocx(bundle.report, handlerName: bundle.handlerName);
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  String _date(Object? v) {
    final d = DateTime.tryParse(v?.toString() ?? '');
    return d == null ? '-' : DateFormat('dd.MM.yyyy').format(d.toLocal());
  }

  String _dateTime(Object? v) {
    final d = DateTime.tryParse(v?.toString() ?? '');
    return d == null ? '-' : DateFormat('dd.MM.yyyy HH:mm').format(d.toLocal());
  }

  String _unit(Object? v, String unit) => v == null ? '-' : '$v $unit';

  String _handling(Object? v) => switch (v?.toString()) {
        'tatt_med_for_destruering' => 'Tatt med for destruering',
        'destruert_pa_plass' => 'Destruert på plass',
        _ => v?.toString() ?? '-',
      };
}

class _ReportBundle {
  const _ReportBundle({required this.report, required this.handlerName});
  final Map<String, dynamic> report;
  final String? handlerName;
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      );
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label;
  final Object? value;
  @override
  Widget build(BuildContext context) {
    final text = value == null || value.toString().trim().isEmpty ? '-' : value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 135, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(child: SelectableText(text)),
        ],
      ),
    );
  }
}

class _PrivateImage extends StatelessWidget {
  const _PrivateImage({required this.bucket, required this.path});
  final String bucket;
  final String path;
  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
        future: Supabase.instance.client.storage.from(bucket).createSignedUrl(path, 3600),
        builder: (_, s) {
          if (!s.hasData) return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(s.data!, width: double.infinity, height: 250, fit: BoxFit.cover),
            ),
          );
        },
      );
}

class _SearchMap extends StatelessWidget {
  const _SearchMap({required this.report});
  final Map<String, dynamic> report;
  @override
  Widget build(BuildContext context) {
    final area = List<Map<String, dynamic>>.from(report['search_area'] ?? const [])
        .map((e) => LatLng((e['lat'] as num).toDouble(), (e['lng'] as num).toDouble()))
        .toList();
    final track = List<Map<String, dynamic>>.from(report['sokshund_search_track_points'] ?? const [])
        .where((e) => e['source'] == 'handler')
        .map((e) => LatLng((e['latitude'] as num).toDouble(), (e['longitude'] as num).toDouble()))
        .toList();
    if (area.isEmpty) return const SizedBox.shrink();
    final boundary = [...area, area.first];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Søksområde og spor', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            SizedBox(
              height: 280,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(initialCenter: area.first, initialZoom: 15),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'no.afgruppen.afd.sokshund'),
                    PolylineLayer(polylines: [
                      Polyline(points: boundary, strokeWidth: 4),
                      if (track.length >= 2) Polyline(points: track, strokeWidth: 4),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
