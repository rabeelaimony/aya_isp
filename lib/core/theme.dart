import 'package:flutter/material.dart';

/// Centralized app theme used across the whole application.
/// Use `AppTheme.lightTheme` in MaterialApp.theme
class AppTheme {
  // Vibrant green identity for the ISP app
  static final Color primary = const Color(0xFF2E7D32); // Green 700
  static final Color primaryDark = const Color(0xFF1B5E20); // Darker green
  static final Color primaryLight = const Color(0xFF66BB6A); // Light green
  static final Color accentRed = const Color(0xFFD32F2F); // Error accent

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryLight,
      secondary: const Color(0xFF43A047),
      onSecondary: Colors.white,
      error: accentRed,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black87,
    );

    return ThemeData(
      colorScheme: colorScheme,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: colorScheme.surface,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withValues(alpha: 0.85),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 6,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        centerTitle: true,
      ),
       elevatedButtonTheme: ElevatedButtonThemeData(
         style: ElevatedButton.styleFrom(
           backgroundColor: colorScheme.primary,
           foregroundColor: colorScheme.onPrimary,
           // Avoid infinite width constraints when buttons are placed in
           // unconstrained parents (dialogs, sheets, rows).
           minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.primary),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 16),
      ),
      iconTheme: IconThemeData(color: colorScheme.primary),
      dividerColor: Colors.grey.shade300,
    );
  }
}
