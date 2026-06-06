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
    final isDark = theme.brightness == Brightness.dark;
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
                color: ReportCardTheme.cardBackground(isDark),
                borderRadius: BorderRadius.circular(ReportCardTheme.radius),
                border: Border.all(
                  color: widget.selected
                      ? theme.colorScheme.primary
                      : ReportCardTheme.cardBorder(isDark, hovered: hovered),
                  width: widget.selected ? 1.5 : 1,
                ),
                boxShadow: ReportCardTheme.cardShadow(isDark, hovered: hovered),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ReportCardTheme.radius),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PriorityStripe(status: widget.report.status),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(isDesktop ? 14 : 12),
                          child: isDesktop
                              ? _DesktopLayout(
                                  report: widget.report,
                                  isDark: isDark,
                                  theme: theme,
                                  isUpdating: widget.isUpdating,
                                  onViewTarget: widget.onTap,
                                )
                              : isTablet
                                  ? _StackedLayout(
                                      report: widget.report,
                                      isDark: isDark,
                                      theme: theme,
                                      isUpdating: widget.isUpdating,
                                      onViewTarget: widget.onTap,
                                      compact: false,
                                    )
                                  : _StackedLayout(
                                      report: widget.report,
                                      isDark: isDark,
                                      theme: theme,
                                      isUpdating: widget.isUpdating,
                                      onViewTarget: widget.onTap,
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
  const _PriorityStripe({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      color: ReportCardTheme.priorityStripe(status),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.report,
    required this.isDark,
    required this.theme,
    required this.isUpdating,
    required this.onViewTarget,
  });

  final ReportEntity report;
  final bool isDark;
  final ThemeData theme;
  final bool isUpdating;
  final VoidCallback onViewTarget;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReportInfoSection(
          report: report,
          isDark: isDark,
          theme: theme,
          showTypeIcon: true,
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: ReportTargetPreview(report: report, isDark: isDark),
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
                onViewTarget: onViewTarget,
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
    required this.isDark,
    required this.theme,
    required this.isUpdating,
    required this.onViewTarget,
    required this.compact,
  });

  final ReportEntity report;
  final bool isDark;
  final ThemeData theme;
  final bool isUpdating;
  final VoidCallback onViewTarget;
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
                isDark: isDark,
                theme: theme,
                showTypeIcon: true,
              ),
            ),
            const SizedBox(width: 8),
            ReportStatusChip(status: report.status),
          ],
        ),
        const SizedBox(height: 10),
        ReportTargetPreview(report: report, isDark: isDark),
        const SizedBox(height: 10),
        ReportActionBar(
          report: report,
          isUpdating: isUpdating,
          onViewTarget: onViewTarget,
          compact: compact,
        ),
      ],
    );
  }
}

class _ReportInfoSection extends StatelessWidget {
  const _ReportInfoSection({
    required this.report,
    required this.isDark,
    required this.theme,
    required this.showTypeIcon,
  });

  final ReportEntity report;
  final bool isDark;
  final ThemeData theme;
  final bool showTypeIcon;

  @override
  Widget build(BuildContext context) {
    final (typeIcon, typeColor) =
        ReportCardTheme.targetTypeVisual(report.targetType);
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
                  color: typeColor.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: typeColor.withValues(alpha: 0.25)),
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
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                if (report.reporter != null) ...[
                  const SizedBox(height: 6),
                  ReportReporterInfo(
                    reporter: report.reporter!,
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 4),
                Tooltip(
                  message: dateText,
                  child: Text(
                    dateText,
                    style: TextStyle(
                      fontSize: 11,
                      color: ReportCardTheme.mutedText(isDark),
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
