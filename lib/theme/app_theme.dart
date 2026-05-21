import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de Cores Premium baseada no logo Doce & Ponto
  static const Color primaryDark = Color(0xFF1A1A1A); // Preto/Dark
  static const Color brandGold = Color(0xFFC29B62);   // Dourado/Bege
  static const Color brandRed = Color(0xFFE3000F);    // Vermelho Cereja
  static const Color backgroundBeige = Color(0xFFFDFBF7);
  static const Color cardOffWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFF8D6E63);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryDark,
      scaffoldBackgroundColor: backgroundBeige,
      colorScheme: const ColorScheme.light(
        primary: primaryDark,
        secondary: brandGold,
        surface: cardOffWhite,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),
      
      // Tipografia Mista (Merriweather para Títulos, Outfit para corpo)
      textTheme: TextTheme(
        displayLarge: GoogleFonts.merriweather(color: textDark, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.merriweather(color: textDark, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.merriweather(color: textDark, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.merriweather(color: textDark, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.merriweather(color: textDark, fontWeight: FontWeight.bold),
        headlineSmall: GoogleFonts.merriweather(color: textDark, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.merriweather(color: textDark, fontWeight: FontWeight.bold, fontSize: 22),
        titleMedium: GoogleFonts.outfit(color: textDark, fontWeight: FontWeight.w600, fontSize: 16),
        titleSmall: GoogleFonts.outfit(color: textDark, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.outfit(color: textDark, fontSize: 16),
        bodyMedium: GoogleFonts.outfit(color: textDark, fontSize: 14),
        bodySmall: GoogleFonts.outfit(color: textLight, fontSize: 12),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: backgroundBeige,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryDark),
        titleTextStyle: GoogleFonts.merriweather(
          color: primaryDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundBeige,
        selectedItemColor: brandGold,
        unselectedItemColor: textLight,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      cardTheme: CardThemeData(
        color: cardOffWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandRed,
        foregroundColor: Colors.white,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandGold),
        ),
        labelStyle: GoogleFonts.outfit(color: textLight),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
