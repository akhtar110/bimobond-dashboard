/// Breakpoints and spacing for RBAC dashboard screens.
enum RbacDeviceType {
  mobileSmall,
  mobileLarge,
  tablet,
  desktop,
}

RbacDeviceType getRbacDeviceType(double width) {
  if (width < 480) return RbacDeviceType.mobileSmall;
  if (width < 720) return RbacDeviceType.mobileLarge;
  if (width < 1200) return RbacDeviceType.tablet;
  return RbacDeviceType.desktop;
}

class RbacLayoutMetrics {
  const RbacLayoutMetrics(this.deviceType);

  final RbacDeviceType deviceType;

  bool get isCompact =>
      deviceType == RbacDeviceType.mobileSmall ||
      deviceType == RbacDeviceType.mobileLarge;

  double get pageHorizontalPadding => switch (deviceType) {
        RbacDeviceType.mobileSmall => 8,
        RbacDeviceType.mobileLarge => 10,
        RbacDeviceType.tablet => 14,
        RbacDeviceType.desktop => 24,
      };

  double get pageTopPadding => isCompact ? 6 : 8;

  double get pageBottomPadding => isCompact ? 10 : 12;

  double get headerGap => isCompact ? 6 : 8;

  double get sectionGap => isCompact ? 10 : 12;

  double get controlGap => isCompact ? 6 : 8;

  /// Icon-only toolbar actions below this content width.
  bool get useIconActions => isCompact;
}
