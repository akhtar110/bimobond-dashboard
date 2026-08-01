import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../gifts/presentation/widgets/gifts_active_filters.dart';
import '../../../gifts/presentation/widgets/gifts_filter_chip.dart';
import '../../../gifts/presentation/widgets/gifts_filter_footer.dart';
import '../../../gifts/presentation/widgets/gifts_filter_models.dart';
import '../../../gifts/presentation/widgets/gifts_filter_section.dart';
import '../../../categories/presentation/bloc/categories_bloc.dart';
import '../../../create_post/domain/entities/create_post_location_entity.dart';
import '../../../post_management/presentation/utils/post_detail_labels.dart';
import '../../../users/presentation/widgets/admin_user_search_field.dart';
import '../../domain/entities/post_filters.dart';
import '../bloc/posts_bloc.dart';
import '../bloc/posts_filter_draft_cubit.dart';
import '../utils/post_sort_labels.dart';
import '../utils/posts_datetime_filter_utils.dart';
import '../utils/posts_time_filter_utils.dart';
import 'posts_category_filter.dart';
import 'posts_datetime_filter.dart';
import 'posts_time_range_filter.dart';
import 'posts_location_filter.dart';
import 'posts_location_search_field.dart';

/// Opens the adaptive filter panel for posts.
Future<void> showPostsFilterPopup({
  required BuildContext context,
  required PostFilters filters,
  required Rect anchorRect,
}) {
  final postsBloc = context.read<PostsBloc>();
  final filterUser = postsBloc.filterUser;
  final categoriesBloc = context.read<CategoriesBloc>();
  final width = MediaQuery.sizeOf(context).width;

  Widget wrap(Widget child) => MultiBlocProvider(
    providers: [
      BlocProvider<PostsBloc>.value(value: postsBloc),
      BlocProvider<CategoriesBloc>.value(value: categoriesBloc),
      BlocProvider(
        create: (_) => PostsFilterDraftCubit(filters, filterUser: filterUser),
      ),
    ],
    child: child,
  );

  if (width < 600) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: wrap(
          PostsFilterPopup(
            appliedFilters: filters,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            showDragHandle: true,
          ),
        ),
      ),
    );
  }

  if (width < 900) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Align(
          alignment: Alignment.center,
          child: wrap(
            PostsFilterPopup(
              appliedFilters: filters,
              width: 420,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
            ),
          ),
        ),
      ),
    );
  }

  const panelWidth = 400.0;
  final media = MediaQuery.sizeOf(context);
  final padding = MediaQuery.paddingOf(context);
  final isRtl = Directionality.of(context) == TextDirection.rtl;

  var left = isRtl ? anchorRect.right - panelWidth : anchorRect.left;
  left = left.clamp(12.0, media.width - panelWidth - 12);
  var top = anchorRect.bottom + 6;
  final maxPanelHeight = media.height * 0.72;
  if (top + 360 > media.height - padding.bottom) {
    top = (anchorRect.top - 6 - maxPanelHeight).clamp(
      padding.top + 12.0,
      media.height - 360.0,
    );
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.15),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                alignment: Alignment.topCenter,
                child: wrap(
                  PostsFilterPopup(
                    appliedFilters: filters,
                    width: panelWidth,
                    maxHeight: maxPanelHeight,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Modern filter panel — grouped sections, chip selectors, sticky footer.
class PostsFilterPopup extends StatelessWidget {
  const PostsFilterPopup({
    super.key,
    required this.appliedFilters,
    this.width,
    this.maxHeight = 560,
    this.borderRadius,
    this.showDragHandle = false,
  });

  final PostFilters appliedFilters;
  final double? width;
  final double maxHeight;
  final BorderRadius? borderRadius;
  final bool showDragHandle;

  void _close(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  void _resetDraft(BuildContext context) {
    context.read<PostsFilterDraftCubit>().reset();
  }

  void _apply(BuildContext context) {
    final draft = context.read<PostsFilterDraftCubit>();
    final postsBloc = context.read<PostsBloc>();
    final applied = draft.toAppliedFilters(postsBloc.activeFilters);
    postsBloc.add(
      UpdatePostFiltersEvent(applied, filterUser: draft.state.user),
    );
    _close(context);
  }

  String _sectionTitle(
    AppLocalizations l10n,
    String key,
    BuildContext context,
  ) {
    return _sectionTitleFromLabel(l10n.tOr(key, key), context);
  }

  String _sectionTitleFromLabel(String text, BuildContext context) {
    if (context.isRtl) return text;
    return text.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(16);

    return Material(
      color: scheme.surface,
      elevation: 10,
      shadowColor: scheme.shadow.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.75)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width ?? 400,
        height: maxHeight,
        child: Column(
          children: [
            if (showDragHandle) const _PostsFilterDragHandle(),
            _PostsFilterHeader(onClose: () => _close(context)),
            Expanded(
              child: BlocBuilder<PostsFilterDraftCubit, PostsFilterDraftState>(
                builder: (context, draft) {
                  final cubit = context.read<PostsFilterDraftCubit>();
                  final activeItems = postsDraftActiveFilterItems(
                    draft,
                    l10n,
                    cubit,
                    locale: Localizations.localeOf(context).languageCode,
                  );
                  final panelKey = ValueKey(
                    'posts-filter-panel-${draft.revision}',
                  );

                  return ListView(
                    key: panelKey,
                    padding: const EdgeInsets.only(bottom: 8),
                    children: [
                      GiftsActiveFilters(items: activeItems),
                      GiftsFilterSection(
                        title: _sectionTitle(
                          l10n,
                          'postFilterAuthorSection',
                          context,
                        ),
                        child: AdminUserSearchField(
                          key: ValueKey('posts-filter-user-${draft.revision}'),
                          compact: true,
                          selectedUser: draft.user,
                          hintText: l10n.t('filterPostsByUser'),
                          onUserSelected: cubit.setUser,
                          onUserConfirmed: () => _apply(context),
                        ),
                      ),
                      GiftsFilterSection(
                        title: _sectionTitle(
                          l10n,
                          'postFilterDateTimeSection',
                          context,
                        ),
                        initiallyExpanded:
                            draft.createdFrom != null ||
                            draft.createdTo != null,
                        child: PostsDateTimeFilterPanel(
                          value: postsDateTimeFromFilters(
                            from: draft.createdFrom,
                            to: draft.createdTo,
                          ),
                          onChanged: (value) {
                            if (!value.hasDateRange) {
                              cubit.clearDateRange();
                            } else {
                              cubit.setDateRange(
                                from: value.from,
                                to: value.to,
                              );
                            }
                          },
                        ),
                      ),
                      GiftsFilterSection(
                        title: _sectionTitleFromLabel(
                          postsTimeRangeTitle(l10n),
                          context,
                        ),
                        initiallyExpanded:
                            draft.createdTimeFromMinutes != null ||
                            draft.createdTimeToMinutes != null,
                        child: PostsTimeRangeFilterPanel(
                          fromMinutes: draft.createdTimeFromMinutes,
                          toMinutes: draft.createdTimeToMinutes,
                          onChanged: (from, to) => cubit.setTimeRange(
                            fromMinutes: from,
                            toMinutes: to,
                          ),
                        ),
                      ),
                      GiftsFilterSection(
                        title: _sectionTitle(
                          l10n,
                          'postFilterPostType',
                          context,
                        ),
                        child: GiftsFilterChipWrap(
                          children: [
                            GiftsFilterChoiceChip(
                              label: l10n.t('postFilterAuctionAll'),
                              selected: draft.postType == PostTypeFilter.all,
                              onTap: () =>
                                  cubit.setPostType(PostTypeFilter.all),
                            ),
                            GiftsFilterChoiceChip(
                              label: l10n.t('postFilterAuctionOnly'),
                              selected:
                                  draft.postType == PostTypeFilter.auction,
                              onTap: () =>
                                  cubit.setPostType(PostTypeFilter.auction),
                            ),
                            GiftsFilterChoiceChip(
                              label: context.trOr(
                                'postFilterAdsOnly',
                                'Ads only',
                              ),
                              selected: draft.postType == PostTypeFilter.ads,
                              onTap: () =>
                                  cubit.setPostType(PostTypeFilter.ads),
                            ),
                          ],
                        ),
                      ),
                      GiftsFilterSection(
                        title: _sectionTitle(l10n, 'postFilterType', context),
                        initiallyExpanded: draft.type != null,
                        child: GiftsFilterChipWrap(
                          children: [
                            GiftsFilterChoiceChip(
                              label: l10n.t('postFilterTypeAll'),
                              selected: draft.type == null,
                              onTap: () => cubit.setType(null),
                            ),
                            GiftsFilterChoiceChip(
                              label: l10n.t('postFilterTypeVideo'),
                              selected: draft.type == 'VIDEO',
                              onTap: () => cubit.setType('VIDEO'),
                            ),
                            GiftsFilterChoiceChip(
                              label: l10n.t('postFilterTypeImage'),
                              selected: draft.type == 'IMAGE',
                              onTap: () => cubit.setType('IMAGE'),
                            ),
                            GiftsFilterChoiceChip(
                              label: l10n.t('postFilterTypeCarousel'),
                              selected: draft.type == 'CAROUSEL',
                              onTap: () => cubit.setType('CAROUSEL'),
                            ),
                          ],
                        ),
                      ),
                      GiftsFilterSection(
                        title: _sectionTitle(l10n, 'postStatus', context),
                        initiallyExpanded: draft.status != null,
                        child: DropdownButtonFormField<String?>(
                          key: ValueKey('posts-filter-status-${draft.revision}'),
                          initialValue: draft.status,
                          isExpanded: true,
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(l10n.t('postFilterStatusAll')),
                            ),
                            for (final status in kPostAdminStatuses)
                              DropdownMenuItem<String?>(
                                value: status,
                                child: Text(postStatusLabel(l10n, status)),
                              ),
                          ],
                          onChanged: cubit.setStatus,
                        ),
                      ),
                      GiftsFilterSection(
                        title: _sectionTitle(l10n, 'privacyStatus', context),
                        initiallyExpanded: draft.privacyStatus != null,
                        child: DropdownButtonFormField<String?>(
                          key: ValueKey(
                            'posts-filter-privacy-${draft.revision}',
                          ),
                          initialValue: draft.privacyStatus,
                          isExpanded: true,
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(l10n.t('postFilterPrivacyAll')),
                            ),
                            for (final privacy in PostFilters.privacyOptions)
                              DropdownMenuItem<String?>(
                                value: privacy,
                                child: Text(privacyLabel(l10n, privacy)),
                              ),
                          ],
                          onChanged: cubit.setPrivacyStatus,
                        ),
                      ),
                      GiftsFilterSection(
                        title: _sectionTitle(l10n, 'location', context),
                        initiallyExpanded: draft.hasLocationFilter,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PostsLocationAnchorButtons(
                              filterUser: draft.user,
                              onPlaceSelected: (place) {
                                final label =
                                    place.city?.trim().isNotEmpty == true
                                        ? place.city!.trim()
                                        : (place.name.trim().isNotEmpty
                                            ? place.name.trim()
                                            : l10n.t(
                                                'postFilterMyLocationAnchor',
                                              ));
                                cubit.setLocationFilter(
                                  city: label,
                                  latitude: place.latitude,
                                  longitude: place.longitude,
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            PostsLocationSearchField(
                              compact: true,
                              selectedPlace:
                                  draft.hasLocationFilter &&
                                      draft.locationLatitude != null &&
                                      draft.locationLongitude != null
                                  ? CreatePostLocationEntity(
                                      name: draft.locationCity ?? '',
                                      latitude: draft.locationLatitude!,
                                      longitude: draft.locationLongitude!,
                                      city: draft.locationCity,
                                    )
                                  : null,
                              onPlaceSelected: (place) {
                                final label =
                                    place.city?.trim().isNotEmpty == true
                                    ? place.city!.trim()
                                    : place.name.trim();
                                cubit.setLocationFilter(
                                  city: label,
                                  latitude: place.latitude,
                                  longitude: place.longitude,
                                );
                              },
                              onClear: () =>
                                  cubit.setLocationFilter(clear: true),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.t('postFilterLocationSearchDescription'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GiftsFilterSection(
                        title: _sectionTitle(
                          l10n,
                          'postFilterSortByAuthor',
                          context,
                        ),
                        child: GiftsFilterChipWrap(
                          children: [
                            GiftsFilterChoiceChip(
                              label: l10n.t('postFilterSortAuthorAsc'),
                              selected: draft.sort == PostFilters.sortAuthorAsc,
                              onTap: () =>
                                  cubit.setSort(PostFilters.sortAuthorAsc),
                            ),
                            GiftsFilterChoiceChip(
                              label: l10n.t('postFilterSortAuthorDesc'),
                              selected:
                                  draft.sort == PostFilters.sortAuthorDesc,
                              onTap: () =>
                                  cubit.setSort(PostFilters.sortAuthorDesc),
                            ),
                          ],
                        ),
                      ),
                      GiftsFilterSection(
                        title: _sectionTitle(
                          l10n,
                          'postFilterSortByDate',
                          context,
                        ),
                        child: GiftsFilterChipWrap(
                          children: [
                            GiftsFilterChoiceChip(
                              label: l10n.t('postFilterSortCreatedDesc'),
                              selected: draft.sort == PostFilters.sortLatest,
                              onTap: () =>
                                  cubit.setSort(PostFilters.sortLatest),
                            ),
                            GiftsFilterChoiceChip(
                              label: l10n.t('postFilterSortCreatedAsc'),
                              selected:
                                  draft.sort == PostFilters.sortCreatedAsc,
                              onTap: () =>
                                  cubit.setSort(PostFilters.sortCreatedAsc),
                            ),
                          ],
                        ),
                      ),
                      GiftsFilterSection(
                        title: _sectionTitle(
                          l10n,
                          'postFilterSortPopular',
                          context,
                        ),
                        child: GiftsFilterChipWrap(
                          children: [
                            GiftsFilterChoiceChip(
                              label: l10n.t('postFilterSortPopular'),
                              selected: draft.sort == PostFilters.sortPopular,
                              onTap: () =>
                                  cubit.setSort(PostFilters.sortPopular),
                            ),
                            GiftsFilterChoiceChip(
                              label: l10n.t('postFilterSortLatest'),
                              selected: draft.sort == PostFilters.sortLatest,
                              onTap: () =>
                                  cubit.setSort(PostFilters.sortLatest),
                            ),
                          ],
                        ),
                      ),
                      GiftsFilterSection(
                        title: _sectionTitle(
                          l10n,
                          'postFilterCategorySection',
                          context,
                        ),
                        initiallyExpanded: draft.categoryId != null,
                        child: PostsFilterCategorySection(
                          selectedCategoryId: draft.categoryId,
                          onCategorySelected:
                              ({categoryId, categoryName, categorySlug}) =>
                                  cubit.setCategory(
                                    categoryId: categoryId,
                                    categoryName: categoryName,
                                    categorySlug: categorySlug,
                                  ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            GiftsFilterFooter(
              onReset: () => _resetDraft(context),
              onCancel: () => _close(context),
              onApply: () => _apply(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostsFilterDragHandle extends StatelessWidget {
  const _PostsFilterDragHandle();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: scheme.outlineVariant.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

/// Title + close only — reset lives in the sticky footer.
class _PostsFilterHeader extends StatelessWidget {
  const _PostsFilterHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.tOr('filters', 'Filters'),
              textAlign: TextAlign.start,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.t('close'),
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

List<GiftsActiveFilterItem> postsDraftActiveFilterItems(
  PostsFilterDraftState draft,
  AppLocalizations l10n,
  PostsFilterDraftCubit cubit, {
  String? locale,
}) {
  final items = <GiftsActiveFilterItem>[];

  final user = draft.user;
  if (user != null) {
    items.add(
      GiftsActiveFilterItem(
        id: 'user',
        label: '@${user.username}',
        onRemove: () => cubit.setUser(null),
      ),
    );
  }

  if (draft.categoryId != null &&
      draft.categoryName != null &&
      draft.categoryName!.isNotEmpty) {
    items.add(
      GiftsActiveFilterItem(
        id: 'category',
        label: draft.categoryName!,
        onRemove: () => cubit.setCategory(),
      ),
    );
  }

  if (draft.createdFrom != null || draft.createdTo != null) {
    items.add(
      GiftsActiveFilterItem(
        id: 'date',
        label: formatPostsDateFilterLabel(
          postsDateTimeFromFilters(
            from: draft.createdFrom,
            to: draft.createdTo,
          ),
          locale: locale,
          t: l10n.t,
        ),
        onRemove: cubit.clearDateRange,
      ),
    );
  }

  if (draft.createdTimeFromMinutes != null ||
      draft.createdTimeToMinutes != null) {
    items.add(
      GiftsActiveFilterItem(
        id: 'time',
        label: formatPostsTimeRangeLabel(
          fromMinutes: draft.createdTimeFromMinutes,
          toMinutes: draft.createdTimeToMinutes,
          locale: locale,
          t: (key) => postsTimeRangeLabelT(l10n, key),
        ),
        onRemove: cubit.clearTimeRange,
      ),
    );
  }

  if (draft.postType != PostTypeFilter.all) {
    final label = switch (draft.postType) {
      PostTypeFilter.auction => l10n.t('postFilterAuctionOnly'),
      PostTypeFilter.ads => l10n.tOr('postFilterAdsOnly', 'Ads only'),
      PostTypeFilter.all => l10n.t('postFilterAuctionAll'),
    };
    items.add(
      GiftsActiveFilterItem(
        id: 'postType',
        label: label,
        onRemove: () => cubit.setPostType(PostTypeFilter.all),
      ),
    );
  }

  if (draft.type != null && draft.type!.isNotEmpty) {
    final label = switch (draft.type) {
      'VIDEO' => l10n.t('postFilterTypeVideo'),
      'IMAGE' => l10n.t('postFilterTypeImage'),
      'CAROUSEL' => l10n.t('postFilterTypeCarousel'),
      _ => draft.type!,
    };
    items.add(
      GiftsActiveFilterItem(
        id: 'mediaType',
        label: label,
        onRemove: () => cubit.setType(null),
      ),
    );
  }

  if (draft.status != null && draft.status!.isNotEmpty) {
    items.add(
      GiftsActiveFilterItem(
        id: 'status',
        label: postStatusLabel(l10n, draft.status!),
        onRemove: () => cubit.setStatus(null),
      ),
    );
  }

  if (draft.privacyStatus != null && draft.privacyStatus!.isNotEmpty) {
    items.add(
      GiftsActiveFilterItem(
        id: 'privacy',
        label: privacyLabel(l10n, draft.privacyStatus!),
        onRemove: () => cubit.setPrivacyStatus(null),
      ),
    );
  }

  if (draft.hasLocationAnchor) {
    items.add(
      GiftsActiveFilterItem(
        id: 'locationProximity',
        label: postsLocationProximityLabel(
          l10n,
          PostFilters(
            locationCity: draft.locationCity,
            locationLatitude: draft.locationLatitude,
            locationLongitude: draft.locationLongitude,
            locationRadiusKm: draft.locationRadiusKm,
          ),
        ),
        onRemove: () => cubit.setLocationFilter(clear: true),
      ),
    );
  }

  if (draft.sort != PostFilters.defaultSort) {
    items.add(
      GiftsActiveFilterItem(
        id: 'sort',
        label: postSortLabel(
          l10n,
          draft.sort,
          anchorUser: draft.user,
          filters: draft.hasLocationAnchor
              ? PostFilters(
                  sort: draft.sort,
                  locationCity: draft.locationCity,
                  locationLatitude: draft.locationLatitude,
                  locationLongitude: draft.locationLongitude,
                )
              : null,
        ),
        onRemove: () => cubit.setSort(PostFilters.defaultSort),
      ),
    );
  }

  return items;
}
