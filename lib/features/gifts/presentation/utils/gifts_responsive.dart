/// Breakpoints and layout helpers for the gifts catalog.
enum GiftsDeviceType {
  mobileSmall,
  mobileLarge,
  tablet,
  desktop,
}

GiftsDeviceType getGiftsDeviceType(double width) {
  if (width < 480) return GiftsDeviceType.mobileSmall;
  if (width < 700) return GiftsDeviceType.mobileLarge;
  if (width < 960) return GiftsDeviceType.tablet;
  return GiftsDeviceType.desktop;
}

class GiftsLayoutMetrics {
  const GiftsLayoutMetrics(this.deviceType);

  final GiftsDeviceType deviceType;

  bool get isMobile =>
      deviceType == GiftsDeviceType.mobileSmall ||
      deviceType == GiftsDeviceType.mobileLarge;

  /// Desktop uses numbered pages; mobile/tablet keep infinite scroll.
  bool get useDesktopPagination => deviceType == GiftsDeviceType.desktop;

  bool get useInfiniteScroll => !useDesktopPagination;

  double get pageHorizontalPadding => switch (deviceType) {
        GiftsDeviceType.mobileSmall => 8,
        GiftsDeviceType.mobileLarge => 10,
        GiftsDeviceType.tablet => 14,
        GiftsDeviceType.desktop => 20,
      };

  double get filterGap => switch (deviceType) {
        GiftsDeviceType.mobileSmall => 4,
        GiftsDeviceType.mobileLarge => 5,
        GiftsDeviceType.tablet => 6,
        GiftsDeviceType.desktop => 8,
      };

  double get toolbarFilterGap => switch (deviceType) {
        GiftsDeviceType.mobileSmall => 3,
        GiftsDeviceType.mobileLarge => 4,
        GiftsDeviceType.tablet => 5,
        GiftsDeviceType.desktop => 10,
      };

  double get filterControlHeight => switch (deviceType) {
        GiftsDeviceType.mobileSmall => 38,
        GiftsDeviceType.mobileLarge => 40,
        GiftsDeviceType.tablet => 44,
        GiftsDeviceType.desktop => 48,
      };

  double get tabStripHeight => switch (deviceType) {
        GiftsDeviceType.mobileSmall => 32,
        GiftsDeviceType.mobileLarge => 36,
        GiftsDeviceType.tablet => 40,
        GiftsDeviceType.desktop => 44,
      };

  double get filterBarTopPadding => switch (deviceType) {
        GiftsDeviceType.mobileSmall => 4,
        GiftsDeviceType.mobileLarge => 6,
        GiftsDeviceType.tablet => 8,
        GiftsDeviceType.desktop => 8,
      };

  double get filterBarBottomPadding => switch (deviceType) {
        GiftsDeviceType.mobileSmall => 4,
        GiftsDeviceType.mobileLarge => 6,
        GiftsDeviceType.tablet => 8,
        GiftsDeviceType.desktop => 8,
      };

  double get gridGap => switch (deviceType) {
        GiftsDeviceType.mobileSmall => 8,
        GiftsDeviceType.mobileLarge => 8,
        GiftsDeviceType.tablet => 10,
        GiftsDeviceType.desktop => 12,
      };

  double get gridTopPadding => switch (deviceType) {
        GiftsDeviceType.mobileSmall => 8,
        GiftsDeviceType.mobileLarge => 10,
        GiftsDeviceType.tablet => 12,
        GiftsDeviceType.desktop => 14,
      };

  double get toolbarControlRadius => switch (deviceType) {
        GiftsDeviceType.mobileSmall => 12,
        GiftsDeviceType.mobileLarge => 14,
        GiftsDeviceType.tablet => 15,
        GiftsDeviceType.desktop => 16,
      };

  bool get useCompactFilterToolbar => isMobile;

  bool get hideResultsCountInline => deviceType == GiftsDeviceType.mobileSmall;
}

/// Pinned filter bar height for [GiftsFilterBarDelegate].
double giftsFilterBarHeight(double width) {
  final m = GiftsLayoutMetrics(getGiftsDeviceType(width));
  final top = m.filterBarTopPadding;
  final bottom = m.filterBarBottomPadding;
  final tabs = m.tabStripHeight;
  final gap = m.filterGap;
  final control = m.filterControlHeight;
  final resultsLine = m.hideResultsCountInline ? 14.0 + m.toolbarFilterGap : 0.0;

  if (width >= 760) {
    return top + tabs + gap + control + bottom + 4;
  }

  if (m.useCompactFilterToolbar) {
    return top +
        tabs +
        resultsLine +
        gap +
        control +
        m.toolbarFilterGap +
        control +
        bottom;
  }

  return top +
      tabs +
      resultsLine +
      gap +
      control +
      m.toolbarFilterGap +
      control +
      m.toolbarFilterGap +
      control +
      bottom;
}
