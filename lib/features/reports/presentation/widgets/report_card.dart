import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/report_entity.dart';
import 'report_action_bar.dart';
import 'report_card_theme.dart';
import 'report_reporter_info.dart';
import 'report_status_chip.dart';
import 'report_target_preview.dart';

/// Enterprise-style moderation review card for a single report.
class ReportCard extends StatefulWidget {
  const ReportCard({
    super.key,
    required this.report,
    required this.isUpdating,
    required this.onTap,
    this.selected = false,
  });

  final ReportEntity report;
  final bool isUpdating;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= ReportCardTheme.desktopBreakpoint;
    final isTablet = screenWidth >= ReportCardTheme.tabletBreakpoint &&
        screenWidth < ReportCardTheme.desktopBreakpoint;
    final hovered = _hovered && !widget.isUpdating;

    return AnimatedOpacity(
      opacity: widget.isUpdating ? 0.65 : 1,
      duration: ReportCardTheme.animDuration,
      child: Semantics(
        button: true,
        label: 'Report: ${widget.report.reason}',
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: widget.isUpdating
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.isUpdating ? null : widget.onTap,
            child: AnimatedContainer(
              duration: ReportCardTheme.animDuration,
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: ReportCardTheme.cardBackground(scheme),
                borderRadius: BorderRadius.circular(ReportCardTheme.radius),
                border: Border.all(
                  color: widget.selected
                      ? scheme.primary
                      : ReportCardTheme.cardBorder(scheme, hovered: hovered),
                  width: widget.selected ? 1.5 : 1,
                ),
                boxShadow: ReportCardTheme.cardShadow(scheme, hovered: hovered),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ReportCardTheme.radius),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PriorityStripe(
                        status: widget.report.status,
                        scheme: scheme,
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(isDesktop ? 14 : 12),
                          child: isDesktop
                              ? _DesktopLayout(
                                  report: widget.report,
                                  theme: theme,
                                  isUpdating: widget.isUpdating,
                                )
                              : isTablet
                                  ? _StackedLayout(
                                      report: widget.report,
                                      theme: theme,
                                      isUpdating: widget.isUpdating,
                                      compact: false,
                                    )
                                  : _StackedLayout(
                                      report: widget.report,
                                      theme: theme,
                                      isUpdating: widget.isUpdating,
                                      compact: true,
                                    ),
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
}

class _PriorityStripe extends StatelessWidget {
  const _PriorityStripe({
    required this.status,
    required this.scheme,
  });
  final String status;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      color: ReportCardTheme.priorityStripe(scheme, status),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.report,
    required this.theme,
    required this.isUpdating,
  });

  final ReportEntity report;
  final ThemeData theme;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReportInfoSection(
          report: report,
          theme: theme,
          showTypeIcon: true,
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: ReportTargetPreview(report: report),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ReportStatusChip(status: report.status),
              const SizedBox(height: 10),
              ReportActionBar(
                report: report,
                isUpdating: isUpdating,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StackedLayout extends StatelessWidget {
  const _StackedLayout({
    required this.report,
    required this.theme,
    required this.isUpdating,
    required this.compact,
  });

  final ReportEntity report;
  final ThemeData theme;
  final bool isUpdating;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ReportInfoSection(
                report: report,
                theme: theme,
                showTypeIcon: true,
              ),
            ),
            const SizedBox(width: 8),
            ReportStatusChip(status: report.status),
          ],
        ),
        const SizedBox(height: 10),
        ReportTargetPreview(report: report),
        const SizedBox(height: 10),
        ReportActionBar(
          report: report,
          isUpdating: isUpdating,
          compact: compact,
        ),
      ],
    );
  }
}

class _ReportInfoSection extends StatelessWidget {
  const _ReportInfoSection({
    required this.report,
    required this.theme,
    required this.showTypeIcon,
  });

  final ReportEntity report;
  final ThemeData theme;
  final bool showTypeIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final (typeIcon, typeColor) =
        ReportCardTheme.targetTypeVisual(scheme, report.targetType);
    final dateText =
        DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt);

    return SizedBox(
      width: showTypeIcon ? 260 : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTypeIcon) ...[
            Tooltip(
              message: report.targetType,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: typeColor.withValues(alpha: 0.28)),
                ),
                child: Icon(typeIcon, size: 18, color: typeColor),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: scheme.onSurface,
                  ),
                ),
                if (report.reporter != null) ...[
                  const SizedBox(height: 6),
                  ReportReporterInfo(reporter: report.reporter!),
                ],
                const SizedBox(height: 4),
                Tooltip(
                  message: dateText,
                  child: Text(
                    dateText,
                    style: TextStyle(
                      fontSize: 11,
                      color: ReportCardTheme.mutedText(scheme),
                    ),
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
