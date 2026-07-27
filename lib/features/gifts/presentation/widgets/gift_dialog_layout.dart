import 'package:flutter/material.dart';

/// Shared sizing for gift create / edit / preview dialogs so content fits
/// without vertical scrolling on typical admin viewports.
class GiftDialogLayout {
  const GiftDialogLayout(this.size);

  final Size size;

  bool get useWideLayout => size.width >= 720;

  double get dialogWidth {
    if (size.width < 560) return size.width * 0.94;
    if (useWideLayout) return (size.width * 0.86).clamp(640.0, 860.0);
    return 520.0;
  }

  EdgeInsets get insetPadding => EdgeInsets.symmetric(
        horizontal: size.width < 560 ? 12 : 20,
        vertical: size.height < 700 ? 12 : 20,
      );

  /// Max height for dialog body (title + actions sit outside).
  double get maxBodyHeight => (size.height * 0.78).clamp(360.0, 640.0);

  double get gap => useWideLayout ? 12 : 10;

  double get fieldGap => 10;

  /// Compact square-ish media tiles in the dialog.
  double get mediaAspectRatio => useWideLayout ? 1.15 : 1.25;

  InputDecoration denseDecoration({
    required String labelText,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: labelText,
      helperText: helperText,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  ButtonStyle denseOutlinedButtonStyle() {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
