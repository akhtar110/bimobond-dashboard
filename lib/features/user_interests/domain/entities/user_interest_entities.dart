import 'package:equatable/equatable.dart';

enum UserInterestPreference {
  interested,
  notInterested,
}

enum UserInterestSource {
  onboarding,
  manual,
  like,
  comment,
  unknown,
}

UserInterestPreference userInterestPreferenceFromApi(String? raw) {
  switch (raw?.toUpperCase()) {
    case 'INTERESTED':
      return UserInterestPreference.interested;
    case 'NOT_INTERESTED':
      return UserInterestPreference.notInterested;
    default:
      return UserInterestPreference.interested;
  }
}

String userInterestPreferenceToApi(UserInterestPreference preference) {
  return switch (preference) {
    UserInterestPreference.interested => 'INTERESTED',
    UserInterestPreference.notInterested => 'NOT_INTERESTED',
  };
}

UserInterestSource userInterestSourceFromApi(String? raw) {
  switch (raw?.toUpperCase()) {
    case 'ONBOARDING':
      return UserInterestSource.onboarding;
    case 'MANUAL':
      return UserInterestSource.manual;
    case 'LIKE':
      return UserInterestSource.like;
    case 'COMMENT':
      return UserInterestSource.comment;
    default:
      return UserInterestSource.unknown;
  }
}

String userInterestSourceToApi(UserInterestSource source) {
  return switch (source) {
    UserInterestSource.onboarding => 'ONBOARDING',
    UserInterestSource.manual => 'MANUAL',
    UserInterestSource.like => 'LIKE',
    UserInterestSource.comment => 'COMMENT',
    UserInterestSource.unknown => 'MANUAL',
  };
}

class InterestCategoryEntity extends Equatable {
  const InterestCategoryEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl,
    this.parentId,
    this.isActive = true,
    this.order = 0,
  });

  final String id;
  final String name;
  final String slug;
  final String? iconUrl;
  final String? parentId;
  final bool isActive;
  final int order;

  @override
  List<Object?> get props =>
      [id, name, slug, iconUrl, parentId, isActive, order];
}

class UserInterestEntity extends Equatable {
  const UserInterestEntity({
    this.userId,
    required this.categoryId,
    required this.preference,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
  });

  final String? userId;
  final String categoryId;
  final UserInterestPreference preference;
  final UserInterestSource source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final InterestCategoryEntity category;

  @override
  List<Object?> get props => [
        userId,
        categoryId,
        preference,
        source,
        createdAt,
        updatedAt,
        category,
      ];
}

class UserInterestsMetaEntity extends Equatable {
  const UserInterestsMetaEntity({
    this.totalInterests = 0,
    this.totalNotInterests = 0,
    this.minRequired = 3,
    this.maxAllowed = 20,
    this.maxNotInterestsAllowed = 20,
    this.needsInterests = false,
  });

  final int totalInterests;
  final int totalNotInterests;
  final int minRequired;
  final int maxAllowed;
  final int maxNotInterestsAllowed;
  final bool needsInterests;

  @override
  List<Object?> get props => [
        totalInterests,
        totalNotInterests,
        minRequired,
        maxAllowed,
        maxNotInterestsAllowed,
        needsInterests,
      ];
}

class UserInterestsResponseEntity extends Equatable {
  const UserInterestsResponseEntity({
    this.interests = const [],
    this.notInterests = const [],
    this.meta = const UserInterestsMetaEntity(),
  });

  final List<UserInterestEntity> interests;
  final List<UserInterestEntity> notInterests;
  final UserInterestsMetaEntity meta;

  bool get isEmpty => interests.isEmpty && notInterests.isEmpty;

  @override
  List<Object?> get props => [interests, notInterests, meta];
}

class UserInterestsFilterQuery extends Equatable {
  const UserInterestsFilterQuery({
    this.search,
    this.preference,
    this.source,
    this.createdFrom,
    this.createdTo,
  });

  final String? search;
  final UserInterestPreference? preference;
  final UserInterestSource? source;
  final DateTime? createdFrom;
  final DateTime? createdTo;

  bool get hasActiveFilters =>
      (search != null && search!.trim().isNotEmpty) ||
      preference != null ||
      source != null ||
      createdFrom != null ||
      createdTo != null;

  UserInterestsFilterQuery copyWith({
    String? search,
    UserInterestPreference? preference,
    UserInterestSource? source,
    DateTime? createdFrom,
    DateTime? createdTo,
    bool clearSearch = false,
    bool clearPreference = false,
    bool clearSource = false,
    bool clearDateRange = false,
  }) {
    return UserInterestsFilterQuery(
      search: clearSearch ? null : (search ?? this.search),
      preference: clearPreference ? null : (preference ?? this.preference),
      source: clearSource ? null : (source ?? this.source),
      createdFrom: clearDateRange ? null : (createdFrom ?? this.createdFrom),
      createdTo: clearDateRange ? null : (createdTo ?? this.createdTo),
    );
  }

  @override
  List<Object?> get props =>
      [search, preference, source, createdFrom, createdTo];
}
