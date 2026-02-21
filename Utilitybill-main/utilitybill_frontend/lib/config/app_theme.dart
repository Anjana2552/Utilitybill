import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central theme controller for light/dark mode with app-specific colors.
class AppTheme {
  static const _prefKey = 'theme_mode';
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  /// Call during app startup
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == 'dark') {
        themeMode.value = ThemeMode.dark;
      } else if (saved == 'system') {
        themeMode.value = ThemeMode.system;
      } else {
        themeMode.value = ThemeMode.light;
      }
    } catch (_) {
      themeMode.value = ThemeMode.light;
    }
  }

  static Future<void> setMode(ThemeMode mode) async {
    themeMode.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      String v = 'light';
      if (mode == ThemeMode.dark) v = 'dark';
      if (mode == ThemeMode.system) v = 'system';
      await prefs.setString(_prefKey, v);
    } catch (_) {}
  }

  static Future<void> toggle() async {
    await setMode(themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  /// Light color scheme (based on provided palette)
  static ThemeData lightTheme() {
    // Approximate the provided blue palette for light mode
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0C165F), // deep navy blue
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF4F62FF), // vivid blue accent
      onPrimaryContainer: Colors.white,
      secondary: Color(0xFF1020CC), // strong royal blue
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF95A0FF),
      onSecondaryContainer: Color(0xFF0C165F),
      tertiary: Color(0xFFAEB6FF), // soft periwinkle
      onTertiary: Color(0xFF0C165F),
      tertiaryContainer: Color(0xFFD8DDFF),
      onTertiaryContainer: Color(0xFF0C165F),
      error: Color(0xFFB00020),
      onError: Colors.white,
      errorContainer: Color(0xFFFDE7E9),
      onErrorContainer: Color(0xFF7A1C1C),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1B1B1B),
      surfaceVariant: Color(0xFFF2F4FF),
      onSurfaceVariant: Color(0xFF404D9A),
      outline: Color(0xFFB0BEC5),
      shadow: Color(0x1F000000),
      scrim: Color(0x42000000),
      inverseSurface: Color(0xFF1B1B1B),
      onInverseSurface: Colors.white,
      inversePrimary: Color(0xFF95A0FF),
      background: Color(0xFFFFFFFF),
      onBackground: Color(0xFF1B1B1B),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        labelStyle: TextStyle(color: scheme.onSurface),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: const StadiumBorder(),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          shape: const StadiumBorder(),
        ),
      ),
      iconTheme: IconThemeData(color: scheme.secondary),
      cardColor: scheme.surface,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFF1B1B1B)),
        bodySmall: TextStyle(color: Color(0xFF404D9A)),
        titleMedium: TextStyle(color: Color(0xFF1B1B1B)),
      ),
    );
  }

  /// Dark color scheme tuned to the same palette.
  static ThemeData darkTheme() {
    // Dark mode mapping of the same blue palette
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF7185FF),
      onPrimary: Colors.white, // ensure strong icon contrast on primary surfaces
      primaryContainer: Color(0xFF4958D1),
      onPrimaryContainer: Colors.white,
      secondary: Color(0xFFA8B3FF),
      onSecondary: Color(0xFF101317),
      secondaryContainer: Color(0xFF3A4399),
      onSecondaryContainer: Colors.white,
      tertiary: Color(0xFFC0C8FF),
      onTertiary: Color(0xFF101317),
      tertiaryContainer: Color(0xFF2F366F),
      onTertiaryContainer: Colors.white,
      error: Color(0xFFCF6679),
      onError: Color(0xFF101317),
      errorContainer: Color(0xFF8C1D18),
      onErrorContainer: Color(0xFFFFFFFF),
      surface: Color(0xFF202224),
      onSurface: Color(0xFFE6E6E6),
      surfaceVariant: Color(0xFF2A2D2F),
      onSurfaceVariant: Color(0xFFB0B0B0),
      outline: Color(0xFF4D4D4D),
      shadow: Color(0xA0000000),
      scrim: Color(0x80000000),
      inverseSurface: Color(0xFFE6E6E6),
      onInverseSurface: Color(0xFF202224),
      inversePrimary: Color(0xFF95A0FF),
      background: Color(0xFF181A1B),
      onBackground: Color(0xFFE6E6E6),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: const StadiumBorder(),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          shape: const StadiumBorder(),
        ),
      ),
      iconTheme: IconThemeData(color: scheme.secondary),
      cardColor: scheme.surface,
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: scheme.onSurface),
        bodySmall: TextStyle(color: scheme.onSurfaceVariant),
        titleMedium: TextStyle(color: scheme.onSurface),
      ),
    );
  }
}
