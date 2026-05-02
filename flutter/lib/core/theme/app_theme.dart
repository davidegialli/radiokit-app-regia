import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary:    AppColors.accent,
        secondary:  AppColors.autoDj,
        surface:    AppColors.surface,
        error:      AppColors.accent,
        onPrimary:  Colors.white,
        onSurface:  AppColors.text,
      ),
      textTheme: _textTheme(base.textTheme),
      dividerColor: AppColors.hairlineSoft,
      cardColor: AppColors.surface,
      iconTheme: const IconThemeData(color: AppColors.text2, size: 18),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgElev,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgElev,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.text3,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.hairlineSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.hairlineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        hintStyle: const TextStyle(color: AppColors.text3, fontSize: 12),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    const family = 'Geist';
    return base.copyWith(
      displayLarge:  base.displayLarge?.copyWith (fontFamily: family, color: AppColors.text),
      displayMedium: base.displayMedium?.copyWith(fontFamily: family, color: AppColors.text),
      displaySmall:  base.displaySmall?.copyWith (fontFamily: family, color: AppColors.text),
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: family, color: AppColors.text, fontWeight: FontWeight.w600),
      headlineMedium:base.headlineMedium?.copyWith(fontFamily: family,color: AppColors.text, fontWeight: FontWeight.w600),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: family, color: AppColors.text, fontWeight: FontWeight.w600),
      titleLarge:    base.titleLarge?.copyWith   (fontFamily: family, color: AppColors.text, fontWeight: FontWeight.w600),
      titleMedium:   base.titleMedium?.copyWith  (fontFamily: family, color: AppColors.text, fontWeight: FontWeight.w500),
      titleSmall:    base.titleSmall?.copyWith   (fontFamily: family, color: AppColors.text2, fontWeight: FontWeight.w500),
      bodyLarge:     base.bodyLarge?.copyWith    (fontFamily: family, color: AppColors.text),
      bodyMedium:    base.bodyMedium?.copyWith   (fontFamily: family, color: AppColors.text2),
      bodySmall:     base.bodySmall?.copyWith    (fontFamily: family, color: AppColors.text3),
      labelLarge:    base.labelLarge?.copyWith   (fontFamily: family, color: AppColors.text2),
      labelMedium:   base.labelMedium?.copyWith  (fontFamily: family, color: AppColors.text3),
      labelSmall:    base.labelSmall?.copyWith   (fontFamily: 'GeistMono', color: AppColors.text3, letterSpacing: 1.2),
    );
  }

  static const TextStyle eyebrow = TextStyle(
    fontFamily: 'GeistMono',
    fontSize: 10,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w500,
    color: AppColors.text3,
  );

  static const TextStyle eyebrowStrong = TextStyle(
    fontFamily: 'GeistMono',
    fontSize: 10,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.text2,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: 'GeistMono',
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
