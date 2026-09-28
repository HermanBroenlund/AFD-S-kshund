import 'package:flutter/material.dart';
import 'new_search_page.dart';
import 'planned_searches_page.dart';

class OpdragPage extends StatelessWidget {
  const OpdragPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Oppdrag')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      ElevatedButton.icon(onPressed: () => _start(context), icon: const Icon(Icons.play_arrow), label: const Text('START SØK')),
      const SizedBox(height: 12),
      ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewSearchPage(mode: SearchFormMode.plan))), icon: const Icon(Icons.event_available), label: const Text('PLANLEGG SØK')),
      const SizedBox(height: 12),
      ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlannedSearchesPage(startMode: false))), icon: const Icon(Icons.list_alt), label: const Text('PLANLAGTE SØK')),
    ]),
  );

  Future<void> _start(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Start søk', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const PlannedSearchesPage(startMode: true))); }, child: const Text('BRUK PLANLAGT SØK')),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const NewSearchPage(mode: SearchFormMode.start))); }, child: const Text('NYTT SØK')),
        ]),
      )),
    );
  }
}
