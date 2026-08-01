/// Breakpoints and layout helpers for the auctions catalog.
enum AuctionsDeviceType {
  mobileSmall,
  mobileLarge,
  tablet,
  desktop,
}

AuctionsDeviceType getAuctionsDeviceType(double width) {
  if (width < 480) return AuctionsDeviceType.mobileSmall;
  if (width < 700) return AuctionsDeviceType.mobileLarge;
  if (width < 1100) return AuctionsDeviceType.tablet;
  return AuctionsDeviceType.desktop;
}

class AuctionsLayoutMetrics {
  const AuctionsLayoutMetrics(this.deviceType);

  final AuctionsDeviceType deviceType;

  static const double maxContentWidth = 1680;

  bool get isMobile =>
      deviceType == AuctionsDeviceType.mobileSmall ||
      deviceType == AuctionsDeviceType.mobileLarge;

  bool get isCompact => isMobile;

  /// Desktop uses numbered pages; mobile/tablet keep infinite scroll.
  bool get useDesktopPagination => deviceType == AuctionsDeviceType.desktop;

  bool get useInfiniteScroll => !useDesktopPagination;

  double get pageHorizontalPadding => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 8,
        AuctionsDeviceType.mobileLarge => 10,
        AuctionsDeviceType.tablet => 14,
        AuctionsDeviceType.desktop => 20,
      };

  double get pageTopPadding => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 4,
        AuctionsDeviceType.mobileLarge => 6,
        AuctionsDeviceType.tablet => 8,
        AuctionsDeviceType.desktop => 10,
      };

  double get sectionGap => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 4,
        AuctionsDeviceType.mobileLarge => 6,
        AuctionsDeviceType.tablet => 8,
        AuctionsDeviceType.desktop => 10,
      };

  double get panelRadius => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 10,
        AuctionsDeviceType.mobileLarge => 10,
        AuctionsDeviceType.tablet => 12,
        AuctionsDeviceType.desktop => 14,
      };

  double get panelPadding => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 10,
        AuctionsDeviceType.mobileLarge => 10,
        AuctionsDeviceType.tablet => 12,
        AuctionsDeviceType.desktop => 14,
      };

  double get filterGap => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 6,
        AuctionsDeviceType.mobileLarge => 8,
        AuctionsDeviceType.tablet => 8,
        AuctionsDeviceType.desktop => 10,
      };

  double get toolbarFilterGap => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 4,
        AuctionsDeviceType.mobileLarge => 6,
        AuctionsDeviceType.tablet => 6,
        AuctionsDeviceType.desktop => 8,
      };

  double get filterControlHeight => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 32,
        AuctionsDeviceType.mobileLarge => 34,
        AuctionsDeviceType.tablet => 36,
        AuctionsDeviceType.desktop => 36,
      };

  /// Compact search field — shorter than toolbar action buttons.
  double get searchControlHeight => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 28,
        AuctionsDeviceType.mobileLarge => 28,
        AuctionsDeviceType.tablet => 30,
        AuctionsDeviceType.desktop => 30,
      };

  double get searchMaxWidth => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 200,
        AuctionsDeviceType.mobileLarge => 220,
        AuctionsDeviceType.tablet => 240,
        AuctionsDeviceType.desktop => 260,
      };

  double get gridGap => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 8,
        AuctionsDeviceType.mobileLarge => 10,
        AuctionsDeviceType.tablet => 12,
        AuctionsDeviceType.desktop => 14,
      };

  double get gridTopPadding => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 6,
        AuctionsDeviceType.mobileLarge => 8,
        AuctionsDeviceType.tablet => 10,
        AuctionsDeviceType.desktop => 12,
      };

  /// Toolbar shows search + actions on one row at this width and above.
  static const double toolbarInlineBreakpoint = 640;

  /// Header uses a single top row (title | tabs | refresh).
  static const double headerWideBreakpoint = 900;

  /// Title and refresh share one row; tabs move below.
  static const double headerMediumBreakpoint = 520;

  bool toolbarInlineAt(double width) => width >= toolbarInlineBreakpoint;

  bool headerWideAt(double width) => width >= headerWideBreakpoint;

  bool headerMediumAt(double width) => width >= headerMediumBreakpoint;

  double titleFontSizeAt(double width) {
    if (width < 480) return 18;
    if (width < headerWideBreakpoint) return 19;
    return 20;
  }

  /// Preferred search width when inline with action buttons.
  double inlineSearchWidthFor(double availableWidth) {
    final actionsWidth = (filterControlHeight * 3) + (filterGap + 2) * 3 + 24;
    final maxSearch = (availableWidth - actionsWidth).clamp(120.0, 420.0);
    if (availableWidth < toolbarInlineBreakpoint) {
      return availableWidth;
    }
    return maxSearch.clamp(searchMaxWidth * 0.85, searchMaxWidth * 1.35);
  }
}

/// Image height scaled to auction card column width.
double auctionCardImageHeight(double cardWidth) {
  if (cardWidth < 180) return 100;
  if (cardWidth < 240) return 120;
  if (cardWidth < 320) return 140;
  return 160;
}
