import 'package:flutter/material.dart';
import '../models/user_model.dart';

// Shamba Smart design system colour palette
class AppColors {
  AppColors._();

  static const soil    = Color(0xFF1E1108);
  static const earth   = Color(0xFF4A2C0E);
  static const harvest = Color(0xFFC8860A);
  static const sun     = Color(0xFFF4B942);
  static const amber   = Color(0xFFFFD166);
  static const leaf    = Color(0xFF1B5E20);
  static const sprout  = Color(0xFF43A047);
  static const mint    = Color(0xFFE8F5E9);
  static const mist    = Color(0xFFFDF6EE);
  static const cream   = Color(0xFFFFFDF8);
  static const ink     = Color(0xFF160E04);
  static const mid     = Color(0xFF7A5C3A);

  // Role accent colours
  static Color roleColor(UserRole role) => switch (role) {
        UserRole.mkulima   => const Color(0xFF2E7D32),
        UserRole.duka      => const Color(0xFF1565C0),
        UserRole.muuzaji   => const Color(0xFF6A1B9A),
        UserRole.mwekezaji => const Color(0xFFC8860A),
        UserRole.afisa     => const Color(0xFF00695C),
      };
}
