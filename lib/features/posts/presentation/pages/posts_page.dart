import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../features/categories/presentation/bloc/categories_bloc.dart';
import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../bloc/posts_bloc.dart';
import '../widgets/post_card.dart';
import '../widgets/posts_filter_bar.dart';

// ── Grid column count ─────────────────────────────────────────────────────────
int postsGridColumnCount(double width) {
  if (width > 1600) return 6;
  if (width > 1300) return 5;
  if (width > 1000) return 4;
  if (width > 700) return 3;
  if (width > 500) return 2;
  return 1;
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<PostsBloc>().add(GetAllPostsEvent());
    context.read<CategoriesBloc>().add(LoadCategoriesEvent());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<PostsBloc>().add(LoadMorePostsEvent());
    }
  }

  void _openPostManagement(ManagedPostEntity post) {
    Navigator.pushNamed(
      context,
      AppRoutes.postManagementDetail,
      arguments: post,
    ).then((result) {
      if (!mounted) return;
      if (result is ManagedPostEntity) {
        context.read<PostsBloc>().add(PatchPostEvent(result));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF7F9FC),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PageHeader(isDark: isDark),
                const SizedBox(height: 10),
                _CategoryFilter(isDark: isDark),
                const SizedBox(height: 10),
                Expanded(
                  child: BlocBuilder<PostsBloc, PostsState>(
                    builder: (context, state) => switch (state) {
                      PostsInitial() || PostsLoading() => LayoutBuilder(
                          builder: (ctx, c) =>
                              _SkeletonGrid(width: c.maxWidth),
                        ),
                      PostsEmpty() => _EmptyView(
                          onClearFilters: () => context
                              .read<PostsBloc>()
                              .add(ClearPostFiltersEvent()),
                        ),
                      PostsError(:final message) => _ErrorView(
                          message: message,
                          onRetry: () =>
                              context.read<PostsBloc>().add(GetAllPostsEvent()),
                        ),
                      PostsLoaded() => _PostsGrid(
                          state: state,
                          scrollController: _scrollController,
                          onPostTap: _openPostManagement,
                        ),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page header
// ─────────────────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B28) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3344) : const Color(0xFFE8ECF0),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1180;
          final title = _HeaderTitle(isDark: isDark, l10n: l10n, theme: theme);
          final toolbar = _HeaderFilterToolbar(isDark: isDark);

          if (desktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title takes only the space it needs on the left.
                title,
                const SizedBox(width: 16),
                // Toolbar expands to fill all remaining space so the Create Post
                // button is always anchored to the far right edge of the header.
                Expanded(child: toolbar),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 10),
              toolbar,
            ],
          );
        },
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({
    required this.isDark,
    required this.l10n,
    required this.theme,
  });

  final bool isDark;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.t('posts'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.45,
            color: isDark ? Colors.white : const Color(0xFF111827),
            height: 1.05,
          ),
        ),
        const SizedBox(height: 4),
        // Use BlocSelector to rebuild only when the selected category name
        // changes.  Fall back to bloc.activeFilters during loading/error so
        // the subtitle stays correct while an API call is in-flight.
        BlocSelector<PostsBloc, PostsState, String?>(
          selector: (state) => switch (state) {
            PostsLoaded(:final filters) => filters.categoryName,
            PostsEmpty(:final filters) => filters.categoryName,
            _ => null, // resolved below from activeFilters
          },
          builder: (ctx, categoryNameFromState) {
            // Prefer the state value; fall back to the bloc's live activeFilters
            // so the subtitle updates immediately when a chip is tapped, even
            // before the API call completes.
            final catName = categoryNameFromState ??
                ctx.read<PostsBloc>().activeFilters.categoryName;
            return Text(
              catName != null
                  ? ctx.tr('showingPostsIn', {'name': catName})
                  : l10n.t('allCategories'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey.shade500 : const Color(0xFF6B7280),
                height: 1.2,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HeaderFilterToolbar extends StatelessWidget {
  const _HeaderFilterToolbar({required this.isDark});

  final bool isDark;

  void _openCreatePost(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.createPost).then((created) {
      if (created == true && context.mounted) {
        context.read<PostsBloc>().add(GetAllPostsEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 760;
        final createButton = _CreatePostButton(
          isDark: isDark,
          iconOnly: narrow,
          onPressed: () => _openCreatePost(context),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PostsFilterBar(isDark: isDark, compact: true),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: createButton,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Filter bar expands to fill the available toolbar width,
            // which naturally pushes the Create Post button to the far right.
            Expanded(child: PostsFilterBar(isDark: isDark, compact: true)),
            const SizedBox(width: 8),
            createButton,
          ],
        );
      },
    );
  }
}

class _CreatePostButton extends StatefulWidget {
  const _CreatePostButton({
    required this.isDark,
    required this.onPressed,
    this.iconOnly = false,
  });

  final bool isDark;
  final VoidCallback onPressed;
  final bool iconOnly;

  @override
  State<_CreatePostButton> createState() => _CreatePostButtonState();
}

class _CreatePostButtonState extends State<_CreatePostButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (widget.iconOnly) {
      return IconButton.filled(
        onPressed: widget.onPressed,
        tooltip: l10n.t('createPost'),
        icon: const Icon(Icons.add_rounded, size: 20),
      );
    }

    final bg = _hovered
        ? const Color(0xFF4F46E5)
        : const Color(0xFF6366F1);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: FilledButton.icon(
          onPressed: widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(
            l10n.t('createPost'),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category filter chips
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.isDark});

  final bool isDark;

  /// Reads the active category ID from whichever state/bloc is available.
  static String? _activeCategoryId(PostsState state, BuildContext context) {
    if (state is PostsLoaded) return state.filters.categoryId;
    // For loading/error states fall back to the bloc's live activeFilters.
    return context.read<PostsBloc>().activeFilters.categoryId;
  }

  static const _palette = [
    Color(0xFF6366F1),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
  ];

  Color _colorForCategory(CategoryEntity cat) {
    final key = cat.slug.isNotEmpty ? cat.slug : cat.name.toLowerCase();
    final idx = key.codeUnits.fold(0, (a, b) => a + b) % _palette.length;
    return _palette[idx];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<CategoriesBloc, CategoriesState>(
      builder: (context, catState) {
        if (catState is! CategoriesLoaded || catState.categories.isEmpty) {
          return const SizedBox.shrink();
        }

        // ── Read selected category from PostsBloc filters ────────────────
        // We use BlocBuilder (not BlocSelector) so chips rebuild whenever
        // filters change — including optimistic updates from the bloc.
        return BlocBuilder<PostsBloc, PostsState>(
          buildWhen: (prev, next) {
            // Rebuild whenever the selected category ID changes in the bloc's
            // active filters (covers both the optimistic update and the final
            // loaded state), or whenever the state type changes.
            final prevId = _activeCategoryId(prev, context);
            final nextId = _activeCategoryId(next, context);
            return prevId != nextId || prev.runtimeType != next.runtimeType;
          },
          builder: (context, postsState) {
            // Always read selectedId from bloc.activeFilters — it is updated
            // synchronously in the event handler before any async work, so it
            // reflects the user's latest selection even while an API call is
            // in-flight.
            final selectedId = context.read<PostsBloc>().activeFilters.categoryId;

            return SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: catState.categories.length + 1,
                separatorBuilder: (context, idx) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _CategoryChip(
                      label: l10n.t('all'),
                      isSelected: selectedId == null,
                      isDark: isDark,
                      onTap: () => context
                          .read<PostsBloc>()
                          .add(FilterPostsByCategoryEvent()),
                    );
                  }
                  final cat = catState.categories[index - 1];
                  return _CategoryChip(
                    label: cat.name,
                    isSelected: selectedId == cat.id,
                    isDark: isDark,
                    accentColor: _colorForCategory(cat),
                    onTap: () => context.read<PostsBloc>().add(
                          FilterPostsByCategoryEvent(
                            categoryId: cat.id,
                            categoryName: cat.name,
                            // Slug is the value the API `?category=` param expects
                            categorySlug: cat.slug.isNotEmpty
                                ? cat.slug
                                : cat.name.toLowerCase(),
                          ),
                        ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryChip extends StatefulWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    this.accentColor,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final Color? accentColor;

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color =
        widget.accentColor ?? Theme.of(context).colorScheme.primary;
    final selected = widget.isSelected;
    final isDark = widget.isDark;

    final bg = selected
        ? color
        : _hovered
            ? (isDark ? const Color(0xFF252B3B) : const Color(0xFFF8FAFC))
            : (isDark ? const Color(0xFF151B28) : Colors.white);

    final fg = selected
        ? Colors.white
        : isDark
            ? Colors.grey.shade300
            : const Color(0xFF374151);

    final borderColor = selected
        ? color
        : isDark
            ? const Color(0xFF334155)
            : const Color(0xFFE2E8F0);

    final scale = _hovered && !selected ? 1.025 : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : _hovered
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.06,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
            ),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                  letterSpacing: selected ? -0.1 : 0,
                ),
                child: Text(widget.label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Posts grid (responsive rows, content-driven card height)
// ─────────────────────────────────────────────────────────────────────────────

class _PostsGrid extends StatelessWidget {
  const _PostsGrid({
    required this.state,
    required this.scrollController,
    required this.onPostTap,
  });

  final PostsLoaded state;
  final ScrollController scrollController;
  final void Function(ManagedPostEntity) onPostTap;

  @override
  Widget build(BuildContext context) {
    final posts = state.posts;
    const gap = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = postsGridColumnCount(constraints.maxWidth);
        final rowCount = (posts.length / columns).ceil();

        return CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, rowIndex) {
                  final start = rowIndex * columns;
                  final end = (start + columns).clamp(0, posts.length);
                  final rowPosts = posts.sublist(start, end);

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: rowIndex < rowCount - 1 ? gap : 0,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < columns; i++) ...[
                            if (i > 0) const SizedBox(width: gap),
                            Expanded(
                              child: i < rowPosts.length
                                  ? PostCard(
                                      post: rowPosts[i],
                                      onTap: () => onPostTap(rowPosts[i]),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
                childCount: rowCount,
              ),
            ),
            if (state.isLoadingMore)
              const SliverToBoxAdapter(child: _LoadMoreIndicator()),
            if (state.hasReachedMax && posts.isNotEmpty)
              SliverToBoxAdapter(child: _EndOfListLabel()),
            // Bottom breathing room
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton loading grid with shimmer
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonGrid extends StatefulWidget {
  const _SkeletonGrid({required this.width});

  final double width;

  @override
  State<_SkeletonGrid> createState() => _SkeletonGridState();
}

class _SkeletonGridState extends State<_SkeletonGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columns = postsGridColumnCount(widget.width);
    const gap = 12.0;
    const rows = 2;

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows,
          separatorBuilder: (context, idx) => const SizedBox(height: gap),
          itemBuilder: (_, rowIndex) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < columns; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    Expanded(
                      child: _ShimmerCard(shimmerValue: _shimmer.value),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({required this.shimmerValue});

  final double shimmerValue;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final highlight =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final shimmerColor = Color.lerp(base, highlight, shimmerValue)!;
    final strongerBase =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3440) : const Color(0xFFE8ECF0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            height: 176,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(shimmerColor, height: 13, width: double.infinity),
                const SizedBox(height: 7),
                _bar(shimmerColor, height: 11, width: 160),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _bar(strongerBase, height: 9, width: 48),
                    const SizedBox(width: 8),
                    _bar(strongerBase, height: 9, width: 40),
                    const SizedBox(width: 8),
                    _bar(strongerBase, height: 9, width: 36),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(Color color, {required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onClearFilters});

  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // hasAnyFilters covers both the category chip and advanced filters
    // (search / type / sort / auction) — the button should appear in any
    // situation where clearing filters might reveal more posts.
    final hasFilters =
        context.read<PostsBloc>().activeFilters.hasAnyFilters;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 34,
                color:
                    isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.t('noPostsFound'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.t('tryDifferentCategory'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? Colors.grey.shade500
                    : const Color(0xFF6B7280),
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: onClearFilters,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),

                ),
                child: Text(l10n.t('clearAllFilters')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2E3440)
                  : const Color(0xFFE8ECF0),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 28,
                  color: Colors.red.shade500,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.t('errorOccurred'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? Colors.grey.shade400
                      : const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: Text(l10n.t('tryAgain')),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pagination indicators
// ─────────────────────────────────────────────────────────────────────────────

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _EndOfListLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 1,
            color: isDark ? const Color(0xFF2E3440) : const Color(0xFFE8ECF0),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.t('allPostsLoaded'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 1,
            color: isDark ? const Color(0xFF2E3440) : const Color(0xFFE8ECF0),
          ),
        ],
      ),
    );
  }
}
