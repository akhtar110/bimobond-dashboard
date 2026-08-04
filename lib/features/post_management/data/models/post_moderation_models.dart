import '../../../../core/utils/api_page_parser.dart';
import '../../domain/entities/post_moderation_entities.dart';

abstract final class PostModerationModels {
  static PostModerationActor? parseActor(dynamic value) {
    if (value is! Map) return null;
    final m = Map<String, dynamic>.from(value);
    final id = _string(m['id']) ?? _string(m['userId']);
    final username = _string(m['username']) ??
        _string(m['userName']) ??
        _string(m['name']);
    if (id == null && username == null) return null;
    return PostModerationActor(
      id: id ?? username ?? '',
      username: username ?? id ?? 'moderator',
      fullName: _string(m['fullName']) ?? _string(m['displayName']),
      avatarUrl: _string(m['avatarUrl']) ??
          _string(m['avatar']) ??
          _string(m['profileImage']),
    );
  }

  static PostModerationTimelineEntry parseTimelineEntry(Map<String, dynamic> m) {
    final moderatorRaw =
        m['moderator'] ?? m['admin'] ?? m['user'] ?? m['performedBy'] ?? m['actor'];
    final status = _string(m['status']) ??
        _string(m['newStatus']) ??
        _string(m['toStatus']) ??
        _string(m['action']) ??
        '';
    final createdAt = _date(
      m['createdAt'] ?? m['timestamp'] ?? m['actionDate'] ?? m['updatedAt'],
    );
    final id = _string(m['id']) ??
        _string(m['_id']) ??
        '${status}_${createdAt?.millisecondsSinceEpoch ?? 0}';

    return PostModerationTimelineEntry(
      id: id,
      status: status.toUpperCase(),
      reason: _string(m['reason']) ?? _string(m['changeReason']),
      note: _string(m['note']) ??
          _string(m['internalNote']) ??
          _string(m['moderatorNote']),
      createdAt: createdAt ?? DateTime.now(),
      moderator: parseActor(moderatorRaw),
      changedFields: _stringList(
        m['changedFields'] ??
            m['updatedFields'] ??
            m['fields'] ??
            m['modifiedFields'],
      ),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static PostModerationTimelinePage timelinePageFromJson(
    dynamic data, {
    required int page,
    required int limit,
  }) {
    final unwrapped = _unwrapTimelinePayload(data);
    final meta = ApiPageParser.extractMeta(unwrapped);
    final rawList = ApiPageParser.extractList(
      unwrapped,
      listKeys: const [
        'timeline',
        'actionTimeline',
        'moderationLogs',
        'moderationTimeline',
        'logs',
        'history',
        'actions',
        'items',
        'data',
        'results',
      ],
    );

    final items = rawList
        .whereType<Map>()
        .map((e) => parseTimelineEntry(Map<String, dynamic>.from(e)))
        .where((e) => e.status.isNotEmpty)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final currentPage = ApiPageParser.intMeta(meta, 'page', fallback: page);
    final totalPages = ApiPageParser.intMeta(
      meta,
      'totalPages',
      fallback: ApiPageParser.intMeta(meta, 'lastPage', fallback: currentPage),
    );
    final total = ApiPageParser.intMeta(meta, 'total', fallback: items.length);
    final hasMore = currentPage < totalPages || items.length >= limit;

    return PostModerationTimelinePage(
      items: items,
      page: currentPage,
      hasMore: hasMore,
      total: total,
    );
  }

  static dynamic _unwrapTimelinePayload(dynamic data) {
    if (data is List) return data;
    if (data is! Map) return data;
    final map = Map<String, dynamic>.from(data);
    final nested = map['data'];
    if (nested is Map &&
        (nested.containsKey('timeline') ||
            nested.containsKey('actionTimeline') ||
            nested.containsKey('items') ||
            nested.containsKey('logs'))) {
      return nested;
    }
    return map;
  }

  static String? _string(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
