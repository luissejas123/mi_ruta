import 'package:flutter/material.dart';

/// Colores semánticos de la app para modo claro y oscuro.
///
/// Usar `AppColors.of(context)` en vez de `Colors.white` / `Colors.black87`
/// fijos: así el texto y los fondos cambian solos con el tema y mantienen
/// contraste legible (mínimo 4.5:1 para texto, criterio WCAG AA).
///
/// El amarillo de marca (`brand`) es para fondos y botones (con texto
/// negro encima). Para TEXTO amarillo usar `accentText`: en modo claro es un
/// ámbar oscuro, porque el amarillo puro sobre blanco no se lee (1.7:1).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color brand;
  final Color onBrand;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentText;
  final Color success;
  final Color danger;
  final Color info;
  final Color warning;

  const AppColors({
    required this.brand,
    required this.onBrand,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.accentText,
    required this.success,
    required this.danger,
    required this.info,
    required this.warning,
  });

  static const brandYellow = Color(0xFFFFC12F);

  static const light = AppColors(
    brand: brandYellow,
    onBrand: Color(0xFF1A1A1A),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF4F4F5),
    border: Color(0xFFE0E0E0),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF5F6368),
    accentText: Color(0xFF8A5A00),
    success: Color(0xFF1B7F3B),
    danger: Color(0xFFC62828),
    info: Color(0xFF1565C0),
    warning: Color(0xFFB45309),
  );

  static const dark = AppColors(
    brand: brandYellow,
    onBrand: Color(0xFF1A1A1A),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceMuted: Color(0xFF2A2A2A),
    border: Color(0xFF3A3A3A),
    textPrimary: Color(0xFFF2F2F2),
    textSecondary: Color(0xFFB8B8B8),
    accentText: brandYellow,
    success: Color(0xFF81C784),
    danger: Color(0xFFEF9A9A),
    info: Color(0xFF90CAF9),
    warning: Color(0xFFFFB74D),
  );

  /// Colores del tema actual. Si por algún motivo la extensión no está
  /// registrada, se elige según el brillo del tema.
  static AppColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  AppColors copyWith({
    Color? brand,
    Color? onBrand,
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? accentText,
    Color? success,
    Color? danger,
    Color? info,
    Color? warning,
  }) {
    return AppColors(
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accentText: accentText ?? this.accentText,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      brand: Color.lerp(brand, other.brand, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}
