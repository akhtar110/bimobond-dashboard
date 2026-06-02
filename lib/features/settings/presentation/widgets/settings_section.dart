import 'package:flutter/material.dart';

/// Shared section chrome for grouped settings blocks.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    this.description,
    required this.child,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor =
        isDark ? Colors.grey.shade500 : const Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: -0.2,
            color: titleColor,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: subtitleColor,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Material 3 surface card used across settings sections.
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outlineBorder =
        theme.colorScheme.outline.withValues(alpha: 0.2);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? theme.colorScheme.primary.withValues(alpha: 0.25)
                : outlineBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark
                    ? (_hovered ? 0.22 : 0.1)
                    : (_hovered ? 0.06 : 0.03),
              ),
              blurRadius: _hovered ? 16 : 10,
              offset: Offset(0, _hovered ? 4 : 2),
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
