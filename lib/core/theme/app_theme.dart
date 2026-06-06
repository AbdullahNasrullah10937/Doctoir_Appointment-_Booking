import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  // ===========================================================================
  // QUREXA HEALTH DESIGN SYSTEM — PRIMARY PALETTE
  // ===========================================================================
  static const Color qPrimary      = Color(0xFF0B6E6E); // deep teal
  static const Color qPrimaryLight = Color(0xFFE6F4F4); // teal tint bg/chips
  static const Color qPrimaryDark  = Color(0xFF084F4F); // pressed/dark accents
  static const Color qAccent       = Color(0xFFF4845F); // warm coral — CTAs
  static const Color qSurface      = Color(0xFFFAFAF8); // warm off-white bg
  static const Color qCard         = Color(0xFFFFFFFF); // pure white cards
  static const Color qBorder       = Color(0xFFEFEFED); // very subtle borders
  static const Color qText         = Color(0xFF1A1A1A); // near-black headings
  static const Color qTextSec      = Color(0xFF6B7280); // muted body text
  static const Color qTextHint     = Color(0xFF9CA3AF); // placeholders
  static const Color qSuccess      = Color(0xFF22C55E); // available/confirmed
  static const Color qWarning      = Color(0xFFF59E0B); // pending/waiting
  static const Color qError        = Color(0xFFEF4444); // error/unavailable
  static const Color qStar         = Color(0xFFFBBF24); // star ratings

  // Available/Busy chip colours
  static const Color qAvailableBg  = Color(0xFFDCFCE7);
  static const Color qAvailableTxt = Color(0xFF15803D);
  static const Color qBusyBg       = Color(0xFFFEE2E2);
  static const Color qBusyTxt      = Color(0xFFDC2626);

  // ===========================================================================
  // LEGACY ALIASES — kept so existing code that references these doesn't break
  // ===========================================================================
  static const Color bg            = qSurface;
  static const Color surface       = qCard;
  static const Color surfaceAlt    = Color(0xFFF0F5FF);
  static const Color card          = qCard;
  static const Color border        = qBorder;
  static const Color accentBlue    = qPrimary;   // remapped to teal
  static const Color accentBlueDark = qPrimaryDark;
  static const Color primaryLight  = qPrimaryLight;
  static const Color primarySoft   = qPrimaryLight;
  static const Color success       = qSuccess;
  static const Color successLight  = qAvailableBg;
  static const Color warning       = qWarning;
  static const Color warningLight  = Color(0xFFFFF2D5);
  static const Color danger        = qError;
  static const Color dangerLight   = qBusyBg;
  static const Color textPrimary   = qText;
  static const Color textSecondary = qTextSec;
  static const Color textMuted     = qTextHint;
  static const Color textSoft      = Color(0xFFB6C0D3);
  static const Color shadow        = Color(0x120B6E6E);
  static const Color primaryBlue   = qPrimary;
  static const Color altPrimaryBlueDark = qPrimaryDark;
  static const Color background    = qCard;
  static const Color altSuccess    = qSuccess;
  static const Color successTint   = qAvailableBg;
  static const Color altWarning    = qWarning;
  static const Color darkText      = qText;
  static const Color lightTint     = qPrimaryLight;
  static const Color error         = qError;
  static const Color errorTint     = qBusyBg;
  static const Color subtitle      = qTextSec;
  static const Color divider       = qBorder;
  static const Color hint          = qTextHint;
  static const Color white         = Color(0xFFFFFFFF);
  static const Color white70       = Color(0xB3FFFFFF);
  static const Color white40       = Color(0x66FFFFFF);
  static const Color shadowColor   = Color(0x0F000000);
  static const Color transparent   = Color(0x001E293B);
  static const Color overlayDark   = Color(0x991E293B);

  // ===========================================================================
  // BORDER RADII
  // ===========================================================================
  static const double radiusSm     = 10;
  static const double radiusMd     = 14;
  static const double radiusLg     = 16; // card radius
  static const double radiusXl     = 24;
  static const double radiusCard   = 16;
  static const double radiusButton = 30; // pill buttons
  static const double radiusChip   = 20;
  static const double radiusAvatar = 100;
  static const double radiusInput  = 12;

  // ===========================================================================
  // SPACING (8px grid)
  // ===========================================================================
  static const double space1 = 6;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;

  static const double altSpace1 = 8;
  static const double altSpace2 = 16;
  static const double altSpace3 = 24;
  static const double altSpace4 = 32;
  static const double altSpace5 = 40;
  static const double altSpace6 = 48;

  // ===========================================================================
  // PADDING
  // ===========================================================================
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(space5, space2, space5, space6);
  static const EdgeInsets pagePaddingTight = EdgeInsets.fromLTRB(space5, space1, space5, space6);
  static const EdgeInsets pagePaddingDense = EdgeInsets.fromLTRB(space5, space3, space5, space6);
  static const EdgeInsets headerPadding    = EdgeInsets.fromLTRB(space5, space3, space5, space2);
  static const EdgeInsets authPadding      = EdgeInsets.symmetric(horizontal: space5, vertical: space3);
  static const EdgeInsets authPaddingTight = EdgeInsets.symmetric(horizontal: space5, vertical: space2);
  static const EdgeInsets onboardingPadding = EdgeInsets.symmetric(horizontal: space5, vertical: space5);

  // ===========================================================================
  // GRADIENTS & SHADOWS
  // ===========================================================================
  // Home hero header: #0B6E6E → #0D8F8F
  static const LinearGradient qHeaderGradient = LinearGradient(
    colors: <Color>[Color(0xFF0B6E6E), Color(0xFF0D8F8F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  // Keep primaryGradient alias so old code still works
  static const LinearGradient primaryGradient = qHeaderGradient;
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: <Color>[qSurface, Color(0xFFF0F9F9), qPrimaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient splashGradient = LinearGradient(
    colors: <Color>[qPrimary, qPrimaryLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient headerGradient = qHeaderGradient;

  static final List<BoxShadow> cardShadow = <BoxShadow>[
    const BoxShadow(color: Color(0x100B6E6E), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> softShadow = <BoxShadow>[
    BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  // ===========================================================================
  // TYPOGRAPHY STYLES (Plus Jakarta Sans headings, DM Sans body)
  // ===========================================================================
  static TextStyle get h1 => GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700, color: qText);
  static TextStyle get h2 => GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: qText);
  static TextStyle get body => GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, color: qText);
  static TextStyle get subtitleStyle => GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, color: qTextSec);
  static TextStyle get caption => GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: qTextSec);
  static TextStyle get label => GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: qText);
  static TextStyle get button => GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white);
  static TextStyle get screenTitle => GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: qText);
  static TextStyle get brandTitle => GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w700, color: qText);
  static TextStyle get profileTitle => GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: qText);

  // ===========================================================================
  // THEME DATA
  // ===========================================================================

  static TextTheme _buildTextTheme() {
    return GoogleFonts.dmSansTextTheme().copyWith(
      displayLarge:  GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 32, color: qText),
      displayMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 28, color: qText),
      headlineLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 26, color: qText, letterSpacing: -0.4),
      headlineMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 22, color: qText, letterSpacing: -0.3),
      titleLarge:    GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 20, color: qText, letterSpacing: -0.2),
      titleMedium:   GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16, color: qText),
      titleSmall:    GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, color: qTextSec),
      bodyLarge:     GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 16, color: qText, height: 1.45),
      bodyMedium:    GoogleFonts.dmSans(fontWeight: FontWeight.w400, fontSize: 14, color: qTextSec, height: 1.45),
      bodySmall:     GoogleFonts.dmSans(fontWeight: FontWeight.w400, fontSize: 12, color: qTextHint),
      labelLarge:    GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14),
      labelMedium:   GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 13),
      labelSmall:    GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 12),
    );
  }

  static AppBarTheme _buildAppBarTheme() {
    return AppBarTheme(
      backgroundColor: qCard,
      foregroundColor: qText,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: qText,
      ),
      iconTheme: const IconThemeData(color: qText, size: 22),
      shape: const Border(bottom: BorderSide(color: qBorder, width: 1)),
    );
  }

  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      color: qCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
        side: const BorderSide(color: qBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    );
  }

  static InputDecorationTheme _buildInputTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8F8F6),
      hintStyle: GoogleFonts.dmSans(fontSize: 14, color: qTextHint),
      labelStyle: GoogleFonts.dmSans(fontSize: 14, color: qTextSec),
      floatingLabelStyle: GoogleFonts.dmSans(fontSize: 14, color: qPrimary, fontWeight: FontWeight.w600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        borderSide: const BorderSide(color: qPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: qError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: qError, width: 1.5),
      ),
    );
  }

  // Legacy input theme accessor (used by some screens)
  static final InputDecorationTheme legacyLibInputDecorationTheme = _buildInputTheme();

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: qPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme() {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: qPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: qPrimary,
        side: const BorderSide(color: qPrimary, width: 1.5),
        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = _buildTextTheme();

    return base.copyWith(
      scaffoldBackgroundColor: qSurface,
      canvasColor: qSurface,
      cardColor: qCard,
      dividerColor: qBorder,
      colorScheme: const ColorScheme.light(
        primary: qPrimary,
        secondary: qAccent,
        surface: qCard,
        error: qError,
        onPrimary: Colors.white,
        onSurface: qText,
        outline: qBorder,
        surfaceTint: qPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: _buildAppBarTheme(),
      cardTheme: _buildCardTheme(),
      inputDecorationTheme: _buildInputTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      filledButtonTheme: _buildFilledButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: qPrimary,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: qCard,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? qPrimary : qTextHint,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(color: isSelected ? qPrimary : qTextHint, size: 22);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: qPrimaryLight,
        selectedColor: qPrimary,
        disabledColor: qBorder,
        labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: qPrimary),
        secondaryLabelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        checkmarkColor: Colors.white,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: qPrimary,
        unselectedLabelColor: qTextHint,
        labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 14),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(color: qPrimary, width: 2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: qText,
        contentTextStyle: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: qCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: qText),
        contentTextStyle: GoogleFonts.dmSans(fontSize: 14, color: qTextSec),
      ),
      listTileTheme: const ListTileThemeData(iconColor: qTextSec, textColor: qText),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: qPrimary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? qPrimary : qCard),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return qPrimary.withValues(alpha: 0.35);
          return qBorder;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? qPrimary : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: qBorder),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? qPrimary : qTextHint),
      ),
      dividerTheme: const DividerThemeData(color: qBorder, space: 24, thickness: 1),
      iconTheme: const IconThemeData(color: qTextSec, size: 22),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd))),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return const BorderSide(color: qPrimary, width: 1.2);
            return const BorderSide(color: qBorder, width: 1);
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? qPrimaryLight : qCard),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? qPrimary : qTextSec),
          textStyle: WidgetStateProperty.all(GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    );
  }
}
