Future<({String name, List<int> bytes})?> pickFilterLutFile() async => null;

bool isAllowedFilterLutFilename(String filename) {
  final lower = filename.toLowerCase();
  return lower.endsWith('.cube') || lower.endsWith('.png');
}
