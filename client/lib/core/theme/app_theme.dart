import 'package:flutter/material.dart';

/// Semantic status colors used throughout the RDMS application.
@immutable
class RdmsStatusColors extends ThemeExtension<RdmsStatusColors> {
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;

  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  const RdmsStatusColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  static const light = RdmsStatusColors(
    success: Color(0xFF166534),
    onSuccess: Colors.white,
    successContainer: Color(0xFFECFDF3),
    onSuccessContainer: Color(0xFF166534),
    warning: Color(0xFF92400E),
    onWarning: Colors.white,
    warningContainer: Color(0xFFFFFBEB),
    onWarningContainer: Color(0xFF92400E),
    error: Color(0xFFB91C1C),
    onError: Colors.white,
    errorContainer: Color(0xFFFEF2F2),
    onErrorContainer: Color(0xFFB91C1C),
    info: Color(0xFF1D4ED8),
    onInfo: Colors.white,
    infoContainer: Color(0xFFEFF6FF),
    onInfoContainer: Color(0xFF1D4ED8),
  );

  static const dark = RdmsStatusColors(
    success: Color(0xFF86EFAC),
    onSuccess: Color(0xFF052E16),
    successContainer: Color(0xFF123522),
    onSuccessContainer: Color(0xFF86EFAC),
    warning: Color(0xFFFCD34D),
    onWarning: Color(0xFF451A03),
    warningContainer: Color(0xFF392D12),
    onWarningContainer: Color(0xFFFCD34D),
    error: Color(0xFFFCA5A5),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF3D1C25),
    onErrorContainer: Color(0xFFFCA5A5),
    info: Color(0xFF93C5FD),
    onInfo: Color(0xFF172554),
    infoContainer: Color(0xFF172F52),
    onInfoContainer: Color(0xFF93C5FD),
  );

  @override
  RdmsStatusColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
  }) {
    return RdmsStatusColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    );
  }

  @override
  RdmsStatusColors lerp(ThemeExtension<RdmsStatusColors>? other, double t) {
    if (other is! RdmsStatusColors) return this;
    return RdmsStatusColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onErrorContainer: Color.lerp(
        onErrorContainer,
        other.onErrorContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
    );
  }
}

/// Centralized application theme and design tokens for RDMS Ultimate.
class AppTheme {
  const AppTheme._();

  // Spacing Scale
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // Radii
  static const double radiusChip = 8.0;
  static const double radiusControl = 12.0;
  static const double radiusPanel = 16.0;
  static const double radiusDialog = 24.0;

  // Motion Durations
  static const Duration durationFeedback = Duration(milliseconds: 120);
  static const Duration durationSelection = Duration(milliseconds: 180);
  static const Duration durationOverlay = Duration(milliseconds: 240);

  // Light Palette
  static const Color lightScaffold = Color(0xFFF6F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightRaisedSurface = Color(0xFFEEF2F8);
  static const Color lightPrimary = Color(0xFF0F52BA);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFEAF1FF);
  static const Color lightOnPrimaryContainer = Color(0xFF153E75);
  static const Color lightPrimaryText = Color(0xFF172338);
  static const Color lightSecondaryText = Color(0xFF526176);
  static const Color lightSeparator = Color(0xFFDCE3EE);
  static const Color lightOutline = Color(0xFF718096);

  // Dark Palette
  static const Color darkScaffold = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF111C2E);
  static const Color darkRaisedSurface = Color(0xFF1A2940);
  static const Color darkPrimary = Color(0xFF93B8FF);
  static const Color darkOnPrimary = Color(0xFF08234F);
  static const Color darkPrimaryContainer = Color(0xFF18335E);
  static const Color darkOnPrimaryContainer = Color(0xFFDCE8FF);
  static const Color darkPrimaryText = Color(0xFFF0F4FC);
  static const Color darkSecondaryText = Color(0xFFB2BED1);
  static const Color darkSeparator = Color(0xFF2B3B53);
  static const Color darkOutline = Color(0xFF8191AB);

  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme.light(
      primary: lightPrimary,
      onPrimary: lightOnPrimary,
      primaryContainer: lightPrimaryContainer,
      onPrimaryContainer: lightOnPrimaryContainer,
      surface: lightSurface,
      onSurface: lightPrimaryText,
      surfaceContainerHighest: lightRaisedSurface,
      outline: lightOutline,
      outlineVariant: lightSeparator,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBg: lightScaffold,
      cardColor: lightSurface,
      dividerColor: lightSeparator,
      statusColors: RdmsStatusColors.light,
      brightness: Brightness.light,
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = const ColorScheme.dark(
      primary: darkPrimary,
      onPrimary: darkOnPrimary,
      primaryContainer: darkPrimaryContainer,
      onPrimaryContainer: darkOnPrimaryContainer,
      surface: darkSurface,
      onSurface: darkPrimaryText,
      surfaceContainerHighest: darkRaisedSurface,
      outline: darkOutline,
      outlineVariant: darkSeparator,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBg: darkScaffold,
      cardColor: darkSurface,
      dividerColor: darkSeparator,
      statusColors: RdmsStatusColors.dark,
      brightness: Brightness.dark,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required Color cardColor,
    required Color dividerColor,
    required RdmsStatusColors statusColors,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final primaryTextColor = isDark ? darkPrimaryText : lightPrimaryText;
    final secondaryTextColor = isDark ? darkSecondaryText : lightSecondaryText;

    final textTheme = TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 21 / 14,
        fontWeight: FontWeight.w400,
        color: primaryTextColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 18 / 12,
        fontWeight: FontWeight.w400,
        color: secondaryTextColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 18 / 12,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: cardColor,
      dividerColor: dividerColor,
      textTheme: textTheme,
      extensions: [statusColors],
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF162238) : const Color(0xFFFFFFFF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: statusColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: statusColors.error, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusControl),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusControl),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusControl),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: dividerColor),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusDialog),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusDialog),
          ),
        ),
      ),
      focusColor: colorScheme.primary.withValues(alpha: 0.12),
    );
  }
}
