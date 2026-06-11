import 'package:flutter/material.dart';

/// Shared layout breakpoints for the reports center shell and tabs.
abstract final class ReportsCenterBreakpoints {
  static const double compactMax = 720;
  static const double stackedHeaderMax = 960;
  static const double navRailMin = 1100;
  static const double maxContentWidth = 1680;
  static const double maxContentWidthXl = 1840;

  static bool isCompact(double width) => width < compactMax;

  static bool useNavRail(double width) => width >= navRailMin;

  static bool useNavDrawer(double width) =>
      width < compactMax;

  static bool useHorizontalTabStrip(double width) =>
      !useNavRail(width) && !useNavDrawer(width);

  static EdgeInsets pagePadding(double width) {
    if (useNavRail(width)) {
      return const EdgeInsets.fromLTRB(20, 16, 24, 20);
    }
    if (isCompact(width)) {
      return const EdgeInsets.fromLTRB(12, 12, 12, 16);
    }
    return const EdgeInsets.fromLTRB(16, 14, 16, 18);
  }

  static double detailPanelWidth(double screenWidth) {
    if (screenWidth < compactMax) return screenWidth;
    if (screenWidth < navRailMin) {
      return (screenWidth * 0.72).clamp(360, 520);
    }
    return (screenWidth * 0.42).clamp(420, 560);
  }
}
