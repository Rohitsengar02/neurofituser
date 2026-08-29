import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - Matching the exact warm light video background tone
  static const Color background = Color(0xFFEFECE6);
  static const Color darkText = Color(0xFF141518);
  static const Color mutedText = Color(0xFF8E95A2);
  static const Color bodyText = Color(0xFF6B7280);
  static const Color accentCoral = Color(0xFFFF5238);
  static const Color accentCoralLight = Color(0xFFFFECE8);
  static const Color dotInactive = Color(0xFFD6D3CD);
  static const Color buttonBlack = Color(0xFF0F1014);

  // Gradient definitions
  static const LinearGradient coralGradient = LinearGradient(
    colors: [Color(0xFFFF5C38), Color(0xFFFF3823)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles with Google Fonts (Plus Jakarta Sans)
  static TextStyle get titleGray => GoogleFonts.plusJakartaSans(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        color: mutedText,
        letterSpacing: -1.2,
        height: 1.15,
      );

  static TextStyle get titleDark => GoogleFonts.plusJakartaSans(
        fontSize: 38,
        fontWeight: FontWeight.w800,
        color: darkText,
        letterSpacing: -1.2,
        height: 1.15,
      );

  static TextStyle get bodyStyle => GoogleFonts.plusJakartaSans(
        fontSize: 15.5,
        fontWeight: FontWeight.w400,
        color: bodyText,
        height: 1.45,
        letterSpacing: -0.2,
      );

  static TextStyle get buttonText => GoogleFonts.plusJakartaSans(
        fontSize: 17.5,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.2,
      );

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: accentCoral,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      colorScheme: const ColorScheme.light(
        primary: accentCoral,
        surface: background,
        onSurface: darkText,
      ),
    );
  }
}
