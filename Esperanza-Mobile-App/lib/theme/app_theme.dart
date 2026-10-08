import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/esperanza_art.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Central ThemeData for the Esperanza Mobile app. Every screen should pull
/// colors/type/radii from here (or the token files it composes) rather than
/// hard-coding values — see ESPERANZA_MOBILE_WEB_ALIGNMENT.md Section 1.
///
/// The 2026-10 design (docs/DESIGN_GUIDELINES.md, "Clay, glass, neumorphism"):
/// navy is identity and structure, gold is action and selection, translucent
/// white is content, soft shadow is depth, clay is personality. Every page
/// sits on the soft colour backdrop ([BackdropPageTransitionsBuilder]) so the
/// glass surfaces above it read as glass; fields are soft neumorphic wells;
/// selection is gold.
class AppTheme {
  AppTheme._();

  static const _fieldRadius = BorderRadius.all(Radius.circular(AppRadius.lg));

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.sans,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy700,
        primary: AppColors.navy700,
        secondary: AppColors.gold500,
        error: AppColors.danger,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
    );

    final transitions = {
      for (final e in base.pageTransitionsTheme.builders.entries) e.key: BackdropPageTransitionsBuilder(e.value),
    };

    return base.copyWith(
      // Clear: each page paints the soft backdrop beneath itself (see
      // [BackdropPageTransitionsBuilder]), so cards above it are glass.
      scaffoldBackgroundColor: AppColors.clear,
      pageTransitionsTheme: PageTransitionsTheme(builders: transitions),
      textTheme: base.textTheme.copyWith(
        headlineMedium: AppTypography.h1,
        headlineSmall: AppTypography.h2,
        titleMedium: AppTypography.h3,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.caption,
        labelLarge: AppTypography.button,
      ),
      appBarTheme: AppBarTheme(
        // Clear: the bar takes the page's own backdrop.
        backgroundColor: AppColors.clear,
        // A clear bar can't infer its status-bar icons from its colour: dark
        // icons, for the light pages every app bar sits on.
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        foregroundColor: AppColors.navy900,
        iconTheme: const IconThemeData(color: AppColors.navy800),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: AppColors.clear,
        titleTextStyle: AppTypography.h3.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy900),
      ),
      // Sheets and dialogs: near-opaque frosted white, generous radius, a
      // handle on sheets. Readability first: barely translucent.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface.withValues(alpha: 0.97),
        surfaceTintColor: AppColors.clear,
        showDragHandle: false,
        dragHandleColor: AppColors.slate300,
        modalBarrierColor: AppColors.navy950.withValues(alpha: 0.45),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface.withValues(alpha: 0.97),
        surfaceTintColor: AppColors.clear,
        barrierColor: AppColors.navy950.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: AppTypography.h3.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy900),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface.withValues(alpha: 0.97),
        surfaceTintColor: AppColors.clear,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        textStyle: const TextStyle(fontSize: AppTextSize.body, color: AppColors.navy900),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.surface.withValues(alpha: 0.98)),
          surfaceTintColor: const WidgetStatePropertyAll(AppColors.clear),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: AppColors.surface.withValues(alpha: 0.9)),
        backgroundColor: AppColors.surface.withValues(alpha: 0.7),
        selectedColor: AppColors.gold400,
        checkmarkColor: AppColors.navy950,
        labelStyle: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600, color: AppColors.navy800),
        secondaryLabelStyle: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w700, color: AppColors.navy950),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface.withValues(alpha: 0.85),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.surface),
        ),
        margin: EdgeInsets.zero,
      ),
      // Fields: soft neumorphic wells — a gently sunken grey-white face with
      // a bright lip, navy text, a gold edge while focused and a red one in
      // error. 16 vertical padding: some residents are older adults who need
      // clearly separated, easy-to-target fields.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slate100.withValues(alpha: 0.85),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        prefixIconColor: AppColors.navy600,
        suffixIconColor: AppColors.navy600,
        // A slate hairline at rest (it was white, and on the light page a
        // field could go unnoticed): identifiable at a glance.
        border: const OutlineInputBorder(borderRadius: _fieldRadius, borderSide: BorderSide(color: AppColors.slate300, width: 1.2)),
        enabledBorder: const OutlineInputBorder(borderRadius: _fieldRadius, borderSide: BorderSide(color: AppColors.slate300, width: 1.2)),
        focusedBorder: const OutlineInputBorder(borderRadius: _fieldRadius, borderSide: BorderSide(color: AppColors.gold500, width: 1.8)),
        errorBorder: const OutlineInputBorder(borderRadius: _fieldRadius, borderSide: BorderSide(color: AppColors.rose500, width: 1.4)),
        focusedErrorBorder: const OutlineInputBorder(borderRadius: _fieldRadius, borderSide: BorderSide(color: AppColors.rose600, width: 1.8)),
        disabledBorder: const OutlineInputBorder(borderRadius: _fieldRadius, borderSide: BorderSide(color: AppColors.slate200)),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.navy700, fontSize: AppTextSize.body, fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(color: AppColors.navy800, fontWeight: FontWeight.w600),
        errorStyle: const TextStyle(color: AppColors.rose700, fontSize: AppTextSize.label, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold400,
          foregroundColor: AppColors.navy950,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: AppTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy800,
          backgroundColor: AppColors.surface.withValues(alpha: 0.6),
          side: BorderSide(color: AppColors.navy700.withValues(alpha: 0.45), width: 1.3),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: AppTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand700,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
          shape: const StadiumBorder(),
          textStyle: AppTypography.button,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: AppColors.navy800)),
      // Pills, like every other action.
      floatingActionButtonTheme: const FloatingActionButtonThemeData(shape: StadiumBorder()),
      // Gold means "on" / "selected" everywhere.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.navy900 : AppColors.surface),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.gold400 : AppColors.slate200),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.gold500 : AppColors.slate300),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.navy700 : AppColors.clear),
        checkColor: const WidgetStatePropertyAll(AppColors.gold300),
        side: const BorderSide(color: AppColors.navy600, width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm - 2)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.navy700 : AppColors.navy600),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.navy700,
        linearTrackColor: AppColors.slate200,
        circularTrackColor: AppColors.gold200,
      ),
      sliderTheme: const SliderThemeData(activeTrackColor: AppColors.gold500, thumbColor: AppColors.navy800),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.navy900,
        unselectedLabelColor: AppColors.slate500,
        indicatorColor: AppColors.gold500,
      ),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.navy700, textColor: AppColors.navy900),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.clear,
        headerBackgroundColor: AppColors.navy800,
        headerForegroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        todayBorder: const BorderSide(color: AppColors.gold500, width: 1.5),
        todayForegroundColor: const WidgetStatePropertyAll(AppColors.navy900),
        dayBackgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.gold400 : null),
        dayForegroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.navy950 : null),
        yearBackgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.gold400 : null),
        yearForegroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.navy950 : null),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.navy800),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.slate600),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        dialHandColor: AppColors.gold400,
        hourMinuteColor: AppColors.slate100,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.slate200, thickness: 1, space: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.navy900,
        unselectedItemColor: AppColors.slate500,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy900.withValues(alpha: 0.95),
        contentTextStyle: const TextStyle(color: AppColors.surface, fontFamily: AppTypography.sans),
        actionTextColor: AppColors.gold300,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
    );
  }
}
