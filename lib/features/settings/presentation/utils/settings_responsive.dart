import 'package:flutter/material.dart';

/// Breakpoints and layout helpers for the settings admin module.
enum SettingsDeviceType {
  mobileSmall,
  mobileLarge,
  tablet,
  desktop,
}

SettingsDeviceType getSettingsDeviceType(double width) {
  if (width < 480) return SettingsDeviceType.mobileSmall;
  if (width < 700) return SettingsDeviceType.mobileLarge;
  if (width < 1200) return SettingsDeviceType.tablet;
  return SettingsDeviceType.desktop;
}

class SettingsLayoutMetrics {
  const SettingsLayoutMetrics(this.deviceType);

  static const double maxContentWidth = 1680;

  final SettingsDeviceType deviceType;

  bool get isMobile =>
      deviceType == SettingsDeviceType.mobileSmall ||
      deviceType == SettingsDeviceType.mobileLarge;

  bool get isCompact => isMobile;

  double get pageHorizontalPadding => switch (deviceType) {
        SettingsDeviceType.mobileSmall => 10,
        SettingsDeviceType.mobileLarge => 12,
        SettingsDeviceType.tablet => 16,
        SettingsDeviceType.desktop => 20,
      };

  double get pageTopPadding => switch (deviceType) {
        SettingsDeviceType.mobileSmall => 10,
        SettingsDeviceType.mobileLarge => 12,
        SettingsDeviceType.tablet => 14,
        SettingsDeviceType.desktop => 16,
      };

  double get sectionGap => switch (deviceType) {
        SettingsDeviceType.mobileSmall => 8,
        SettingsDeviceType.mobileLarge => 10,
        SettingsDeviceType.tablet => 12,
        SettingsDeviceType.desktop => 14,
      };

  double get panelRadius => switch (deviceType) {
        SettingsDeviceType.mobileSmall => 12,
        SettingsDeviceType.mobileLarge => 12,
        SettingsDeviceType.tablet => 14,
        SettingsDeviceType.desktop => 16,
      };

  double get panelPadding => switch (deviceType) {
        SettingsDeviceType.mobileSmall => 12,
        SettingsDeviceType.mobileLarge => 12,
        SettingsDeviceType.tablet => 14,
        SettingsDeviceType.desktop => 16,
      };

  double get filterControlHeight => switch (deviceType) {
        SettingsDeviceType.mobileSmall => 38,
        SettingsDeviceType.mobileLarge => 40,
        SettingsDeviceType.tablet => 44,
        SettingsDeviceType.desktop => 48,
      };

  double get tabStripHeight => switch (deviceType) {
        SettingsDeviceType.mobileSmall => 36,
        SettingsDeviceType.mobileLarge => 38,
        SettingsDeviceType.tablet => 40,
        SettingsDeviceType.desktop => 44,
      };
}

/// Opens a settings form as a centered popup dialog (never a full-screen route).
/// Matches the App settings tab pattern so add/edit stays on the settings page.
Future<T?> showSettingsAdaptiveForm<T>({
  required BuildContext context,
  required Widget Function(BuildContext dialogContext) builder,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final viewInsets = MediaQuery.viewInsetsOf(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          backgroundColor: Theme.of(ctx).colorScheme.surface.withValues(alpha: 0),
          elevation: 0,
          child: builder(ctx),
        ),
      );
    },
  );
}
