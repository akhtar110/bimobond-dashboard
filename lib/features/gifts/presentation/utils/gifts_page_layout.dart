import 'gifts_responsive.dart';

/// Responsive column count for the admin gift grid.
int giftsGridColumnCount(double width) {
  if (width > 1600) return 6;
  if (width > 1300) return 5;
  if (width > 1000) return 4;
  if (width > 700) return 3;
  if (width > 480) return 2;
  return 1;
}

double giftsPageHorizontalPadding(double width) =>
    GiftsLayoutMetrics(getGiftsDeviceType(width)).pageHorizontalPadding;

enum GiftsTableDensity { wide, medium, narrow }

GiftsTableDensity giftsTableDensityForWidth(double width) {
  if (width >= 1100) return GiftsTableDensity.wide;
  if (width >= 760) return GiftsTableDensity.medium;
  return GiftsTableDensity.narrow;
}
