/// Shared responsive breakpoints and helpers for the admin dashboard.
library;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Breakpoint constants
// ---------------------------------------------------------------------------

abstract final class AppBreakpoints {
  static const double mobile  = 480;
  static const double tablet  = 768;
  static const double laptop  = 1024;
  static const double desktop = 1280;

  static AppBreakpoint of(double width) {
    if (width < mobile)  return AppBreakpoint.mobile;
    if (width < tablet)  return AppBreakpoint.tablet;
    if (width < laptop)  return AppBreakpoint.laptop;
    return AppBreakpoint.desktop;
  }

  static double contentHPad(double width) {
    if (width < mobile)  return 8;
    if (width < tablet)  return 12;
    if (width < laptop)  return 16;
    return 20;
  }

  static double contentVPad(double width) {
    if (width < mobile)  return 8;
    if (width < tablet)  return 10;
    return 14;
  }
}

// ---------------------------------------------------------------------------
// Breakpoint enum
// ---------------------------------------------------------------------------

enum AppBreakpoint {
  mobile,
  tablet,
  laptop,
  desktop;

  bool operator >=(AppBreakpoint other) => index >= other.index;
  bool operator >(AppBreakpoint other)  => index > other.index;
  bool operator <=(AppBreakpoint other) => index <= other.index;
  bool operator <(AppBreakpoint other)  => index < other.index;
}

// ---------------------------------------------------------------------------
// BuildContext extension
// ---------------------------------------------------------------------------

extension AppBreakpointContext on BuildContext {
  AppBreakpoint get breakpoint =>
      AppBreakpoints.of(MediaQuery.sizeOf(this).width);
  bool get isMobileScreen => breakpoint == AppBreakpoint.mobile;
  bool get isTabletScreen => breakpoint == AppBreakpoint.tablet;
  bool get isWideScreen   => breakpoint >= AppBreakpoint.laptop;
}
