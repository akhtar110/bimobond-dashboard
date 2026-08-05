import 'package:flutter/material.dart';

/// Shared section chrome for grouped settings blocks.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    this.description,
    required this.child,
    this.trailing,
  });

  final String title;
  final String? description;
  final Widget child;
  final Widget? trailing;

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
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Material 3 borderless surface card used across settings and profile sections.
class SettingsSurfaceCard extends StatefulWidget {
  const SettingsSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  State<SettingsSurfaceCard> createState() => _SettingsSurfaceCardState();
}

class _SettingsSurfaceCardState extends State<SettingsSurfaceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? scheme.primary.withValues(alpha: 0.25)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: _hovered ? 0.06 : 0.02),
              blurRadius: _hovered ? 12 : 6,
              offset: Offset(0, _hovered ? 3 : 1),
            ),
          ],
        ),
        child: Padding(
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}
