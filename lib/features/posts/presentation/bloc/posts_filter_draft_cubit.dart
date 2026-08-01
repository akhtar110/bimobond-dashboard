import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/post_filters.dart';
import '../utils/posts_datetime_filter_utils.dart';

/// Immutable draft edited in the posts filter popup before Apply.
class PostsFilterDraftState extends Equatable {
  const PostsFilterDraftState({
    required this.postType,
    this.type,
    this.sort = PostFilters.defaultSort,
    this.user,
    this.createdFrom,
    this.createdTo,
    this.createdTimeFromMinutes,
    this.createdTimeToMinutes,
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    this.locationCity,
    this.locationLatitude,
    this.locationLongitude,
    this.locationRadiusKm = PostFilters.defaultLocationRadiusKm,
    this.status,
    this.privacyStatus,
    this.revision = 0,
  });

  factory PostsFilterDraftState.fromFilters(
    PostFilters filters, {
    UserEntity? filterUser,
  }) {
    return PostsFilterDraftState(
      postType: filters.postTypeFilter,
      type: filters.type,
      sort: filters.sort ?? PostFilters.defaultSort,
      user: filterUser,
      createdFrom: filters.createdFrom,
      createdTo: filters.createdTo,
      createdTimeFromMinutes: filters.createdTimeFromMinutes,
      createdTimeToMinutes: filters.createdTimeToMinutes,
      categoryId: filters.categoryId,
      categoryName: filters.categoryName,
      categorySlug: filters.categorySlug,
      locationCity: filters.locationCity,
      locationLatitude: filters.locationLatitude,
      locationLongitude: filters.locationLongitude,
      locationRadiusKm:
          filters.locationRadiusKm ?? PostFilters.defaultLocationRadiusKm,
      status: filters.status,
      privacyStatus: filters.privacyStatus,
    );
  }

  final PostTypeFilter postType;
  final String? type;
  final String sort;
  final UserEntity? user;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final int? createdTimeFromMinutes;
  final int? createdTimeToMinutes;
  final String? categoryId;
  final String? categoryName;
  final String? categorySlug;
  final String? locationCity;
  final double? locationLatitude;
  final double? locationLongitude;
  final double? locationRadiusKm;
  final String? status;
  final String? privacyStatus;

  /// Bumped on [PostsFilterDraftCubit.reset] to force dependent widgets to refresh.
  final int revision;

  bool get hasLocationAnchor =>
      locationLatitude != null && locationLongitude != null;

  bool get hasLocationFilter => hasLocationAnchor;

  int get activeCount {
    var count = 0;
    if (postType != PostTypeFilter.all) count++;
    if (type != null && type!.isNotEmpty) count++;
    if (sort != PostFilters.defaultSort) count++;
    if (user != null) count++;
    if (createdFrom != null ||
        createdTo != null ||
        createdTimeFromMinutes != null ||
        createdTimeToMinutes != null) {
      count++;
    }
    if (categoryId != null) count++;
    if (hasLocationAnchor) count++;
    if (status != null && status!.isNotEmpty) count++;
    if (privacyStatus != null && privacyStatus!.isNotEmpty) count++;
    return count;
  }

  PostsFilterDraftState copyWith({
    PostTypeFilter? postType,
    String? type,
    String? sort,
    UserEntity? user,
    DateTime? createdFrom,
    DateTime? createdTo,
    int? createdTimeFromMinutes,
    int? createdTimeToMinutes,
    String? categoryId,
    String? categoryName,
    String? categorySlug,
    String? locationCity,
    double? locationLatitude,
    double? locationLongitude,
    double? locationRadiusKm,
    String? status,
    String? privacyStatus,
    int? revision,
    bool clearType = false,
    bool clearUser = false,
    bool clearDateRange = false,
    bool clearTimeRange = false,
    bool clearCategory = false,
    bool clearLocation = false,
    bool clearStatus = false,
    bool clearPrivacyStatus = false,
  }) {
    return PostsFilterDraftState(
      postType: postType ?? this.postType,
      type: clearType ? null : (type ?? this.type),
      sort: sort ?? this.sort,
      user: clearUser ? null : (user ?? this.user),
      createdFrom: clearDateRange ? null : (createdFrom ?? this.createdFrom),
      createdTo: clearDateRange ? null : (createdTo ?? this.createdTo),
      createdTimeFromMinutes: clearTimeRange
          ? null
          : (createdTimeFromMinutes ?? this.createdTimeFromMinutes),
      createdTimeToMinutes: clearTimeRange
          ? null
          : (createdTimeToMinutes ?? this.createdTimeToMinutes),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      categoryName: clearCategory ? null : (categoryName ?? this.categoryName),
      categorySlug: clearCategory ? null : (categorySlug ?? this.categorySlug),
      locationCity: clearLocation ? null : (locationCity ?? this.locationCity),
      locationLatitude: clearLocation
          ? null
          : (locationLatitude ?? this.locationLatitude),
      locationLongitude: clearLocation
          ? null
          : (locationLongitude ?? this.locationLongitude),
      locationRadiusKm: clearLocation
          ? PostFilters.defaultLocationRadiusKm
          : (locationRadiusKm ?? this.locationRadiusKm),
      status: clearStatus ? null : (status ?? this.status),
      privacyStatus: clearPrivacyStatus
          ? null
          : (privacyStatus ?? this.privacyStatus),
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [
    postType,
    type,
    sort,
    user,
    createdFrom,
    createdTo,
    createdTimeFromMinutes,
    createdTimeToMinutes,
    categoryId,
    categoryName,
    categorySlug,
    locationCity,
    locationLatitude,
    locationLongitude,
    locationRadiusKm,
    status,
    privacyStatus,
    revision,
  ];
}

/// Dialog-scoped cubit for filter draft edits (Apply commits to [PostsBloc]).
class PostsFilterDraftCubit extends Cubit<PostsFilterDraftState> {
  PostsFilterDraftCubit(PostFilters filters, {UserEntity? filterUser})
    : super(PostsFilterDraftState.fromFilters(filters, filterUser: filterUser));

  void setPostType(PostTypeFilter value) {
    if (state.postType == value) return;
    emit(state.copyWith(postType: value));
  }

  void setType(String? value) {
    if (state.type == value) return;
    emit(state.copyWith(type: value, clearType: value == null));
  }

  void setStatus(String? value) {
    if (state.status == value) return;
    emit(state.copyWith(status: value, clearStatus: value == null));
  }

  void setPrivacyStatus(String? value) {
    if (state.privacyStatus == value) return;
    emit(state.copyWith(
      privacyStatus: value,
      clearPrivacyStatus: value == null,
    ));
  }

  void setSort(String value) {
    if (state.sort == value) return;
    emit(state.copyWith(sort: value));
  }

  void setLocationFilter({
    String? city,
    double? latitude,
    double? longitude,
    double? radiusKm,
    bool clear = false,
  }) {
    if (clear) {
      emit(state.copyWith(clearLocation: true));
      return;
    }

    emit(
      state.copyWith(
        locationCity: city,
        locationLatitude: latitude,
        locationLongitude: longitude,
        locationRadiusKm: radiusKm,
      ),
    );
  }

  void setLocationRadius(double radiusKm) {
    if (state.locationRadiusKm == radiusKm) return;
    emit(state.copyWith(locationRadiusKm: radiusKm));
  }

  void setUser(UserEntity? user) {
    final nextId = user?.id;
    final currentId = state.user?.id;
    if (nextId == currentId && (user != null || state.user == null)) return;
    emit(state.copyWith(user: user, clearUser: user == null));
  }

  void setDateRange({DateTime? from, DateTime? to}) {
    emit(state.copyWith(createdFrom: from, createdTo: to));
  }

  void setDateTimeFilter(PostsDateTimeFilterValue value) {
    emit(
      PostsFilterDraftState(
        postType: state.postType,
        type: state.type,
        sort: state.sort,
        user: state.user,
        createdFrom: value.from,
        createdTo: value.to,
        createdTimeFromMinutes: value.timeFromMinutes,
        createdTimeToMinutes: value.timeToMinutes,
        categoryId: state.categoryId,
        categoryName: state.categoryName,
        categorySlug: state.categorySlug,
        revision: state.revision,
      ),
    );
  }

  void clearDateTimeFilters() {
    if (state.createdFrom == null &&
        state.createdTo == null &&
        state.createdTimeFromMinutes == null &&
        state.createdTimeToMinutes == null) {
      return;
    }
    emit(state.copyWith(clearDateRange: true, clearTimeRange: true));
  }

  void clearDateRange() {
    if (state.createdFrom == null && state.createdTo == null) return;
    emit(state.copyWith(clearDateRange: true));
  }

  void setTimeRange({int? fromMinutes, int? toMinutes}) {
    if (fromMinutes == null && toMinutes == null) {
      clearTimeRange();
      return;
    }
    emit(
      state.copyWith(
        createdTimeFromMinutes: fromMinutes,
        createdTimeToMinutes: toMinutes,
      ),
    );
  }

  void clearTimeRange() {
    if (state.createdTimeFromMinutes == null &&
        state.createdTimeToMinutes == null) {
      return;
    }
    emit(state.copyWith(clearTimeRange: true));
  }

  void setCategory({
    String? categoryId,
    String? categoryName,
    String? categorySlug,
  }) {
    final clear = categoryId == null;
    if (!clear &&
        state.categoryId == categoryId &&
        state.categoryName == categoryName &&
        state.categorySlug == categorySlug) {
      return;
    }
    emit(
      state.copyWith(
        categoryId: categoryId,
        categoryName: categoryName,
        categorySlug: categorySlug,
        clearCategory: clear,
      ),
    );
  }

  /// Clears every popup filter back to defaults (draft only until Apply).
  void reset() {
    emit(
      PostsFilterDraftState(
        postType: PostTypeFilter.all,
        sort: PostFilters.defaultSort,
        revision: state.revision + 1,
      ),
    );
  }

  /// Builds the filters payload while preserving search from [base].
  PostFilters toAppliedFilters(PostFilters base) {
    return PostFilters(
      categoryId: state.categoryId,
      categoryName: state.categoryName,
      categorySlug: state.categorySlug,
      search: base.search,
      userId: state.user?.id,
      userName: state.user?.username,
      createdFrom: state.createdFrom,
      createdTo: state.createdTo,
      createdTimeFromMinutes: state.createdTimeFromMinutes,
      createdTimeToMinutes: state.createdTimeToMinutes,
      type: state.type,
      sort: state.sort,
      isAuctionable: state.postType == PostTypeFilter.auction ? true : null,
      isAd: state.postType == PostTypeFilter.ads ? true : null,
      locationCity: state.locationCity,
      locationLatitude: state.locationLatitude,
      locationLongitude: state.locationLongitude,
      locationRadiusKm: state.locationRadiusKm,
      status: state.status,
      privacyStatus: state.privacyStatus,
    );
  }
}
