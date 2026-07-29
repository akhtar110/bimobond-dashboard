/// Breakpoints and spacing for the analytics dashboard chrome.
enum AnalyticsDeviceType {
  mobileSmall,
  mobileLarge,
  tablet,
  desktop,
}

AnalyticsDeviceType getAnalyticsDeviceType(double width) {
  if (width < 480) return AnalyticsDeviceType.mobileSmall;
  if (width < 720) return AnalyticsDeviceType.mobileLarge;
  if (width < 1200) return AnalyticsDeviceType.tablet;
  return AnalyticsDeviceType.desktop;
}

class AnalyticsLayoutMetrics {
  const AnalyticsLayoutMetrics(this.deviceType);

  final AnalyticsDeviceType deviceType;

  bool get isCompact =>
      deviceType == AnalyticsDeviceType.mobileSmall ||
      deviceType == AnalyticsDeviceType.mobileLarge;

  double get pageHorizontalPadding => switch (deviceType) {
        AnalyticsDeviceType.mobileSmall => 8,
        AnalyticsDeviceType.mobileLarge => 10,
        AnalyticsDeviceType.tablet => 14,
        AnalyticsDeviceType.desktop => 24,
      };

  double get pageTopPadding => isCompact ? 6 : 8;

  double get pageBottomPadding => isCompact ? 10 : 12;

  double get headerGap => isCompact ? 6 : 8;

  double get sectionGap => isCompact ? 12 : 16;

  double get controlGap => isCompact ? 6 : 8;
}
