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

/// Opens a form as bottom sheet on narrow screens, dialog on wider screens.
Future<T?> showSettingsAdaptiveForm<T>({
  required BuildContext context,
  required Widget Function(BuildContext dialogContext) builder,
}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: builder(ctx),
      ),
    );
  }

  return showDialog<T>(
    context: context,
    builder: builder,
  );
}
