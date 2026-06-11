import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../utils/report_detail_labels.dart';
import '../utils/reports_center_theme.dart';

/// Compact header + body for inline report details inside the reports center.
class ReportsEmbeddedPanel extends StatelessWidget {
  const ReportsEmbeddedPanel({
    super.key,
    required this.title,
    required this.onClose,
    required this.child,
    this.actions = const [],
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onClose;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SizedBox.expand(
      child: ColoredBox(
        color: scheme.surfaceContainerLowest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                boxShadow: ReportsCenterTheme.shadowSm(scheme),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 12, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        tooltip:
                            MaterialLocalizations.of(context).closeButtonLabel,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              scheme.surfaceContainerHigh.withValues(alpha: 0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: onClose,
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ReportsCenterTheme.muted(theme, scheme)
                                    .copyWith(fontSize: 12),
                              ),
                            ] else ...[
                              const SizedBox(height: 2),
                              Text(
                                ReportDetailLabels.investigationWorkspace(
                                  context.l10n,
                                ),
                                style: ReportsCenterTheme.muted(theme, scheme)
                                    .copyWith(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...actions,
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// Wraps detail content in either a full [Scaffold] or an embedded panel.
class ReportsDetailShell extends StatelessWidget {
  const ReportsDetailShell({
    super.key,
    required this.title,
    required this.body,
    this.onClose,
    this.actions = const [],
    this.backgroundColor,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final VoidCallback? onClose;
  final List<Widget> actions;
  final Color? backgroundColor;

  bool get embedded => onClose != null;

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return ReportsEmbeddedPanel(
        title: title,
        subtitle: subtitle,
        onClose: onClose!,
        actions: actions,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (subtitle != null)
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          ...actions,
          const SizedBox(width: 8),
        ],
      ),
      body: body,
    );
  }
}
