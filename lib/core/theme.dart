import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Mode Colors
  static const Color primaryBlue = Color(0xFF1A365D); // Đậm sâu, sang trọng (Navy)
  static const Color accentBlue = Color(0xFF3182CE); // Tươi sáng làm điểm nhấn
  static const Color primaryWhite = Color(0xFFF7FAFC); // Nền xám rất nhạt
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2D3748);
  static const Color textLight = Color(0xFF718096);
  
  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0F172A); // Nền tối tinh tế (Slate 900)
  static const Color darkCard = Color(0xFF1E293B); // Nền card tối (Slate 800)
  static const Color darkTextMain = Color(0xFFF8FAFC); // Chữ trắng sáng (Slate 50)
  static const Color darkTextSub = Color(0xFF94A3B8); // Chữ phụ xám mờ (Slate 400)
  
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
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
        onSurface: textDark,
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

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accentBlue,
      scaffoldBackgroundColor: darkBackground,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
        bodyColor: darkTextMain,
        displayColor: darkTextMain,
      ),
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        secondary: accentBlue,
        background: darkBackground,
        surface: darkCard,
        onSurface: darkTextMain,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkTextMain),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: darkTextMain,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: accentBlue.withOpacity(0.4),
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
        fillColor: darkCard,
        hintStyle: const TextStyle(color: darkTextSub),
        prefixIconColor: accentBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
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
