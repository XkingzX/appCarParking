import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF1A365D); // Đậm sâu, sang trọng (Navy)
  static const Color accentBlue = Color(0xFF3182CE); // Tươi sáng làm điểm nhấn
  static const Color primaryWhite = Color(0xFFF7FAFC); // Nền xám rất nhạt
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2D3748);
  static const Color textLight = Color(0xFF718096);
  
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: primaryWhite,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentBlue,
        background: primaryWhite,
        surface: cardColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryBlue),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textDark,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: primaryBlue.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: textLight),
        prefixIconColor: accentBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      ),
    );
  }
}
