import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kSeed = Color(0xFF1F5E3F);
const Color kCaramel = Color(0xFF8A6D3B);
const Color kBackground = Color(0xFFFAF9F4);
const Color kAgaveBright = Color(0xFF2F7D55);

const List<FontFeature> kTabular = [FontFeature.tabularFigures()];

ColorScheme _scheme(Brightness brightness) {
  final base = ColorScheme.fromSeed(seedColor: kSeed, brightness: brightness);
  if (brightness == Brightness.dark) {
    return base.copyWith(
      secondary: const Color(0xFFD3B77F),
      onSecondary: const Color(0xFF4A3607),
      secondaryContainer: const Color(0xFF5C4A20),
      onSecondaryContainer: const Color(0xFFF1E2C3),
    );
  }
  return base.copyWith(
    secondary: kCaramel,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFF1E2C3),
    onSecondaryContainer: const Color(0xFF4E3512),
  );
}

ThemeData buildAppTheme(Brightness brightness) {
  final scheme = _scheme(brightness);
  final isDark = brightness == Brightness.dark;
  final inter = GoogleFonts.inter().fontFamily;
  final cardColor = isDark ? scheme.surfaceContainerLow : Colors.white;

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: inter,
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF11140F) : kBackground,
    appBarTheme: AppBarTheme(
      backgroundColor:
          isDark ? kAgaveBright : scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: scheme.onPrimary,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 1,
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? scheme.surfaceContainerLow : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardColor,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        );
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: cardColor,
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
      unselectedIconTheme:
          IconThemeData(color: scheme.onSurfaceVariant),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    textTheme: _tabular(ThemeData(brightness: brightness)
        .textTheme
        .apply(fontFamily: inter)),
  );
}

TextTheme _tabular(TextTheme t) {
  TextStyle fix(TextStyle? s) => (s ?? const TextStyle()).copyWith(
        fontFeatures: kTabular,
      );
  return TextTheme(
    displayLarge: fix(t.displayLarge),
    displayMedium: fix(t.displayMedium),
    displaySmall: fix(t.displaySmall),
    headlineLarge: fix(t.headlineLarge),
    headlineMedium: fix(t.headlineMedium),
    headlineSmall: fix(t.headlineSmall)
        .copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
    titleLarge: fix(t.titleLarge).copyWith(fontWeight: FontWeight.w600),
    titleMedium: fix(t.titleMedium).copyWith(fontWeight: FontWeight.w600),
    titleSmall: fix(t.titleSmall),
    bodyLarge: fix(t.bodyLarge),
    bodyMedium: fix(t.bodyMedium),
    bodySmall: fix(t.bodySmall),
    labelLarge: fix(t.labelLarge),
    labelMedium: fix(t.labelMedium),
    labelSmall: fix(t.labelSmall),
  );
}