import 'package:flutter/material.dart';

import '../utils/reports_center_theme.dart';

/// Premium section card for report investigation detail views.
class ReportsDetailSection extends StatelessWidget {
  const ReportsDetailSection({
    super.key,
    required this.title,
    required this.child,
    this.compact = false,
    this.trailing,
    this.icon,
  });

  final String title;
  final Widget child;
  final bool compact;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: ReportsCenterTheme.detailSection(scheme),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 15, color: scheme.primary),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: ReportsCenterTheme.sectionTitle(theme),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            SizedBox(height: compact ? 10 : 12),
            child,
          ],
        ),
      ),
    );
  }
}
