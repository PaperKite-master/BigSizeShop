import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const seedColor = Color(0xFFC59B27); // Classical Gold/Yellow
    const primaryColor = Color(0xFFB58920);
    const darkEspresso = Color(0xFF3D251E); // Warm dark brown
    const creamBackground = Color(0xFFFAF6EE); // Warm parchment cream
    const cardColor = Color(0xFFFFFDF9); // Soft clean cream

    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      primary: primaryColor,
      secondary: darkEspresso,
      surface: cardColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: baseColorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: creamBackground,
      cardColor: cardColor,
      
      // Classic typography settings
      fontFamily: 'serif', // Elegant serif font style for a literary/antique feel
      
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: darkEspresso,
        titleTextStyle: TextStyle(
          fontFamily: 'serif',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkEspresso,
          letterSpacing: 1.0,
        ),
        iconTheme: IconThemeData(color: darkEspresso),
      ),
      
      // Vintage styled Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        labelStyle: const TextStyle(
          color: darkEspresso,
          fontFamily: 'serif',
        ),
        floatingLabelStyle: const TextStyle(
          color: primaryColor,
          fontFamily: 'serif',
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFD4C5A3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFE4D7BA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Antique style buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkEspresso,
          foregroundColor: creamBackground,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: primaryColor, width: 1),
          ),
          textStyle: const TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkEspresso,
          side: const BorderSide(color: darkEspresso, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEFE6D4),
        disabledColor: Colors.grey.shade200,
        selectedColor: primaryColor,
        secondarySelectedColor: darkEspresso,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        labelStyle: const TextStyle(
          color: darkEspresso,
          fontFamily: 'serif',
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: const BorderSide(color: Color(0xFFD4C5A3), width: 0.5),
        ),
      ),
    );
  }
}