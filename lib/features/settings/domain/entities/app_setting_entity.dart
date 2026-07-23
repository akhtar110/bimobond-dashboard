import 'package:equatable/equatable.dart';

/// Known protected keys that should not be casually deleted from the admin UI.
abstract final class ProtectedSettingKeys {
  static const values = <String>{
    'AUCTION_COMMISSION_PERCENT',
    'COINS_PER_PRICE_UNIT',
    'DEFAULT_CURRENCY_CODE',
    'MIN_WITHDRAWAL_COINS',
    'PROMOTIONS_ENABLED',
    'AUCTIONS_ENABLED',
    'AUCTION_ESCROW_ENABLED',
    'NOTIFICATIONS_ENABLED',
    'NOTIFICATIONS_PUSH_ENABLED',
    'NOTIFICATIONS_SOCIAL_ENABLED',
    'NOTIFICATIONS_POSTS_ENABLED',
    'NOTIFICATIONS_GIFTS_ENABLED',
    'NOTIFICATIONS_AUCTIONS_ENABLED',
    'NOTIFICATIONS_CHAT_ENABLED',
    'NOTIFICATIONS_ADMIN_ENABLED',
    'UPLOAD_IMAGE_MAX_MB',
    'UPLOAD_AUDIO_MAX_MB',
    'UPLOAD_VIDEO_MAX_MB',
    'UPLOAD_MAX_FILES_PER_REQUEST',
    'UPLOAD_IMAGE_ALLOWED_MIME',
    'UPLOAD_AUDIO_ALLOWED_MIME',
    'UPLOAD_VIDEO_ALLOWED_MIME',
  };

  static bool isProtected(String key) => values.contains(key.toUpperCase());
}

/// Notification setting keys (BOOLEAN switches under FEATURES).
abstract final class NotificationSettingKeys {
  static const enabled = 'NOTIFICATIONS_ENABLED';
  static const push = 'NOTIFICATIONS_PUSH_ENABLED';
  static const social = 'NOTIFICATIONS_SOCIAL_ENABLED';
  static const posts = 'NOTIFICATIONS_POSTS_ENABLED';
  static const gifts = 'NOTIFICATIONS_GIFTS_ENABLED';
  static const auctions = 'NOTIFICATIONS_AUCTIONS_ENABLED';
  static const chat = 'NOTIFICATIONS_CHAT_ENABLED';
  static const admin = 'NOTIFICATIONS_ADMIN_ENABLED';

  static const all = <String>[
    enabled,
    push,
    social,
    posts,
    gifts,
    auctions,
    chat,
    admin,
  ];
}

/// Upload setting keys under FEATURES.
abstract final class UploadSettingKeys {
  static const imageMaxMb = 'UPLOAD_IMAGE_MAX_MB';
  static const audioMaxMb = 'UPLOAD_AUDIO_MAX_MB';
  static const videoMaxMb = 'UPLOAD_VIDEO_MAX_MB';
  static const maxFiles = 'UPLOAD_MAX_FILES_PER_REQUEST';
  static const imageMime = 'UPLOAD_IMAGE_ALLOWED_MIME';
  static const audioMime = 'UPLOAD_AUDIO_ALLOWED_MIME';
  static const videoMime = 'UPLOAD_VIDEO_ALLOWED_MIME';

  static const all = <String>[
    imageMaxMb,
    audioMaxMb,
    videoMaxMb,
    maxFiles,
    imageMime,
    audioMime,
    videoMime,
  ];

  static bool isMimeKey(String key) =>
      key == imageMime || key == audioMime || key == videoMime;
}

/// Backend [AppSettingCategory] values.
abstract final class AppSettingCategories {
  static const general = 'GENERAL';
  static const branding = 'BRANDING';
  static const economy = 'ECONOMY';
  static const commission = 'COMMISSION';
  static const currency = 'CURRENCY';
  static const auction = 'AUCTION';
  static const promotion = 'PROMOTION';
  static const features = 'FEATURES';

  static const all = <String>[
    general,
    branding,
    economy,
    commission,
    currency,
    auction,
    promotion,
    features,
  ];
}

class AppSettingEntity extends Equatable {
  const AppSettingEntity({
    required this.key,
    required this.value,
    this.id,
    this.description,
    this.type = 'STRING',
    this.category,
    this.label,
    this.sortOrder = 0,
    this.isPublic = false,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String key;
  final String value;
  final String? description;
  final String type;
  final String? category;
  final String? label;
  final int sortOrder;
  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isProtected => ProtectedSettingKeys.isProtected(key);

  bool get isBoolean => type.toUpperCase() == 'BOOLEAN';

  bool get isNumber => type.toUpperCase() == 'NUMBER';

  bool get isJson => type.toUpperCase() == 'JSON';

  bool get boolValue =>
      value.toLowerCase() == 'true' || value == '1';

  String get displayLabel =>
      (label != null && label!.trim().isNotEmpty) ? label!.trim() : key;

  AppSettingEntity copyWith({
    String? id,
    String? key,
    String? value,
    String? description,
    String? type,
    String? category,
    String? label,
    int? sortOrder,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppSettingEntity(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      label: label ?? this.label,
      sortOrder: sortOrder ?? this.sortOrder,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        key,
        value,
        description,
        type,
        category,
        label,
        sortOrder,
        isPublic,
        createdAt,
        updatedAt,
      ];
}
