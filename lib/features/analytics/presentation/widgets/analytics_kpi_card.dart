import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

class AnimatedCounterText extends StatelessWidget {
  const AnimatedCounterText({
    super.key,
    required this.text,
    this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 8),
          child: child,
        ),
      ),
      child: Text(text, style: style),
    );
  }
}

class AnalyticsKpiCard extends StatefulWidget {
  const AnalyticsKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color? accent;

  @override
  State<AnalyticsKpiCard> createState() => _AnalyticsKpiCardState();
}

class _AnalyticsKpiCardState extends State<AnalyticsKpiCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.accent ?? scheme.primary;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 720;
    final tight = width < 480;

    final padding = tight ? 10.0 : (compact ? 12.0 : 18.0);
    final iconBox = tight ? 28.0 : (compact ? 32.0 : 40.0);
    final iconSize = tight ? 14.0 : (compact ? 16.0 : 20.0);
    final radius = tight ? 10.0 : (compact ? 12.0 : 16.0);
    final iconRadius = tight ? 8.0 : (compact ? 10.0 : 12.0);
    final titleGap = tight ? 8.0 : (compact ? 10.0 : 14.0);
    final valueStyle = (tight
            ? Theme.of(context).textTheme.titleMedium
            : compact
                ? Theme.of(context).textTheme.titleLarge
                : Theme.of(context).textTheme.headlineSmall)
        ?.copyWith(
      fontWeight: FontWeight.w800,
      color: scheme.onSurface,
      letterSpacing: -0.5,
      height: 1.1,
    );
    final titleStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: tight ? 10.5 : (compact ? 11.5 : null),
        );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontSize: tight ? 10 : (compact ? 11 : null),
          height: 1.2,
        );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color:
                _hovered ? accent.withValues(alpha: 0.45) : scheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: _hovered ? 0.08 : 0.04),
              blurRadius: _hovered ? 18 : 12,
              offset: Offset(0, _hovered ? 6 : 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(iconRadius),
                  ),
                  child: Icon(widget.icon, size: iconSize, color: accent),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: titleStyle,
                  ),
                ),
              ],
            ),
            SizedBox(height: titleGap),
            AnimatedCounterText(
              text: widget.value,
              style: valueStyle,
            ),
            SizedBox(height: tight ? 2 : 4),
            Text(
              widget.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: subtitleStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyticsSectionCard extends StatelessWidget {
  const AnalyticsSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.error,
    this.onRetry,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
            const SizedBox(height: 16),
            if (error != null)
              AnalyticsSectionError(message: error!, onRetry: onRetry)
            else
              child,
          ],
        ),
      ),
    );
  }
}

class AnalyticsSectionError extends StatelessWidget {
  const AnalyticsSectionError({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.error),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(context.l10n.t('retry')),
            ),
          ],
        ],
      ),
    );
  }
}

class AnalyticsMiniStat extends StatelessWidget {
  const AnalyticsMiniStat({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: scheme.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
