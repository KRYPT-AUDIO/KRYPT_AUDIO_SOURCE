/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *     This KRYPT AUDIO visual reskin is based on the Musify upstream project.
 *     Upstream: https://github.com/gokadzev/Musify
 */

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/services/plugin_service.dart';
import 'package:musify/theme/app_colors.dart';
import 'package:musify/theme/krypt_design.dart';

ThemeMode themeMode = getThemeMode(themeModeSetting);
Brightness brightness = getBrightnessFromThemeMode(themeMode);

Brightness getBrightnessFromThemeMode(ThemeMode themeMode) {
  final themeBrightnessMapping = {
    ThemeMode.light: Brightness.light,
    ThemeMode.dark: Brightness.dark,
    ThemeMode.system:
        SchedulerBinding.instance.platformDispatcher.platformBrightness,
  };

  return themeBrightnessMapping[themeMode] ?? Brightness.dark;
}

ThemeMode getThemeMode(int themeModeIndex) {
  const themeModes = ThemeMode.values;
  if (themeModeIndex >= 0 && themeModeIndex < themeModes.length) {
    return themeModes[themeModeIndex];
  }
  return ThemeMode.system;
}

ColorScheme getAppColorScheme(
  ColorScheme? lightColorScheme,
  ColorScheme? darkColorScheme,
) {
  final selectedScheme = (brightness == Brightness.light)
      ? lightColorScheme
      : darkColorScheme;

  final brandScheme = ColorScheme.fromSeed(
    seedColor: primaryColorSetting == const Color(0xFF009688)
        ? kryptViolet
        : primaryColorSetting,
    brightness: brightness,
  );
  final baseScheme = useSystemColor.value && selectedScheme != null
      ? selectedScheme
      : brandScheme;
  final primary = _pluginColor('--krypt-primary');
  final secondary = _pluginColor('--krypt-secondary');
  return baseScheme.copyWith(primary: primary, secondary: secondary);
}

ThemeData getAppTheme(ColorScheme colorScheme) {
  final isLight = colorScheme.brightness == Brightness.light;
  final pureBlack = !isLight && usePureBlackColor.value;
  final defaultTheme = isLight ? ThemeData.light() : ThemeData.dark();
  final scheme = isLight
      ? colorScheme.copyWith(
          surface: KryptDesign.lightSurface,
          surfaceContainerLowest: KryptDesign.lightSurface,
          surfaceContainerLow: KryptDesign.lightSurfaceLow,
          surfaceContainer: KryptDesign.lightSurfaceLow,
          surfaceContainerHigh: KryptDesign.lightSurfaceHigh,
          surfaceContainerHighest: KryptDesign.lightSurfaceHigh,
          outline: KryptDesign.lightOutline,
          outlineVariant: KryptDesign.lightOutline.withValues(alpha: 0.55),
        )
      : colorScheme.copyWith(
          surface: pureBlack
              ? const Color(0xFF000000)
              : KryptDesign.darkBackdrop,
          surfaceContainerLowest: pureBlack
              ? const Color(0xFF000000)
              : KryptDesign.darkBackdrop,
          surfaceContainerLow: pureBlack
              ? const Color(0xFF0D0D12)
              : KryptDesign.darkSurface,
          surfaceContainer: pureBlack
              ? const Color(0xFF121218)
              : KryptDesign.darkSurface,
          surfaceContainerHigh: pureBlack
              ? const Color(0xFF191920)
              : KryptDesign.darkSurfaceHigh,
          surfaceContainerHighest: pureBlack
              ? const Color(0xFF202027)
              : KryptDesign.darkSurfaceHigh,
          outline: Colors.white.withValues(alpha: 0.16),
          outlineVariant: Colors.white.withValues(alpha: 0.10),
        );
  final foreground = scheme.onSurface;
  final background = scheme.surface;
  final cardBackground = scheme.surfaceContainerLow;
  final radius = BorderRadius.circular(KryptDesign.radiusMedium);

  return ThemeData(
    scaffoldBackgroundColor: background,
    colorScheme: scheme,
    textTheme: defaultTheme.textTheme.apply(
      bodyColor: foreground,
      displayColor: foreground,
    ),
    iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    cardColor: cardBackground,
    cardTheme: defaultTheme.cardTheme.copyWith(
      elevation: 0,
      color: cardBackground,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    appBarTheme: defaultTheme.appBarTheme.copyWith(
      backgroundColor: background,
      foregroundColor: foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: foreground,
        letterSpacing: -0.2,
      ),
      toolbarHeight: 64,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 24),
      actionsIconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 24),
    ),
    listTileTheme: defaultTheme.listTileTheme.copyWith(
      textColor: foreground,
      iconColor: scheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minLeadingWidth: 36,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: scheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    sliderTheme: defaultTheme.sliderTheme.copyWith(
      year2023: false,
      trackHeight: 6,
      thumbSize: WidgetStateProperty.all(const Size(7, 28)),
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.outlineVariant,
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.14),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return scheme.onPrimary;
        return scheme.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return scheme.primary.withValues(alpha: 0.72);
        }
        return scheme.surfaceContainerHigh;
      }),
      trackOutlineColor: WidgetStateProperty.all(scheme.outlineVariant),
    ),
    bottomSheetTheme: defaultTheme.bottomSheetTheme.copyWith(
      backgroundColor: cardBackground,
      modalBackgroundColor: cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    inputDecorationTheme: defaultTheme.inputDecorationTheme.copyWith(
      filled: true,
      isDense: true,
      fillColor: scheme.surfaceContainerHigh,
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KryptDesign.radiusSmall),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KryptDesign.radiusSmall),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KryptDesign.radiusSmall),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.fromLTRB(18, 14, 20, 14),
    ),
    dialogTheme: defaultTheme.dialogTheme.copyWith(
      backgroundColor: cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: KryptDesign.radiusLargeAsRadius,
      ),
    ),
    navigationBarTheme: defaultTheme.navigationBarTheme.copyWith(
      backgroundColor: Colors.transparent,
      elevation: 0,
      height: 70,
      indicatorColor: scheme.primary.withValues(alpha: 0.20),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
          size: 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? foreground
              : scheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
        );
      }),
    ),
    navigationRailTheme: defaultTheme.navigationRailTheme.copyWith(
      backgroundColor: Colors.transparent,
      elevation: 0,
      indicatorColor: scheme.primary.withValues(alpha: 0.20),
      selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(
        color: foreground,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
    ),
    popupMenuTheme: defaultTheme.popupMenuTheme.copyWith(
      color: cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KryptDesign.radiusSmall),
      ),
    ),
    dividerTheme: defaultTheme.dividerTheme.copyWith(
      color: scheme.outlineVariant,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.secondaryContainer,
      closeIconColor: scheme.onSecondaryContainer,
      contentTextStyle: TextStyle(
        color: scheme.onSecondaryContainer,
        fontWeight: FontWeight.w500,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KryptDesign.radiusSmall),
        side: BorderSide(color: scheme.outlineVariant, width: 0.5),
      ),
      elevation: 0,
      actionTextColor: scheme.secondary,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.outlineVariant,
      circularTrackColor: scheme.outlineVariant,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: true,
  );
}

Color? _pluginColor(String token) {
  final value = KryptPluginService.instance.themeTokens[token]?.replaceFirst(
    '#',
    '',
  );
  if (value == null) return null;
  final normalized = value.length == 6 ? 'ff$value' : value;
  final integer = int.tryParse(normalized, radix: 16);
  return integer == null ? null : Color(integer);
}
