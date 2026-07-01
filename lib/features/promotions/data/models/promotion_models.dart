import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/pagination_meta.dart';
import '../../domain/entities/promotion_entities.dart';
import '../../domain/entities/promotion_overview_entity.dart';
import 'promoted_post_models.dart';

double _double(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _int(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

DateTime _requiredDate(dynamic value) =>
    _date(value) ?? DateTime.fromMillisecondsSinceEpoch(0);

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.map((e) => e.toString()).toList();
}

class PromotionOverviewModel extends PromotionOverviewEntity {
  const PromotionOverviewModel({
    required super.totalCampaigns,
    required super.activeCampaigns,
    required super.pendingPaymentCampaigns,
    required super.pausedCampaigns,
    required super.completedCampaigns,
    required super.rejectedCampaigns,
    required super.totalPackages,
    required super.activePackages,
    required super.totalImpressions,
    required super.impressionsLast24Hours,
    required super.totalSpentCoins,
    required super.activeBudgetCoins,
    required super.activeSpentCoins,
  });

  factory PromotionOverviewModel.fromJson(Map<String, dynamic> json) {
    final campaigns = json['campaigns'] as Map<String, dynamic>? ?? {};
    final packages = json['packages'] as Map<String, dynamic>? ?? {};
    final impressions = json['impressions'] as Map<String, dynamic>? ?? {};
    final revenue = json['revenue'] as Map<String, dynamic>? ?? {};
    return PromotionOverviewModel(
      totalCampaigns: _int(campaigns['total']),
      activeCampaigns: _int(campaigns['active']),
      pendingPaymentCampaigns: _int(campaigns['pendingPayment']),
      pausedCampaigns: _int(campaigns['paused']),
      completedCampaigns: _int(campaigns['completed']),
      rejectedCampaigns: _int(campaigns['rejected']),
      totalPackages: _int(packages['total']),
      activePackages: _int(packages['active']),
      totalImpressions: _int(impressions['total']),
      impressionsLast24Hours: _int(impressions['last24Hours']),
      totalSpentCoins: _double(revenue['totalSpentCoins']),
      activeBudgetCoins: _double(revenue['activeBudgetCoins']),
      activeSpentCoins: _double(revenue['activeSpentCoins']),
    );
  }
}

class CampaignUserModel extends CampaignUserEntity {
  const CampaignUserModel({
    required super.id,
    super.username,
    super.fullName,
    super.email,
    super.avatarUrl,
    super.isVerified,
    super.isBanned,
  });

  factory CampaignUserModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const CampaignUserModel(id: '');
    }
    return CampaignUserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString(),
      fullName: json['fullName']?.toString(),
      email: json['email']?.toString(),
      avatarUrl: resolveMediaUrl(json['avatarUrl']?.toString()),
      isVerified: json['isVerified'] == true,
      isBanned: json['isBanned'] == true,
    );
  }
}

class CampaignPostModel extends CampaignPostEntity {
  const CampaignPostModel({
    required super.id,
    super.description,
    super.thumbnailUrl,
    super.videoUrl,
    super.animatedCoverUrl,
    super.isAd,
    super.status,
    super.privacyStatus,
    super.userId,
  });

  factory CampaignPostModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CampaignPostModel(id: '');
    return CampaignPostModel(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString(),
      thumbnailUrl: readPromotionPostThumbnailUrl(json),
      videoUrl: readPromotionPostVideoUrl(json),
      animatedCoverUrl: resolveMediaUrl(json['animatedCoverUrl']?.toString()),
      isAd: json['isAd'] == true,
      status: json['status']?.toString(),
      privacyStatus: json['privacyStatus']?.toString(),
      userId: json['userId']?.toString(),
    );
  }
}

class CampaignPackageSummaryModel extends CampaignPackageSummaryEntity {
  const CampaignPackageSummaryModel({
    required super.id,
    required super.name,
    required super.priceCoins,
    required super.impressionCount,
    super.isActive,
  });

  factory CampaignPackageSummaryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const CampaignPackageSummaryModel(
        id: '',
        name: '',
        priceCoins: 0,
        impressionCount: 0,
      );
    }
    return CampaignPackageSummaryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      priceCoins: _double(json['priceCoins']),
      impressionCount: _int(json['impressionCount']),
      isActive: json['isActive'] != false,
    );
  }
}

class CampaignModel extends CampaignEntity {
  const CampaignModel({
    required super.id,
    required super.userId,
    required super.postId,
    required super.packageId,
    required super.status,
    required super.objective,
    required super.budgetCoins,
    required super.spentCoins,
    required super.impressionTarget,
    required super.impressionCount,
    super.targetGenders,
    super.targetAgeMin,
    super.targetAgeMax,
    super.targetCountryCodes,
    super.targetLanguages,
    super.targetCategoryIds,
    super.targetLatitude,
    super.targetLongitude,
    super.targetRadiusKm,
    super.startAt,
    super.endAt,
    required super.createdAt,
    required super.updatedAt,
    super.user,
    super.post,
    super.package,
    super.recordedImpressions,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    final count = json['_count'];
    return CampaignModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      packageId: json['packageId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      objective: json['objective']?.toString() ?? '',
      budgetCoins: _double(json['budgetCoins']),
      spentCoins: _double(json['spentCoins']),
      impressionTarget: _int(json['impressionTarget']),
      impressionCount: _int(json['impressionCount']),
      targetGenders: _stringList(json['targetGenders']),
      targetAgeMin: json['targetAgeMin'] == null
          ? null
          : _int(json['targetAgeMin']),
      targetAgeMax: json['targetAgeMax'] == null
          ? null
          : _int(json['targetAgeMax']),
      targetCountryCodes: _stringList(json['targetCountryCodes']),
      targetLanguages: _stringList(json['targetLanguages']),
      targetCategoryIds: _stringList(json['targetCategoryIds']),
      targetLatitude: json['targetLatitude'] == null
          ? null
          : _double(json['targetLatitude']),
      targetLongitude: json['targetLongitude'] == null
          ? null
          : _double(json['targetLongitude']),
      targetRadiusKm: json['targetRadiusKm'] == null
          ? null
          : _double(json['targetRadiusKm']),
      startAt: _date(json['startAt']),
      endAt: _date(json['endAt']),
      createdAt: _requiredDate(json['createdAt']),
      updatedAt: _requiredDate(json['updatedAt']),
      user: json['user'] is Map<String, dynamic>
          ? CampaignUserModel.fromJson(json['user'] as Map<String, dynamic>)
          : json['owner'] is Map<String, dynamic>
              ? CampaignUserModel.fromJson(json['owner'] as Map<String, dynamic>)
              : null,
      post: json['post'] is Map<String, dynamic>
          ? CampaignPostModel.fromJson(json['post'] as Map<String, dynamic>)
          : null,
      package: json['package'] is Map<String, dynamic>
          ? CampaignPackageSummaryModel.fromJson(
              json['package'] as Map<String, dynamic>,
            )
          : null,
      recordedImpressions:
          count is Map ? _int(count['impressions']) : null,
    );
  }
}

class CampaignPageModel extends PaginatedResult<CampaignEntity> {
  CampaignPageModel({
    required super.data,
    required super.meta,
  });

  factory CampaignPageModel.fromJson(Map<String, dynamic> json) {
    final items = (json['data'] as List? ?? [])
        .map((e) => CampaignModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final metaJson = json['meta'] as Map<String, dynamic>? ?? {};
    return CampaignPageModel(
      data: items,
      meta: PaginationMetaModel.fromJson(metaJson),
    );
  }
}

class CampaignStatsModel extends CampaignStatsEntity {
  const CampaignStatsModel({
    required super.campaignId,
    required super.status,
    required super.objective,
    required super.impressionCount,
    required super.impressionTarget,
    required super.remainingImpressions,
    required super.spentCoins,
    required super.budgetCoins,
    required super.remainingBudgetCoins,
    required super.totalRecordedImpressions,
    required super.progressPercent,
    super.user,
    super.post,
    super.targetGenders,
    super.targetAgeMin,
    super.targetAgeMax,
    super.targetCountryCodes,
    super.targetLanguages,
    super.targetCategoryIds,
    super.targetLatitude,
    super.targetLongitude,
    super.targetRadiusKm,
  });

  factory CampaignStatsModel.fromJson(Map<String, dynamic> json) {
    final targeting =
        json['targeting'] as Map<String, dynamic>? ?? json;
    return CampaignStatsModel(
      campaignId: json['campaignId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      objective: json['objective']?.toString() ?? '',
      impressionCount: _int(json['impressionCount']),
      impressionTarget: _int(json['impressionTarget']),
      remainingImpressions: _int(json['remainingImpressions']),
      spentCoins: _double(json['spentCoins']),
      budgetCoins: _double(json['budgetCoins']),
      remainingBudgetCoins: _double(json['remainingBudgetCoins']),
      totalRecordedImpressions: _int(json['totalRecordedImpressions']),
      progressPercent: _double(json['progressPercent']),
      user: json['user'] is Map<String, dynamic>
          ? CampaignUserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      post: json['post'] is Map<String, dynamic>
          ? CampaignPostModel.fromJson(json['post'] as Map<String, dynamic>)
          : null,
      targetGenders: _stringList(targeting['targetGenders']),
      targetAgeMin: targeting['targetAgeMin'] == null
          ? null
          : _int(targeting['targetAgeMin']),
      targetAgeMax: targeting['targetAgeMax'] == null
          ? null
          : _int(targeting['targetAgeMax']),
      targetCountryCodes: _stringList(targeting['targetCountryCodes']),
      targetLanguages: _stringList(targeting['targetLanguages']),
      targetCategoryIds: _stringList(targeting['targetCategoryIds']),
      targetLatitude: targeting['targetLatitude'] == null
          ? null
          : _double(targeting['targetLatitude']),
      targetLongitude: targeting['targetLongitude'] == null
          ? null
          : _double(targeting['targetLongitude']),
      targetRadiusKm: targeting['targetRadiusKm'] == null
          ? null
          : _double(targeting['targetRadiusKm']),
    );
  }
}

class CampaignImpressionViewerModel extends CampaignImpressionViewerEntity {
  const CampaignImpressionViewerModel({
    required super.id,
    super.username,
    super.fullName,
    super.avatarUrl,
  });

  factory CampaignImpressionViewerModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CampaignImpressionViewerModel(id: '');
    return CampaignImpressionViewerModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString(),
      fullName: json['fullName']?.toString(),
      avatarUrl: resolveMediaUrl(json['avatarUrl']?.toString()),
    );
  }
}

class CampaignImpressionModel extends CampaignImpressionEntity {
  const CampaignImpressionModel({
    required super.id,
    required super.campaignId,
    required super.postId,
    super.viewerId,
    required super.costCoins,
    required super.createdAt,
    super.viewer,
  });

  factory CampaignImpressionModel.fromJson(Map<String, dynamic> json) {
    return CampaignImpressionModel(
      id: json['id']?.toString() ?? '',
      campaignId: json['campaignId']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      viewerId: json['viewerId']?.toString(),
      costCoins: _double(json['costCoins']),
      createdAt: _requiredDate(json['createdAt']),
      viewer: json['viewer'] is Map<String, dynamic>
          ? CampaignImpressionViewerModel.fromJson(
              json['viewer'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class CampaignImpressionPageModel
    extends PaginatedResult<CampaignImpressionEntity> {
  CampaignImpressionPageModel({
    required super.data,
    required super.meta,
  });

  factory CampaignImpressionPageModel.fromJson(Map<String, dynamic> json) {
    final items = (json['data'] as List? ?? [])
        .map((e) => CampaignImpressionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return CampaignImpressionPageModel(
      data: items,
      meta: PaginationMetaModel.fromJson(
        json['meta'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class PromotionPackageModel extends PromotionPackageEntity {
  const PromotionPackageModel({
    required super.id,
    required super.name,
    required super.priceCoins,
    required super.impressionCount,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PromotionPackageModel.fromJson(Map<String, dynamic> json) {
    return PromotionPackageModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      priceCoins: _double(json['priceCoins']),
      impressionCount: _int(json['impressionCount']),
      isActive: json['isActive'] != false,
      createdAt: _requiredDate(json['createdAt']),
      updatedAt: _requiredDate(json['updatedAt']),
    );
  }
}

class BulkActionResultModel extends BulkActionResultEntity {
  const BulkActionResultModel({
    required super.action,
    super.status,
    required super.successCount,
    super.notFoundCount,
    super.skippedCount,
    super.campaignIds,
    super.packageIds,
    super.notFoundIds,
    super.skippedIds,
  });

  factory BulkActionResultModel.fromJson(Map<String, dynamic> json) {
    return BulkActionResultModel(
      action: json['action']?.toString() ?? '',
      status: json['status']?.toString(),
      successCount: _int(json['successCount']),
      notFoundCount: _int(json['notFoundCount']),
      skippedCount: _int(json['skippedCount']),
      campaignIds: _stringList(json['campaignIds']),
      packageIds: _stringList(json['packageIds']),
      notFoundIds: _stringList(json['notFoundIds']),
      skippedIds: _stringList(json['skippedIds']),
    );
  }
}

class LocationPointModel extends LocationPointEntity {
  const LocationPointModel({
    required super.id,
    required super.latitude,
    required super.longitude,
    super.accuracy,
    super.altitude,
    super.city,
    super.region,
    super.country,
    super.source,
    required super.createdAt,
  });

  factory LocationPointModel.fromJson(Map<String, dynamic> json) {
    return LocationPointModel(
      id: json['id']?.toString() ?? '',
      latitude: _double(json['latitude'] ?? json['lat']),
      longitude: _double(json['longitude'] ?? json['lng']),
      accuracy: json['accuracy'] == null ? null : _double(json['accuracy']),
      altitude: json['altitude'] == null ? null : _double(json['altitude']),
      city: json['city']?.toString(),
      region: json['region']?.toString(),
      country: json['country']?.toString(),
      source: json['source']?.toString(),
      createdAt: _requiredDate(json['createdAt']),
    );
  }
}

class LocationHistoryPageModel extends PaginatedResult<LocationPointEntity> {
  LocationHistoryPageModel({
    required super.data,
    required super.meta,
  });

  factory LocationHistoryPageModel.fromJson(Map<String, dynamic> json) {
    final items = _parseLocationPoints(json['data']);
    return LocationHistoryPageModel(
      data: items,
      meta: PaginationMetaModel.fromJson(
        json['meta'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

List<LocationPointModel> _parseLocationPoints(dynamic raw) {
  if (raw is! List) return const [];

  final items = <LocationPointModel>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    try {
      items.add(
        LocationPointModel.fromJson(Map<String, dynamic>.from(entry)),
      );
    } catch (_) {
      continue;
    }
  }
  return items;
}

class MovementPathModel extends MovementPathEntity {
  const MovementPathModel({
    required super.userId,
    required super.points,
    required super.total,
    required super.returned,
    super.from,
    super.to,
    super.limit,
  });

  factory MovementPathModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return MovementPathModel(
      userId: json['userId']?.toString() ?? '',
      points: _parseLocationPoints(json['points']),
      total: _int(meta['total']),
      returned: _int(meta['returned']),
      from: _date(meta['from']),
      to: _date(meta['to']),
      limit: meta['limit'] == null ? null : _int(meta['limit']),
    );
  }
}

class PaginationMetaModel extends PaginationMeta {
  const PaginationMetaModel({
    required super.total,
    required super.page,
    required super.limit,
    required super.totalPages,
  });

  factory PaginationMetaModel.fromJson(Map<String, dynamic> json) {
    return PaginationMetaModel(
      total: _int(json['total']),
      page: _int(json['page']) == 0 ? 1 : _int(json['page']),
      limit: _int(json['limit']) == 0 ? 20 : _int(json['limit']),
      totalPages: _int(json['totalPages']) == 0 ? 1 : _int(json['totalPages']),
    );
  }
}
