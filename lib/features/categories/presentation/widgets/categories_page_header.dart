import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/categories_bloc.dart';
import 'category_form_dialog.dart';

/// Compact categories top bar — title + actions, no subtitle/stat badges.
class CategoriesPageHeader extends StatelessWidget {
  const CategoriesPageHeader({
    super.key,
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
    final scheme = theme.colorScheme;
    final controlSize = compact ? 36.0 : 40.0;

    final refreshBtn = CategoriesHeaderIconButton(
      isDark: isDark,
      icon: Icons.refresh_rounded,
      tooltip: l10n.t('refresh'),
      size: controlSize,
      onTap: () =>
          context.read<CategoriesBloc>().add(LoadCategoriesEvent()),
    );

    final addBtn = compact
        ? FilledButton(
            onPressed: () => showCategoryForm(context),
            style: FilledButton.styleFrom(
              elevation: 0,
              minimumSize: Size(controlSize, controlSize),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Icon(Icons.add_rounded, size: 18),
          )
        : FilledButton.icon(
            onPressed: () => showCategoryForm(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.t('newCategory')),
            style: FilledButton.styleFrom(
              elevation: 0,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              l10n.t('categoriesTitle'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (compact
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineSmall)
                  ?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: scheme.onSurface,
                height: 1.1,
              ),
            ),
          ),
          addBtn,
          SizedBox(width: compact ? 6 : 8),
          refreshBtn,
        ],
      ),
    );
  }
}

class CategoriesHeaderBadge extends StatelessWidget {
  const CategoriesHeaderBadge({
    super.key,
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
    super.key,
    required this.isDark,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 44,
  });

  final bool isDark;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;

  @override
  State<CategoriesHeaderIconButton> createState() =>
      CategoriesHeaderIconButtonState();
}

class CategoriesHeaderIconButtonState
    extends State<CategoriesHeaderIconButton> {
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
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _hovered
                  ? scheme.surfaceContainerHigh
                  : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered
                    ? scheme.primary.withValues(alpha: 0.35)
                    : outlineBorder,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              size: widget.size <= 36 ? 18 : 20,
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
    super.key,
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
  State<CategoriesActionToolButton> createState() =>
      CategoriesActionToolButtonState();
}

class CategoriesActionToolButtonState
    extends State<CategoriesActionToolButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final outlineBorder = Theme.of(context).colorScheme.outlineVariant;
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
