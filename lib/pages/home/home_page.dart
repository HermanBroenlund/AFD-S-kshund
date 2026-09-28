import 'package:flutter/material.dart';
import '../../widgets/afd_logo.dart';
import '../../widgets/afd_menu_button.dart';
import '../opdrag/opdrag_page.dart';
import '../trening/trening_page.dart';
import '../kalender/kalender_page.dart';
import '../hunder/hunder_page.dart';
import '../historikk/historikk_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AFD Søkshund')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Center(child: AfdLogo(height: 150)),
          const SizedBox(height: 20),
          AfdMenuButton(label: 'OPPDRAG', icon: Icons.search, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OpdragPage()))),
          const SizedBox(height: 12),
          AfdMenuButton(label: 'TRENING', icon: Icons.school_outlined, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TreningPage()))),
          const SizedBox(height: 12),
          AfdMenuButton(label: 'KALENDER', icon: Icons.calendar_month, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KalenderPage()))),
          const SizedBox(height: 12),
          AfdMenuButton(label: 'HUNDER', icon: Icons.pets, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HunderPage()))),
          const SizedBox(height: 12),
          AfdMenuButton(label: 'HISTORIKK', icon: Icons.history, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistorikkPage()))),
        ],
      ),
    ),
  );
}
