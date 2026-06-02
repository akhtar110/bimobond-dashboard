/// Responsive column visibility for the users data table.
class UsersTableConfig {
  const UsersTableConfig({
    required this.showAccount,
    required this.showEngagement,
    required this.compactActions,
    required this.minWidth,
  });

  final bool showAccount;
  final bool showEngagement;
  final bool compactActions;
  final double minWidth;

  factory UsersTableConfig.fromConstraints(double width) {
    return UsersTableConfig(
      showAccount: width >= 720,
      showEngagement: width >= 900,
      compactActions: width < 1100,
      minWidth: width < 560 ? 560 : width,
    );
  }
}
