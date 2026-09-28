import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  @override
  void initState() { super.initState(); type.text = widget.existing?['material_type'] ?? ''; notes.text = widget.existing?['notes'] ?? ''; }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.existing == null ? 'Nytt treningsfunn' : 'Treningsfunn')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      TextField(controller: type, decoration: const InputDecoration(labelText: 'Type / kategori')),
      const SizedBox(height: 10),
      TextField(controller: notes, maxLines: 4, decoration: const InputDecoration(labelText: 'Notat')),
      const SizedBox(height: 10),
      ElevatedButton.icon(onPressed: () async { final p = await ImagePicker().pickImage(source: ImageSource.camera); if (p != null) setState(() => photo = p); }, icon: const Icon(Icons.camera_alt), label: Text(photo == null ? 'TA BILDE AV NEDGRAVING' : 'BILDE VALGT')),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: save, child: const Text('LAGRE')),
      if (widget.existing != null) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: delete, icon: const Icon(Icons.delete_outline), label: const Text('SLETT')),
      ],
    ]),
  );

  Future<void> save() async {
    final client = Supabase.instance.client;
    final pos = await LocationService().current();
    String? photoPath = widget.existing?['photo_path'] as String?;
    if (photo != null) {
      photoPath = 'training/${DateTime.now().millisecondsSinceEpoch}.${photo!.name.split('.').last}';
      await client.storage.from('training-media').uploadBinary(photoPath, await photo!.readAsBytes());
    }
    final values = {
      'material_type': type.text.trim(),
      'notes': notes.text.trim(),
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'photo_path': photoPath,
      'buried_at': widget.existing?['buried_at'] ?? DateTime.now().toIso8601String(),
      'created_by': client.auth.currentUser!.id,
    };
    String id;
    if (widget.existing == null) {
      final row = await client.from('training_finds').insert(values).select('id').single(); id = row['id'] as String;
      await client.from('calendar_events').insert({'event_type':'training_find','title':'Treningsfunn: ${type.text.trim()}','starts_at':values['buried_at'],'linked_table':'training_finds','linked_id':id,'created_by':client.auth.currentUser!.id});
    } else {
      id = widget.existing!['id'] as String; await client.from('training_finds').update(values).eq('id', id);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> delete() async { await Supabase.instance.client.from('training_finds').delete().eq('id', widget.existing!['id']); if (mounted) Navigator.pop(context); }
}
