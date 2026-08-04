import 'package:flutter/material.dart';

/// Shared spacing + breakpoint tokens for the moderation dashboard.
abstract final class InvestigationTheme {
  /// Minimum width for three-column moderation layout (with sidebar open,
  /// content pane is often narrower than full viewport).
  static const threeColumn = 1280.0;
  static const desktop = 1200.0;
  static const wide = 1440.0;
  static const tablet = 768.0;
  /// Side-by-side post fields + moderation row (tablet landscape / narrow desktop).
  static const twoColumnRow = 992.0;
  static const compact = 480.0;

  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;

  static const radius = 20.0;
  static const radiusSm = 12.0;
  static const radiusLg = 24.0;
  static const animMs = 200;

  /// Portrait framing for mobile-style post preview (9:16).
  static const portraitAspect = 9 / 16;

  /// Admin media preview card — compact portrait framing for moderation UI.
  static const mediaPreviewMaxWidth = 380.0;
  static const mediaPreviewHeight = mediaPreviewMaxWidth / portraitAspect;

  static ColorScheme schemeOf(BuildContext context) =>
      Theme.of(context).colorScheme;

  static Color mutedText(BuildContext context) =>
      schemeOf(context).onSurfaceVariant;

  static BoxDecoration cardDecoration(BuildContext context) {
    final scheme = schemeOf(context);
    return BoxDecoration(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      boxShadow: [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static InputDecoration fieldDecoration(
    BuildContext context, {
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
  }) {
    final scheme = schemeOf(context);
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    );
  }
}
