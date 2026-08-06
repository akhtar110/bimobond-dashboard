import '../../domain/entities/user_history_entity.dart';

class UserHistoryItemModel extends UserHistoryEntity {
  const UserHistoryItemModel({
    required super.type,
    required super.createdAt,
    required super.data,
  });

  factory UserHistoryItemModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] ?? json['payload'] ?? json['details'];
    final data = <String, dynamic>{};

    if (rawData is Map<String, dynamic>) {
      data.addAll(rawData);
    } else if (rawData is Map) {
      data.addAll(Map<String, dynamic>.from(rawData));
    }

    // Merge all top-level keys into data so no payload detail is missed.
    for (final entry in json.entries) {
      if (entry.key != 'data' && !data.containsKey(entry.key)) {
        data[entry.key] = entry.value;
      }
    }

    final rawType = json['type'] ??
        json['action'] ??
        json['event'] ??
        json['activityType'] ??
        json['category'] ??
        data['type'] ??
        data['action'] ??
        '';

    final rawDate = json['createdAt'] ??
        json['timestamp'] ??
        json['created_at'] ??
        json['time'] ??
        json['date'] ??
        data['createdAt'] ??
        data['timestamp'];

    return UserHistoryItemModel(
      type: rawType.toString(),
      createdAt: _parseDate(rawDate),
      data: data,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    if (value is num) {
      // Handle timestamp in millis or seconds
      final ms = value > 10000000000 ? value.toInt() : (value * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }
    return DateTime.now();
  }
}

class UserHistoryMetaModel extends UserHistoryMetaEntity {
  const UserHistoryMetaModel({
    required super.total,
    required super.page,
    required super.limit,
    required super.totalPages,
    super.note,
  });

  factory UserHistoryMetaModel.fromJson(Map<String, dynamic>? json, {int fallbackTotal = 0}) {
    if (json == null) {
      return UserHistoryMetaModel(
        total: fallbackTotal,
        page: 1,
        limit: 30,
        totalPages: (fallbackTotal > 0 ? (fallbackTotal + 29) ~/ 30 : 1).clamp(1, 1 << 30),
      );
    }

    final total = _int(json['total'], fallback: fallbackTotal);
    final page = _int(json['page'], fallback: 1);
    final limit = _int(json['limit'], fallback: 30);
    final totalPages = _int(
      json['totalPages'] ?? json['lastPage'],
      fallback: limit > 0 ? ((total + limit - 1) ~/ limit).clamp(1, 1 << 30) : 1,
    );

    return UserHistoryMetaModel(
      total: total,
      page: page < 1 ? 1 : page,
      limit: limit < 1 ? 30 : limit,
      totalPages: totalPages < 1 ? 1 : totalPages,
      note: json['note']?.toString(),
    );
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}

class UserHistoryResponseModel {
  const UserHistoryResponseModel({
    required this.items,
    required this.meta,
  });

  final List<UserHistoryItemModel> items;
  final UserHistoryMetaModel meta;

  factory UserHistoryResponseModel.fromJson(Map<String, dynamic> json) {
    dynamic rawList;
    if (json['data'] is List) {
      rawList = json['data'];
    } else if (json['history'] is List) {
      rawList = json['history'];
    } else if (json['items'] is List) {
      rawList = json['items'];
    } else if (json['timeline'] is List) {
      rawList = json['timeline'];
    } else if (json['logs'] is List) {
      rawList = json['logs'];
    } else if (json['records'] is List) {
      rawList = json['records'];
    } else if (json['results'] is List) {
      rawList = json['results'];
    } else if (json['data'] is Map) {
      final inner = json['data'] as Map;
      if (inner['history'] is List) {
        rawList = inner['history'];
      } else if (inner['items'] is List) {
        rawList = inner['items'];
      } else if (inner['timeline'] is List) {
        rawList = inner['timeline'];
      } else if (inner['logs'] is List) {
        rawList = inner['logs'];
      } else if (inner['records'] is List) {
        rawList = inner['records'];
      } else if (inner['data'] is List) {
        rawList = inner['data'];
      }
    }

    final items = rawList is List
        ? rawList
            .whereType<Map>()
            .map(
              (e) => UserHistoryItemModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList(growable: false)
        : const <UserHistoryItemModel>[];

    dynamic metaRaw = json['meta'] ?? json['pagination'];
    if (metaRaw == null && json['data'] is Map) {
      final inner = json['data'] as Map;
      metaRaw = inner['meta'] ?? inner['pagination'];
    }

    final meta = UserHistoryMetaModel.fromJson(
      metaRaw is Map<String, dynamic>
          ? metaRaw
          : metaRaw is Map
              ? Map<String, dynamic>.from(metaRaw)
              : null,
      fallbackTotal: items.length,
    );

    return UserHistoryResponseModel(items: items, meta: meta);
  }

  UserHistoryPageEntity toEntity() {
    return UserHistoryPageEntity(
      items: items,
      meta: meta,
    );
  }
}
