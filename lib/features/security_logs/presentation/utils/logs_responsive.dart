enum LogsDeviceType { mobile, tablet, desktop }

LogsDeviceType getLogsDeviceType(double width) {
  if (width < 640) return LogsDeviceType.mobile;
  if (width < 1024) return LogsDeviceType.tablet;
  return LogsDeviceType.desktop;
}

class LogsLayoutMetrics {
  LogsLayoutMetrics(this.device);

  final LogsDeviceType device;

  bool get isMobile => device == LogsDeviceType.mobile;
  bool get isTablet => device == LogsDeviceType.tablet;

  double get pageHorizontalPadding {
    if (isMobile) return 12;
    if (isTablet) return 16;
    return 24;
  }

  double get pageTopPadding => isMobile ? 10 : 16;
  double get pageBottomPadding => isMobile ? 10 : 16;
  double get toolbarSectionGap => isMobile ? 8 : (isTablet ? 12 : 14);
  double get toolbarFilterGap => isMobile ? 6 : 10;
  double get sectionGap => isMobile ? 10 : (isTablet ? 12 : 16);
}
