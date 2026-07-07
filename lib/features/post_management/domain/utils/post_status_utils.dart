/// Normalizes API post status strings for models and UI.
String normalizePostStatus(String? raw, {String fallback = 'PUBLISHED'}) {
  if (raw == null) return fallback;
  final value = raw.trim().toUpperCase();
  if (value.isEmpty) return fallback;
  return value;
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
