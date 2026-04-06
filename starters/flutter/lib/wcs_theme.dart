import 'package:flutter/material.dart';

class WcsTheme {
  static const Color bg = Color(0xFF0C1222);
  static const Color card = Color(0xFF121A2F);
  static const Color muted = Color(0xFFA7B0C2);
  static const Color text = Color(0xFFE9EEF9);
  static const Color brand = Color(0xFF30C7FF);
  static const Color accent = Color(0xFF22D3A6);
  static const Color line = Color(0xFF243352);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: brand,
        secondary: accent,
        surface: card,
        onSurface: text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),
      cardTheme: const CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: line),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
