import 'package:flutter/material.dart';
import 'package:mi_ruta/core/theme/app_colors.dart';

/// Temas claro y oscuro de Mi Ruta.
///
/// Todos los componentes (tarjetas, diálogos, botones, chips, campos de
/// texto, snackbars) toman sus colores de [AppColors] para que el modo
/// oscuro no deje texto negro sobre fondo oscuro ni texto blanco sobre
/// fondo blanco.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light, AppColors.light);

  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandYellow,
      brightness: brightness,
    ).copyWith(
      primary: c.brand,
      onPrimary: c.onBrand,
      secondary: c.brand,
      onSecondary: c.onBrand,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      outline: c.border,
      error: c.danger,
    );

    final textTheme = TextTheme(
      displaySmall: TextStyle(color: c.textPrimary),
      headlineMedium: TextStyle(color: c.textPrimary),
      headlineSmall: TextStyle(color: c.textPrimary),
      titleLarge: TextStyle(color: c.textPrimary),
      titleMedium: TextStyle(color: c.textPrimary),
      titleSmall: TextStyle(color: c.textSecondary),
      bodyLarge: TextStyle(color: c.textPrimary),
      bodyMedium: TextStyle(color: c.textPrimary),
      bodySmall: TextStyle(color: c.textSecondary),
      labelLarge: TextStyle(color: c.textPrimary),
      labelMedium: TextStyle(color: c.textSecondary),
      labelSmall: TextStyle(color: c.textSecondary),
    );

    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [c],
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      cardColor: c.surface,
      dividerColor: c.border,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: c.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.accentText,
        unselectedItemColor: c.textSecondary,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: rounded,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(color: c.textPrimary, fontSize: 15),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        textColor: c.textPrimary,
        iconColor: c.textSecondary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceMuted,
        labelStyle: TextStyle(color: c.textPrimary),
        side: BorderSide(color: c.border),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF2E2E2E)
            : const Color(0xFF323232),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: c.textSecondary),
        labelStyle: TextStyle(color: c.textSecondary),
        prefixIconColor: c.textSecondary,
        suffixIconColor: c.textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.brand,
          foregroundColor: c.onBrand,
          disabledBackgroundColor: c.brand.withValues(alpha: 0.45),
          disabledForegroundColor: c.onBrand.withValues(alpha: 0.6),
          shape: rounded,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.border),
          shape: rounded,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.accentText),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.brand,
        foregroundColor: c.onBrand,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.brand),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.brand : null,
        ),
      ),
    );
  }
}
