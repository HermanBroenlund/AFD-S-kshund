import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/search_repository.dart';
import 'new_search_page.dart';

class PlannedSearchesPage extends StatefulWidget {
  const PlannedSearchesPage({super.key, required this.startMode});
  final bool startMode;
  @override
  State<PlannedSearchesPage> createState() => _PlannedSearchesPageState();
}

class _PlannedSearchesPageState extends State<PlannedSearchesPage> {
  late final repo = SearchRepository(Supabase.instance.client);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.startMode ? 'Velg planlagt søk' : 'Planlagte søk')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.plannedSearches(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final rows = snap.data!;
        if (rows.isEmpty) return const Center(child: Text('Ingen planlagte søk.'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = rows[i];
            return Card(child: ListTile(
              title: Text(r['company_name'] ?? 'Uten firmanavn'),
              subtitle: Text((r['planned_date'] ?? '').toString()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewSearchPage(mode: widget.startMode ? SearchFormMode.start : SearchFormMode.plan, existingSearch: r))),
            ));
          },
        );
      },
    ),
  );
}
