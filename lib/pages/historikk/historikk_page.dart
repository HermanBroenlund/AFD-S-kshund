import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'report_detail_page.dart';
import 'training_history_detail_page.dart';

class HistorikkPage extends StatefulWidget {
  const HistorikkPage({super.key});

  @override
  State<HistorikkPage> createState() => _HistorikkPageState();
}

class _HistorikkPageState extends State<HistorikkPage> {
  Future<_HistoryData> load() async {
    final client = Supabase.instance.client;
    final results = await Future.wait([
      client.from('sokshund_searches').select('id,search_name,company_name,status,planned_date,completed_at').eq('status', 'completed').order('completed_at', ascending: false),
      client.from('sokshund_training_sessions').select().order('searched_at', ascending: false),
    ]);
    return _HistoryData(
      searches: List<Map<String, dynamic>>.from(results[0]),
      trainings: List<Map<String, dynamic>>.from(results[1]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Historikk')),
        body: FutureBuilder<_HistoryData>(
          future: load(),
          builder: (_, s) {
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            final data = s.data!;
            if (data.searches.isEmpty && data.trainings.isEmpty) {
              return const Center(child: Text('Ingen historikk ennå.'));
            }
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (data.searches.isNotEmpty) ...[
                  Text('Rapporter etter oppdrag', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...data.searches.map((r) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text(_reportName(r)),
                          subtitle: Text(_dateTime(r['completed_at'])),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ReportDetailPage(searchId: r['id'].toString())),
                          ),
                        ),
                      )),
                ],
                if (data.trainings.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text('Gjennomførte treninger', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...data.trainings.map((t) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.pets_outlined),
                          title: Text(t['material_type'] ?? 'Trening'),
                          subtitle: Text(_dateTime(t['searched_at'])),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TrainingHistoryDetailPage(session: t)),
                          ),
                        ),
                      )),
                ],
              ],
            );
          },
        ),
      );

  String _reportName(Map<String, dynamic> r) {
    final company = (r['company_name'] ?? 'Firma').toString().trim().replaceAll(RegExp(r'[^A-Za-z0-9ÆØÅæøå_-]+'), '_');
    final d = DateTime.tryParse(r['planned_date']?.toString() ?? '') ?? DateTime.now();
    return 'RS-$company-${DateFormat('yyyy-MM-dd').format(d)}';
  }

  String _dateTime(Object? value) {
    final d = DateTime.tryParse(value?.toString() ?? '');
    return d == null ? '-' : DateFormat('dd.MM.yyyy HH:mm').format(d.toLocal());
  }
}

class _HistoryData {
  const _HistoryData({required this.searches, required this.trainings});
  final List<Map<String, dynamic>> searches;
  final List<Map<String, dynamic>> trainings;
}
