import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  // ===========================================================================
  // BASE COLORS (Source of truth from core/theme/app_theme.dart)
  // ===========================================================================
  static const Color bg = Color(0xFFF6F9FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF0F5FF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3EAF6);
  static const Color accentBlue = Color(0xFF3B7CFF);
  static const Color accentBlueDark = Color(0xFF2E66F2);
  static const Color primaryLight = Color(0xFFDCE8FF);
  static const Color primarySoft = Color(0xFFEAF2FF);
  static const Color success = Color(0xFF1DBE74);
  static const Color successLight = Color(0xFFE3F8EE);
  static const Color warning = Color(0xFFF3A638);
  static const Color warningLight = Color(0xFFFFF2D5);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFFE3E3);
  static const Color textPrimary = Color(0xFF0F1C2E);
  static const Color textSecondary = Color(0xFF4B5A73);
  static const Color textMuted = Color(0xFF8C97AE);
  static const Color textSoft = Color(0xFFB6C0D3);
  static const Color shadow = Color(0x140F172A);

  // ===========================================================================
  // LEGACY COLORS (Imported from lib/theme/app_theme.dart - Documented Variants)
  // ===========================================================================
  static const Color primaryBlue = Color(0xFF567DDD); // Variant of accentBlue
  // primaryBlueDark is defined above as accentBlueDark, but we keep the lib variant color:
  static const Color altPrimaryBlueDark = Color(0xFF3B5FC0);
  static const Color background = Color(0xFFFFFFFF); // Same as surface
  // 'card' is identical (0xFFFFFFFF)
  static const Color altSuccess = Color(0xFF3CA95D);
  static const Color successTint = Color(0xFFD1FAE5);
  static const Color altWarning = Color(0xFFF39D0B);
  static const Color darkText = Color(0xFF1E293B); // Variant of textPrimary
  static const Color lightTint = Color(0xFFEEF2FF);
  static const Color error = Color(0xFFEF4444); // Identical to danger
  static const Color errorTint = Color(0xFFFEE2E2);
  static const Color subtitle = Color(0xFF64748B); // Variant of textSecondary
  static const Color divider = Color(0xFFE2E8F0); // Variant of border
  static const Color hint = Color(0xFF94A3B8); // Variant of textMuted
  static const Color white = Color(0xFFFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white40 = Color(0x66FFFFFF);
  static const Color shadowColor = Color(0x0F000000);
  static const Color transparent = Color(0x001E293B);
  static const Color overlayDark = Color(0x991E293B);

  // ===========================================================================
  // BORDER RADII
  // ===========================================================================
  // Core properties
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 24;
  // Lib unique variants
  static const double radiusCard = 16;
  static const double radiusButton = 12;
  static const double radiusChip = 24;
  static const double radiusAvatar = 100;
  static const double radiusInput = 12;

  // ===========================================================================
  // SPACING SCALES
  // ===========================================================================
  // Core properties
  static const double space1 = 6;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;

  // Lib variants (Remapped to prevent conflicts with core space1-6)
  static const double altSpace1 = 8;
  static const double altSpace2 = 16;
  static const double altSpace3 = 24;
  static const double altSpace4 = 32;
  static const double altSpace5 = 40;
  static const double altSpace6 = 48;

  // ===========================================================================
  // PADDING (Core)
  // ===========================================================================
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(
    space4,
    space2,
    space4,
    space6,
  );
  static const EdgeInsets pagePaddingTight = EdgeInsets.fromLTRB(
    space4,
    space1,
    space4,
    space6,
  );
  static const EdgeInsets pagePaddingDense = EdgeInsets.fromLTRB(
    space4,
    space3,
    space4,
    space6,
  );
  static const EdgeInsets headerPadding = EdgeInsets.fromLTRB(
    space4,
    space3,
    space4,
    space2,
  );
  static const EdgeInsets authPadding = EdgeInsets.symmetric(
    horizontal: space4,
    vertical: space3,
  );
  static const EdgeInsets authPaddingTight = EdgeInsets.symmetric(
    horizontal: space4,
    vertical: space2,
  );
  static const EdgeInsets onboardingPadding = EdgeInsets.symmetric(
    horizontal: space5,
    vertical: space5,
  );

  // ===========================================================================
  // GRADIENTS & SHADOWS
  // ===========================================================================
  // Core
  static const LinearGradient primaryGradient = LinearGradient(
    colors: <Color>[accentBlue, Color(0xFF6FA2FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: <Color>[bg, Color(0xFFF0F5FF), primarySoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static final List<BoxShadow> cardShadow = <BoxShadow>[
    const BoxShadow(color: shadow, blurRadius: 18, offset: Offset(0, 8)),
  ];

  // Lib
  static const List<BoxShadow> softShadow = <BoxShadow>[
    BoxShadow(color: shadowColor, blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const LinearGradient splashGradient = LinearGradient(
    colors: <Color>[primaryBlue, lightTint],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient headerGradient = LinearGradient(
    colors: <Color>[primaryBlue, altPrimaryBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===========================================================================
  // TYPOGRAPHY (Lib GoogleFonts.inter specific styles)
  // ===========================================================================
  static final TextStyle h1 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: darkText,
  );
  static final TextStyle h2 = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: darkText,
  );
  static final TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: darkText,
  );
  static final TextStyle subtitleStyle = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: subtitle,
  );
  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: subtitle,
  );
  static final TextStyle label = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: darkText,
  );
  static final TextStyle button = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: white,
  );
  static final TextStyle screenTitle = GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: darkText,
  );
  static final TextStyle brandTitle = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: darkText,
  );
  static final TextStyle profileTitle = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: darkText,
  );

  // ===========================================================================
  // COMPONENT THEMES (Light Mode Modular Functions)
  // ===========================================================================

  static TextTheme _buildLightTextTheme(ThemeData base) {
    // Merged approach: Core uses Poppins, which acts as the source of truth for standard UI.
    return GoogleFonts.poppinsTextTheme(base.textTheme)
        .copyWith(
          headlineLarge: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.6,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.4,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          titleSmall: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textPrimary,
            height: 1.45,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textSecondary,
            height: 1.45,
          ),
          bodySmall: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
          labelLarge: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        )
        .apply(bodyColor: textPrimary, displayColor: textPrimary);
  }

  static AppBarTheme _buildLightAppBarTheme() {
    return AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true, // Prioritize core
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0.5,
      shadowColor: shadow,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    );
  }

  static CardThemeData _buildLightCardTheme() {
    return CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          radiusLg,
        ), // Prioritizes radiusLg from Core over radiusCard
        side: const BorderSide(color: border, width: 1),
      ),
      margin: EdgeInsets.zero,
    );
  }

  static InputDecorationTheme _buildLightInputDecorationTheme() {
    // Merged Input Decoration (Preserving core logic but ensuring lib variants are acknowledged)
    return InputDecorationTheme(
      filled: true,
      fillColor:
          surface, // Lib uses lightTint, Core uses surface. Prioritizing Core.
      hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      labelStyle: const TextStyle(color: textSecondary),
      floatingLabelStyle: const TextStyle(
        color: accentBlue,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: space4,
        vertical: space3,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: accentBlue, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: danger),
      ),
    );
  }

  // Fallback explicit component from lib (for manual use if needed)
  static final InputDecorationTheme legacyLibInputDecorationTheme =
      InputDecorationTheme(
        filled: true,
        fillColor: lightTint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: hint,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: darkText,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: altSpace2,
          vertical: 14,
        ),
      );

  static ElevatedButtonThemeData _buildLightElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: shadow,
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: space5),
      ),
    );
  }

  static FilledButtonThemeData _buildLightFilledButtonTheme() {
    // From Lib directly since Core doesn't define FilledButtonThemeData
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor:
            accentBlue, // Changed from primaryBlue to align with Core
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
        ),
        textStyle: button, // Using Inter button typography as requested by lib
      ),
    );
  }

  static OutlinedButtonThemeData _buildLightOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentBlue,
        side: const BorderSide(color: border, width: 1.2), // Core border
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: space5),
      ),
    );
  }

  // ===========================================================================
  // LIGHT & DARK THEMEDATA
  // ===========================================================================

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: card,
      dividerColor: border,
      colorScheme: const ColorScheme.light(
        primary: accentBlue,
        secondary: accentBlue,
        surface: surface,
        error: danger,
        onPrimary: Colors.white,
        onSurface: textPrimary,
        outline: border,
        surfaceTint: accentBlue,
      ),
      textTheme: _buildLightTextTheme(base),
      appBarTheme: _buildLightAppBarTheme(),
      cardTheme: _buildLightCardTheme(),
      inputDecorationTheme: _buildLightInputDecorationTheme(),
      elevatedButtonTheme: _buildLightElevatedButtonTheme(),
      filledButtonTheme: _buildLightFilledButtonTheme(),
      outlinedButtonTheme: _buildLightOutlinedButtonTheme(),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentBlue,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primarySoft,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? accentBlue : textMuted,
            size: 24,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primarySoft,
        disabledColor: surfaceAlt,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
        secondaryLabelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: accentBlue,
        ),
        side: const BorderSide(color: border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: space2,
          vertical: space1,
        ),
        checkmarkColor: accentBlue,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textMuted,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: primarySoft,
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: space3, vertical: 10),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const BorderSide(color: accentBlue, width: 1.2);
            }
            return const BorderSide(color: border, width: 1.1);
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? primarySoft
                : surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? accentBlue
                : textSecondary;
          }),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        dense: false,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentBlue,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentBlue;
          return surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentBlue.withValues(alpha: 0.35);
          }
          return border;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentBlue;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentBlue;
          return textMuted;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        space: 24,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: textSecondary, size: 24),
    );
  }
}
