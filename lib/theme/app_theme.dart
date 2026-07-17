import 'package:flutter/material.dart';

/// Corner-radius and spacing tokens mirroring the mockup's `--r-sm/md/lg` and
/// `--pad-*`/`--gap-*` CSS variables (see design/DESIGN.md) — kept as named
/// constants rather than magic numbers scattered through widgets.
class AppRadius {
  AppRadius._();

  static const double sm = 14;
  static const double md = 20;
  static const double lg = 28;
}

class AppSpacing {
  AppSpacing._();

  static const double sm = 12;
  static const double md = 16;
  static const double row = 14;
}

/// Semantic green/red used for on/off and granted/denied status — Material
/// 3's `ColorScheme` has no built-in "success" role (only `error`), so these
/// are fixed brand colors rather than seed-derived, kept the same across
/// light and dark theme.
class AppStatusColors {
  AppStatusColors._();

  static const Color active = Color(0xFF2E7D32);
  static const Color activeContainer = Color(0xFFC8E6C9);
  static const Color onActiveContainer = Color(0xFF1B5E20);

  static const Color inactive = Color(0xFFB3564B);
  static const Color inactiveContainer = Color(0xFFFFE0B2);
  static const Color onInactiveContainer = Color(0xFFE65100);
}

/// Seed color for the app's `ColorScheme`. `design/DESIGN.md`'s mockup
/// parameterizes color via an OKLCH primary hue (`--hue-p`) rather than a
/// literal hex, defaulting to hue 268 ("Vivid Trio" mood in the design
/// source) — an electric blue-violet that fits the "physical button fires an
/// instant action" concept the whole app is built around. This is that hue
/// converted to sRGB, used as a deliberate seed instead of Material 3's stock
/// demo purple (`0xFF6750A4`).
const Color _seedColor = Color(0xFF334FB8);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
  );
}

ThemeData buildAppDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
  );
}

// Status/navigation bar icon appearance is set natively in
// MainActivity.applySystemBarAppearance(), not from Dart — Flutter's
// SystemUiOverlayStyle bridge proved unreliable on this device.
