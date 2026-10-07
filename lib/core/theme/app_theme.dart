import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Palette
  static const Color primary = Color(0xFFFF5722); // Artisan Pizza Flame Orange
  static const Color primaryDark = Color(0xFFE64A19);
  static const Color primaryLight = Color(0xFFFF8A65);
  static const Color accentGold = Color(0xFFFFB300); // Golden Mozzarella / Crust

  // Dark Canvas Tones
  static const Color background = Color(0xFF0D0E12); // Deep Obsidian
  static const Color surface = Color(0xFF16181F); // Midnight Card Surface
  static const Color surfaceElevated = Color(0xFF1E212B);
  static const Color surfaceBorder = Color(0xFF282C38);
  static const Color divider = Color(0xFF222633);

  // Status Tones
  static const Color statusPending = Color(0xFFF59E0B); // Amber warning
  static const Color statusConfirmed = Color(0xFF3B82F6); // Blue
  static const Color statusPreparing = Color(0xFF8B5CF6); // Violet / In Kitchen
  static const Color statusReady = Color(0xFF06B6D4); // Cyan / Ready for pickup
  static const Color statusDelivered = Color(0xFF10B981); // Emerald Green / Done
  static const Color statusCancelled = Color(0xFFEF4444); // Crimson / Cancelled

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Glow Shadows
  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 4),
        )
      ];

  static List<BoxShadow> get pendingGlow => [
        BoxShadow(
          color: statusPending.withValues(alpha: 0.35),
          blurRadius: 14,
          offset: const Offset(0, 3),
        )
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )
      ];

  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accentGold,
        surface: surface,
        error: statusCancelled,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface.withValues(alpha: 0.95),
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 2,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: GoogleFonts.outfit(color: textMuted, fontSize: 14),
      ),
    );
  }
}
