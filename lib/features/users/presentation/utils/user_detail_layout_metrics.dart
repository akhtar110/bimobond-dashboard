import 'responsive.dart';

/// Responsive layout tokens for [UserDetailScreen] admin actions.
class UserDetailLayoutMetrics {
  const UserDetailLayoutMetrics(this.deviceType);

  final DeviceType deviceType;

  bool get isMobile =>
      deviceType == DeviceType.mobileSmall ||
      deviceType == DeviceType.mobileLarge;

  bool get isTablet => deviceType == DeviceType.tablet;

  bool get isDesktop => deviceType == DeviceType.desktop;

  int get actionsGridColumns => switch (deviceType) {
        DeviceType.mobileSmall => 2,
        DeviceType.mobileLarge => 2,
        DeviceType.tablet => 3,
        DeviceType.desktop => 4,
      };

  double get sectionPadding => switch (deviceType) {
        DeviceType.mobileSmall => 14,
        DeviceType.mobileLarge => 16,
        DeviceType.tablet => 18,
        DeviceType.desktop => 20,
      };

  double get sectionSpacing => switch (deviceType) {
        DeviceType.mobileSmall => 10,
        DeviceType.mobileLarge => 12,
        DeviceType.tablet => 14,
        DeviceType.desktop => 16,
      };

  double get gridSpacing => switch (deviceType) {
        DeviceType.mobileSmall => 8,
        DeviceType.mobileLarge => 10,
        DeviceType.tablet => 12,
        DeviceType.desktop => 12,
      };

  double get actionCardMinHeight => switch (deviceType) {
        DeviceType.mobileSmall => 88,
        DeviceType.mobileLarge => 92,
        DeviceType.tablet => 96,
        DeviceType.desktop => 100,
      };

  double get actionIconSize => switch (deviceType) {
        DeviceType.mobileSmall => 20,
        DeviceType.mobileLarge => 22,
        DeviceType.tablet => 22,
        DeviceType.desktop => 24,
      };

  double get actionIconPadding => switch (deviceType) {
        DeviceType.mobileSmall => 8,
        DeviceType.mobileLarge => 9,
        DeviceType.tablet => 10,
        DeviceType.desktop => 10,
      };
}

UserDetailLayoutMetrics userDetailLayoutMetrics(double width) {
  return UserDetailLayoutMetrics(getDeviceType(width));
}
