import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../localization/localization.dart';
import '../../bloc/sidebar_bloc.dart';

class SidebarHeader extends StatelessWidget {
  const SidebarHeader({
    super.key,
    required this.collapsed,
    this.showToggle = true,
  });

  final bool collapsed;
  final bool showToggle;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SidebarLogo(size: 36, iconSize: 20),
            if (showToggle) ...[
              const SizedBox(height: 8),
              _CollapseButton(collapsed: collapsed, compact: true),
            ],
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final l10n = context.l10n;
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 8),
      child: Row(
        children: [
          const _SidebarLogo(size: 40, iconSize: 22),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('bimoBondAdmin'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    l10n.tOr('adminDashboard', 'Admin Dashboard'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showToggle) _CollapseButton(collapsed: collapsed),
        ],
      ),
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  const _SidebarLogo({required this.size, required this.iconSize});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            scheme.primary.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.admin_panel_settings_rounded,
        color: scheme.onPrimary,
        size: iconSize,
      ),
    );
  }
}

class _CollapseButton extends StatefulWidget {
  const _CollapseButton({
    required this.collapsed,
    this.compact = false,
  });

  final bool collapsed;
  final bool compact;

  @override
  State<_CollapseButton> createState() => _CollapseButtonState();
}

class _CollapseButtonState extends State<_CollapseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = widget.compact ? 28.0 : 32.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.read<SidebarBloc>().add(const ToggleSidebarEvent()),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _hovered
                ? scheme.primary.withValues(alpha: 0.12)
                : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? scheme.primary.withValues(alpha: 0.35)
                  : scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Icon(
            widget.collapsed
                ? Icons.chevron_right_rounded
                : Icons.chevron_left_rounded,
            size: widget.compact ? 16 : 18,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}
