import 'package:flutter/material.dart';

/// Shared spacing + breakpoint tokens for the moderation dashboard.
abstract final class InvestigationTheme {
  static const desktop = 1200.0;
  static const tablet = 768.0;

  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;

  static const radius = 18.0;
  static const radiusSm = 12.0;
  static const animMs = 200;

  static BoxDecoration cardDecoration(BuildContext context, {bool isDark = false}) {
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: isDark ? const Color(0xFF151B28) : scheme.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? const Color(0xFF2A3344)
            : scheme.outlineVariant.withValues(alpha: 0.45),
      ),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  static Color mutedText(BuildContext context, bool isDark) =>
      isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
}
