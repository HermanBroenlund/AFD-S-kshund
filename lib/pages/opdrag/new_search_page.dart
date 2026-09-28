import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/search_models.dart';
import '../../repositories/search_repository.dart';
import '../../services/weather_service.dart';
import '../../widgets/search_area_map.dart';
import 'active_search_page.dart';

enum SearchFormMode { plan, start }

class NewSearchPage extends StatefulWidget {
  const NewSearchPage({super.key, required this.mode, this.existingSearch});
  final SearchFormMode mode;
  final Map<String, dynamic>? existingSearch;
  @override
  State<NewSearchPage> createState() => _NewSearchPageState();
}

class _NewSearchPageState extends State<NewSearchPage> {
  final formKey = GlobalKey<FormState>();
  final company = TextEditingController();
  final org = TextEditingController();
  final contact = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final notes = TextEditingController();
  List<LatLng> area = [];
  String? dogId;
  DateTime date = DateTime.now();
  bool busy = false;

  late final repo = SearchRepository(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    final r = widget.existingSearch;
    if (r != null) {
      company.text = r['company_name'] ?? '';
      org.text = r['organization_number'] ?? '';
      contact.text = r['contact_name'] ?? '';
      email.text = r['contact_email'] ?? '';
      phone.text = r['contact_phone'] ?? '';
      notes.text = r['notes'] ?? '';
      dogId = r['dog_id'] as String?;
      date = DateTime.tryParse((r['planned_date'] ?? '').toString()) ?? DateTime.now();
      final pts = r['search_area'] as List<dynamic>? ?? [];
      area = pts.map((p) => LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble())).toList();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.mode == SearchFormMode.plan ? 'Planlegg søk' : 'Nytt søk')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client.from('dogs').select('id,name').eq('active', true).order('name').then((v) => List<Map<String,dynamic>>.from(v)),
      builder: (context, snap) {
        final dogs = snap.data ?? [];
        return Form(
          key: formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextFormField(controller: company, decoration: const InputDecoration(labelText: 'Firma *'), validator: required),
            const SizedBox(height: 10),
            TextFormField(controller: org, decoration: const InputDecoration(labelText: 'Organisasjonsnummer *'), validator: required),
            const SizedBox(height: 10),
            TextFormField(controller: contact, decoration: const InputDecoration(labelText: 'Kontaktperson *'), validator: required),
            const SizedBox(height: 10),
            TextFormField(controller: email, decoration: const InputDecoration(labelText: 'E-post *'), keyboardType: TextInputType.emailAddress, validator: required),
            const SizedBox(height: 10),
            TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'Telefon *'), keyboardType: TextInputType.phone, validator: required),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: dogId,
              decoration: const InputDecoration(labelText: 'Hund *'),
              items: dogs.map((d) => DropdownMenuItem(value: d['id'] as String, child: Text(d['name'] as String))).toList(),
              onChanged: (v) => setState(() => dogId = v),
              validator: (v) => v == null ? 'Velg hund' : null,
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text('Dato'),
              subtitle: Text('${date.day.toString().padLeft(2,'0')}.${date.month.toString().padLeft(2,'0')}.${date.year}'),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async { final d = await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: date); if (d != null) setState(() => date = d); },
            ),
            const SizedBox(height: 16),
            Text('Søksområde', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SearchAreaMap(points: area, onChanged: (v) => area = v),
            const SizedBox(height: 10),
            TextFormField(controller: notes, decoration: const InputDecoration(labelText: 'Notat'), maxLines: 3),
            const SizedBox(height: 18),
            ElevatedButton(onPressed: busy ? null : submit, child: Text(widget.mode == SearchFormMode.plan ? 'LAGRE PLANLAGT SØK' : 'GÅ TIL OPPSTART')),
          ]),
        );
      },
    ),
  );

  String? required(String? v) => (v == null || v.trim().isEmpty) ? 'Påkrevd' : null;

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    if (area.length < 3) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Legg inn minst tre punkt i søksområdet.'))); return; }
    final handler = Supabase.instance.client.auth.currentUser!.id;
    final draft = SearchDraft(
      id: widget.existingSearch?['id'] as String?,
      companyName: company.text.trim(),
      organizationNumber: org.text.trim(),
      contactName: contact.text.trim(),
      contactEmail: email.text.trim(),
      contactPhone: phone.text.trim(),
      dogId: dogId!,
      handlerId: handler,
      plannedDate: date,
      area: area,
      notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
    );
    setState(() => busy = true);
    try {
      if (widget.mode == SearchFormMode.plan) {
        await repo.savePlanned(draft);
        if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Søket er planlagt.'))); Navigator.pop(context); }
        return;
      }
      final center = _center(area);
      final weather = await WeatherService().fetch(center.latitude, center.longitude);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ActiveSearchPage(draft: draft, weather: weather)));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
    finally { if (mounted) setState(() => busy = false); }
  }

  LatLng _center(List<LatLng> pts) => LatLng(pts.map((e) => e.latitude).reduce((a,b)=>a+b)/pts.length, pts.map((e) => e.longitude).reduce((a,b)=>a+b)/pts.length);
}
