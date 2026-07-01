import 'package:equatable/equatable.dart';

import '../../../post_management/domain/entities/post_media_entity.dart';

class CampaignUserEntity extends Equatable {
  const CampaignUserEntity({
    required this.id,
    this.username,
    this.fullName,
    this.email,
    this.avatarUrl,
    this.isVerified = false,
    this.isBanned = false,
  });

  final String id;
  final String? username;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final bool isVerified;
  final bool isBanned;

  String get displayName =>
      (fullName?.trim().isNotEmpty == true ? fullName : null) ??
      (username?.trim().isNotEmpty == true ? username : null) ??
      id;

  @override
  List<Object?> get props =>
      [id, username, fullName, email, avatarUrl, isVerified, isBanned];
}

class CampaignPostEntity extends Equatable {
  const CampaignPostEntity({
    required this.id,
    this.description,
    this.thumbnailUrl,
    this.videoUrl,
    this.animatedCoverUrl,
    this.isAd = false,
    this.status,
    this.privacyStatus,
    this.userId,
  });

  final String id;
  final String? description;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? animatedCoverUrl;
  final bool isAd;
  final String? status;
  final String? privacyStatus;
  final String? userId;

  String? get previewThumbnailUrl {
    for (final candidate in [thumbnailUrl, animatedCoverUrl]) {
      final url = candidate?.trim();
      if (url != null && url.isNotEmpty && !isLikelyVideoFileUrl(url)) {
        return url;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        description,
        thumbnailUrl,
        videoUrl,
        isAd,
        status,
        privacyStatus,
        userId,
      ];
}

class CampaignPackageSummaryEntity extends Equatable {
  const CampaignPackageSummaryEntity({
    required this.id,
    required this.name,
    required this.priceCoins,
    required this.impressionCount,
    this.isActive = true,
  });

  final String id;
  final String name;
  final double priceCoins;
  final int impressionCount;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, priceCoins, impressionCount, isActive];
}

class CampaignEntity extends Equatable {
  const CampaignEntity({
    required this.id,
    required this.userId,
    required this.postId,
    required this.packageId,
    required this.status,
    required this.objective,
    required this.budgetCoins,
    required this.spentCoins,
    required this.impressionTarget,
    required this.impressionCount,
    this.targetGenders = const [],
    this.targetAgeMin,
    this.targetAgeMax,
    this.targetCountryCodes = const [],
    this.targetLanguages = const [],
    this.targetCategoryIds = const [],
    this.targetLatitude,
    this.targetLongitude,
    this.targetRadiusKm,
    this.startAt,
    this.endAt,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.post,
    this.package,
    this.recordedImpressions,
  });

  final String id;
  final String userId;
  final String postId;
  final String packageId;
  final String status;
  final String objective;
  final double budgetCoins;
  final double spentCoins;
  final int impressionTarget;
  final int impressionCount;
  final List<String> targetGenders;
  final int? targetAgeMin;
  final int? targetAgeMax;
  final List<String> targetCountryCodes;
  final List<String> targetLanguages;
  final List<String> targetCategoryIds;
  final double? targetLatitude;
  final double? targetLongitude;
  final double? targetRadiusKm;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CampaignUserEntity? user;
  final CampaignPostEntity? post;
  final CampaignPackageSummaryEntity? package;
  final int? recordedImpressions;

  double get progressPercent => impressionTarget <= 0
      ? 0
      : ((impressionCount / impressionTarget) * 100).clamp(0, 100);

  double get remainingBudgetCoins =>
      (budgetCoins - spentCoins).clamp(0, double.infinity);

  @override
  List<Object?> get props => [
        id,
        userId,
        postId,
        packageId,
        status,
        objective,
        budgetCoins,
        spentCoins,
        impressionTarget,
        impressionCount,
        targetGenders,
        targetAgeMin,
        targetAgeMax,
        targetCountryCodes,
        targetLanguages,
        targetCategoryIds,
        targetLatitude,
        targetLongitude,
        targetRadiusKm,
        startAt,
        endAt,
        createdAt,
        updatedAt,
        user,
        post,
        package,
        recordedImpressions,
      ];
}

class CampaignStatsEntity extends Equatable {
  const CampaignStatsEntity({
    required this.campaignId,
    required this.status,
    required this.objective,
    required this.impressionCount,
    required this.impressionTarget,
    required this.remainingImpressions,
    required this.spentCoins,
    required this.budgetCoins,
    required this.remainingBudgetCoins,
    required this.totalRecordedImpressions,
    required this.progressPercent,
    this.user,
    this.post,
    this.targetGenders = const [],
    this.targetAgeMin,
    this.targetAgeMax,
    this.targetCountryCodes = const [],
    this.targetLanguages = const [],
    this.targetCategoryIds = const [],
    this.targetLatitude,
    this.targetLongitude,
    this.targetRadiusKm,
  });

  final String campaignId;
  final String status;
  final String objective;
  final int impressionCount;
  final int impressionTarget;
  final int remainingImpressions;
  final double spentCoins;
  final double budgetCoins;
  final double remainingBudgetCoins;
  final int totalRecordedImpressions;
  final double progressPercent;
  final CampaignUserEntity? user;
  final CampaignPostEntity? post;
  final List<String> targetGenders;
  final int? targetAgeMin;
  final int? targetAgeMax;
  final List<String> targetCountryCodes;
  final List<String> targetLanguages;
  final List<String> targetCategoryIds;
  final double? targetLatitude;
  final double? targetLongitude;
  final double? targetRadiusKm;

  @override
  List<Object?> get props => [
        campaignId,
        status,
        objective,
        impressionCount,
        impressionTarget,
        remainingImpressions,
        spentCoins,
        budgetCoins,
        remainingBudgetCoins,
        totalRecordedImpressions,
        progressPercent,
        user,
        post,
        targetGenders,
        targetAgeMin,
        targetAgeMax,
        targetCountryCodes,
        targetLanguages,
        targetCategoryIds,
        targetLatitude,
        targetLongitude,
        targetRadiusKm,
      ];
}

class CampaignImpressionViewerEntity extends Equatable {
  const CampaignImpressionViewerEntity({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;

  String get displayName =>
      (fullName?.trim().isNotEmpty == true ? fullName : null) ??
      (username?.trim().isNotEmpty == true ? username : null) ??
      id;

  @override
  List<Object?> get props => [id, username, fullName, avatarUrl];
}

class CampaignImpressionEntity extends Equatable {
  const CampaignImpressionEntity({
    required this.id,
    required this.campaignId,
    required this.postId,
    this.viewerId,
    required this.costCoins,
    required this.createdAt,
    this.viewer,
  });

  final String id;
  final String campaignId;
  final String postId;
  final String? viewerId;
  final double costCoins;
  final DateTime createdAt;
  final CampaignImpressionViewerEntity? viewer;

  @override
  List<Object?> get props =>
      [id, campaignId, postId, viewerId, costCoins, createdAt, viewer];
}

class PromotionPackageEntity extends Equatable {
  const PromotionPackageEntity({
    required this.id,
    required this.name,
    required this.priceCoins,
    required this.impressionCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final double priceCoins;
  final int impressionCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props =>
      [id, name, priceCoins, impressionCount, isActive, createdAt, updatedAt];
}

class BulkActionResultEntity extends Equatable {
  const BulkActionResultEntity({
    required this.action,
    this.status,
    required this.successCount,
    this.notFoundCount = 0,
    this.skippedCount = 0,
    this.campaignIds = const [],
    this.packageIds = const [],
    this.notFoundIds = const [],
    this.skippedIds = const [],
  });

  final String action;
  final String? status;
  final int successCount;
  final int notFoundCount;
  final int skippedCount;
  final List<String> campaignIds;
  final List<String> packageIds;
  final List<String> notFoundIds;
  final List<String> skippedIds;

  @override
  List<Object?> get props => [
        action,
        status,
        successCount,
        notFoundCount,
        skippedCount,
        campaignIds,
        packageIds,
        notFoundIds,
        skippedIds,
      ];
}

class LocationPointEntity extends Equatable {
  const LocationPointEntity({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.city,
    this.region,
    this.country,
    this.source,
    required this.createdAt,
  });

  final String id;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final String? city;
  final String? region;
  final String? country;
  final String? source;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        latitude,
        longitude,
        accuracy,
        altitude,
        city,
        region,
        country,
        source,
        createdAt,
      ];
}

class MovementPathEntity extends Equatable {
  const MovementPathEntity({
    required this.userId,
    required this.points,
    required this.total,
    required this.returned,
    this.from,
    this.to,
    this.limit,
  });

  final String userId;
  final List<LocationPointEntity> points;
  final int total;
  final int returned;
  final DateTime? from;
  final DateTime? to;
  final int? limit;

  @override
  List<Object?> get props => [userId, points, total, returned, from, to, limit];
}

class UpdateCampaignData {
  const UpdateCampaignData({
    this.status,
    this.targetGenders,
    this.targetAgeMin,
    this.targetAgeMax,
    this.targetCountryCodes,
    this.targetLanguages,
    this.targetCategoryIds,
    this.targetLatitude,
    this.targetLongitude,
    this.targetRadiusKm,
    this.endAt,
  });

  final String? status;
  final List<String>? targetGenders;
  final int? targetAgeMin;
  final int? targetAgeMax;
  final List<String>? targetCountryCodes;
  final List<String>? targetLanguages;
  final List<String>? targetCategoryIds;
  final double? targetLatitude;
  final double? targetLongitude;
  final double? targetRadiusKm;
  final DateTime? endAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (status != null) map['status'] = status;
    if (targetGenders != null) map['targetGenders'] = targetGenders;
    if (targetAgeMin != null) map['targetAgeMin'] = targetAgeMin;
    if (targetAgeMax != null) map['targetAgeMax'] = targetAgeMax;
    if (targetCountryCodes != null) {
      map['targetCountryCodes'] = targetCountryCodes;
    }
    if (targetLanguages != null) map['targetLanguages'] = targetLanguages;
    if (targetCategoryIds != null) {
      map['targetCategoryIds'] = targetCategoryIds;
    }
    if (targetLatitude != null) map['targetLatitude'] = targetLatitude;
    if (targetLongitude != null) map['targetLongitude'] = targetLongitude;
    if (targetRadiusKm != null) map['targetRadiusKm'] = targetRadiusKm;
    if (endAt != null) map['endAt'] = endAt!.toUtc().toIso8601String();
    return map;
  }
}

class CreatePackageData {
  const CreatePackageData({
    required this.name,
    required this.priceCoins,
    required this.impressionCount,
    this.isActive = true,
  });

  final String name;
  final double priceCoins;
  final int impressionCount;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'name': name,
        'priceCoins': priceCoins,
        'impressionCount': impressionCount,
        'isActive': isActive,
      };
}

class UpdatePackageData {
  const UpdatePackageData({
    this.name,
    this.priceCoins,
    this.impressionCount,
    this.isActive,
  });

  final String? name;
  final double? priceCoins;
  final int? impressionCount;
  final bool? isActive;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (priceCoins != null) map['priceCoins'] = priceCoins;
    if (impressionCount != null) map['impressionCount'] = impressionCount;
    if (isActive != null) map['isActive'] = isActive;
    return map;
  }
}

class AdminCampaignsQuery {
  const AdminCampaignsQuery({
    this.page = 1,
    this.limit = 20,
    this.status,
    this.objective,
    this.userId,
    this.postId,
    this.packageId,
    this.search,
  });

  final int page;
  final int limit;
  final String? status;
  final String? objective;
  final String? userId;
  final String? postId;
  final String? packageId;
  final String? search;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null && status!.isNotEmpty) params['status'] = status;
    if (objective != null && objective!.isNotEmpty) {
      params['objective'] = objective;
    }
    if (userId != null && userId!.isNotEmpty) params['userId'] = userId;
    if (postId != null && postId!.isNotEmpty) params['postId'] = postId;
    if (packageId != null && packageId!.isNotEmpty) {
      params['packageId'] = packageId;
    }
    final term = search?.trim();
    if (term != null && term.isNotEmpty) params['search'] = term;
    return params;
  }

  AdminCampaignsQuery copyWith({
    int? page,
    int? limit,
    String? status,
    bool clearStatus = false,
    String? objective,
    bool clearObjective = false,
    String? userId,
    bool clearUserId = false,
    String? postId,
    bool clearPostId = false,
    String? packageId,
    bool clearPackageId = false,
    String? search,
    bool clearSearch = false,
  }) {
    return AdminCampaignsQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      status: clearStatus ? null : (status ?? this.status),
      objective: clearObjective ? null : (objective ?? this.objective),
      userId: clearUserId ? null : (userId ?? this.userId),
      postId: clearPostId ? null : (postId ?? this.postId),
      packageId: clearPackageId ? null : (packageId ?? this.packageId),
      search: clearSearch ? null : (search ?? this.search),
    );
  }
}

class PackagesQuery {
  const PackagesQuery({this.search});

  final String? search;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    final term = search?.trim();
    if (term != null && term.isNotEmpty) {
      params['search'] = term;
    }
    return params;
  }

  PackagesQuery copyWith({String? search, bool clearSearch = false}) {
    return PackagesQuery(
      search: clearSearch ? null : (search ?? this.search),
    );
  }
}

class LocationHistoryQuery {
  const LocationHistoryQuery({
    this.page = 1,
    this.limit = 50,
    this.from,
    this.to,
    this.source,
  });

  final int page;
  final int limit;
  final DateTime? from;
  final DateTime? to;
  final String? source;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (from != null) params['from'] = from!.toUtc().toIso8601String();
    if (to != null) params['to'] = to!.toUtc().toIso8601String();
    if (source != null && source!.isNotEmpty) params['source'] = source;
    return params;
  }
}

class MovementPathQuery {
  const MovementPathQuery({
    this.from,
    this.to,
    this.limit = 1000,
    this.source,
  });

  final DateTime? from;
  final DateTime? to;
  final int limit;
  final String? source;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{'limit': limit};
    if (from != null) params['from'] = from!.toUtc().toIso8601String();
    if (to != null) params['to'] = to!.toUtc().toIso8601String();
    if (source != null && source!.isNotEmpty) params['source'] = source;
    return params;
  }
}

class BulkCampaignActionRequest {
  const BulkCampaignActionRequest({
    this.campaignIds = const [],
    this.packageIds = const [],
    required this.action,
    this.status,
  });

  final List<String> campaignIds;
  final List<String> packageIds;
  final String action;
  final String? status;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'action': action};
    if (campaignIds.isNotEmpty) map['campaignIds'] = campaignIds;
    if (packageIds.isNotEmpty) map['packageIds'] = packageIds;
    if (status != null) map['status'] = status;
    return map;
  }
}
