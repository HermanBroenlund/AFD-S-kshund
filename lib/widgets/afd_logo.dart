import 'package:flutter/material.dart';

class AfdLogo extends StatelessWidget {
  const AfdLogo({super.key, this.height = 130});
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset('assets/images/afd_sokshund_logo.png', height: height, fit: BoxFit.contain),
      );
}
