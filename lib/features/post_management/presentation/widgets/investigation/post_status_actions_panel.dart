import 'package:flutter/material.dart';

import '../../../../../core/localization/localization.dart';
import '../../../domain/utils/post_status_utils.dart';
import '../../utils/post_detail_labels.dart';
import '../../utils/post_status_confirm_dialog.dart';
import 'investigation_theme.dart';
import 'post_surface_card.dart';

/// Inline admin controls for all post statuses (PUBLISHED → ARCHIVED).
class PostStatusActionsPanel extends StatelessWidget {
  const PostStatusActionsPanel({
    super.key,
    required this.currentStatus,
    required this.isBusy,
    required this.isDark,
  });

  final String currentStatus;
  final bool isBusy;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final active = normalizePostStatus(currentStatus);

    return PostSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.flag_circle_outlined,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.t('postStatus'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isBusy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: InvestigationTheme.s8),
          Text(
            l10n.t('changePostStatus'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: InvestigationTheme.mutedText(context),
            ),
          ),
          const SizedBox(height: InvestigationTheme.s12),
          Wrap(
            spacing: InvestigationTheme.s8,
            runSpacing: InvestigationTheme.s8,
            children: kPostAdminStatuses.map((status) {
              final selected = active == status;
              final color =
                  postStatusColorFromScheme(theme.colorScheme, status);
              return _StatusActionChip(
                label: postStatusLabel(l10n, status),
                icon: postStatusIcon(status),
                color: color,
                selected: selected,
                disabled: isBusy,
                onTap: selected
                    ? null
                    : () => requestPostStatusChange(
                          context,
                          currentStatus: active,
                          newStatus: status,
                        ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatusActionChip extends StatefulWidget {
  const _StatusActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  State<_StatusActionChip> createState() => _StatusActionChipState();
}

class _StatusActionChipState extends State<_StatusActionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.disabled && widget.onTap != null;
    final bg = widget.selected
        ? widget.color.withValues(alpha: 0.14)
        : (_hovered && enabled
            ? widget.color.withValues(alpha: 0.08)
            : (widget.selected
                ? widget.color.withValues(alpha: 0.14)
                : Colors.transparent));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? widget.onTap : null,
          borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: InvestigationTheme.animMs),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
              border: Border.all(
                color: widget.selected
                    ? widget.color
                    : widget.color.withValues(alpha: _hovered && enabled ? 0.45 : 0.25),
                width: widget.selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.selected ? Icons.check_circle_rounded : widget.icon,
                  size: 14,
                  color: widget.color,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        widget.selected ? FontWeight.w800 : FontWeight.w600,
                    color: widget.color,
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
