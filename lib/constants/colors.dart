import 'package:flutter/material.dart';

const Color _baseColor = Color(0xFF123456);

Color _darken(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return hslDark.toColor();
}

LinearGradient getBaseGradient() {
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_baseColor.withOpacity(0.8), _darken(_baseColor, 0.3)],
  );
}
