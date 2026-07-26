import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_motion.dart';
import 'app_palette.dart';
import 'app_typography.dart';

/// Assembles the light and dark [ThemeData] from the design tokens.
///
/// Both themes share the same shapes, spacing and motion; only the surface and
/// text ramps differ, which is what keeps the app recognisable in either mode.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final surface = isDark ? AppPalette.night : AppPalette.dawn;
    final card = isDark ? AppPalette.nightCard : AppPalette.dawnCard;
    final border = isDark ? AppPalette.nightBorder : AppPalette.dawnBorder;
    final textStrong = isDark ? AppPalette.onDark : AppPalette.inkStrong;
    final textMuted = isDark ? AppPalette.onDarkMuted : AppPalette.inkMuted;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppPalette.violetLight : AppPalette.violet,
      onPrimary: isDark ? AppPalette.night : Colors.white,
      primaryContainer: isDark ? AppPalette.violetDark : AppPalette.violetSoft,
      onPrimaryContainer: isDark ? AppPalette.onDark : AppPalette.violetDark,
      secondary: AppPalette.teal,
      onSecondary: isDark ? AppPalette.night : Colors.white,
      secondaryContainer:
          isDark ? AppPalette.tealDark : const Color(0xFFD8F7F5),
      onSecondaryContainer: isDark ? AppPalette.onDark : AppPalette.tealDark,
      tertiary: AppPalette.amber,
      onTertiary: const Color(0xFF3A2400),
      tertiaryContainer: isDark ? AppPalette.amberDark : AppPalette.amberLight,
      onTertiaryContainer: const Color(0xFF3A2400),
      error: AppPalette.coral,
      onError: Colors.white,
      errorContainer: isDark ? const Color(0xFF6B2020) : const Color(0xFFFFE1E1),
      onErrorContainer: isDark ? AppPalette.onDark : const Color(0xFF7A1B1B),
      surface: surface,
      onSurface: textStrong,
      surfaceContainerLowest: isDark ? const Color(0xFF07091C) : Colors.white,
      surfaceContainerLow: isDark ? AppPalette.nightElevated : Colors.white,
      surfaceContainer: card,
      surfaceContainerHigh:
          isDark ? const Color(0xFF232760) : const Color(0xFFF1EEFF),
      surfaceContainerHighest:
          isDark ? const Color(0xFF2A2E6B) : const Color(0xFFEAE6FB),
      onSurfaceVariant: textMuted,
      outline: border,
      outlineVariant: isDark ? const Color(0xFF232760) : const Color(0xFFEFECFA),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? AppPalette.dawn : AppPalette.night,
      onInverseSurface: isDark ? AppPalette.inkStrong : AppPalette.onDark,
      inversePrimary: isDark ? AppPalette.violet : AppPalette.violetLight,
    );

    final text = AppTypography.textTheme(textStrong, textMuted);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: text,
      fontFamily: AppTypography.body,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: text.headlineSmall,
        iconTheme: IconThemeData(color: textStrong),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: border),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          foregroundColor: scheme.primary,
          side: BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: BorderSide(color: border),
        ),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: textMuted.withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppPalette.nightBorder : AppPalette.inkStrong,
        contentTextStyle: text.bodyMedium?.copyWith(color: AppPalette.onDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? scheme.primary
              : border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: border,
        circularTrackColor: border,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
