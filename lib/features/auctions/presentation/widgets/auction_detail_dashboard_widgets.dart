import 'package:flutter/material.dart';

/// Consistent spacing scale for the auction detail dashboard.
abstract final class DashboardSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;
}

abstract final class DashboardBreakpoints {
  static const double mobile = 768;
  static const double tablet = 1200;
  static const double largeDesktop = 1600;
  static const double maxContentWidth = 1600;
}

enum DashboardLayoutTier {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

DashboardLayoutTier dashboardLayoutTier(double width) {
  if (width >= DashboardBreakpoints.largeDesktop) {
    return DashboardLayoutTier.largeDesktop;
  }
  if (width >= DashboardBreakpoints.tablet) {
    return DashboardLayoutTier.desktop;
  }
  if (width >= DashboardBreakpoints.mobile) {
    return DashboardLayoutTier.tablet;
  }
  return DashboardLayoutTier.mobile;
}

int metricGridColumns(DashboardLayoutTier tier, double availableWidth) {
  const minCardWidth = 168.0;
  final maxColumns = switch (tier) {
    DashboardLayoutTier.mobile => 1,
    DashboardLayoutTier.tablet => 2,
    DashboardLayoutTier.desktop => 2,
    DashboardLayoutTier.largeDesktop => 3,
  };

  final fitted = ((availableWidth + DashboardSpace.md) /
          (minCardWidth + DashboardSpace.md))
      .floor();

  return fitted.clamp(1, maxColumns);
}

double dashboardHorizontalPadding(DashboardLayoutTier tier) {
  return switch (tier) {
    DashboardLayoutTier.mobile => DashboardSpace.lg,
    DashboardLayoutTier.tablet => DashboardSpace.xl,
    DashboardLayoutTier.desktop => DashboardSpace.xxl,
    DashboardLayoutTier.largeDesktop => DashboardSpace.xxxl,
  };
}

class DashboardShell extends StatelessWidget {
  const DashboardShell({
    super.key,
    required this.child,
    this.scrollable = true,
    this.padding,
  });

  final Widget child;
  final bool scrollable;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tier = dashboardLayoutTier(constraints.maxWidth);
        final horizontal = dashboardHorizontalPadding(tier);
        final resolvedPadding = padding ??
            EdgeInsets.fromLTRB(
              horizontal,
              DashboardSpace.xl,
              horizontal,
              DashboardSpace.xxl,
            );

        final content = SizedBox(
          width: double.infinity,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: DashboardBreakpoints.maxContentWidth,
              ),
              child: child,
            ),
          ),
        );

        if (!scrollable) {
          return Padding(padding: resolvedPadding, child: content);
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: resolvedPadding,
                child: content,
              ),
            ),
          ],
        );
      },
    );
  }
}

class DashboardCard extends StatefulWidget {
  const DashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DashboardSpace.xl),
    this.backgroundColor,
    this.elevated = true,
    this.interactive = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final bool elevated;
  final bool interactive;

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.backgroundColor ?? scheme.surface;

    return MouseRegion(
      onEnter: widget.interactive ? (_) => setState(() => _hovered = true) : null,
      onExit: widget.interactive ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: _hovered
              ? Color.alphaBlend(
                  scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  bg,
                )
              : bg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: widget.elevated
              ? [
                  BoxShadow(
                    blurRadius: _hovered ? 32 : 24,
                    spreadRadius: -8,
                    offset: Offset(0, _hovered ? 12 : 8),
                    color: scheme.shadow.withValues(alpha: _hovered ? 0.12 : 0.08),
                  ),
                ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}

class DashboardSection extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: DashboardSpace.xs),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: DashboardSpace.lg),
        child,
      ],
    );
  }
}

class MetricCard extends StatefulWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool compact;

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(DashboardSpace.lg),
        decoration: BoxDecoration(
          color: _hovered
              ? scheme.surfaceContainerHigh
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              widget.icon,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: DashboardSpace.md),
            Text(
              widget.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
            const SizedBox(height: DashboardSpace.xs),
            Text(
              widget.value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: (widget.compact
                      ? theme.textTheme.bodyMedium
                      : theme.textTheme.titleSmall)
                  ?.copyWith(
                fontWeight: FontWeight.w700,
                color: widget.valueColor ?? scheme.onSurface,
                letterSpacing: -0.1,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.title,
    required this.displayName,
    this.username,
    this.email,
    this.avatarUrl,
    this.accent,
    this.trailing,
    this.metadata = const [],
  });

  final String title;
  final String displayName;
  final String? username;
  final String? email;
  final String? avatarUrl;
  final Color? accent;
  final Widget? trailing;
  final List<Widget> metadata;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accentColor = accent ?? scheme.primary;
    final tinted = accent != null;

    return DashboardCard(
      backgroundColor: tinted
          ? Color.alphaBlend(
              accentColor.withValues(alpha: 0.12),
              scheme.surfaceContainerLow,
            )
          : null,
      padding: const EdgeInsets.all(DashboardSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tinted ? accentColor : scheme.onSurface,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: DashboardSpace.lg),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: scheme.surfaceContainerHighest,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 28,
                        color: scheme.onSurfaceVariant,
                      )
                    : null,
              ),
              const SizedBox(width: DashboardSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (username != null) ...[
                      const SizedBox(height: DashboardSpace.xs),
                      Text(
                        '@$username',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (email != null) ...[
                      const SizedBox(height: DashboardSpace.xs),
                      Text(
                        email!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (metadata.isNotEmpty) ...[
            const SizedBox(height: DashboardSpace.lg),
            ...metadata,
          ],
        ],
      ),
    );
  }
}

class DashboardInlineMeta extends StatelessWidget {
  const DashboardInlineMeta({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.2,
    );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );

    if (compact) {
      return SizedBox(
        width: 148,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: scheme.onSurfaceVariant),
                const SizedBox(width: DashboardSpace.xs),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DashboardSpace.xs),
            Padding(
              padding: const EdgeInsets.only(left: 17),
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
            ),
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: DashboardSpace.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: DashboardSpace.xs),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class ActionPanel extends StatelessWidget {
  const ActionPanel({
    super.key,
    required this.title,
    required this.children,
    this.isLoading = false,
  });

  final String title;
  final List<Widget> children;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.all(DashboardSpace.xl),
      child: DashboardSection(
        title: title,
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: DashboardSpace.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
      ),
    );
  }
}

enum ActionPanelButtonVariant { primary, destructive }

class ActionPanelButton extends StatefulWidget {
  const ActionPanelButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.variant = ActionPanelButtonVariant.primary,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final ActionPanelButtonVariant variant;

  @override
  State<ActionPanelButton> createState() => _ActionPanelButtonState();
}

class _ActionPanelButtonState extends State<ActionPanelButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDestructive =
        widget.variant == ActionPanelButtonVariant.destructive;

    final bg = isDestructive ? scheme.error : scheme.primary;
    final fg = isDestructive ? scheme.onError : scheme.onPrimary;
    final elevation = _hovered ? 8.0 : 4.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : (_hovered ? 1.01 : 1),
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  blurRadius: elevation * 3,
                  offset: Offset(0, elevation),
                  color: bg.withValues(alpha: _hovered ? 0.45 : 0.28),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 20, color: fg),
                const SizedBox(width: DashboardSpace.sm),
                Text(
                  widget.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
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

class ActivityFeed extends StatelessWidget {
  const ActivityFeed({
    super.key,
    required this.title,
    required this.count,
    required this.children,
    this.expanded = false,
    this.emptyMessage,
  });

  final String title;
  final int count;
  final List<Widget> children;
  final bool expanded;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final body = children.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: DashboardSpace.xl),
            child: Text(
              emptyMessage ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        : ListView.separated(
            shrinkWrap: !expanded,
            physics: expanded
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: children.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: DashboardSpace.sm),
            itemBuilder: (_, index) => children[index],
          );

    final card = DashboardCard(
      padding: const EdgeInsets.all(DashboardSpace.xl),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(width: DashboardSpace.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DashboardSpace.md,
                    vertical: DashboardSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DashboardSpace.lg),
            if (expanded) Expanded(child: body) else body,
          ],
        ),
      ),
    );

    if (!expanded) {
      return SizedBox(width: double.infinity, child: card);
    }
    return SizedBox(width: double.infinity, child: card);
  }
}

class ActivityFeedItem extends StatefulWidget {
  const ActivityFeedItem({
    super.key,
    required this.avatarUrl,
    required this.primaryText,
    this.secondaryText,
    this.amount,
    this.timestamp,
    this.leading,
  });

  final String? avatarUrl;
  final String primaryText;
  final String? secondaryText;
  final String? amount;
  final String? timestamp;
  final Widget? leading;

  @override
  State<ActivityFeedItem> createState() => _ActivityFeedItemState();
}

class _ActivityFeedItemState extends State<ActivityFeedItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: DashboardSpace.md,
          vertical: DashboardSpace.md,
        ),
        decoration: BoxDecoration(
          color: _hovered
              ? scheme.surfaceContainerLow
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: scheme.surfaceContainerHighest,
              backgroundImage: widget.avatarUrl != null
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null
                  ? Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    )
                  : null,
            ),
            const SizedBox(width: DashboardSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.primaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (widget.secondaryText != null) ...[
                    const SizedBox(height: DashboardSpace.xs),
                    Row(
                      children: [
                        if (widget.leading != null) ...[
                          widget.leading!,
                          const SizedBox(width: DashboardSpace.xs),
                        ],
                        Expanded(
                          child: Text(
                            widget.secondaryText!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (widget.amount != null || widget.timestamp != null) ...[
              const SizedBox(width: DashboardSpace.sm),
              Flexible(
                fit: FlexFit.loose,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 148),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.amount != null)
                      Text(
                        widget.amount!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    if (widget.timestamp != null) ...[
                      const SizedBox(height: DashboardSpace.xs),
                      Text(
                        widget.timestamp!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            ],
          ],
        ),
      ),
    );
  }
}
