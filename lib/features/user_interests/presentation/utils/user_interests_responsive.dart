enum UserInterestsDeviceType { mobile, tablet, desktop }

UserInterestsDeviceType getUserInterestsDeviceType(double width) {
  if (width < 700) return UserInterestsDeviceType.mobile;
  if (width < 1100) return UserInterestsDeviceType.tablet;
  return UserInterestsDeviceType.desktop;
}

class UserInterestsLayoutMetrics {
  UserInterestsLayoutMetrics(this.deviceType);

  final UserInterestsDeviceType deviceType;

  bool get isMobile => deviceType == UserInterestsDeviceType.mobile;
  bool get isTablet => deviceType == UserInterestsDeviceType.tablet;

  double get toolbarControlHeight => 36;
  double get toolbarFilterGap => isMobile ? 8 : 10;
  double get sectionGap => isMobile ? 12 : 16;
  double get cardGap => isMobile ? 8 : 10;
}
