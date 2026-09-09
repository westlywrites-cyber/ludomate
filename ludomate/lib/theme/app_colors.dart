import 'package:flutter/material.dart';

/// Central palette for LudoMate. Keep every color reference in the app
/// pointing at these constants so the theme can be adjusted from one place.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF6C3BFF); // Royal Purple
  static const Color secondary = Color(0xFFFF8A1F); // Vibrant Orange
  static const Color darkNavy = Color(0xFF11142D);
  static const Color background = Color(0xFFF7F7FB);
  static const Color textDark = Color(0xFF17172A);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);

  // Ludo board zone colors (4 players)
  static const Color zoneRed = Color(0xFFF04444);
  static const Color zoneGreen = Color(0xFF22C55E);
  static const Color zoneYellow = Color(0xFFF5C542);
  static const Color zoneBlue = Color(0xFF3B82F6);
}
