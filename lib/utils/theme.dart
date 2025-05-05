import 'package:flutter/material.dart';

class AppTheme {
  // Light theme colors
  static const Color primaryColorLight = Color(0xFF3366FF); // Blue
  static const Color secondaryColorLight = Color(0xFF00CC99); // Teal
  static const Color backgroundColorLight = Color(0xFFF5F7FA);
  static const Color surfaceColorLight = Colors.white;
  static const Color errorColorLight = Color(0xFFFF3B30);
  static const Color textColorLight = Color(0xFF1A1A1A);

  // Dark theme colors
  static const Color primaryColorDark = Color(0xFF4D7CFF); // Lighter blue
  static const Color secondaryColorDark = Color(0xFF00EEAD); // Lighter teal
  static const Color backgroundColorDark = Color(0xFF121212);
  static const Color surfaceColorDark = Color(0xFF1E1E1E);
  static const Color errorColorDark = Color(0xFFFF6B6B);
  static const Color textColorDark = Color(0xFFF0F0F0);

  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    letterSpacing: 0.2,
  );

  static const TextStyle smallTextStyle = TextStyle(
    fontSize: 14,
    letterSpacing: 0.1,
  );

  // Button styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  static final ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  // Input decoration
  static InputDecoration inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColorLight,
      colorScheme: const ColorScheme.light(
        primary: primaryColorLight,
        secondary: secondaryColorLight,
        background: backgroundColorLight,
        surface: surfaceColorLight,
        error: errorColorLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: textColorLight,
        onSurface: textColorLight,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColorLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColorLight,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButtonStyle),
      textTheme: const TextTheme(
        displayLarge: headingStyle,
        headlineMedium: subheadingStyle,
        bodyLarge: bodyStyle,
        bodySmall: smallTextStyle,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColorDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColorDark,
        secondary: secondaryColorDark,
        background: backgroundColorDark,
        surface: surfaceColorDark,
        error: errorColorDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: textColorDark,
        onSurface: textColorDark,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColorDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColorDark,
        foregroundColor: textColorDark,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButtonStyle),
      textTheme: const TextTheme(
        displayLarge: headingStyle,
        headlineMedium: subheadingStyle,
        bodyLarge: bodyStyle,
        bodySmall: smallTextStyle,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}