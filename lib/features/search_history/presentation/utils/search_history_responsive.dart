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
        SearchHistoryDeviceType.tablet => 14,
        SearchHistoryDeviceType.desktop => 24,
      };

  double get pageTopPadding => switch (deviceType) {
        SearchHistoryDeviceType.mobileSmall => 8,
        SearchHistoryDeviceType.mobileLarge => 10,
        SearchHistoryDeviceType.tablet => 12,
        SearchHistoryDeviceType.desktop => 24,
      };

  double get pageBottomPadding => switch (deviceType) {
        SearchHistoryDeviceType.mobileSmall => 12,
        SearchHistoryDeviceType.mobileLarge => 14,
        SearchHistoryDeviceType.tablet => 16,
        SearchHistoryDeviceType.desktop => 32,
      };

  double get sectionGap => switch (deviceType) {
        SearchHistoryDeviceType.mobileSmall => 6,
        SearchHistoryDeviceType.mobileLarge => 8,
        SearchHistoryDeviceType.tablet => 10,
        SearchHistoryDeviceType.desktop => 12,
      };

  double get toolbarSectionGap => switch (deviceType) {
        SearchHistoryDeviceType.mobileSmall => 4,
        SearchHistoryDeviceType.mobileLarge => 5,
        SearchHistoryDeviceType.tablet => 6,
        SearchHistoryDeviceType.desktop => 10,
      };

  double get filterGap => switch (deviceType) {
        SearchHistoryDeviceType.mobileSmall => 4,
        SearchHistoryDeviceType.mobileLarge => 5,
        SearchHistoryDeviceType.tablet => 6,
        SearchHistoryDeviceType.desktop => 8,
      };

  double get toolbarFilterGap => switch (deviceType) {
        SearchHistoryDeviceType.mobileSmall => 3,
        SearchHistoryDeviceType.mobileLarge => 4,
        SearchHistoryDeviceType.tablet => 5,
        SearchHistoryDeviceType.desktop => 8,
      };

  double get toolbarControlHeight => switch (deviceType) {
        SearchHistoryDeviceType.mobileSmall => 38,
        SearchHistoryDeviceType.mobileLarge => 40,
        SearchHistoryDeviceType.tablet => 42,
        SearchHistoryDeviceType.desktop => 44,
      };

  bool get useDesktopPagination => deviceType == SearchHistoryDeviceType.desktop;
}
