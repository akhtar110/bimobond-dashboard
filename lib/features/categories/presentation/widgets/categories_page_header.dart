import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/categories_bloc.dart';
import 'category_form_dialog.dart';

class CategoriesPageHeader extends StatelessWidget {
  const CategoriesPageHeader({
    required this.isDark,
    required this.state,
    this.compact = false,
  });

  final bool isDark;
  final CategoriesState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final loaded = state is CategoriesLoaded ? state as CategoriesLoaded : null;
    final total = loaded?.categories.length ?? 0;
    final rootCount = loaded?.roots.length ?? 0;
    final subCount = total - rootCount;
    final active = loaded?.categories.where((c) => c.isActive).length ?? 0;
    final scheme = theme.colorScheme;
    final titleColor = scheme.onSurface;
    final subtitleColor = scheme.onSurfaceVariant;
    final outlineBorder = scheme.outlineVariant;

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
                    CategoriesHeaderBadge(
                      icon: Icons.layers_outlined,
                      label: '$rootCount root',
                      isDark: isDark,
                    ),
                    if (subCount > 0)
                      CategoriesHeaderBadge(
                        icon: Icons.account_tree_outlined,
                        label: '$subCount subcategories',
                        isDark: isDark,
                        accent: theme.colorScheme.secondary,
                      ),
                    CategoriesHeaderBadge(
                      icon: Icons.check_circle_outline_rounded,
                      label: '$active ${l10n.t('active').toLowerCase()}',
                      isDark: isDark,
                      accent: theme.colorScheme.tertiary,
                    ),
                  ],
                ),
              ],
            ],
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CategoriesHeaderIconButton(
                isDark: isDark,
                icon: Icons.refresh_rounded,
                tooltip: l10n.t('refresh'),
                onTap: () =>
                    context.read<CategoriesBloc>().add(LoadCategoriesEvent()),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => showCategoryForm(context),
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
        SizedBox(height: compact ? 12 : 24),
        if (!compact) Divider(height: 1, thickness: 1, color: outlineBorder),
      ],
    );
  }
}

class CategoriesHeaderBadge extends StatelessWidget {
  const CategoriesHeaderBadge({
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
    final scheme = theme.colorScheme;
    final color = accent ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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
            color: scheme.onSurface,
          ),
        ),
      ]),
    );
  }
}

class CategoriesHeaderIconButton extends StatefulWidget {
  const CategoriesHeaderIconButton({
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
  State<CategoriesHeaderIconButton> createState() => CategoriesHeaderIconButtonState();
}

class CategoriesHeaderIconButtonState extends State<CategoriesHeaderIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final outlineBorder = scheme.outlineVariant;

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
              color: _hovered
                  ? scheme.surfaceContainerHigh
                  : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered
                    ? scheme.primary.withValues(alpha: 0.35)
                    : outlineBorder,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class CategoriesActionToolButton extends StatefulWidget {
  const CategoriesActionToolButton({
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
  State<CategoriesActionToolButton> createState() => CategoriesActionToolButtonState();
}

class CategoriesActionToolButtonState extends State<CategoriesActionToolButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final outlineBorder =
        Theme.of(context).colorScheme.outlineVariant;
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
