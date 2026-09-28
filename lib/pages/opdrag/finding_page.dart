import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/search_repository.dart';
import '../../services/location_service.dart';

class FindingPage extends StatefulWidget {
  const FindingPage({super.key, required this.searchId});
  final String searchId;
  @override
  State<FindingPage> createState() => _FindingPageState();
}

class _FindingPageState extends State<FindingPage> {
  final description = TextEditingController();
  String handling = 'tatt_med_for_destruering';
  final photos = <XFile>[];
  bool busy = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Registrer funn')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      TextField(controller: description, maxLines: 5, decoration: const InputDecoration(labelText: 'Beskrivelse av funnet')),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: handling,
        decoration: const InputDecoration(labelText: 'Håndtering'),
        items: const [
          DropdownMenuItem(value: 'tatt_med_for_destruering', child: Text('Tatt med for destruering')),
          DropdownMenuItem(value: 'destruert_pa_plass', child: Text('Destruert på plass')),
        ],
        onChanged: (v) => setState(() => handling = v!),
      ),
      const SizedBox(height: 12),
      ElevatedButton.icon(onPressed: () async { final p = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 88); if (p != null) setState(() => photos.add(p)); }, icon: const Icon(Icons.camera_alt), label: Text('TA BILDE AV FUNN (${photos.length})')),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: busy ? null : save, child: const Text('LAGRE FUNN')),
    ]),
  );

  Future<void> save() async {
    if (description.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Legg inn en beskrivelse.'))); return; }
    setState(() => busy = true);
    try {
      final p = await LocationService().current();
      final repo = SearchRepository(Supabase.instance.client);
      final id = await repo.registerFinding(searchId: widget.searchId, description: description.text.trim(), handling: handling, latitude: p.latitude, longitude: p.longitude);
      for (final photo in photos) {
        await repo.uploadFindingPhoto(widget.searchId, id, await photo.readAsBytes(), photo.name.split('.').last.toLowerCase());
      }
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
    finally { if (mounted) setState(() => busy = false); }
  }
}
