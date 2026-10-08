import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Giao diện riêng của module Quán ăn (xanh biển – trắng, mục 3.19).
/// Mọi màu, chữ, khoảng cách khai báo ở đây; màn hình của module chỉ dùng lại.
class QuanAnColors {
  QuanAnColors._();

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

  /// Nền huy hiệu nhãn xác minh đánh giá 🛵 🍽 📍 (xám xanh nhạt, chữ `primary`; mục 3.19 "Huy hiệu").
  static const labelSoft = Color(0xFFEAF0F8);

  /// Chấm điểm gốc trên bản đồ (`accent` có quầng sáng; mục 3.19 "Bản đồ").
  static const originDot = accent;

  /// Thông tin chung (dùng lại màu chính; mục 3.19 "Màu trạng thái").
  static const info = primary;
  static const infoSoft = primaryLight;

  static const success = Color(0xFF137333);
  static const successSoft = Color(0xFFE8F6EE);
  static const warning = Color(0xFFB45309);
  static const warningSoft = Color(0xFFFFF4E0);
  static const danger = Color(0xFFC62828);
  static const dangerSoft = Color(0xFFFDECEC);
}

/// Lưới 4 điểm: khoảng cách chỉ dùng các giá trị này.
class QuanAnSpacing {
  QuanAnSpacing._();

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

class QuanAnRadius {
  QuanAnRadius._();

  static const double button = 12;
  static const double card = 16;
  static const double input = 12;
  static const double sheet = 24;
  static const double pill = 999;
}

/// Kiểu chữ (mục 3.19). Màu mặc định `textPrimary`, riêng `price` là `primary`.
class QuanAnText {
  QuanAnText._();

  static const display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: QuanAnColors.textPrimary,
  );
  static const h1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: QuanAnColors.textPrimary,
  );
  static const h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: QuanAnColors.textPrimary,
  );
  static const h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: QuanAnColors.textPrimary,
  );
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: QuanAnColors.textPrimary,
  );
  static const bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: QuanAnColors.textSecondary,
  );
  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: QuanAnColors.textPrimary,
  );
  static const price = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: QuanAnColors.primary,
  );
}

class QuanAnTheme {
  QuanAnTheme._();

  /// Font Be Vietnam Pro tải qua mạng; [webFont] = false (dùng trong test) thì
  /// dùng font mặc định của hệ thống.
  /// Mặc định bật; test đặt false để không tải font qua mạng.
  @visibleForTesting
  static bool webFontEnabled = true;

  static ThemeData data({bool? webFont}) {
    webFont ??= webFontEnabled;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: QuanAnColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: QuanAnColors.primary,
          onPrimary: QuanAnColors.white,
          primaryContainer: QuanAnColors.primaryLight,
          onPrimaryContainer: QuanAnColors.primaryDark,
          secondary: QuanAnColors.primary,
          surface: QuanAnColors.white,
          onSurface: QuanAnColors.textPrimary,
          onSurfaceVariant: QuanAnColors.textSecondary,
          outline: QuanAnColors.border,
          outlineVariant: QuanAnColors.border,
          error: QuanAnColors.danger,
          onError: QuanAnColors.white,
          errorContainer: QuanAnColors.dangerSoft,
          onErrorContainer: QuanAnColors.danger,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: QuanAnColors.background,
    );
    final textTheme =
        (webFont
                ? GoogleFonts.beVietnamProTextTheme(base.textTheme)
                : base.textTheme)
            .apply(
              bodyColor: QuanAnColors.textPrimary,
              displayColor: QuanAnColors.textPrimary,
            );

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(QuanAnRadius.input),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: QuanAnColors.white,
        foregroundColor: QuanAnColors.textPrimary,
        surfaceTintColor: QuanAnColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: QuanAnColors.primary),
        titleTextStyle: QuanAnText.h2.copyWith(
          fontFamily: textTheme.bodyMedium?.fontFamily,
        ),
      ),
      cardTheme: CardThemeData(
        color: QuanAnColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QuanAnRadius.card),
          side: const BorderSide(color: QuanAnColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: QuanAnColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: QuanAnSpacing.lg,
          vertical: QuanAnSpacing.md,
        ),
        border: border(QuanAnColors.border),
        enabledBorder: border(QuanAnColors.border),
        focusedBorder: border(QuanAnColors.primary, 1.5),
        errorBorder: border(QuanAnColors.danger),
        focusedErrorBorder: border(QuanAnColors.danger, 1.5),
        errorStyle: const TextStyle(color: QuanAnColors.danger),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          backgroundColor: QuanAnColors.primary,
          foregroundColor: QuanAnColors.white,
          disabledBackgroundColor: QuanAnColors.buttonDisabled,
          disabledForegroundColor: QuanAnColors.white,
          textStyle: QuanAnText.label,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(QuanAnRadius.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          foregroundColor: QuanAnColors.primary,
          backgroundColor: QuanAnColors.white,
          side: const BorderSide(color: QuanAnColors.primary, width: 1.5),
          textStyle: QuanAnText.label,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(QuanAnRadius.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: QuanAnColors.primary,
          textStyle: QuanAnText.label,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: QuanAnColors.white,
        selectedColor: QuanAnColors.primaryLight,
        checkmarkColor: QuanAnColors.primary,
        side: const BorderSide(color: QuanAnColors.border),
        labelStyle: QuanAnText.label,
        shape: const StadiumBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? QuanAnColors.white
              : QuanAnColors.textDisabled,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? QuanAnColors.primary
              : QuanAnColors.border,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? QuanAnColors.primary : null,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: QuanAnColors.textPrimary,
        contentTextStyle: const TextStyle(color: QuanAnColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QuanAnRadius.button),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: QuanAnColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(QuanAnRadius.sheet),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: QuanAnColors.border,
        space: 1,
      ),
    );
  }

  /// Đổ bóng nhẹ màu xanh (8%) cho thẻ và thanh dưới cùng.
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: QuanAnColors.primary.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
