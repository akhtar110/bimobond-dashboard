import '../../domain/entities/user_history_entity.dart';

class UserHistoryItemModel extends UserHistoryEntity {
  const UserHistoryItemModel({
    required super.type,
    required super.createdAt,
    required super.data,
  });

  factory UserHistoryItemModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final data = rawData is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawData)
        : rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : <String, dynamic>{};

    // Lift common top-level fields into data when present.
    for (final key in const [
      'id',
      'targetType',
      'targetId',
      'meta',
      'postId',
      'post',
      'profile',
      'viewer',
      'visitCount',
      'source',
      'gift',
      'receiver',
      'coins',
      'priceCoins',
      'content',
      'query',
      'keyword',
      'latitude',
      'longitude',
      'city',
      'country',
      'story',
      'owner',
    ]) {
      if (json[key] != null && !data.containsKey(key)) {
        data[key] = json[key];
      }
    }

    return UserHistoryItemModel(
      type: json['type']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']),
      data: data,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
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

  factory UserHistoryMetaModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const UserHistoryMetaModel(
        total: 0,
        page: 1,
        limit: 30,
        totalPages: 1,
      );
    }

    final total = _int(json['total']);
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
    final rawList = json['data'];
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

    final metaRaw = json['meta'];
    final meta = UserHistoryMetaModel.fromJson(
      metaRaw is Map<String, dynamic>
          ? metaRaw
          : metaRaw is Map
              ? Map<String, dynamic>.from(metaRaw)
              : null,
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
