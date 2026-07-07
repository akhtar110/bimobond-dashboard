import 'package:flutter/material.dart';

enum ReportsDeviceType {
  mobileSmall,
  mobileLarge,
  tablet,
  desktop,
}

ReportsDeviceType getReportsDeviceType(double width) {
  if (width < 480) return ReportsDeviceType.mobileSmall;
  if (width < 700) return ReportsDeviceType.mobileLarge;
  if (width < 1200) return ReportsDeviceType.tablet;
  return ReportsDeviceType.desktop;
}

class ReportsLayoutMetrics {
  const ReportsLayoutMetrics(this.deviceType);

  final ReportsDeviceType deviceType;

  bool get isMobile =>
      deviceType == ReportsDeviceType.mobileSmall ||
      deviceType == ReportsDeviceType.mobileLarge;

  bool get useDesktopPagination =>
      deviceType == ReportsDeviceType.desktop;

  bool get useInfiniteScroll => !useDesktopPagination;

  double get pageHorizontalPadding => switch (deviceType) {
        ReportsDeviceType.mobileSmall => 8,
        ReportsDeviceType.mobileLarge => 10,
        ReportsDeviceType.tablet => 12,
        ReportsDeviceType.desktop => 16,
      };

  double get sectionGap => switch (deviceType) {
        ReportsDeviceType.mobileSmall => 6,
        ReportsDeviceType.mobileLarge => 8,
        ReportsDeviceType.tablet => 10,
        ReportsDeviceType.desktop => 12,
      };

  double get filterGap => switch (deviceType) {
        ReportsDeviceType.mobileSmall => 4,
        ReportsDeviceType.mobileLarge => 5,
        ReportsDeviceType.tablet => 6,
        ReportsDeviceType.desktop => 8,
      };

  double get tableMinWidth => switch (deviceType) {
        ReportsDeviceType.mobileSmall => 0,
        ReportsDeviceType.mobileLarge => 0,
        ReportsDeviceType.tablet => 720,
        ReportsDeviceType.desktop => 980,
      };
}

ReportsLayoutMetrics reportsMetricsOf(BuildContext context) {
  return ReportsLayoutMetrics(
    getReportsDeviceType(MediaQuery.sizeOf(context).width),
  );
}

bool reportsUseInfiniteScroll(double width) => width < 1200;

bool reportsUseDesktopPagination(double width) => width >= 1200;

const double reportsScrollLoadThreshold = 300;

bool reportsShouldLoadMore(ScrollController controller) {
  if (!controller.hasClients) return false;
  final position = controller.position;
  return position.pixels >= position.maxScrollExtent - reportsScrollLoadThreshold;
}
