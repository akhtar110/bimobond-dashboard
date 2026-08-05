/// Normalizes API post status strings for models and UI.
String normalizePostStatus(String? raw, {String fallback = 'PUBLISHED'}) {
  if (raw == null) return fallback;
  var value = raw.trim();
  if (value.isEmpty) return fallback;

  // camelCase → SNAKE_CASE (e.g. underReview → UNDER_REVIEW)
  value = value.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (match) => '${match[1]}_${match[2]}',
  );
  value = value.replaceAll(RegExp(r'[\s-]+'), '_').toUpperCase();

  const aliases = {
    'UNDERREVIEW': 'UNDER_REVIEW',
  };
  return aliases[value] ?? value;
}

bool isDraftPostStatus(String status) =>
    normalizePostStatus(status) == 'DRAFT';

bool isPublishedPostStatus(String status) =>
    normalizePostStatus(status) == 'PUBLISHED';

String? readPostStatusFromJson(Map<String, dynamic> json) {
  final raw = json['status'] ?? json['postStatus'] ?? json['post_status'];
  if (raw == null) return null;
  final value = raw.toString().trim();
  return value.isEmpty ? null : value;
}
