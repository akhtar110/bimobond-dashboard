import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

/// Visual tokens for report card presentation widgets.
abstract final class ReportCardTheme {
  static const double radius = 18;
  static const double desktopBreakpoint = 1200;
  static const double tabletBreakpoint = 768;
  static const Duration animDuration = Duration(milliseconds: 180);

  static Color cardBackground(ColorScheme scheme) => scheme.surface;

  static Color cardBorder(ColorScheme scheme, {bool hovered = false}) {
    if (hovered) return scheme.outline;
    return scheme.outlineVariant;
  }

  static List<BoxShadow> cardShadow(ColorScheme scheme, {bool hovered = false}) {
    return [
      BoxShadow(
        color: scheme.shadow.withValues(alpha: hovered ? 0.08 : 0.04),
        blurRadius: hovered ? 16 : 10,
        offset: Offset(0, hovered ? 4 : 2),
      ),
    ];
  }

  /// Semantic status color for stripes, filter chips, etc.
  static Color reportStatusColor(ColorScheme scheme, String? status) =>
      switch (status) {
        'PENDING' => scheme.tertiary,
        'RESOLVED' => scheme.primary,
        'DISMISSED' => scheme.onSurfaceVariant,
        null => scheme.primary,
        _ => scheme.secondary,
      };

  static Color priorityStripe(ColorScheme scheme, String status) =>
      reportStatusColor(scheme, status);

  static ({Color fg, Color bg, String label, IconData icon}) reportStatusStyle(
    ColorScheme scheme,
    String status, {
    AppLocalizations? l10n,
  }) {
    return switch (status) {
      'PENDING' => (
          fg: scheme.onTertiaryContainer,
          bg: scheme.tertiaryContainer,
          label: l10n?.t('pending') ?? 'Pending',
          icon: Icons.schedule_rounded,
        ),
      'RESOLVED' => (
          fg: scheme.onPrimaryContainer,
          bg: scheme.primaryContainer,
          label: l10n?.t('resolved') ?? 'Resolved',
          icon: Icons.check_circle_outline_rounded,
        ),
      'DISMISSED' => (
          fg: scheme.onSurfaceVariant,
          bg: scheme.surfaceContainerHigh,
          label: l10n?.t('dismissed') ?? 'Dismissed',
          icon: Icons.remove_circle_outline_rounded,
        ),
      _ => (
          fg: scheme.onSecondaryContainer,
          bg: scheme.secondaryContainer,
          label: status,
          icon: Icons.flag_outlined,
        ),
    };
  }

  static (IconData icon, Color color) targetTypeVisual(
    ColorScheme scheme,
    String targetType,
  ) =>
      switch (targetType) {
        'post' => (Icons.videocam_outlined, scheme.primary),
        'user' => (Icons.person_outline_rounded, scheme.secondary),
        'comment' => (
            Icons.chat_bubble_outline_rounded,
            scheme.tertiary,
          ),
        _ => (Icons.help_outline_rounded, scheme.onSurfaceVariant),
      };

  static Color mutedText(ColorScheme scheme) => scheme.onSurfaceVariant;

  static Color previewSurface(ColorScheme scheme) =>
      scheme.surfaceContainerLow;
}
