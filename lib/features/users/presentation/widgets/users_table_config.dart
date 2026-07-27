import '../utils/responsive.dart';

/// Responsive column visibility for the users data table.
class UsersTableConfig {
  const UsersTableConfig({
    required this.showAccount,
    required this.showEngagement,
    required this.compactActions,
    required this.minWidth,
    this.checkboxWidth = 44,
  });

  final bool showAccount;
  final bool showEngagement;
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
      compactActions: width < 1100,
      minWidth: width,
      checkboxWidth: device == DeviceType.tablet ? 36 : 34,
    );
  }
}
