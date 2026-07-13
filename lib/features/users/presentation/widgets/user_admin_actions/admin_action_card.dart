import 'package:flutter/material.dart';

import '../../../../../core/localization/localization.dart';
import '../../../domain/entities/user_admin_action_type.dart';
import '../../../domain/entities/user_entity.dart';
import '../../utils/user_admin_action_presentation.dart';
import '../../utils/user_detail_layout_metrics.dart';

class AdminActionCard extends StatefulWidget {
  const AdminActionCard({
    super.key,
    required this.action,
    required this.user,
    required this.metrics,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  final UserAdminActionType action;
  final UserEntity user;
  final UserDetailLayoutMetrics metrics;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback? onTap;

  @override
  State<AdminActionCard> createState() => _AdminActionCardState();
}

class _AdminActionCardState extends State<AdminActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDestructive = widget.action.isDestructive(widget.user);
    final accent = isDestructive ? scheme.error : scheme.primary;
    final label = l10n.tOr(
      widget.action.labelKey(widget.user),
      _fallbackLabel(widget.action),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hovered ? -2.0 : 0.0, 0),
        child: Material(
          color: scheme.surface,
          elevation: _hovered ? 2 : 0,
          shadowColor: scheme.shadow.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.isDisabled ? null : widget.onTap,
            borderRadius: BorderRadius.circular(16),
            hoverColor: accent.withValues(alpha: 0.06),
            splashColor: accent.withValues(alpha: 0.1),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hovered
                      ? accent.withValues(alpha: 0.35)
                      : scheme.outlineVariant.withValues(alpha: 0.65),
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: widget.metrics.actionCardMinHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(
                              widget.metrics.actionIconPadding,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: widget.isLoading
                                ? SizedBox(
                                    width: widget.metrics.actionIconSize,
                                    height: widget.metrics.actionIconSize,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: accent,
                                    ),
                                  )
                                : Icon(
                                    widget.action.icon,
                                    size: widget.metrics.actionIconSize,
                                    color: accent,
                                  ),
                          ),
                          const Spacer(),
                          if (widget.isDisabled && !widget.isLoading)
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: widget.isDisabled
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                          height: 1.2,
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
    );
  }

  String _fallbackLabel(UserAdminActionType action) {
    return switch (action) {
      UserAdminActionType.ban => 'Ban',
      UserAdminActionType.unban => 'Unban',
      UserAdminActionType.promote => 'Promote',
      UserAdminActionType.demote => 'Demote',
      UserAdminActionType.delete => 'Delete',
    };
  }
}
