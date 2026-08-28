import 'package:flutter/material.dart';

/// The Hosanna brand mark (rounded square logo) at a given [size].
class HosannaLogo extends StatelessWidget {
  const HosannaLogo({super.key, this.size = 72, this.borderRadius = 20});

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return ColoredBox(
      color: Theme.of(context).colorScheme.primary,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.music_note, size: size * 0.5, color: Colors.white),
      ),
    );
  }
}
