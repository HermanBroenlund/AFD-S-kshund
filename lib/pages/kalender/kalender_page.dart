import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../trening/use_training_find_page.dart';

class KalenderPage extends StatefulWidget {
  const KalenderPage({super.key});
  @override
  State<KalenderPage> createState() => _KalenderPageState();
}

class _KalenderPageState extends State<KalenderPage> {
  DateTime focused = DateTime.now();
  DateTime selected = DateTime.now();
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final v = await Supabase.instance.client.from('sokshund_calendar_events').select().order('starts_at');
    if (mounted) setState(() => events = List<Map<String, dynamic>>.from(v));
  }

  List<Map<String, dynamic>> forDay(DateTime day) => events.where((e) {
        final d = DateTime.tryParse(e['starts_at'].toString())?.toLocal();
        return d != null && d.year == day.year && d.month == day.month && d.day == day.day;
      }).toList();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Kalender')),
        floatingActionButton: FloatingActionButton(onPressed: addNote, child: const Icon(Icons.note_add)),
        body: Column(
          children: [
            TableCalendar<Map<String, dynamic>>(
              firstDay: DateTime.utc(2025, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: focused,
              selectedDayPredicate: (d) => isSameDay(selected, d),
              eventLoader: forDay,
              onDaySelected: (s, f) => setState(() {
                selected = s;
                focused = f;
              }),
              onPageChanged: (f) => focused = f,
            ),
            Expanded(
              child: ListView(
                children: forDay(selected)
                    .map(
                      (e) => ListTile(
                        leading: Icon(_icon(e['event_type'] as String?)),
                        title: Text(e['title'] ?? 'Hendelse'),
                        subtitle: Text(e['notes'] ?? ''),
                        trailing: e['linked_id'] != null ? const Icon(Icons.chevron_right) : null,
                        onTap: () => openEvent(e),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      );

  IconData _icon(String? t) => switch (t) {
        'planned_search' => Icons.search,
        'training_find' => Icons.location_on,
        'dog_event' => Icons.pets,
        'training' => Icons.school,
        _ => Icons.notes,
      };

  Future<void> openEvent(Map<String, dynamic> event) async {
    if (event['event_type'] == 'training_find' && event['linked_id'] != null) {
      final row = await Supabase.instance.client
          .from('sokshund_training_finds')
          .select()
          .eq('id', event['linked_id'])
          .maybeSingle();
      if (row != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UseTrainingFindPage(find: row)),
        );
        await load();
      }
    }
  }

  Future<void> addNote() async {
    final c = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Notat ${selected.day}.${selected.month}.${selected.year}'),
        content: TextField(controller: c, maxLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Avbryt')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Lagre')),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    await Supabase.instance.client.from('sokshund_calendar_events').insert({
      'event_type': 'note',
      'title': 'Notat',
      'notes': text,
      'starts_at': DateTime(selected.year, selected.month, selected.day, 12).toIso8601String(),
      'created_by': Supabase.instance.client.auth.currentUser!.id,
    });
    await load();
  }
}
