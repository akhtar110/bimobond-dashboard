enum SearchHistoryDeviceType {
  mobileSmall,
  mobileLarge,
  tablet,
  desktop,
}

SearchHistoryDeviceType getSearchHistoryDeviceType(double width) {
  if (width < 480) return SearchHistoryDeviceType.mobileSmall;
  if (width < 700) return SearchHistoryDeviceType.mobileLarge;
  if (width < 1200) return SearchHistoryDeviceType.tablet;
  return SearchHistoryDeviceType.desktop;
}

/// Responsive layout tokens for search history screens.
class SearchHistoryLayoutMetrics {
  const SearchHistoryLayoutMetrics(this.deviceType);

  final SearchHistoryDeviceType deviceType;

  bool get isMobile =>
      deviceType == SearchHistoryDeviceType.mobileSmall ||
      deviceType == SearchHistoryDeviceType.mobileLarge;

  double get pageHorizontalPadding => switch (deviceType) {
        SearchHistoryDeviceType.mobileSmall => 8,
        SearchHistoryDeviceType.mobileLarge => 10,
        SearchHistoryDeviceType.tablet => 12,
        SearchHistoryDeviceType.desktop => 20,
      };

  double get pageTopPadding => switch (deviceType) {
        SearchHistoryDeviceType.mobileSmall => 6,
        SearchHistoryDeviceType.mobileLarge => 8,
        SearchHistoryDeviceType.tablet => 10,
        SearchHistoryDeviceType.desktop => 16,
      };

  double get pageBottomPadding => switch (deviceType) {
        SearchHistoryDeviceType.mobileSmall => 10,
        SearchHistoryDeviceType.mobileLarge => 12,
        SearchHistoryDeviceType.tablet => 14,
        SearchHistoryDeviceType.desktop => 24,
      };

  double get sectionGap => switch (deviceType) {
        SearchHistoryDeviceType.mobileSmall => 4,
        SearchHistoryDeviceType.mobileLarge => 6,
        SearchHistoryDeviceType.tablet => 8,
        SearchHistoryDeviceType.desktop => 10,
      };

  double get toolbarSectionGap => switch (deviceType) {
        SearchHistoryDeviceType.mobileSmall => 3,
        SearchHistoryDeviceType.mobileLarge => 4,
        SearchHistoryDeviceType.tablet => 5,
        SearchHistoryDeviceType.desktop => 8,
      };

  double get filterGap => switch (deviceType) {
        SearchHistoryDeviceType.mobileSmall => 3,
        SearchHistoryDeviceType.mobileLarge => 4,
        SearchHistoryDeviceType.tablet => 5,
        SearchHistoryDeviceType.desktop => 6,
      };

  double get toolbarFilterGap => switch (deviceType) {
        SearchHistoryDeviceType.mobileSmall => 2,
        SearchHistoryDeviceType.mobileLarge => 3,
        SearchHistoryDeviceType.tablet => 4,
        SearchHistoryDeviceType.desktop => 6,
      };

  double get toolbarControlHeight => switch (deviceType) {
        SearchHistoryDeviceType.mobileSmall => 36,
        SearchHistoryDeviceType.mobileLarge => 38,
        SearchHistoryDeviceType.tablet => 40,
        SearchHistoryDeviceType.desktop => 42,
      };

  bool get useDesktopPagination => deviceType == SearchHistoryDeviceType.desktop;
}
