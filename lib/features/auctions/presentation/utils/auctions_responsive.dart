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
        AuctionsDeviceType.mobileSmall => 10,
        AuctionsDeviceType.mobileLarge => 12,
        AuctionsDeviceType.tablet => 16,
        AuctionsDeviceType.desktop => 20,
      };

  double get pageTopPadding => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 10,
        AuctionsDeviceType.mobileLarge => 12,
        AuctionsDeviceType.tablet => 14,
        AuctionsDeviceType.desktop => 16,
      };

  double get sectionGap => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 8,
        AuctionsDeviceType.mobileLarge => 10,
        AuctionsDeviceType.tablet => 12,
        AuctionsDeviceType.desktop => 14,
      };

  double get panelRadius => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 12,
        AuctionsDeviceType.mobileLarge => 12,
        AuctionsDeviceType.tablet => 14,
        AuctionsDeviceType.desktop => 16,
      };

  double get panelPadding => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 12,
        AuctionsDeviceType.mobileLarge => 12,
        AuctionsDeviceType.tablet => 14,
        AuctionsDeviceType.desktop => 16,
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

  double get gridGap => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 8,
        AuctionsDeviceType.mobileLarge => 10,
        AuctionsDeviceType.tablet => 12,
        AuctionsDeviceType.desktop => 14,
      };

  double get gridTopPadding => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 10,
        AuctionsDeviceType.mobileLarge => 12,
        AuctionsDeviceType.tablet => 14,
        AuctionsDeviceType.desktop => 16,
      };
}

/// Image height scaled to auction card column width.
double auctionCardImageHeight(double cardWidth) {
  if (cardWidth < 180) return 100;
  if (cardWidth < 240) return 120;
  if (cardWidth < 320) return 140;
  return 160;
}
