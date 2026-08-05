import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/post_filters.dart';
import '../bloc/posts_bloc.dart';
import '../utils/post_sort_labels.dart';
import '../utils/posts_datetime_filter_utils.dart';
import '../utils/posts_time_filter_utils.dart';
import 'posts_time_range_filter.dart';
import '../utils/posts_page_refresh.dart';
import '../utils/posts_responsive.dart';
import 'posts_datetime_filter.dart';
import 'posts_filter_bar.dart';
import 'posts_filter_button.dart';
import 'posts_filter_popup.dart';
import 'posts_sort_dropdown.dart';
import 'posts_location_filter.dart';
import 'posts_location_picker.dart';
import 'posts_view_toggle.dart';

/// Single-row SaaS-style posts toolbar — title, search, and compact actions.
class PostsPageHeader extends StatelessWidget {
  const PostsPageHeader({super.key, this.metrics});

  final PostsLayoutMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final m = metrics ??
            PostsLayoutMetrics(getPostsDeviceType(constraints.maxWidth));
        final wide = constraints.maxWidth >= 900;
        final controlHeight = _toolbarControlHeight(m);
        final gap = m.filterGap + 2;

        if (wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _PostsToolbarRow(
                metrics: m,
                controlHeight: controlHeight,
                gap: gap,
                showTitle: true,
                inlineActions: true,
              ),
              const PostsActiveFilterChips(),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _PostsToolbarRow(
              metrics: m,
              controlHeight: controlHeight,
              gap: gap,
              showTitle: true,
              inlineActions: false,
            ),
            SizedBox(height: gap),
            _PostsToolbarRow(
              metrics: m,
              controlHeight: controlHeight,
              gap: gap,
              showTitle: false,
              inlineActions: true,
            ),
            const PostsActiveFilterChips(),
          ],
        );
      },
    );
  }
}

double _toolbarControlHeight(PostsLayoutMetrics m) => switch (m.deviceType) {
      PostsDeviceType.mobileSmall => 34.0,
      PostsDeviceType.mobileLarge => 34.0,
      PostsDeviceType.tablet => 36.0,
      PostsDeviceType.desktop => 36.0,
    };

class _PostsToolbarRow extends StatelessWidget {
  const _PostsToolbarRow({
    required this.metrics,
    required this.controlHeight,
    required this.gap,
    required this.showTitle,
    required this.inlineActions,
  });

  final PostsLayoutMetrics metrics;
  final double controlHeight;
  final double gap;
  final bool showTitle;
  final bool inlineActions;

  void _openCreatePost(BuildContext context) {
    final l10n = context.l10n;
    Navigator.pushNamed(context, AppRoutes.createPost).then((result) {
      if (!context.mounted) return;
      if (result == 'published' || result == 'draft') {
        refreshPostsPageFeed(context);
        final msg = result == 'draft'
            ? l10n.t('postDraftSaved')
            : l10n.t('postCreatedSuccess');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _openFilters(BuildContext context, PostFilters filters) {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = box?.size ?? Size.zero;
    showPostsFilterPopup(
      context: context,
      filters: filters,
      anchorRect: Rect.fromLTWH(origin.dx, origin.dy, size.width, size.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final createButton = PostsCreatePostButton(
      height: controlHeight,
      iconOnly: metrics.isMobile,
      onPressed: () => _openCreatePost(context),
    );

    final actions = inlineActions
        ? BlocSelector<PostsBloc, PostsState, PostFilters>(
            selector: (state) => switch (state) {
              PostsLoaded(:final filters) => filters,
              PostsEmpty(:final filters) => filters,
              _ => context.read<PostsBloc>().activeFilters,
            },
            builder: (context, filters) {
              final activeCount = postsAppliedFilterCount(filters);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PostsDateTimeFilterButton(height: controlHeight),
                  SizedBox(width: gap),
                  PostsLocationFilterToolbarButton(height: controlHeight),
                  SizedBox(width: gap),
                  PostsSortDropdown(height: controlHeight),
                  SizedBox(width: gap),
                  PostsTimeRangeFilterButton(height: controlHeight),
                  SizedBox(width: gap),
                  Builder(
                    builder: (buttonContext) {
                      return PostsFilterButton(
                        activeCount: activeCount,
                        height: controlHeight,
                        iconOnly: true,
                        onPressed: () =>
                            _openFilters(buttonContext, filters),
                      );
                    },
                  ),
                  SizedBox(width: gap),
                  PostsViewToggle(height: controlHeight),
                  SizedBox(width: gap),
                  createButton,
                  SizedBox(width: gap),
                  PostsPageSettingButton(height: controlHeight),
                ],
              );
            },
          )
        : null;

    if (!showTitle && inlineActions) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: PostsFilterBar(
              isDark: isDark,
              compact: true,
              metrics: metrics,
            ),
          ),
          SizedBox(width: gap),
          actions!,
        ],
      );
    }

    if (showTitle && !inlineActions) {
      return const Row(
        children: [
          Expanded(child: PostsHeaderTitle()),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const PostsHeaderTitle(),
        SizedBox(width: gap + 8),
        Expanded(
          child: PostsFilterBar(
            isDark: isDark,
            compact: true,
            metrics: metrics,
          ),
        ),
        SizedBox(width: gap),
        actions!,
      ],
    );
  }
}

class PostsHeaderTitle extends StatelessWidget {
  const PostsHeaderTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocSelector<PostsBloc, PostsState, int?>(
      selector: (state) => switch (state) {
        PostsLoaded(:final total) => total,
        _ => null,
      },
      builder: (context, total) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.t('posts'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: scheme.onSurface,
                height: 1.1,
                fontSize: metricsTitleSize(context),
              ),
            ),
            if (total != null) ...[
              const SizedBox(width: 8),
              Text(
                '$total',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  double metricsTitleSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 480) return 18;
    if (width < 900) return 19;
    return 20;
  }
}

/// Compact dismissible chips for active popup filters (not search).
class PostsActiveFilterChips extends StatelessWidget {
  const PostsActiveFilterChips({super.key});

  PostFilters _readFilters(PostsState state, BuildContext context) {
    return switch (state) {
      PostsLoaded(:final filters) => filters,
      PostsEmpty(:final filters) => filters,
      _ => context.read<PostsBloc>().activeFilters,
    };
  }

  UserEntity? _readUser(PostsState state, BuildContext context) {
    return switch (state) {
      PostsLoaded(:final filterUser) => filterUser,
      PostsEmpty(:final filterUser) => filterUser,
      _ => context.read<PostsBloc>().filterUser,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<PostsBloc, PostsState>(
      buildWhen: (prev, next) {
        final prevF = _readFilters(prev, context);
        final nextF = _readFilters(next, context);
        return prevF != nextF ||
            _readUser(prev, context)?.id != _readUser(next, context)?.id;
      },
      builder: (context, state) {
        final filters = _readFilters(state, context);
        final user = _readUser(state, context);
        final chips = <Widget>[];

        if (filters.categoryId != null &&
            filters.categoryName != null &&
            filters.categoryName!.isNotEmpty) {
          chips.add(
            _ActiveFilterChip(
              label: filters.categoryName!,
              onRemove: () => context
                  .read<PostsBloc>()
                  .add(FilterPostsByCategoryEvent()),
            ),
          );
        }

        if (user != null) {
          chips.add(
            _ActiveFilterChip(
              label: '@${user.username}',
              onRemove: () => context
                  .read<PostsBloc>()
                  .add(const FilterPostsByUserEvent(null)),
            ),
          );
        }

        if (filters.hasDateRange) {
          final locale = Localizations.localeOf(context).languageCode;
          final label = formatPostsDateFilterLabel(
            postsDateTimeFromFilters(
              from: filters.createdFrom,
              to: filters.createdTo,
            ),
            locale: locale,
            t: l10n.t,
          );
          chips.add(
            _ActiveFilterChip(
              label: label,
              onRemove: () => context.read<PostsBloc>().add(
                    UpdatePostFiltersEvent(
                      filters.copyWith(clearDateRange: true),
                    ),
                  ),
            ),
          );
        }

        if (filters.hasTimeRange) {
          final locale = Localizations.localeOf(context).languageCode;
          final label = formatPostsTimeRangeLabel(
            fromMinutes: filters.createdTimeFromMinutes,
            toMinutes: filters.createdTimeToMinutes,
            locale: locale,
            t: (key) => postsTimeRangeLabelT(l10n, key),
          );
          chips.add(
            _ActiveFilterChip(
              label: label,
              onRemove: () => context.read<PostsBloc>().add(
                    UpdatePostFiltersEvent(
                      filters.copyWith(clearTimeRange: true),
                    ),
                  ),
            ),
          );
        }

        if (filters.isAuctionable == true) {
          chips.add(
            _ActiveFilterChip(
              label: l10n.tOr('postFilterAuctionOnly', 'Auctions Only'),
              onRemove: () => context.read<PostsBloc>().add(
                    UpdatePostFiltersEvent(
                      filters.copyWith(
                        clearAuction: true,
                        clearAd: true,
                      ),
                    ),
                  ),
            ),
          );
        } else if (filters.isAd == true) {
          chips.add(
            _ActiveFilterChip(
              label: l10n.tOr('postFilterAdsOnly', 'Ads Only'),
              onRemove: () => context.read<PostsBloc>().add(
                    UpdatePostFiltersEvent(
                      filters.copyWith(
                        clearAuction: true,
                        clearAd: true,
                      ),
                    ),
                  ),
            ),
          );
        }

        if (filters.type != null && filters.type!.isNotEmpty) {
          final typeLabel = switch (filters.type) {
            'VIDEO' => l10n.t('postFilterTypeVideo'),
            'IMAGE' => l10n.t('postFilterTypeImage'),
            'CAROUSEL' => l10n.t('postFilterTypeCarousel'),
            _ => filters.type!,
          };
          chips.add(
            _ActiveFilterChip(
              label: typeLabel,
              onRemove: () => context.read<PostsBloc>().add(
                    UpdatePostFiltersEvent(filters.copyWith(clearType: true)),
                  ),
            ),
          );
        }

        if (filters.hasLocationFilter) {
          chips.add(
            _ActiveFilterChip(
              label: postsLocationProximityLabel(l10n, filters),
              onRemove: () => context.read<PostsBloc>().add(
                    UpdatePostFiltersEvent(
                      postsFiltersClearLocation(filters),
                    ),
                  ),
            ),
          );
        }

        if (filters.sort != null &&
            filters.sort != PostFilters.defaultSort) {
          chips.add(
            _ActiveFilterChip(
              label: postSortLabel(l10n, filters.sort),
              onRemove: () => context.read<PostsBloc>().add(
                    UpdatePostFiltersEvent(
                      filters.copyWith(clearSort: true),
                    ),
                  ),
            ),
          );
        }

        if (chips.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...chips,
              TextButton(
                onPressed: () =>
                    context.read<PostsBloc>().add(ClearPostFiltersEvent()),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.t('clearAllFilters'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 4, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
              Icon(
                Icons.close_rounded,
                size: 14,
                color: scheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostsCreatePostButton extends StatelessWidget {
  const PostsCreatePostButton({
    super.key,
    required this.onPressed,
    this.iconOnly = false,
    this.height = 36,
  });

  final VoidCallback onPressed;
  final bool iconOnly;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    if (iconOnly) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: Size(height, height),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Icon(Icons.add_rounded, size: 18),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: Size(0, height),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: const Icon(Icons.add_rounded, size: 16),
      label: Text(
        l10n.t('createPost'),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
      ),
    );
  }
}

/// Compact Page Setting button placed beside the 'Create Post' button.
class PostsPageSettingButton extends StatelessWidget {
  const PostsPageSettingButton({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return BlocSelector<PostsBloc, PostsState, int>(
      selector: (state) => switch (state) {
        PostsLoaded(:final pageSize) => pageSize,
        _ => context.read<PostsBloc>().pageSize,
      },
      builder: (context, currentSize) {
        return PopupMenuButton<int>(
          tooltip: l10n.tOr('pageSetting', 'Page Setting'),
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          color: scheme.surface,
          elevation: 4,
          onSelected: (int newSize) {
            context
                .read<PostsBloc>()
                .add(ChangePostsPageSizeEvent(newSize));
          },
          itemBuilder: (ctx) => [
            PopupMenuItem<int>(
              enabled: false,
              height: 32,
              child: Text(
                l10n.tOr('postsPerPage', 'Posts per page'),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const PopupMenuDivider(height: 4),
            for (final size in const [20, 50, 100])
              PopupMenuItem<int>(
                value: size,
                height: 38,
                child: Row(
                  children: [
                    Text(
                      '$size ${l10n.tOr('perPage', 'per page')}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: currentSize == size
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: currentSize == size
                            ? scheme.primary
                            : scheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (currentSize == size)
                      Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
                  ],
                ),
              ),
          ],
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '$currentSize',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
