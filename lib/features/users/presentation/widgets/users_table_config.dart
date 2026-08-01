import '../utils/responsive.dart';

/// Responsive column visibility for the users data table.
class UsersTableConfig {
  const UsersTableConfig({
    required this.showAccount,
    required this.showEngagement,
    required this.showLocation,
    required this.compactActions,
    required this.minWidth,
    this.checkboxWidth = 44,
  });

  final bool showAccount;
  final bool showEngagement;
  final bool showLocation;
  final bool compactActions;
  final double minWidth;
  final double checkboxWidth;

  factory UsersTableConfig.fromConstraints(
    double width, {
    DeviceType? deviceType,
  }) {
    final device = deviceType ?? getDeviceType(width);

    return UsersTableConfig(
      showAccount: width >= (device == DeviceType.tablet ? 640 : 720),
      // Keep followers / posts / likes visible whenever the table is shown.
      showEngagement: true,
      showLocation: true,
      // Inline action chips need room; collapse to overflow menu earlier
      // on laptop/tablet content widths to avoid overlap.
      compactActions: width < 1500 ||
          device == DeviceType.tablet ||
          device == DeviceType.mobileLarge ||
          device == DeviceType.mobileSmall,
      minWidth: width,
      checkboxWidth: device == DeviceType.tablet ? 36 : 34,
    );
  }
}
