import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HunderPage extends StatefulWidget {
  const HunderPage({super.key});
  @override
  State<HunderPage> createState() => _HunderPageState();
}
class _HunderPageState extends State<HunderPage> {
  Future<List<Map<String,dynamic>>> load() => Supabase.instance.client.from('sokshund_dogs').select().order('name').then((v)=>List<Map<String,dynamic>>.from(v));
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar: AppBar(title:const Text('Hunder')),
    floatingActionButton: FloatingActionButton.extended(onPressed:()=>editDog(),icon:const Icon(Icons.add),label:const Text('Legg til hund')),
    body: FutureBuilder<List<Map<String,dynamic>>>(future:load(),builder:(_,s){final rows=s.data??[];return ListView.builder(itemCount:rows.length,itemBuilder:(_,i){final d=rows[i];return ListTile(leading:const CircleAvatar(child:Icon(Icons.pets)),title:Text(d['name']??''),subtitle:Text(d['tracker_provider']??'Ingen tracker'),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')editDog(d);if(v=='event')addEvent(d);},itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('Rediger')),PopupMenuItem(value:'event',child:Text('Legg til hendelse'))]));});}),
  );
  Future<void> editDog([Map<String,dynamic>? dog]) async { final n=TextEditingController(text:dog?['name']??''); final chip=TextEditingController(text:dog?['chip_number']??''); final tracker=TextEditingController(text:dog?['tracker_device_id']??''); final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(dog==null?'Ny hund':'Rediger hund'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Navn')),const SizedBox(height:8),TextField(controller:chip,decoration:const InputDecoration(labelText:'Chipnummer')),const SizedBox(height:8),TextField(controller:tracker,decoration:const InputDecoration(labelText:'Tracker-ID'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Avbryt')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Lagre'))])); if(ok!=true)return; final data={'name':n.text.trim(),'chip_number':chip.text.trim(),'tracker_device_id':tracker.text.trim(),'active':true}; if(dog==null)await Supabase.instance.client.from('sokshund_dogs').insert(data);else await Supabase.instance.client.from('sokshund_dogs').update(data).eq('id',dog['id']); setState((){}); }
  Future<void> addEvent(Map<String,dynamic> dog) async { final title=TextEditingController(); final d=await showDatePicker(context:context,firstDate:DateTime.now().subtract(const Duration(days:365)),lastDate:DateTime.now().add(const Duration(days:3650)),initialDate:DateTime.now()); if(d==null)return; final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text('Hendelse – ${dog['name']}'),content:TextField(controller:title,decoration:const InputDecoration(labelText:'Hendelse')),actions:[FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Lagre'))])); if(ok!=true)return; final id=(await Supabase.instance.client.from('sokshund_dog_events').insert({'dog_id':dog['id'],'title':title.text.trim(),'event_date':d.toIso8601String(),'created_by':Supabase.instance.client.auth.currentUser!.id}).select('id').single())['id']; await Supabase.instance.client.from('sokshund_calendar_events').insert({'event_type':'dog_event','title':'${dog['name']}: ${title.text.trim()}','starts_at':d.toIso8601String(),'linked_table':'sokshund_dog_events','linked_id':id,'created_by':Supabase.instance.client.auth.currentUser!.id}); }
}
