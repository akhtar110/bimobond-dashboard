import '../../domain/entities/gift_group_entities.dart';
import 'gift_model.dart';

int _groupAsInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _groupParseDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class GiftGroupMemberModel extends GiftGroupMemberEntity {
  const GiftGroupMemberModel({
    required super.gift,
    required super.sortOrder,
  });

  factory GiftGroupMemberModel.fromJson(Map<String, dynamic> json) {
    final giftJson = json['gift'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['gift'] as Map)
        : json;
    return GiftGroupMemberModel(
      gift: GiftModel.fromJson(giftJson),
      sortOrder: _groupAsInt(json['sortOrder'] ?? giftJson['sortOrder']),
    );
  }
}

class GiftGroupModel extends GiftGroupEntity {
  const GiftGroupModel({
    required super.id,
    required super.name,
    required super.slug,
    super.iconUrl,
    required super.sortOrder,
    required super.isActive,
    super.createdAt,
    super.updatedAt,
    required super.giftCount,
    required super.gifts,
  });

  factory GiftGroupModel.fromJson(Map<String, dynamic> json) {
    final giftsRaw = json['gifts'];
    final members = giftsRaw is List
        ? giftsRaw
            .whereType<Map<String, dynamic>>()
            .map(GiftGroupMemberModel.fromJson)
            .toList()
        : const <GiftGroupMemberModel>[];

    return GiftGroupModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      // Keep raw path from API; tabs/form resolve via resolveMediaUrl for display.
      iconUrl: json['iconUrl']?.toString(),
      sortOrder: _groupAsInt(json['sortOrder']),
      isActive: json['isActive'] != false,
      createdAt: _groupParseDate(json['createdAt']),
      updatedAt: _groupParseDate(json['updatedAt']),
      giftCount: _groupAsInt(json['giftCount'] ?? members.length),
      gifts: members,
    );
  }
}

List<GiftGroupEntity> parseGiftGroupList(Object? data) {
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map(GiftGroupModel.fromJson)
        .toList();
  }
  if (data is Map<String, dynamic>) {
    final nested = data['data'];
    if (nested is List) {
      return nested
          .whereType<Map<String, dynamic>>()
          .map(GiftGroupModel.fromJson)
          .toList();
    }
  }
  return const [];
}

GiftGroupEntity parseGiftGroup(Object? data) {
  if (data is Map<String, dynamic>) {
    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      return GiftGroupModel.fromJson(nested);
    }
    return GiftGroupModel.fromJson(data);
  }
  throw Exception('Invalid gift group response');
}
