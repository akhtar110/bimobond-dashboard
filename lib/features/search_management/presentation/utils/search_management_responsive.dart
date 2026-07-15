enum SearchManagementDeviceType {
  mobileSmall,
  mobileLarge,
  tablet,
  desktop,
}

SearchManagementDeviceType getSearchManagementDeviceType(double width) {
  if (width < 480) return SearchManagementDeviceType.mobileSmall;
  if (width < 700) return SearchManagementDeviceType.mobileLarge;
  if (width < 1200) return SearchManagementDeviceType.tablet;
  return SearchManagementDeviceType.desktop;
}

class SearchManagementLayoutMetrics {
  const SearchManagementLayoutMetrics(this.deviceType);

  final SearchManagementDeviceType deviceType;

  bool get isMobile =>
      deviceType == SearchManagementDeviceType.mobileSmall ||
      deviceType == SearchManagementDeviceType.mobileLarge;

  bool get useCompactTable => isMobile;

  double get pageHorizontalPadding => switch (deviceType) {
        SearchManagementDeviceType.mobileSmall => 8,
        SearchManagementDeviceType.mobileLarge => 10,
        SearchManagementDeviceType.tablet => 12,
        SearchManagementDeviceType.desktop => 20,
      };

  double get pageTopPadding => switch (deviceType) {
        SearchManagementDeviceType.mobileSmall => 6,
        SearchManagementDeviceType.mobileLarge => 8,
        SearchManagementDeviceType.tablet => 10,
        SearchManagementDeviceType.desktop => 16,
      };

  double get pageBottomPadding => switch (deviceType) {
        SearchManagementDeviceType.mobileSmall => 10,
        SearchManagementDeviceType.mobileLarge => 12,
        SearchManagementDeviceType.tablet => 14,
        SearchManagementDeviceType.desktop => 24,
      };

  double get sectionGap => switch (deviceType) {
        SearchManagementDeviceType.mobileSmall => 4,
        SearchManagementDeviceType.mobileLarge => 6,
        SearchManagementDeviceType.tablet => 8,
        SearchManagementDeviceType.desktop => 10,
      };

  double get filterGap => switch (deviceType) {
        SearchManagementDeviceType.mobileSmall => 3,
        SearchManagementDeviceType.mobileLarge => 4,
        SearchManagementDeviceType.tablet => 5,
        SearchManagementDeviceType.desktop => 6,
      };

  double get toolbarFilterGap => switch (deviceType) {
        SearchManagementDeviceType.mobileSmall => 2,
        SearchManagementDeviceType.mobileLarge => 3,
        SearchManagementDeviceType.tablet => 4,
        SearchManagementDeviceType.desktop => 6,
      };

  double get toolbarControlHeight => switch (deviceType) {
        SearchManagementDeviceType.mobileSmall => 36,
        SearchManagementDeviceType.mobileLarge => 38,
        SearchManagementDeviceType.tablet => 40,
        SearchManagementDeviceType.desktop => 42,
      };
}
