import 'package:equatable/equatable.dart';

import 'gift_entity.dart';

class GiftGroupMemberEntity extends Equatable {
  const GiftGroupMemberEntity({
    required this.gift,
    required this.sortOrder,
  });

  final GiftEntity gift;
  final int sortOrder;

  @override
  List<Object?> get props => [gift, sortOrder];
}

class GiftGroupEntity extends Equatable {
  const GiftGroupEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl,
    required this.sortOrder,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    required this.giftCount,
    required this.gifts,
  });

  final String id;
  final String name;
  final String slug;
  final String? iconUrl;
  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int giftCount;
  final List<GiftGroupMemberEntity> gifts;

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        iconUrl,
        sortOrder,
        isActive,
        createdAt,
        updatedAt,
        giftCount,
        gifts,
      ];
}

class CreateGiftGroupData extends Equatable {
  const CreateGiftGroupData({
    required this.name,
    required this.slug,
    this.iconUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String name;
  final String slug;
  final String? iconUrl;
  final int sortOrder;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug.trim().toLowerCase(),
        if (iconUrl != null && iconUrl!.trim().isNotEmpty)
          'iconUrl': iconUrl!.trim(),
        'sortOrder': sortOrder,
        'isActive': isActive,
      };

  @override
  List<Object?> get props => [name, slug, iconUrl, sortOrder, isActive];
}

class UpdateGiftGroupData extends Equatable {
  const UpdateGiftGroupData({
    this.name,
    this.slug,
    this.iconUrl,
    this.sortOrder,
    this.isActive,
    this.clearIconUrl = false,
  });

  final String? name;
  final String? slug;
  final String? iconUrl;
  final int? sortOrder;
  final bool? isActive;
  final bool clearIconUrl;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (slug != null) json['slug'] = slug!.trim().toLowerCase();
    if (clearIconUrl) {
      json['iconUrl'] = null;
    } else if (iconUrl != null) {
      json['iconUrl'] = iconUrl!.trim().isEmpty ? null : iconUrl!.trim();
    }
    if (sortOrder != null) json['sortOrder'] = sortOrder;
    if (isActive != null) json['isActive'] = isActive;
    return json;
  }

  @override
  List<Object?> get props =>
      [name, slug, iconUrl, sortOrder, isActive, clearIconUrl];
}

class GiftGroupReorderItem extends Equatable {
  const GiftGroupReorderItem({required this.id, required this.sortOrder});

  final String id;
  final int sortOrder;

  Map<String, dynamic> toJson() => {'id': id, 'sortOrder': sortOrder};

  @override
  List<Object?> get props => [id, sortOrder];
}

class GiftGroupMembershipItem extends Equatable {
  const GiftGroupMembershipItem({
    required this.giftId,
    required this.sortOrder,
  });

  final String giftId;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'giftId': giftId,
        'sortOrder': sortOrder,
      };

  @override
  List<Object?> get props => [giftId, sortOrder];
}
