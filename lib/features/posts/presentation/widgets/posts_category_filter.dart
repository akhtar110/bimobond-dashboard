import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/presentation/bloc/categories_bloc.dart';
import '../bloc/posts_bloc.dart';
import '../utils/posts_responsive.dart';
import 'posts_filter_panel_ui.dart';

class PostsCategoryFilter extends StatelessWidget {
  const PostsCategoryFilter({super.key, this.metrics});

  final PostsLayoutMetrics? metrics;

  static String? _activeCategoryId(PostsState state, BuildContext context) {
    if (state is PostsLoaded) return state.filters.categoryId;
    return context.read<PostsBloc>().activeFilters.categoryId;
  }

  // Brand accent palette â€” intentionally not from ColorScheme so categories
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

  Color _colorForCategory(CategoryEntity cat) =>
      PostsCategoryFilter.colorForCategory(cat);

  static Color colorForCategory(CategoryEntity cat) {
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
            final selectedId = context
                .read<PostsBloc>()
                .activeFilters
                .categoryId;
            final m =
                metrics ??
                PostsLayoutMetrics(
                  getPostsDeviceType(MediaQuery.sizeOf(context).width),
                );

            return SizedBox(
              height: m.categoryStripHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: catState.catalogCategories.length + 1,
                separatorBuilder: (context, idx) =>
                    SizedBox(width: m.filterGap + 1),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return PostsCategoryChip(
                      label: l10n.t('all'),
                      isSelected: selectedId == null,
                      compact: m.isMobile,
                      onTap: () => context.read<PostsBloc>().add(
                        FilterPostsByCategoryEvent(),
                      ),
                    );
                  }
                  final cat = catState.catalogCategories[index - 1];
                  return PostsCategoryChip(
                    label: cat.name,
                    category: cat,
                    isSelected: cat.id.isNotEmpty && selectedId == cat.id,
                    accentColor: _colorForCategory(cat),
                    compact: m.isMobile,
                    onTap: () {
                      if (kDebugMode) {
                        debugPrint(
                          '[CategoryChip] tapped â†’ '
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

class PostsCategoryChip extends StatefulWidget {
  const PostsCategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.accentColor,
    this.category,
    this.compact = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? accentColor;
  final CategoryEntity? category;
  final bool compact;

  @override
  State<PostsCategoryChip> createState() => PostsCategoryChipState();
}

class PostsCategoryChipState extends State<PostsCategoryChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = widget.accentColor ?? scheme.primary;
    final selected = widget.isSelected;

    final bg = selected
        ? color.withValues(alpha: 0.14)
        : _hovered
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerLow;

    final fg = selected ? color : scheme.onSurface;
    final borderColor = selected
        ? color.withValues(alpha: 0.45)
        : scheme.outlineVariant;

    final scale = _hovered && !selected ? 1.025 : 1.0;
    final chipHeight = widget.compact ? 32.0 : 36.0;
    final hPad = widget.compact ? 10.0 : 12.0;
    final fontSize = widget.compact ? 11.5 : 12.5;

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
            height: chipHeight,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : _hovered
                      ? [
                          BoxShadow(
                            color: scheme.shadow.withValues(alpha: 0.05),
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
                  fontSize: fontSize,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                  letterSpacing: selected ? -0.1 : 0,
                ),
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Category chips for the posts filter panel (draft selection before Apply).
class PostsFilterCategorySection extends StatelessWidget {
  const PostsFilterCategorySection({
    super.key,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  final String? selectedCategoryId;
  final void Function({
    String? categoryId,
    String? categoryName,
    String? categorySlug,
  }) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<CategoriesBloc, CategoriesState>(
      builder: (context, catState) {
        if (catState is! CategoriesLoaded ||
            catState.catalogCategories.isEmpty) {
          return const SizedBox.shrink();
        }

        return PostsFilterChipGrid(
          children: [
            PostsCategoryChip(
              label: l10n.t('all'),
              isSelected: selectedCategoryId == null,
              compact: true,
              onTap: () => onCategorySelected(),
            ),
            for (final cat in catState.catalogCategories)
              PostsCategoryChip(
                label: cat.name,
                category: cat,
                isSelected: cat.id.isNotEmpty && selectedCategoryId == cat.id,
                accentColor: PostsCategoryFilter.colorForCategory(cat),
                compact: true,
                onTap: () => onCategorySelected(
                  categoryId: cat.id,
                  categoryName: cat.name,
                  categorySlug:
                      cat.slug.isNotEmpty ? cat.slug : cat.name.toLowerCase(),
                ),
              ),
          ],
        );
      },
    );
  }
}
