import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistorikkPage extends StatelessWidget {
  const HistorikkPage({super.key});
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Historikk')),
    body:FutureBuilder<List<Map<String,dynamic>>>(
      future:Supabase.instance.client.from('searches').select('id,search_name,company_name,status,started_at,completed_at').eq('status','completed').order('completed_at',ascending:false).then((v)=>List<Map<String,dynamic>>.from(v)),
      builder:(_,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());final rows=s.data!;if(rows.isEmpty)return const Center(child:Text('Ingen gjennomførte søk.'));return ListView.separated(padding:const EdgeInsets.all(12),itemCount:rows.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){final r=rows[i];return Card(child:ListTile(title:Text(r['search_name']??r['company_name']??'Søk'),subtitle:Text(r['completed_at']?.toString()??''),trailing:const Icon(Icons.description_outlined),onTap:()=>_show(context,r)));});},
    ),
  );
  Future<void> _show(BuildContext context,Map<String,dynamic> row) async { final full=await Supabase.instance.client.from('searches').select('*, weather_snapshots(*), findings(*), search_photos(*)').eq('id',row['id']).single(); if(!context.mounted)return; showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text(full['search_name']??'Rapportgrunnlag'),content:SingleChildScrollView(child:SelectableText(full.toString())),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Lukk'))])); }
}
