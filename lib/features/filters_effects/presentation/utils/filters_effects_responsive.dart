enum FiltersEffectsDeviceType {
  mobileSmall,
  mobileLarge,
  tabletSmall,
  tablet,
  laptop,
  desktop,
  desktopWide,
}

FiltersEffectsDeviceType getFiltersEffectsDeviceType(double width) {
  if (width < 480) return FiltersEffectsDeviceType.mobileSmall;
  if (width < 600) return FiltersEffectsDeviceType.mobileLarge;
  if (width < 768) return FiltersEffectsDeviceType.tabletSmall;
  if (width < 992) return FiltersEffectsDeviceType.tablet;
  if (width < 1200) return FiltersEffectsDeviceType.laptop;
  if (width < 1400) return FiltersEffectsDeviceType.desktop;
  return FiltersEffectsDeviceType.desktopWide;
}

/// Responsive layout tokens for filters & effects admin screens.
class FiltersEffectsLayoutMetrics {
  const FiltersEffectsLayoutMetrics(this.deviceType);

  final FiltersEffectsDeviceType deviceType;

  bool get isMobile =>
      deviceType == FiltersEffectsDeviceType.mobileSmall ||
      deviceType == FiltersEffectsDeviceType.mobileLarge;

  bool get isCompact =>
      isMobile || deviceType == FiltersEffectsDeviceType.tabletSmall;

  bool get useDesktopPagination =>
      deviceType == FiltersEffectsDeviceType.desktop ||
      deviceType == FiltersEffectsDeviceType.desktopWide;

  double get pageHorizontalPadding => switch (deviceType) {
    FiltersEffectsDeviceType.mobileSmall => 8,
    FiltersEffectsDeviceType.mobileLarge => 10,
    FiltersEffectsDeviceType.tabletSmall => 12,
    FiltersEffectsDeviceType.tablet => 14,
    FiltersEffectsDeviceType.laptop => 18,
    FiltersEffectsDeviceType.desktop => 22,
    FiltersEffectsDeviceType.desktopWide => 24,
  };

  double get pageTopPadding => switch (deviceType) {
    FiltersEffectsDeviceType.mobileSmall => 8,
    FiltersEffectsDeviceType.mobileLarge => 10,
    FiltersEffectsDeviceType.tabletSmall => 10,
    FiltersEffectsDeviceType.tablet => 12,
    FiltersEffectsDeviceType.laptop => 16,
    FiltersEffectsDeviceType.desktop => 20,
    FiltersEffectsDeviceType.desktopWide => 24,
  };

  double get pageBottomPadding => switch (deviceType) {
    FiltersEffectsDeviceType.mobileSmall => 12,
    FiltersEffectsDeviceType.mobileLarge => 14,
    FiltersEffectsDeviceType.tabletSmall => 14,
    FiltersEffectsDeviceType.tablet => 16,
    FiltersEffectsDeviceType.laptop => 20,
    FiltersEffectsDeviceType.desktop => 28,
    FiltersEffectsDeviceType.desktopWide => 32,
  };

  double get sectionGap => switch (deviceType) {
    FiltersEffectsDeviceType.mobileSmall => 6,
    FiltersEffectsDeviceType.mobileLarge => 8,
    FiltersEffectsDeviceType.tabletSmall => 8,
    FiltersEffectsDeviceType.tablet => 10,
    FiltersEffectsDeviceType.laptop => 10,
    FiltersEffectsDeviceType.desktop => 12,
    FiltersEffectsDeviceType.desktopWide => 14,
  };

  double get toolbarSectionGap => switch (deviceType) {
    FiltersEffectsDeviceType.mobileSmall => 4,
    FiltersEffectsDeviceType.mobileLarge => 5,
    FiltersEffectsDeviceType.tabletSmall => 5,
    FiltersEffectsDeviceType.tablet => 6,
    FiltersEffectsDeviceType.laptop => 8,
    FiltersEffectsDeviceType.desktop => 10,
    FiltersEffectsDeviceType.desktopWide => 12,
  };

  double get filterGap => switch (deviceType) {
    FiltersEffectsDeviceType.mobileSmall => 4,
    FiltersEffectsDeviceType.mobileLarge => 5,
    FiltersEffectsDeviceType.tabletSmall => 6,
    FiltersEffectsDeviceType.tablet => 6,
    FiltersEffectsDeviceType.laptop => 8,
    FiltersEffectsDeviceType.desktop => 8,
    FiltersEffectsDeviceType.desktopWide => 10,
  };

  double get toolbarFilterGap => switch (deviceType) {
    FiltersEffectsDeviceType.mobileSmall => 3,
    FiltersEffectsDeviceType.mobileLarge => 4,
    FiltersEffectsDeviceType.tabletSmall => 4,
    FiltersEffectsDeviceType.tablet => 5,
    FiltersEffectsDeviceType.laptop => 6,
    FiltersEffectsDeviceType.desktop => 8,
    FiltersEffectsDeviceType.desktopWide => 8,
  };

  double get toolbarControlHeight => switch (deviceType) {
    FiltersEffectsDeviceType.mobileSmall => 38,
    FiltersEffectsDeviceType.mobileLarge => 40,
    FiltersEffectsDeviceType.tabletSmall => 40,
    FiltersEffectsDeviceType.tablet => 42,
    FiltersEffectsDeviceType.laptop => 42,
    FiltersEffectsDeviceType.desktop => 44,
    FiltersEffectsDeviceType.desktopWide => 44,
  };

  double get kpiMinTileWidth => switch (deviceType) {
    FiltersEffectsDeviceType.mobileSmall => 140,
    FiltersEffectsDeviceType.mobileLarge => 150,
    FiltersEffectsDeviceType.tabletSmall => 160,
    FiltersEffectsDeviceType.tablet => 170,
    FiltersEffectsDeviceType.laptop => 180,
    FiltersEffectsDeviceType.desktop => 190,
    FiltersEffectsDeviceType.desktopWide => 200,
  };
}
