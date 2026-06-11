import 'package:flutter/material.dart';

/// Enterprise design tokens for the Reports Center shell (Material 3).
abstract final class ReportsCenterTheme {
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusPill = 999;

  static const double navRailWidth = 248;
  static const double navItemHeight = 44;
  static const double headerControlHeight = 40;

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 240);
  static const Curve ease = Curves.easeOutCubic;

  static double maxContentWidth(double screenWidth) {
    if (screenWidth >= 1920) return 1840;
    if (screenWidth >= 1440) return 1680;
    return 1680;
  }

  static List<BoxShadow> shadowSm(ColorScheme scheme) => [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> shadowMd(ColorScheme scheme) => [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.07),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> shadowLg(ColorScheme scheme) => [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.12),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  static LinearGradient pageBackgroundGradient(ColorScheme scheme) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.surfaceContainerLowest,
        Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.03),
          scheme.surfaceContainerLowest,
        ),
      ],
    );
  }

  static LinearGradient accentWash(ColorScheme scheme, Color accent) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        accent.withValues(alpha: 0.14),
        accent.withValues(alpha: 0.04),
      ],
    );
  }

  static BoxDecoration navRailPanel(ColorScheme scheme) {
    return BoxDecoration(
      color: scheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(radiusLg),
      border: Border.all(
        color: scheme.outlineVariant.withValues(alpha: 0.35),
      ),
      boxShadow: shadowMd(scheme),
    );
  }

  static BoxDecoration headerSurface(ColorScheme scheme) {
    return BoxDecoration(
      color: scheme.surface.withValues(alpha: 0.88),
      border: Border(
        bottom: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration dataPanel(ColorScheme scheme) {
    return BoxDecoration(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(radiusLg),
      border: Border.all(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
      ),
      boxShadow: shadowSm(scheme),
    );
  }

  static BoxDecoration kpiCard(ColorScheme scheme, {Color? accent}) {
    final tone = accent ?? scheme.primary;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radiusMd),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.surface,
          Color.alphaBlend(tone.withValues(alpha: 0.06), scheme.surface),
        ],
      ),
      border: Border.all(
        color: tone.withValues(alpha: 0.12),
      ),
      boxShadow: shadowSm(scheme),
    );
  }

  static BoxDecoration detailSection(ColorScheme scheme) {
    return BoxDecoration(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(radiusMd),
      border: Border.all(
        color: scheme.outlineVariant.withValues(alpha: 0.45),
      ),
      boxShadow: shadowSm(scheme),
    );
  }

  static BoxDecoration drawerPanel(ColorScheme scheme) {
    return BoxDecoration(
      color: scheme.surface,
      borderRadius: const BorderRadius.horizontal(
        left: Radius.circular(radiusLg),
      ),
      boxShadow: shadowLg(scheme),
    );
  }

  static TextStyle sectionTitle(ThemeData theme) {
    return theme.textTheme.titleSmall!.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.2,
    );
  }

  static TextStyle tableHeader(ThemeData theme, ColorScheme scheme) {
    return theme.textTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: scheme.onSurfaceVariant,
    );
  }

  static TextStyle muted(ThemeData theme, ColorScheme scheme) {
    return theme.textTheme.bodySmall!.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.35,
    );
  }
}
