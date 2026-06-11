import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../features/categories/presentation/bloc/categories_bloc.dart';
import '../../../../features/categories/presentation/widgets/category_icon.dart';
import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../../domain/enums/posts_view_type.dart';
import '../bloc/posts_bloc.dart';
import '../widgets/bulk_selection_toolbar.dart';
import '../widgets/posts_filter_bar.dart';
import '../widgets/posts_table_view.dart';
import '../widgets/posts_view_toggle.dart';
import '../widgets/selectable_post_card_wrapper.dart';

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
    context.read<CategoriesBloc>().add(LoadCategoriesEvent(forCatalog: true));
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
      } else if (result == true) {
        context.read<PostsBloc>().add(RemovePostEvent(post.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
            const _SelectAllPostsIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const _ClearSelectionIntent(),
      },
      child: Actions(
        actions: {
          _SelectAllPostsIntent: CallbackAction<_SelectAllPostsIntent>(
            onInvoke: (_) {
              context.read<PostsBloc>().add(SelectAllPostsEvent());
              return null;
            },
          ),
          _ClearSelectionIntent: CallbackAction<_ClearSelectionIntent>(
            onInvoke: (_) {
              context.read<PostsBloc>().add(ClearSelectionEvent());
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: BlocListener<PostsBloc, PostsState>(
            listenWhen: (prev, next) =>
                next is PostsLoaded &&
                next.bulkActionMessage != null &&
                (prev is! PostsLoaded ||
                    prev.bulkActionMessage != next.bulkActionMessage),
            listener: (context, state) {
              if (state is! PostsLoaded || state.bulkActionMessage == null) {
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(state.bulkActionMessage!),
                  backgroundColor:
                      state.bulkActionIsError ? Colors.red.shade700 : null,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<PostsBloc>().add(ClearBulkActionFeedbackEvent());
            },
            child: Container(
              color: scheme.surfaceContainerLowest,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1680),
                  child: Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _PageHeader(),
                        const SizedBox(height: 10),
                        const _CategoryFilter(),
                        const SizedBox(height: 10),
                        const BulkSelectionToolbar(),
                        const SizedBox(height: 10),
                        Expanded(
                          child: BlocBuilder<PostsBloc, PostsState>(
                            buildWhen: (prev, next) =>
                                prev.runtimeType != next.runtimeType ||
                                (prev is PostsLoaded &&
                                    next is PostsLoaded &&
                                    (prev.posts != next.posts ||
                                        prev.viewType != next.viewType ||
                                        prev.selectedPostIds !=
                                            next.selectedPostIds ||
                                        prev.isLoadingMore !=
                                            next.isLoadingMore ||
                                        prev.isPerformingBulkAction !=
                                            next.isPerformingBulkAction)),
                            builder: (context, state) => switch (state) {
                              PostsInitial() || PostsLoading() =>
                                LayoutBuilder(
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
                                  onRetry: () => context
                                      .read<PostsBloc>()
                                      .add(GetAllPostsEvent()),
                                ),
                              PostsLoaded() => _PostsContent(
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
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectAllPostsIntent extends Intent {
  const _SelectAllPostsIntent();
}

class _ClearSelectionIntent extends Intent {
  const _ClearSelectionIntent();
}

// ─────────────────────────────────────────────────────────────────────────────
// Page header
// ─────────────────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1180;
          final title = _HeaderTitle(l10n: l10n, theme: theme);
          final toolbar = const _HeaderFilterToolbar();

          if (desktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                title,
                const SizedBox(width: 16),
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
  const _HeaderTitle({required this.l10n, required this.theme});

  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.t('posts'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.45,
            color: scheme.onSurface,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 4),
        BlocSelector<PostsBloc, PostsState, String?>(
          selector: (state) => switch (state) {
            PostsLoaded(:final filters) => filters.categoryName,
            PostsEmpty(:final filters) => filters.categoryName,
            _ => null,
          },
          builder: (ctx, categoryNameFromState) {
            final catName = categoryNameFromState ??
                ctx.read<PostsBloc>().activeFilters.categoryName;
            return Text(
              catName != null
                  ? ctx.tr('showingPostsIn', {'name': catName})
                  : l10n.t('allCategories'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
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
  const _HeaderFilterToolbar();

  void _openCreatePost(BuildContext context) {
    final l10n = context.l10n;
    Navigator.pushNamed(context, AppRoutes.createPost).then((result) {
      if (!context.mounted) return;
      if (result == 'published' || result == 'draft') {
        context.read<PostsBloc>().add(GetAllPostsEvent());
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 760;
        final createButton = _CreatePostButton(
          iconOnly: narrow,
          onPressed: () => _openCreatePost(context),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PostsFilterBar(isDark: isDark, compact: true),
              const SizedBox(height: 8),
              Row(
                children: [
                  const PostsViewToggle(),
                  const Spacer(),
                  createButton,
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: PostsFilterBar(isDark: isDark, compact: true)),
            const SizedBox(width: 8),
            const PostsViewToggle(),
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
    required this.onPressed,
    this.iconOnly = false,
  });

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
    final scheme = Theme.of(context).colorScheme;

    if (widget.iconOnly) {
      return IconButton.filled(
        onPressed: widget.onPressed,
        tooltip: l10n.t('createPost'),
        icon: const Icon(Icons.add_rounded, size: 20),
      );
    }

    final bg = _hovered
        ? scheme.primary.withValues(alpha: 0.85)
        : scheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: FilledButton.icon(
          onPressed: widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: scheme.onPrimary,
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
  const _CategoryFilter();

  static String? _activeCategoryId(PostsState state, BuildContext context) {
    if (state is PostsLoaded) return state.filters.categoryId;
    return context.read<PostsBloc>().activeFilters.categoryId;
  }

  // Brand accent palette — intentionally not from ColorScheme so categories
  // remain visually distinct regardless of the active theme.
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
        if (catState is! CategoriesLoaded ||
            catState.catalogCategories.isEmpty) {
          return const SizedBox.shrink();
        }

        return BlocBuilder<PostsBloc, PostsState>(
          buildWhen: (prev, next) {
            final prevId = _activeCategoryId(prev, context);
            final nextId = _activeCategoryId(next, context);
            return prevId != nextId || prev.runtimeType != next.runtimeType;
          },
          builder: (context, postsState) {
            final selectedId =
                context.read<PostsBloc>().activeFilters.categoryId;

            return SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: catState.catalogCategories.length + 1,
                separatorBuilder: (context, idx) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _CategoryChip(
                      label: l10n.t('all'),
                      isSelected: selectedId == null,
                      onTap: () => context
                          .read<PostsBloc>()
                          .add(FilterPostsByCategoryEvent()),
                    );
                  }
                  final cat = catState.catalogCategories[index - 1];
                  return _CategoryChip(
                    label: cat.name,
                    category: cat,
                    isSelected: cat.id.isNotEmpty && selectedId == cat.id,
                    accentColor: _colorForCategory(cat),
                    onTap: () {
                      if (kDebugMode) {
                        debugPrint(
                          '[CategoryChip] tapped → '
                          'id="${cat.id}"  '
                          'name="${cat.name}"  '
                          'slug="${cat.slug}"',
                        );
                      }
                      context.read<PostsBloc>().add(
                            FilterPostsByCategoryEvent(
                              categoryId: cat.id,
                              categoryName: cat.name,
                              categorySlug: cat.slug.isNotEmpty
                                  ? cat.slug
                                  : cat.name.toLowerCase(),
                            ),
                          );
                    },
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
    required this.onTap,
    this.accentColor,
    this.category,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? accentColor;
  final CategoryEntity? category;

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = widget.accentColor ?? scheme.primary;
    final selected = widget.isSelected;

    final bg = selected
        ? color
        : _hovered
            ? scheme.surfaceContainerHigh
            : scheme.surface;

    final fg = selected
        ? Colors.white
        : scheme.onSurface;

    final borderColor = selected ? color : scheme.outlineVariant;

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
                            color: scheme.shadow.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.category != null) ...[
                    CategoryIcon(
                      category: widget.category,
                      size: 18,
                      borderRadius: BorderRadius.circular(5),
                      backgroundColor: selected
                          ? Colors.white.withValues(alpha: 0.2)
                          : scheme.surfaceContainerHighest,
                      iconColor: fg,
                    ),
                    const SizedBox(width: 6),
                  ],
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 160),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: fg,
                      letterSpacing: selected ? -0.1 : 0,
                    ),
                    child: Text(widget.label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Posts content (grid / list with shared pagination)
// ─────────────────────────────────────────────────────────────────────────────

class _PostsContent extends StatelessWidget {
  const _PostsContent({
    required this.state,
    required this.scrollController,
    required this.onPostTap,
  });

  final PostsLoaded state;
  final ScrollController scrollController;
  final void Function(ManagedPostEntity) onPostTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: state.viewType == PostsViewType.grid
          ? _PostsGrid(
              key: const ValueKey('posts_grid'),
              state: state,
              scrollController: scrollController,
              onPostTap: onPostTap,
            )
          : _PostsList(
              key: const ValueKey('posts_list'),
              state: state,
              scrollController: scrollController,
              onPostTap: onPostTap,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Posts grid (responsive rows, content-driven card height)
// ─────────────────────────────────────────────────────────────────────────────

class _PostsGrid extends StatelessWidget {
  const _PostsGrid({
    super.key,
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
                                  ? SelectablePostCard(
                                      post: rowPosts[i],
                                      isSelected: state.selectedPostIds
                                          .contains(rowPosts[i].id),
                                      onSelectionChanged: (selected) =>
                                          togglePostSelection(
                                        context,
                                        rowPosts[i].id,
                                        selected ?? false,
                                      ),
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
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Posts list view
// ─────────────────────────────────────────────────────────────────────────────

class _PostsList extends StatelessWidget {
  const _PostsList({
    super.key,
    required this.state,
    required this.scrollController,
    required this.onPostTap,
  });

  final PostsLoaded state;
  final ScrollController scrollController;
  final void Function(ManagedPostEntity) onPostTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final posts = state.posts;

    return LayoutBuilder(
      builder: (context, constraints) {
        final density = postsTableDensityForWidth(constraints.maxWidth);

        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PostsTableHeaderDelegate(
                    l10n: l10n,
                    scheme: scheme,
                    density: density,
                    allVisibleSelected: state.allVisibleSelected,
                    someVisibleSelected: state.someVisibleSelected,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = posts[index];
                      final isLast = index == posts.length - 1;
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : Border(
                                  bottom: BorderSide(
                                    color: scheme.outlineVariant
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                        ),
                        child: PostsTableRow(
                          post: post,
                          density: density,
                          isSelected:
                              state.selectedPostIds.contains(post.id),
                          onSelectionChanged: (selected) =>
                              togglePostSelection(
                            context,
                            post.id,
                            selected ?? false,
                          ),
                          onTap: () => onPostTap(post),
                        ),
                      );
                    },
                    childCount: posts.length,
                  ),
                ),
                if (state.isLoadingMore)
                  const SliverToBoxAdapter(child: _LoadMoreIndicator()),
                if (state.hasReachedMax && posts.isNotEmpty)
                  SliverToBoxAdapter(child: _EndOfListLabel()),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PostsTableHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PostsTableHeaderDelegate({
    required this.l10n,
    required this.scheme,
    required this.density,
    required this.allVisibleSelected,
    required this.someVisibleSelected,
  });

  final AppLocalizations l10n;
  final ColorScheme scheme;
  final PostsTableDensity density;
  final bool allVisibleSelected;
  final bool someVisibleSelected;

  @override
  double get minExtent => kPostsTableHeaderHeight;

  @override
  double get maxExtent => kPostsTableHeaderHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: scheme.surfaceContainerLow,
      elevation: overlapsContent ? 1 : 0,
      shadowColor: scheme.shadow.withValues(alpha: 0.08),
      child: PostsTableHeader(
        l10n: l10n,
        density: density,
        allVisibleSelected: allVisibleSelected,
        someVisibleSelected: someVisibleSelected,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PostsTableHeaderDelegate oldDelegate) {
    return oldDelegate.allVisibleSelected != allVisibleSelected ||
        oldDelegate.someVisibleSelected != someVisibleSelected ||
        oldDelegate.density != density;
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
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerLow;
    final highlight = scheme.surfaceContainerHighest;
    final shimmerColor = Color.lerp(base, highlight, shimmerValue)!;
    final strongerBase = scheme.surfaceContainerHighest;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
                color: scheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 34,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.t('noPostsFound'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.t('tryDifferentCategory'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.05),
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
                  color: scheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 28,
                  color: scheme.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.t('errorOccurred'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
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
    final scheme = Theme.of(context).colorScheme;
    final dividerColor = scheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 32, height: 1, color: dividerColor),
          const SizedBox(width: 12),
          Text(
            l10n.t('allPostsLoaded'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 32, height: 1, color: dividerColor),
        ],
      ),
    );
  }
}
