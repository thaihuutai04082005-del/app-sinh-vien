import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Giao diện riêng của module Tìm trọ (xanh biển – trắng, mục 2.19).
/// Mọi màu, chữ, khoảng cách khai báo ở đây; màn hình của module chỉ dùng lại.
class TroColors {
  TroColors._();

  static const primary = Color(0xFF1565C0);
  static const primaryDark = Color(0xFF0D47A1);
  static const primaryLight = Color(0xFFE3F0FF);
  static const primarySoft = Color(0xFFBBD8FA);

  /// Chỉ để trang trí, không đặt chữ trắng lên màu này (không đủ tương phản).
  static const accent = Color(0xFF29B6F6);

  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF4F8FD);
  static const border = Color(0xFFD6E4F5);
  static const textPrimary = Color(0xFF0F1C2E);
  static const textSecondary = Color(0xFF5B6B80);
  static const textDisabled = Color(0xFFA9B6C6);
  static const buttonDisabled = Color(0xFFC9D6E6);
  static const skeleton = Color(0xFFE6EEF8);
  static const markerGrey = Color(0xFF64748B);

  static const success = Color(0xFF137333);
  static const successSoft = Color(0xFFE8F6EE);
  static const warning = Color(0xFFB45309);
  static const warningSoft = Color(0xFFFFF4E0);
  static const danger = Color(0xFFC62828);
  static const dangerSoft = Color(0xFFFDECEC);
}

/// Lưới 4 điểm: khoảng cách chỉ dùng các giá trị này.
class TroSpacing {
  TroSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Lề màn hình và khoảng cách giữa các thẻ.
  static const double screen = 16;
  static const double cardGap = 12;
}

class TroRadius {
  TroRadius._();

  static const double button = 12;
  static const double card = 16;
  static const double input = 12;
  static const double sheet = 24;
  static const double pill = 999;
}

/// Kiểu chữ (mục 2.19). Màu mặc định `textPrimary`, riêng `price` là `primary`.
class TroText {
  TroText._();

  static const display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: TroColors.textPrimary,
  );
  static const h1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: TroColors.textPrimary,
  );
  static const h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: TroColors.textPrimary,
  );
  static const h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: TroColors.textPrimary,
  );
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: TroColors.textPrimary,
  );
  static const bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: TroColors.textSecondary,
  );
  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: TroColors.textPrimary,
  );
  static const price = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: TroColors.primary,
  );
}

class TroTheme {
  TroTheme._();

  /// Font Be Vietnam Pro tải qua mạng; [webFont] = false (dùng trong test) thì
  /// dùng font mặc định của hệ thống.
  /// Mặc định bật; test đặt false để không tải font qua mạng.
  @visibleForTesting
  static bool webFontEnabled = true;

  static ThemeData data({bool? webFont}) {
    webFont ??= webFontEnabled;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: TroColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: TroColors.primary,
          onPrimary: TroColors.white,
          primaryContainer: TroColors.primaryLight,
          onPrimaryContainer: TroColors.primaryDark,
          secondary: TroColors.primary,
          surface: TroColors.white,
          onSurface: TroColors.textPrimary,
          onSurfaceVariant: TroColors.textSecondary,
          outline: TroColors.border,
          outlineVariant: TroColors.border,
          error: TroColors.danger,
          onError: TroColors.white,
          errorContainer: TroColors.dangerSoft,
          onErrorContainer: TroColors.danger,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: TroColors.background,
    );
    final textTheme =
        (webFont
                ? GoogleFonts.beVietnamProTextTheme(base.textTheme)
                : base.textTheme)
            .apply(
              bodyColor: TroColors.textPrimary,
              displayColor: TroColors.textPrimary,
            );

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(TroRadius.input),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: TroColors.white,
        foregroundColor: TroColors.textPrimary,
        surfaceTintColor: TroColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: TroColors.primary),
        titleTextStyle: TroText.h2.copyWith(
          fontFamily: textTheme.bodyMedium?.fontFamily,
        ),
      ),
      cardTheme: CardThemeData(
        color: TroColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TroRadius.card),
          side: const BorderSide(color: TroColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TroColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TroSpacing.lg,
          vertical: TroSpacing.md,
        ),
        border: border(TroColors.border),
        enabledBorder: border(TroColors.border),
        focusedBorder: border(TroColors.primary, 1.5),
        errorBorder: border(TroColors.danger),
        focusedErrorBorder: border(TroColors.danger, 1.5),
        errorStyle: const TextStyle(color: TroColors.danger),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          backgroundColor: TroColors.primary,
          foregroundColor: TroColors.white,
          disabledBackgroundColor: TroColors.buttonDisabled,
          disabledForegroundColor: TroColors.white,
          textStyle: TroText.label,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TroRadius.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          foregroundColor: TroColors.primary,
          backgroundColor: TroColors.white,
          side: const BorderSide(color: TroColors.primary, width: 1.5),
          textStyle: TroText.label,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TroRadius.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: TroColors.primary,
          textStyle: TroText.label,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: TroColors.white,
        selectedColor: TroColors.primaryLight,
        checkmarkColor: TroColors.primary,
        side: const BorderSide(color: TroColors.border),
        labelStyle: TroText.label,
        shape: const StadiumBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? TroColors.white
              : TroColors.textDisabled,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? TroColors.primary
              : TroColors.border,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? TroColors.primary : null,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: TroColors.textPrimary,
        contentTextStyle: const TextStyle(color: TroColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TroRadius.button),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: TroColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(TroRadius.sheet),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: TroColors.border, space: 1),
    );
  }

  /// Đổ bóng nhẹ màu xanh (8%) cho thẻ và thanh dưới cùng.
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: TroColors.primary.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
