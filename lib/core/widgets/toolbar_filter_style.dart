import 'package:flutter/material.dart';

/// Shared chrome for compact admin toolbar filters (search, dropdowns, date).
abstract final class ToolbarFilterStyle {
  static const double borderRadius = 10;
  static const double controlHeight = 40;

  static BorderRadius get radius => BorderRadius.circular(borderRadius);

  static BoxDecoration boxDecoration(ColorScheme scheme) => BoxDecoration(
        color: scheme.surface,
        borderRadius: radius,
        border: Border.all(color: scheme.outlineVariant),
      );

  static OutlineInputBorder outlineBorder(ColorScheme scheme) =>
      OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.outlineVariant),
      );

  static OutlineInputBorder focusedBorder(ColorScheme scheme) =>
      OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      );

  static InputDecoration inputDecoration(
    ColorScheme scheme, {
    String? hintText,
    TextStyle? hintStyle,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final enabled = outlineBorder(scheme);
    final focused = focusedBorder(scheme);
    return InputDecoration(
      hintText: hintText,
      hintStyle: hintStyle,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: true,
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      border: enabled,
      enabledBorder: enabled,
      focusedBorder: focused,
      disabledBorder: enabled,
      errorBorder: enabled,
      focusedErrorBorder: focused,
    );
  }
}
