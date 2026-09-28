import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class AfdMenuButton extends StatelessWidget {
  const AfdMenuButton({super.key, required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 72,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.afdYellow,
            foregroundColor: AppColors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onTap,
          icon: Icon(icon, size: 28),
          label: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        ),
      );
}
