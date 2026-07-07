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
  if (width < 1200) return AuctionsDeviceType.tablet;
  return AuctionsDeviceType.desktop;
}

class AuctionsLayoutMetrics {
  const AuctionsLayoutMetrics(this.deviceType);

  final AuctionsDeviceType deviceType;

  bool get isMobile =>
      deviceType == AuctionsDeviceType.mobileSmall ||
      deviceType == AuctionsDeviceType.mobileLarge;

  double get pageHorizontalPadding => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 8,
        AuctionsDeviceType.mobileLarge => 10,
        AuctionsDeviceType.tablet => 14,
        AuctionsDeviceType.desktop => 20,
      };

  double get pageTopPadding => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 8,
        AuctionsDeviceType.mobileLarge => 10,
        AuctionsDeviceType.tablet => 14,
        AuctionsDeviceType.desktop => 20,
      };

  double get sectionGap => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 6,
        AuctionsDeviceType.mobileLarge => 8,
        AuctionsDeviceType.tablet => 10,
        AuctionsDeviceType.desktop => 12,
      };

  double get filterGap => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 4,
        AuctionsDeviceType.mobileLarge => 5,
        AuctionsDeviceType.tablet => 6,
        AuctionsDeviceType.desktop => 8,
      };

  double get toolbarFilterGap => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 3,
        AuctionsDeviceType.mobileLarge => 4,
        AuctionsDeviceType.tablet => 5,
        AuctionsDeviceType.desktop => 8,
      };

  double get filterControlHeight => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 28,
        AuctionsDeviceType.mobileLarge => 30,
        AuctionsDeviceType.tablet => 32,
        AuctionsDeviceType.desktop => 32,
      };

  double get gridGap => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 8,
        AuctionsDeviceType.mobileLarge => 8,
        AuctionsDeviceType.tablet => 10,
        AuctionsDeviceType.desktop => 12,
      };

  double get gridTopPadding => switch (deviceType) {
        AuctionsDeviceType.mobileSmall => 8,
        AuctionsDeviceType.mobileLarge => 10,
        AuctionsDeviceType.tablet => 12,
        AuctionsDeviceType.desktop => 14,
      };
}

/// Image height scaled to auction card column width.
double auctionCardImageHeight(double cardWidth) {
  if (cardWidth < 180) return 100;
  if (cardWidth < 240) return 120;
  if (cardWidth < 320) return 140;
  return 160;
}
