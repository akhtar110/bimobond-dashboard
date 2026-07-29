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
    FiltersEffectsDeviceType.mobileSmall => 6,
    FiltersEffectsDeviceType.mobileLarge => 6,
    FiltersEffectsDeviceType.tabletSmall => 8,
    FiltersEffectsDeviceType.tablet => 8,
    FiltersEffectsDeviceType.laptop => 8,
    FiltersEffectsDeviceType.desktop => 10,
    FiltersEffectsDeviceType.desktopWide => 10,
  };

  double get pageBottomPadding => switch (deviceType) {
    FiltersEffectsDeviceType.mobileSmall => 10,
    FiltersEffectsDeviceType.mobileLarge => 10,
    FiltersEffectsDeviceType.tabletSmall => 12,
    FiltersEffectsDeviceType.tablet => 12,
    FiltersEffectsDeviceType.laptop => 12,
    FiltersEffectsDeviceType.desktop => 14,
    FiltersEffectsDeviceType.desktopWide => 16,
  };

  double get sectionGap => switch (deviceType) {
    FiltersEffectsDeviceType.mobileSmall => 4,
    FiltersEffectsDeviceType.mobileLarge => 4,
    FiltersEffectsDeviceType.tabletSmall => 5,
    FiltersEffectsDeviceType.tablet => 6,
    FiltersEffectsDeviceType.laptop => 6,
    FiltersEffectsDeviceType.desktop => 8,
    FiltersEffectsDeviceType.desktopWide => 8,
  };

  double get toolbarSectionGap => switch (deviceType) {
    FiltersEffectsDeviceType.mobileSmall => 4,
    FiltersEffectsDeviceType.mobileLarge => 4,
    FiltersEffectsDeviceType.tabletSmall => 4,
    FiltersEffectsDeviceType.tablet => 5,
    FiltersEffectsDeviceType.laptop => 6,
    FiltersEffectsDeviceType.desktop => 6,
    FiltersEffectsDeviceType.desktopWide => 8,
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
    FiltersEffectsDeviceType.mobileSmall => 4,
    FiltersEffectsDeviceType.mobileLarge => 4,
    FiltersEffectsDeviceType.tabletSmall => 4,
    FiltersEffectsDeviceType.tablet => 4,
    FiltersEffectsDeviceType.laptop => 5,
    FiltersEffectsDeviceType.desktop => 6,
    FiltersEffectsDeviceType.desktopWide => 6,
  };

  double get toolbarControlHeight => switch (deviceType) {
    FiltersEffectsDeviceType.mobileSmall => 36,
    FiltersEffectsDeviceType.mobileLarge => 36,
    FiltersEffectsDeviceType.tabletSmall => 38,
    FiltersEffectsDeviceType.tablet => 38,
    FiltersEffectsDeviceType.laptop => 40,
    FiltersEffectsDeviceType.desktop => 40,
    FiltersEffectsDeviceType.desktopWide => 40,
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
