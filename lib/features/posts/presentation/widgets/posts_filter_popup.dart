import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../categories/presentation/bloc/categories_bloc.dart';
import '../../../create_post/domain/entities/create_post_location_entity.dart';
import '../../../gifts/presentation/widgets/gifts_filter_models.dart';
import '../../../users/presentation/widgets/admin_user_search_field.dart';
import '../../domain/entities/post_filters.dart';
import '../bloc/posts_bloc.dart';
import '../bloc/posts_filter_draft_cubit.dart';
import '../utils/post_sort_labels.dart';
import '../utils/posts_datetime_filter_utils.dart';
import '../utils/posts_time_filter_utils.dart';
import 'posts_category_filter.dart';
import 'posts_filter_panel_ui.dart';
import 'posts_location_filter.dart';
import 'posts_location_picker.dart';
import 'posts_location_search_field.dart';
import 'posts_time_range_filter.dart';

double _postsFilterPanelWidth(BuildContext context, double? preferred) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  if (preferred == null) return screenWidth;
  return preferred.clamp(280.0, screenWidth - 24.0);
}

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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            showDragHandle: true,
            fullWidth: true,
          ),
        ),
      ),
    );
  }

  if (width < 900) {
    final dialogWidth = _postsFilterPanelWidth(context, 440);
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: width < 640 ? 12 : 20,
          vertical: 20,
        ),
        child: Align(
          alignment: Alignment.center,
          child: wrap(
            PostsFilterPopup(
              appliedFilters: filters,
              width: dialogWidth,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
            ),
          ),
        ),
      ),
    );
  }

  final panelWidth = _postsFilterPanelWidth(context, 440);
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
    barrierColor: Colors.black.withValues(alpha: 0.22),
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

/// Premium filter panel — glass shell, compact sections, sticky footer.
class PostsFilterPopup extends StatelessWidget {
  const PostsFilterPopup({
    super.key,
    required this.appliedFilters,
    this.width,
    this.maxHeight = 560,
    this.borderRadius,
    this.showDragHandle = false,
    this.fullWidth = false,
  });

  final PostFilters appliedFilters;
  final double? width;
  final double maxHeight;
  final BorderRadius? borderRadius;
  final bool showDragHandle;
  final bool fullWidth;

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

  void _applyDatePreset(
    PostsFilterDraftCubit cubit,
    PostsDateTimePreset preset,
  ) {
    if (preset == PostsDateTimePreset.all) {
      cubit.clearDateRange();
      return;
    }
    final next = postsDateTimePresetValue(preset);
    cubit.setDateRange(from: next.from, to: next.to);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(14);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final panelWidth = fullWidth
        ? screenWidth
        : (width != null ? width!.clamp(280.0, screenWidth - 24.0) : 440.0);

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: radius,
      child: PostsFilterGlassShell(
        borderRadius: radius,
        child: SizedBox(
          width: panelWidth,
          height: maxHeight,
          child: Column(
            children: [
              if (showDragHandle) const _PostsFilterDragHandle(),
              PostsFilterPanelHeader(onClose: () => _close(context)),
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
                    final dateValue = postsDateTimeFromFilters(
                      from: draft.createdFrom,
                      to: draft.createdTo,
                    );
                    final datePreset =
                        dateValue.detectPreset() ?? PostsDateTimePreset.all;

                    return ListView(
                      key: ValueKey('posts-filter-panel-${draft.revision}'),
                      padding: const EdgeInsets.only(
                        bottom: PostsFilterPanelTokens.spacing,
                      ),
                      children: [
                        PostsFilterActiveTags(
                          labels: [
                            for (final item in activeItems)
                              (id: item.id, label: item.label),
                          ],
                          onRemove: (id) {
                            final item =
                                activeItems.firstWhere((i) => i.id == id);
                            item.onRemove();
                          },
                        ),
                        PostsFilterSection(
                          title: l10n.tOr('postFilterAuthorSection', 'Author'),
                          icon: Icons.person_outline_rounded,
                          showDivider: false,
                          child: AdminUserSearchField(
                            key: ValueKey('posts-filter-user-${draft.revision}'),
                            compact: true,
                            selectedUser: draft.user,
                            hintText: l10n.t('filterPostsByUser'),
                            onUserSelected: cubit.setUser,
                            onUserConfirmed: () => _apply(context),
                          ),
                        ),
                        PostsFilterSection(
                          title: l10n.tOr('postFilterDateTimeSection', 'Date'),
                          icon: Icons.calendar_today_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PostsFilterDatePresets(
                                selected: datePreset,
                                onPreset: (preset) =>
                                    _applyDatePreset(cubit, preset),
                              ),
                              const SizedBox(
                                height: PostsFilterPanelTokens.spacing,
                              ),
                              PostsFilterInlineDateRange(
                                from: draft.createdFrom,
                                to: draft.createdTo,
                                onChanged: (from, to) {
                                  if (from == null && to == null) {
                                    cubit.clearDateRange();
                                  } else {
                                    cubit.setDateRange(from: from, to: to);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        PostsFilterSection(
                          title: postsTimeRangeTitle(l10n),
                          icon: Icons.schedule_outlined,
                          child: PostsFilterInlineTimeRange(
                            fromMinutes: draft.createdTimeFromMinutes,
                            toMinutes: draft.createdTimeToMinutes,
                            onChanged: (from, to) => cubit.setTimeRange(
                              fromMinutes: from,
                              toMinutes: to,
                            ),
                          ),
                        ),
                        PostsFilterSection(
                          title: l10n.tOr('postFilterPostType', 'Post type'),
                          icon: Icons.category_outlined,
                          child: PostsFilterChipGrid(
                            children: [
                              PostsFilterChoiceChip(
                                label: l10n.t('postFilterAuctionAll'),
                                selected: draft.postType == PostTypeFilter.all,
                                onTap: () =>
                                    cubit.setPostType(PostTypeFilter.all),
                              ),
                              PostsFilterChoiceChip(
                                label: l10n.t('postFilterAuctionOnly'),
                                selected:
                                    draft.postType == PostTypeFilter.auction,
                                onTap: () =>
                                    cubit.setPostType(PostTypeFilter.auction),
                              ),
                              PostsFilterChoiceChip(
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
                        PostsFilterSection(
                          title: l10n.tOr('postFilterType', 'Media type'),
                          icon: Icons.perm_media_outlined,
                          child: PostsFilterChipGrid(
                            children: [
                              PostsFilterChoiceChip(
                                label: l10n.t('postFilterTypeAll'),
                                selected: draft.type == null,
                                onTap: () => cubit.setType(null),
                              ),
                              PostsFilterChoiceChip(
                                label: l10n.t('postFilterTypeVideo'),
                                selected: draft.type == 'VIDEO',
                                onTap: () => cubit.setType('VIDEO'),
                              ),
                              PostsFilterChoiceChip(
                                label: l10n.t('postFilterTypeImage'),
                                selected: draft.type == 'IMAGE',
                                onTap: () => cubit.setType('IMAGE'),
                              ),
                              PostsFilterChoiceChip(
                                label: l10n.t('postFilterTypeCarousel'),
                                selected: draft.type == 'CAROUSEL',
                                onTap: () => cubit.setType('CAROUSEL'),
                              ),
                            ],
                          ),
                        ),
                        PostsFilterSection(
                          title: l10n.tOr('location', 'Location'),
                          icon: Icons.place_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PostsLocationAnchorButtons(
                                filterUser: draft.user,
                                onPlaceSelected: (place) {
                                  final label =
                                      locationFilterLabelFromPlace(place);
                                  cubit.setLocationFilter(
                                    city: label,
                                    clearAnchor: true,
                                  );
                                },
                              ),
                              const SizedBox(
                                height: PostsFilterPanelTokens.spacing,
                              ),
                              PostsLocationSearchField(
                                compact: true,
                                selectedPlace: draft.hasLocationFilter &&
                                        draft.locationCity != null
                                    ? CreatePostLocationEntity(
                                        name: draft.locationCity!,
                                        latitude: 0,
                                        longitude: 0,
                                        city: draft.locationCity,
                                      )
                                    : null,
                                onPlaceSelected: (place) {
                                  final label =
                                      locationFilterLabelFromPlace(place);
                                  cubit.setLocationFilter(
                                    city: label,
                                    clearAnchor: true,
                                  );
                                },
                                onClear: () =>
                                    cubit.setLocationFilter(clear: true),
                              ),
                              const SizedBox(
                                height: PostsFilterPanelTokens.spacing,
                              ),
                              Text(
                                l10n.t('postFilterLocationSearchDescription'),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10.5,
                                  color: scheme.onSurfaceVariant
                                      .withValues(alpha: 0.85),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PostsFilterSection(
                          title: l10n.tOr('sort', 'Sort'),
                          icon: Icons.sort_rounded,
                          child: PostsFilterChipGrid(
                            children: [
                              PostsFilterChoiceChip(
                                label: l10n.t('postFilterSortAuthorAsc'),
                                selected:
                                    draft.sort == PostFilters.sortAuthorAsc,
                                onTap: () =>
                                    cubit.setSort(PostFilters.sortAuthorAsc),
                              ),
                              PostsFilterChoiceChip(
                                label: l10n.t('postFilterSortAuthorDesc'),
                                selected:
                                    draft.sort == PostFilters.sortAuthorDesc,
                                onTap: () =>
                                    cubit.setSort(PostFilters.sortAuthorDesc),
                              ),
                              PostsFilterChoiceChip(
                                label: l10n.t('postFilterSortCreatedDesc'),
                                selected: draft.sort == PostFilters.sortLatest,
                                onTap: () =>
                                    cubit.setSort(PostFilters.sortLatest),
                              ),
                              PostsFilterChoiceChip(
                                label: l10n.t('postFilterSortCreatedAsc'),
                                selected:
                                    draft.sort == PostFilters.sortCreatedAsc,
                                onTap: () =>
                                    cubit.setSort(PostFilters.sortCreatedAsc),
                              ),
                              PostsFilterChoiceChip(
                                label: l10n.t('postFilterSortPopular'),
                                selected: draft.sort == PostFilters.sortPopular,
                                onTap: () =>
                                    cubit.setSort(PostFilters.sortPopular),
                              ),
                              PostsFilterChoiceChip(
                                label: l10n.t('postFilterSortLatest'),
                                selected: draft.sort == PostFilters.sortLatest,
                                onTap: () =>
                                    cubit.setSort(PostFilters.sortLatest),
                              ),
                            ],
                          ),
                        ),
                        PostsFilterSection(
                          title:
                              l10n.tOr('postFilterCategorySection', 'Category'),
                          icon: Icons.label_outline_rounded,
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
                        const SizedBox(height: PostsFilterPanelTokens.spacing),
                      ],
                    );
                  },
                ),
              ),
              PostsFilterPanelFooter(
                onReset: () => _resetDraft(context),
                onApply: () => _apply(context),
              ),
            ],
          ),
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
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Center(
        child: Container(
          width: 32,
          height: 3,
          decoration: BoxDecoration(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
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

  if (draft.hasLocationFilter) {
    items.add(
      GiftsActiveFilterItem(
        id: 'locationProximity',
        label: postsLocationProximityLabel(
          l10n,
          PostFilters(locationCity: draft.locationCity),
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
          filters: draft.hasLocationFilter
              ? PostFilters(
                  sort: draft.sort,
                  locationCity: draft.locationCity,
                )
              : null,
        ),
        onRemove: () => cubit.setSort(PostFilters.defaultSort),
      ),
    );
  }

  return items;
}
