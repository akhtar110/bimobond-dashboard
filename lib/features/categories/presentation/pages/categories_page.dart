import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n_message.dart';
import '../../../../core/localization/localization.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/categories_bloc.dart';

// ─── Layout helpers ───────────────────────────────────────────────────────────

int categoriesGridColumnCount(double width) {
  if (width > 1600) return 4;
  if (width > 1200) return 3;
  if (width > 700) return 2;
  return 1;
}

double _pageHorizontalPadding(double width) {
  if (width >= 1600) return 32;
  if (width >= 768) return 24;
  return 16;
}

double _gridGap(double width) {
  if (width >= 1200) return 20;
  if (width >= 768) return 16;
  return 12;
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoriesBloc, CategoriesState>(
      listener: (context, state) {
        if (state is CategoriesLoaded) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(localizeMessage(context, state.successMessage!)),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ));
          }
          if (state.failureMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.failureMessage!),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ));
          }
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF7F9FC),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hPad = _pageHorizontalPadding(constraints.maxWidth);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1680),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(hPad, 28, hPad, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PageHeader(isDark: isDark, state: state),
                        const SizedBox(height: 24),
                        Expanded(child: _buildBody(context, state, isDark)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CategoriesState state, bool isDark) {
    if (state is CategoriesLoading) return _LoadingView(isDark: isDark);
    if (state is CategoriesError) {
      return _ErrorView(
        message: state.message,
        onRetry: () => context.read<CategoriesBloc>().add(LoadCategoriesEvent()),
      );
    }
    if (state is CategoriesLoaded) {
      if (state.categories.isEmpty) {
        return _EmptyView(isDark: isDark);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilterBar(state: state, isDark: isDark),
          const SizedBox(height: 20),
          Expanded(
            child: state.filteredRoots.isEmpty
                ? _FilteredEmptyState(filter: state.filter, isDark: isDark)
                : _HierarchyGrid(state: state, isDark: isDark),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

// ─── Page header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.isDark, required this.state});

  final bool isDark;
  final CategoriesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final loaded = state is CategoriesLoaded ? state as CategoriesLoaded : null;
    final total = loaded?.categories.length ?? 0;
    final rootCount = loaded?.roots.length ?? 0;
    final subCount = total - rootCount;
    final active = loaded?.categories.where((c) => c.isActive).length ?? 0;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? Colors.grey.shade400 : const Color(0xFF6B7280);
    final outlineBorder = theme.colorScheme.outline.withValues(alpha: 0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('categoriesTitle'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: titleColor,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.t('categoriesSubtitle'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: subtitleColor,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              if (total > 0) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeaderBadge(
                      icon: Icons.layers_outlined,
                      label: '$rootCount root',
                      isDark: isDark,
                    ),
                    if (subCount > 0)
                      _HeaderBadge(
                        icon: Icons.account_tree_outlined,
                        label: '$subCount subcategories',
                        isDark: isDark,
                        accent: Colors.indigo,
                      ),
                    _HeaderBadge(
                      icon: Icons.check_circle_outline_rounded,
                      label: '$active ${l10n.t('active').toLowerCase()}',
                      isDark: isDark,
                      accent: const Color(0xFF16A34A),
                    ),
                  ],
                ),
              ],
            ],
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderIconButton(
                isDark: isDark,
                icon: Icons.refresh_rounded,
                tooltip: l10n.t('refresh'),
                onTap: () =>
                    context.read<CategoriesBloc>().add(LoadCategoriesEvent()),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => _showDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.t('newCategory')),
                style: FilledButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: 20),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: actions,
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: titleBlock), actions],
          );
        }),
        const SizedBox(height: 24),
        Divider(height: 1, thickness: 1, color: outlineBorder),
      ],
    );
  }

  void _showDialog(BuildContext context, {CategoryEntity? parent}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<CategoriesBloc>(),
        child: _CategoryFormDialog(parentForNew: parent),
      ),
    );
  }
}

// ─── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.state, required this.isDark});

  final CategoriesLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final l10n = context.l10n;
    final outlineBorder = theme.colorScheme.outline.withValues(alpha: 0.2);

    final allCount = state.roots.length;
    final activeCount = state.roots.where((c) => c.isActive).length;
    final inactiveCount = allCount - activeCount;

    final tabs = [
      (filter: CategoryFilter.all, label: l10n.t('filterAll'), count: allCount),
      (filter: CategoryFilter.active, label: l10n.t('active'), count: activeCount),
      (filter: CategoryFilter.inactive, label: l10n.t('inactive'), count: inactiveCount),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.filter_list_rounded,
            size: 16,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tabs.map((tab) {
                final isSelected = state.filter == tab.filter;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context
                        .read<CategoriesBloc>()
                        .add(ChangeCategoryFilterEvent(tab.filter)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary
                            : (isDark
                                ? const Color(0xFF252B3B)
                                : const Color(0xFFF3F4F6)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? primary
                              : outlineBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.grey.shade300
                                      : const Color(0xFF374151)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : (isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${tab.count}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.grey.shade300
                                        : const Color(0xFF374151)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filtered empty state ─────────────────────────────────────────────────────

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({required this.filter, required this.isDark});

  final CategoryFilter filter;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final primary = theme.colorScheme.primary;

    final (icon, message) = switch (filter) {
      CategoryFilter.active => (
          Icons.visibility_outlined,
          l10n.t('noActiveCategories'),
        ),
      CategoryFilter.inactive => (
          Icons.visibility_off_outlined,
          l10n.t('noInactiveCategories'),
        ),
      CategoryFilter.all => (Icons.category_outlined, l10n.t('noCategoriesYet')),
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: primary),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => context
                .read<CategoriesBloc>()
                .add(ChangeCategoryFilterEvent(CategoryFilter.all)),
            icon: const Icon(Icons.clear_rounded, size: 16),
            label: Text(l10n.t('showAllCategories')),
          ),
        ],
      ),
    );
  }
}

// ─── Hierarchy grid ───────────────────────────────────────────────────────────

class _HierarchyGrid extends StatelessWidget {
  const _HierarchyGrid({required this.state, required this.isDark});

  final CategoriesLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final roots = state.filteredRoots;

    return LayoutBuilder(builder: (context, constraints) {
      final columns = categoriesGridColumnCount(constraints.maxWidth);
      final gap = _gridGap(constraints.maxWidth);
      final rowCount = (roots.length / columns).ceil();

      return ListView.separated(
        itemCount: rowCount,
        separatorBuilder: (_, __) => SizedBox(height: gap),
        itemBuilder: (context, rowIndex) {
          final start = rowIndex * columns;
          final end = (start + columns).clamp(0, roots.length);
          final rowItems = roots.sublist(start, end);

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < columns; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  Expanded(
                    child: i < rowItems.length
                        ? _RootCategoryCard(
                            category: rowItems[i],
                            subcategories: state.childrenOf(rowItems[i].id),
                            allRoots: roots,
                            isDark: isDark,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        },
      );
    });
  }
}

// ─── Root category card ───────────────────────────────────────────────────────

class _RootCategoryCard extends StatefulWidget {
  const _RootCategoryCard({
    required this.category,
    required this.subcategories,
    required this.allRoots,
    required this.isDark,
  });

  final CategoryEntity category;
  final List<CategoryEntity> subcategories;
  final List<CategoryEntity> allRoots;
  final bool isDark;

  @override
  State<_RootCategoryCard> createState() => _RootCategoryCardState();
}

class _RootCategoryCardState extends State<_RootCategoryCard> {
  bool _hovered = false;
  bool _expanded = false;

  CategoryEntity get cat => widget.category;
  bool get isDark => widget.isDark;

  static const _palette = [
    Color(0xFF6366F1), Color(0xFF0EA5E9), Color(0xFF10B981),
    Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFEC4899),
    Color(0xFF8B5CF6), Color(0xFF14B8A6),
  ];

  Color get _color {
    final key = cat.slug.isNotEmpty ? cat.slug : cat.name.toLowerCase();
    final idx = key.codeUnits.fold(0, (a, b) => a + b) % _palette.length;
    return _palette[idx];
  }

  String get _initial =>
      cat.name.isNotEmpty ? cat.name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color;
    final outlineBorder = theme.colorScheme.outline.withValues(alpha: 0.2);
    final metaColor = isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF);
    final hasDesc = cat.description != null && cat.description!.isNotEmpty;
    final hasSubs = widget.subcategories.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 200),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? color.withValues(alpha: 0.45) : outlineBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark
                    ? (_hovered ? 0.28 : 0.12)
                    : (_hovered ? 0.08 : 0.04),
              ),
              blurRadius: _hovered ? 20 : 10,
              offset: Offset(0, _hovered ? 6 : 2),
            ),
            if (_hovered)
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Accent bar ──────────────────────────────────────────────
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.55)],
                ),
              ),
            ),

            // ── Card body ───────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + name + status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color.withValues(alpha: 0.9),
                                color.withValues(alpha: 0.65),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 6),
                              _StatusBadge(isActive: cat.isActive),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Expanded(
                      child: hasDesc
                          ? Text(
                              cat.description!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 13,
                                height: 1.45,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : const Color(0xFF6B7280),
                              ),
                            )
                          : Text(
                              context.l10n.t('categoryDescriptionHint'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 13,
                                height: 1.45,
                                fontStyle: FontStyle.italic,
                                color: metaColor.withValues(alpha: 0.85),
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),

                    // Meta chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MetaChip(
                          icon: Icons.tag_rounded,
                          label: cat.slug,
                          isDark: isDark,
                        ),
                        if (hasSubs)
                          _MetaChip(
                            icon: Icons.account_tree_outlined,
                            label:
                                '${widget.subcategories.length} sub',
                            isDark: isDark,
                            accent: color,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),

            // ── Subcategories expand section ────────────────────────────
            if (hasSubs) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _expanded
                              ? context.l10n.t('hideSubcategories')
                              : context.tr('showSubcategories', {
                                  'count':
                                      '${widget.subcategories.length}',
                                }),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _SubcategoryList(
                  subcategories: widget.subcategories,
                  allRoots: widget.allRoots,
                  isDark: isDark,
                  accentColor: color,
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],

            // ── Card actions ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: _CardActions(
                category: cat,
                allRoots: widget.allRoots,
                isDark: isDark,
                hasChildren: hasSubs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Subcategory list (inside expanded card section) ──────────────────────────

class _SubcategoryList extends StatelessWidget {
  const _SubcategoryList({
    required this.subcategories,
    required this.allRoots,
    required this.isDark,
    required this.accentColor,
  });

  final List<CategoryEntity> subcategories;
  final List<CategoryEntity> allRoots;
  final bool isDark;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CategoriesBloc>();
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF252B3B)
            : accentColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final sub in subcategories) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.subdirectory_arrow_right_rounded,
                    size: 14,
                    color: accentColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                        if (sub.slug.isNotEmpty)
                          Text(
                            sub.slug,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _StatusDot(isActive: sub.isActive),
                  const SizedBox(width: 8),
                  // Edit subcategory
                  _MiniActionBtn(
                    icon: Icons.edit_outlined,
                    color: isDark
                        ? Colors.grey.shade300
                        : const Color(0xFF4B5563),
                    tooltip: l10n.t('edit'),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (ctx) => BlocProvider.value(
                        value: bloc,
                        child: _CategoryFormDialog(editing: sub),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Delete subcategory
                  _MiniActionBtn(
                    icon: Icons.delete_outline_rounded,
                    color: isDark
                        ? const Color(0xFFFCA5A5)
                        : Colors.red.shade600,
                    tooltip: l10n.t('delete'),
                    onTap: () => _confirmDelete(context, bloc, sub),
                  ),
                ],
              ),
            ),
            if (sub != subcategories.last)
              Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
                color: accentColor.withValues(alpha: 0.12),
              ),
          ],
          // "Add subcategory" row
          Divider(
            height: 1,
            color: accentColor.withValues(alpha: 0.12),
          ),
          InkWell(
            onTap: () => showDialog<void>(
              context: context,
              builder: (ctx) => BlocProvider.value(
                value: bloc,
                child: _CategoryFormDialog(
                  parentForNew: subcategories.first.parentId != null
                      ? allRoots.where((r) =>
                          r.id == subcategories.first.parentId).firstOrNull
                      : null,
                ),
              ),
            ),
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.add_rounded,
                      size: 14,
                      color: accentColor.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Text(
                    l10n.t('addSubcategory'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    CategoriesBloc bloc,
    CategoryEntity sub,
  ) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
          const SizedBox(width: 10),
          Expanded(child: Text(l10n.t('deleteCategoryTitle'))),
        ]),
        content: Text(
          context.tr('deleteCategoryMessage', {'name': sub.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              bloc.add(DeleteCategoryEvent(sub.id));
            },
            child: Text(l10n.t('delete')),
          ),
        ],
      ),
    );
  }
}

// ─── Card actions ─────────────────────────────────────────────────────────────

class _CardActions extends StatelessWidget {
  const _CardActions({
    required this.category,
    required this.allRoots,
    required this.isDark,
    required this.hasChildren,
  });

  final CategoryEntity category;
  final List<CategoryEntity> allRoots;
  final bool isDark;
  final bool hasChildren;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<CategoriesBloc>();

    return Row(
      children: [
        // Toggle active
        Expanded(
          child: _ActionToolButton(
            tooltip: category.isActive
                ? l10n.t('deactivate')
                : l10n.t('activate'),
            onTap: () => bloc.add(UpdateCategoryEvent(
              id: category.id,
              data: UpdateCategoryData(isActive: !category.isActive),
            )),
            backgroundColor: category.isActive
                ? (isDark
                    ? const Color(0xFF422006)
                    : Colors.orange.shade50)
                : (isDark
                    ? const Color(0xFF14532D)
                    : Colors.green.shade50),
            icon: category.isActive
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            iconColor: category.isActive
                ? (isDark ? Colors.orange.shade300 : Colors.orange.shade700)
                : (isDark ? Colors.green.shade300 : Colors.green.shade700),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        // Edit
        Expanded(
          child: _ActionToolButton(
            tooltip: l10n.t('edit'),
            onTap: () => showDialog<void>(
              context: context,
              builder: (ctx) => BlocProvider.value(
                value: bloc,
                child: _CategoryFormDialog(editing: category),
              ),
            ),
            backgroundColor:
                isDark ? const Color(0xFF252B3B) : const Color(0xFFF3F4F6),
            icon: Icons.edit_outlined,
            iconColor: isDark ? Colors.grey.shade300 : const Color(0xFF4B5563),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        // Add subcategory (root cards only)
        Expanded(
          child: _ActionToolButton(
            tooltip: l10n.t('addSubcategory'),
            onTap: () => showDialog<void>(
              context: context,
              builder: (ctx) => BlocProvider.value(
                value: bloc,
                child: _CategoryFormDialog(parentForNew: category),
              ),
            ),
            backgroundColor: isDark
                ? const Color(0xFF1C2637)
                : const Color(0xFFEFF6FF),
            icon: Icons.add_rounded,
            iconColor:
                isDark ? Colors.blue.shade300 : Colors.blue.shade600,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        // Delete
        Expanded(
          child: _ActionToolButton(
            tooltip: hasChildren
                ? l10n.t('deleteSubcategoriesFirst')
                : l10n.t('delete'),
            onTap: hasChildren ? null : () => _confirmDelete(context, bloc),
            backgroundColor:
                isDark ? const Color(0xFF3B1D1D) : Colors.red.shade50,
            icon: Icons.delete_outline_rounded,
            iconColor: hasChildren
                ? (isDark ? Colors.grey.shade600 : Colors.grey.shade400)
                : (isDark ? const Color(0xFFFCA5A5) : Colors.red.shade600),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, CategoriesBloc bloc) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
          const SizedBox(width: 10),
          Expanded(child: Text(l10n.t('deleteCategoryTitle'))),
        ]),
        content: Text(
          context.tr('deleteCategoryMessage', {'name': category.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              bloc.add(DeleteCategoryEvent(category.id));
            },
            child: Text(l10n.t('delete')),
          ),
        ],
      ),
    );
  }
}

// ─── Create / Edit dialog ─────────────────────────────────────────────────────

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({this.editing, this.parentForNew});

  /// Non-null when editing an existing category.
  final CategoryEntity? editing;

  /// Pre-select this root category as parent when creating a new subcategory.
  final CategoryEntity? parentForNew;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late bool _isActive;
  String? _selectedParentId; // null = root category

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final cat = widget.editing;
    _nameCtrl = TextEditingController(text: cat?.name ?? '');
    _descCtrl = TextEditingController(text: cat?.description ?? '');
    _isActive = cat?.isActive ?? true;

    if (_isEditing) {
      _selectedParentId = cat!.parentId;
    } else if (widget.parentForNew != null) {
      _selectedParentId = widget.parentForNew!.id;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit(List<CategoryEntity> roots) {
    if (!_formKey.currentState!.validate()) return;
    final bloc = context.read<CategoriesBloc>();

    if (_isEditing) {
      final cat = widget.editing!;
      final parentChanged = _selectedParentId != cat.parentId;
      bloc.add(UpdateCategoryEvent(
        id: cat.id,
        data: UpdateCategoryData(
          name: _nameCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          isActive: _isActive,
          parentId: _selectedParentId,
          setParentId: parentChanged,
        ),
      ));
    } else {
      bloc.add(CreateCategoryEvent(
        CreateCategoryData(
          name: _nameCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          isActive: _isActive,
          parentId: _selectedParentId,
        ),
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outlineBorder = theme.colorScheme.outline.withValues(alpha: 0.2);

    return BlocListener<CategoriesBloc, CategoriesState>(
      listener: (context, state) {
        if (state is CategoriesLoaded && state.successMessage != null) {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        }
      },
      child: BlocBuilder<CategoriesBloc, CategoriesState>(
        builder: (context, state) {
          final isSubmitting =
              state is CategoriesLoaded && state.isSubmitting;
          final roots = state is CategoriesLoaded
              ? state.roots
                  // Exclude self when editing (cannot be parent of itself)
                  .where((r) => r.id != widget.editing?.id)
                  .toList()
              : <CategoryEntity>[];

          // Cannot set parent if the edited category already has children
          final editedHasChildren = _isEditing &&
              state is CategoriesLoaded &&
              state.childrenOf(widget.editing!.id).isNotEmpty;

          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Dialog header ─────────────────────────────────
                      Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _isEditing
                                ? Icons.edit_outlined
                                : Icons.add_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEditing
                                    ? l10n.t('editCategory')
                                    : l10n.t('newCategory'),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.t('categoriesSubtitle'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      Divider(height: 1, color: outlineBorder),
                      const SizedBox(height: 20),

                      // ── Name field ────────────────────────────────────
                      _FormField(
                        controller: _nameCtrl,
                        label: l10n.t('categoryName'),
                        hint: l10n.t('categoryNameHint'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? l10n.t('nameRequired')
                                : null,
                        enabled: !isSubmitting,
                      ),
                      const SizedBox(height: 18),

                      // ── Description field ─────────────────────────────
                      _FormField(
                        controller: _descCtrl,
                        label: l10n.t('categoryDescription'),
                        hint: l10n.t('categoryDescriptionHint'),
                        maxLines: 3,
                        enabled: !isSubmitting,
                      ),
                      const SizedBox(height: 18),

                      // ── Parent category dropdown ───────────────────────
                      if (!editedHasChildren) ...[
                        _ParentDropdown(
                          roots: roots,
                          selected: _selectedParentId,
                          isDark: isDark,
                          enabled: !isSubmitting,
                          onChanged: (v) =>
                              setState(() => _selectedParentId = v),
                        ),
                        const SizedBox(height: 18),
                      ] else ...[
                        // Show info that parent cannot be changed while it has children
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: Colors.amber.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.t('cannotChangeParentWithChildren'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // ── Active toggle ─────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF252B3B)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: outlineBorder),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l10n.t('activeLabel'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            l10n.t('visibleToPublic'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? Colors.grey.shade500
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                          value: _isActive,
                          onChanged: isSubmitting
                              ? null
                              : (v) => setState(() => _isActive = v),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Dialog actions ────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(l10n.t('cancel')),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            onPressed: isSubmitting ? null : () => _submit(roots),
                            style: FilledButton.styleFrom(
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : Text(
                                    _isEditing
                                        ? l10n.t('saveChanges')
                                        : l10n.t('create'),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Parent category dropdown ─────────────────────────────────────────────────

class _ParentDropdown extends StatelessWidget {
  const _ParentDropdown({
    required this.roots,
    required this.selected,
    required this.isDark,
    required this.enabled,
    required this.onChanged,
  });

  final List<CategoryEntity> roots;
  final String? selected;
  final bool isDark;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final outlineBorder = theme.colorScheme.outline.withValues(alpha: 0.2);
    final fillColor =
        isDark ? const Color(0xFF252B3B) : const Color(0xFFF8FAFC);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('parentCategory'),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: selected,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: theme.colorScheme.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          hint: Text(
            l10n.t('noParentCategory'),
            style: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Row(children: [
                Icon(Icons.layers_outlined,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.t('noParentCategory')),
              ]),
            ),
            ...roots.map(
              (r) => DropdownMenuItem<String?>(
                value: r.id,
                child: Row(children: [
                  Icon(Icons.folder_outlined,
                      size: 16,
                      color: isDark
                          ? Colors.grey.shade400
                          : const Color(0xFF6B7280)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
            ),
          ],
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isActive
        ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D))
        : (isDark ? Colors.grey.shade400 : const Color(0xFF6B7280));
    final bg = isActive
        ? (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7))
        : (isDark ? const Color(0xFF252B3B) : const Color(0xFFF3F4F6));
    final dot = isActive ? const Color(0xFF22C55E) : Colors.grey.shade500;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          isActive ? l10n.t('active') : l10n.t('inactive'),
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg),
        ),
      ]),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF22C55E) : Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.isDark,
    this.accent,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ??
        (isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent != null
            ? accent!.withValues(alpha: isDark ? 0.18 : 0.08)
            : (isDark ? const Color(0xFF252B3B) : const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: accent != null
                  ? accent!
                  : (isDark
                      ? Colors.grey.shade400
                      : const Color(0xFF6B7280)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _MiniActionBtn extends StatelessWidget {
  const _MiniActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _ActionToolButton extends StatefulWidget {
  const _ActionToolButton({
    required this.tooltip,
    required this.onTap,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  final String tooltip;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  @override
  State<_ActionToolButton> createState() => _ActionToolButtonState();
}

class _ActionToolButtonState extends State<_ActionToolButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final outlineBorder =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.2);
    final disabled = widget.onTap == null;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: disabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: disabled
                  ? widget.backgroundColor.withValues(alpha: 0.5)
                  : (_hovered
                      ? widget.backgroundColor.withValues(alpha: 0.92)
                      : widget.backgroundColor),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_hovered && !disabled)
                    ? widget.iconColor.withValues(alpha: 0.35)
                    : outlineBorder,
              ),
              boxShadow: (_hovered && !disabled)
                  ? [
                      BoxShadow(
                        color: widget.iconColor.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              widget.icon,
              size: 17,
              color: disabled
                  ? widget.iconColor.withValues(alpha: 0.4)
                  : widget.iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.icon,
    required this.label,
    required this.isDark,
    this.accent,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade200 : const Color(0xFF374151),
          ),
        ),
      ]),
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  const _HeaderIconButton({
    required this.isDark,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final bool isDark;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outlineBorder = theme.colorScheme.outline.withValues(alpha: 0.2);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.isDark
                  ? (_hovered
                      ? const Color(0xFF252B3B)
                      : const Color(0xFF1E293B))
                  : (_hovered
                      ? const Color(0xFFE5E7EB)
                      : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered
                    ? theme.colorScheme.primary.withValues(alpha: 0.35)
                    : outlineBorder,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              size: 20,
              color: widget.isDark
                  ? Colors.grey.shade200
                  : const Color(0xFF4B5563),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Form field ───────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor =
        isDark ? const Color(0xFF252B3B) : const Color(0xFFF8FAFC);
    final outlineBorder = theme.colorScheme.outline.withValues(alpha: 0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          enabled: enabled,
          validator: validator,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ─── Empty / Error / Loading states ──────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.t('loading'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.grey.shade500 : const Color(0xFF6B7280),
          ),
        ),
      ]),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final outlineBorder = theme.colorScheme.outline.withValues(alpha: 0.2);
    final bloc = context.read<CategoriesBloc>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: outlineBorder),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: 0.15),
                    primary.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: primary.withValues(alpha: 0.2)),
              ),
              child:
                  Icon(Icons.category_outlined, size: 40, color: primary),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.t('noCategoriesYet'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.t('createFirstCategoryHint'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: isDark
                    ? Colors.grey.shade500
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (ctx) => BlocProvider.value(
                  value: bloc,
                  child: const _CategoryFormDialog(),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.t('createFirstCategory')),
              style: FilledButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final danger =
        isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
    final outlineBorder = theme.colorScheme.outline.withValues(alpha: 0.2);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: danger.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 36, color: danger),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.t('couldNotLoadCategories'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: isDark
                    ? Colors.grey.shade500
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.t('tryAgain')),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: outlineBorder),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
