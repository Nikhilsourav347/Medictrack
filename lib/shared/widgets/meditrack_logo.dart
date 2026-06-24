import 'package:flutter/material.dart';

class MediTrackLogo extends StatelessWidget {
  final double size;
  const MediTrackLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D9E75).withValues(alpha: 0.15),
            blurRadius: size * 0.2,
            spreadRadius: 1,
            offset: Offset(0, size * 0.05),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
