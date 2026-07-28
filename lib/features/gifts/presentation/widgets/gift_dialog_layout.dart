import 'package:flutter/material.dart';

/// Shared responsive layout metrics and input decorations for gift create, edit,
/// and preview dialogs.
class GiftDialogLayout {
  const GiftDialogLayout(this.size);

  final Size size;

  bool get useWideLayout => size.width >= 720;
  bool get isCompactMobile => size.width < 520;

  double get dialogWidth {
    if (size.width < 560) return size.width * 0.94;
    if (useWideLayout) return (size.width * 0.84).clamp(680.0, 840.0);
    return (size.width * 0.90).clamp(480.0, 620.0);
  }

  double get previewDialogWidth {
    if (size.width < 560) return size.width * 0.94;
    if (useWideLayout) return (size.width * 0.82).clamp(680.0, 840.0);
    return (size.width * 0.90).clamp(480.0, 620.0);
  }

  EdgeInsets get insetPadding => EdgeInsets.symmetric(
        horizontal: size.width < 560 ? 12 : 20,
        vertical: size.height < 700 ? 12 : 20,
      );

  double get maxBodyHeight => (size.height * 0.84).clamp(380.0, 660.0);
  double get previewMaxBodyHeight => (size.height * 0.82).clamp(360.0, 620.0);

  double get gap => useWideLayout ? 14 : 10;
  double get fieldGap => 10;

  double get mediaMaxHeight => useWideLayout ? 130 : 110;
  double get previewMediaMaxHeight => useWideLayout ? 160 : 140;
  double get previewAnimationHeight => previewMediaMaxHeight;
  double get previewAudioSwatchHeight => useWideLayout ? 104 : 92;

  Widget mediaFrame({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: mediaMaxHeight,
        width: double.infinity,
        child: child,
      ),
    );
  }

  Widget previewMediaFrame({required Widget child, double? height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height ?? previewMediaMaxHeight,
        width: double.infinity,
        child: child,
      ),
    );
  }

  InputDecoration denseDecoration({
    required String labelText,
    String? helperText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      helperText: helperText,
      isDense: true,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x33000000)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3F51B5), width: 1.5),
      ),
    );
  }

  ButtonStyle denseOutlinedButtonStyle() {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
