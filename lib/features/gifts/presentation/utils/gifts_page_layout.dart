import 'gifts_responsive.dart';

/// Responsive column count for the admin gift grid.
int giftsGridColumnCount(double width) {
  if (width > 1500) return 7;
  if (width > 1200) return 6;
  if (width > 980) return 5;
  if (width > 760) return 4;
  if (width > 520) return 3;
  if (width > 360) return 2;
  return 1;
}

double giftsPageHorizontalPadding(double width) =>
    GiftsLayoutMetrics(getGiftsDeviceType(width)).pageHorizontalPadding;

enum GiftsTableDensity { wide, medium, narrow }

GiftsTableDensity giftsTableDensityForWidth(double width) {
  if (width >= 1180) return GiftsTableDensity.wide;
  if (width >= 820) return GiftsTableDensity.medium;
  return GiftsTableDensity.narrow;
}
