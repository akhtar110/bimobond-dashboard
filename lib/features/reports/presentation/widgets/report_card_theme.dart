import 'package:flutter/material.dart';

/// Visual tokens for report card presentation widgets.
abstract final class ReportCardTheme {
  static const double radius = 16;
  static const double desktopBreakpoint = 1200;
  static const double tabletBreakpoint = 768;
  static const Duration animDuration = Duration(milliseconds: 180);

  static Color cardBackground(bool isDark) =>
      isDark ? const Color(0xFF151B28) : Colors.white;

  static Color cardBorder(bool isDark, {bool hovered = false}) {
    if (hovered) {
      return isDark ? const Color(0xFF3B4A63) : const Color(0xFFCBD5E1);
    }
    return isDark ? const Color(0xFF2A3344) : const Color(0xFFE8ECF0);
  }

  static List<BoxShadow> cardShadow(bool isDark, {bool hovered = false}) {
    if (isDark) return const [];
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: hovered ? 0.07 : 0.035),
        blurRadius: hovered ? 16 : 10,
        offset: Offset(0, hovered ? 4 : 2),
      ),
    ];
  }

  static Color priorityStripe(String status) => switch (status) {
        'PENDING' => const Color(0xFFF59E0B),
        'RESOLVED' => const Color(0xFF10B981),
        'DISMISSED' => const Color(0xFF9CA3AF),
        _ => const Color(0xFF6366F1),
      };

  static (IconData icon, Color color) targetTypeVisual(String targetType) =>
      switch (targetType) {
        'post' => (Icons.videocam_outlined, const Color(0xFF0EA5E9)),
        'user' => (Icons.person_outline_rounded, const Color(0xFF8B5CF6)),
        'comment' => (
            Icons.chat_bubble_outline_rounded,
            const Color(0xFF6366F1)
          ),
        _ => (Icons.help_outline_rounded, const Color(0xFF6B7280)),
      };

  static Color mutedText(bool isDark) =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

  static Color previewSurface(bool isDark) =>
      isDark ? const Color(0xFF0F1421) : const Color(0xFFF8FAFC);
}
