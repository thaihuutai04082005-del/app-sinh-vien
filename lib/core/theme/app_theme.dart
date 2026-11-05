import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  /// Thẻ phẳng, ô nhập bo tròn, thanh tiêu đề cùng màu nền
  /// (lấy từ khung UniHub cũ).
  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final colors = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    );
    final background = isLight ? AppColors.background : colors.surface;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.outlineVariant),
    );

    return ThemeData(
      colorScheme: colors,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isLight ? Colors.white : colors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : colors.surfaceContainerHigh,
        border: border,
        enabledBorder: border,
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(
          isLight ? Colors.white : colors.surfaceContainerHigh,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: colors.outlineVariant)),
      ),
    );
  }
}
