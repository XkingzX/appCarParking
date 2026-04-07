import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF0050A0);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color accentOrange = Color(0xFFF2A900); // Màu vàng cam cho điểm nhấn (như slot xe)
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF777777);
  
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: primaryWhite,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentOrange,
        background: primaryWhite,
        surface: primaryWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryWhite,
        foregroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryBlue),
        titleTextStyle: TextStyle(
          color: primaryBlue,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: primaryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      fontFamily: 'Roboto', // Sử dụng font mặc định hiện đại, nếu cần có thể thêm Google Fonts sau
    );
  }
}
