/// Responsive column count for the admin posts grid.
/// Matches gifts/auctions so cards share the same card width.
int postsGridColumnCount(double width) {
  if (width > 1500) return 7;
  if (width > 1200) return 6;
  if (width > 980) return 5;
  if (width > 760) return 4;
  if (width > 520) return 3;
  if (width > 360) return 2;
  return 1;
}
