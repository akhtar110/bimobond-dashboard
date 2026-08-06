import '../../../promotions/domain/entities/pagination_meta.dart';
import '../../domain/entities/log_entity.dart';

class LogModel extends LogEntity {
  const LogModel({
    required super.id,
    required super.createdAt,
    required super.category,
    required super.action,
    super.actorId,
    super.actorRole,
    super.userFullName,
    super.userName,
    super.userEmail,
    super.avatarUrl,
    super.targetType,
    super.targetId,
    super.meta,
    super.description,
    super.descriptionEn,
    super.ipAddress,
    super.userAgent,
    super.deviceId,
    super.permission,
    super.raw,
  });

  factory LogModel.fromJson(Map<String, dynamic> json) {
    final root = Map<String, dynamic>.from(json);
    final actor = _asMap(root['actor']);

    final actorId = _str(root['actorId']) ?? _str(actor?['id']);
    final actorRole = _str(root['actorRole'])?.toUpperCase();
    final category = _str(root['category'])?.toUpperCase() ?? '';
    final action = _str(root['action'])?.toUpperCase() ?? '';

    final userFullName = _str(actor?['fullName']) ??
        _str(root['userFullName']) ??
        _str(root['fullName']);
    final userName = _str(actor?['username']) ??
        _str(root['userName']) ??
        _str(root['username']);
    final userEmail = _str(actor?['email']) ?? _str(root['userEmail']);
    final avatarUrl = _str(actor?['avatarUrl']) ?? _str(root['avatarUrl']);

    final meta = _asMap(root['meta']);
    final description = _str(root['description']) ??
        _str(root['message']) ??
        _metaSummary(meta);
    final descriptionEn = _str(root['descriptionEn']);

    final createdAt = _parseDate(root['createdAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    return LogModel(
      id: _str(root['id']) ??
          '${actorId ?? 'log'}_${createdAt.millisecondsSinceEpoch}',
      createdAt: createdAt,
      category: category,
      action: action,
      actorId: actorId,
      actorRole: actorRole,
      userFullName: userFullName,
      userName: userName,
      userEmail: userEmail,
      avatarUrl: avatarUrl,
      targetType: _str(root['targetType'])?.toUpperCase(),
      targetId: _str(root['targetId']),
      meta: meta,
      description: description,
      descriptionEn: descriptionEn,
      ipAddress: _str(root['ipAddress']),
      userAgent: _str(root['userAgent']),
      deviceId: _str(root['deviceId']),
      permission: _str(root['permission']),
      raw: root,
    );
  }
}

class LogsResponseModel extends PaginatedResult<LogEntity> {
  const LogsResponseModel({
    required super.data,
    required super.meta,
  });

  factory LogsResponseModel.fromJson(Map<String, dynamic> json) {
    final unwrapped = _unwrapPaginated(json);
    final items = (unwrapped['data'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => LogModel.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);

    final metaJson = unwrapped['meta'] is Map
        ? Map<String, dynamic>.from(unwrapped['meta'] as Map)
        : <String, dynamic>{};

    final total = _int(metaJson['total'] ?? unwrapped['total']);
    final page = () {
      final value = _int(metaJson['page'] ?? unwrapped['page']);
      return value < 1 ? 1 : value;
    }();
    final limit = () {
      final value = _int(metaJson['limit'] ?? unwrapped['limit']);
      return value < 1 ? 50 : value;
    }();
    final totalPages = () {
      final last = _int(metaJson['lastPage'] ?? unwrapped['lastPage']);
      final pages = _int(metaJson['totalPages'] ?? unwrapped['totalPages']);
      final resolved = last > 0 ? last : pages;
      if (resolved > 0) return resolved;
      if (limit <= 0) return 1;
      return total <= 0 ? 1 : ((total + limit - 1) ~/ limit);
    }();

    return LogsResponseModel(
      data: items,
      meta: PaginationMeta(
        total: total,
        page: page,
        limit: limit,
        totalPages: totalPages,
      ),
    );
  }
}

String? _metaSummary(Map<String, dynamic>? meta) {
  if (meta == null || meta.isEmpty) return null;
  final path = _str(meta['path']);
  final method = _str(meta['method']);
  if (method != null && path != null) return '$method $path';
  if (path != null) return path;
  final keys = meta.keys.take(3).join(', ');
  return keys.isEmpty ? null : keys;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

Map<String, dynamic> _unwrapPaginated(Map<String, dynamic> data) {
  final nested = data['data'];
  if (nested is Map &&
      (nested['data'] is List ||
          nested['logs'] is List ||
          nested['items'] is List)) {
    final map = Map<String, dynamic>.from(nested);
    map['data'] = nested['data'] ?? nested['logs'] ?? nested['items'];
    return map;
  }
  if (data['data'] is List) return data;
  if (data['logs'] is List) {
    return {...data, 'data': data['logs']};
  }
  if (data['items'] is List) {
    return {...data, 'data': data['items']};
  }
  return data;
}

String? _str(dynamic value) {
  if (value == null) return null;
  if (value is Map || value is Iterable) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _int(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is num) {
    final n = value.toInt();
    if (n > 9999999999) {
      return DateTime.fromMillisecondsSinceEpoch(n, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(n * 1000, isUtc: true);
  }
  return DateTime.tryParse(value.toString())?.toUtc();
}
