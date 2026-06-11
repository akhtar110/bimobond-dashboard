import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/report_entity.dart';
import '../bloc/reports_bloc.dart';
import '../utils/report_target_navigation.dart';

/// Moderation actions for a report card or table row.
class ReportActionBar extends StatelessWidget {
  const ReportActionBar({
    super.key,
    required this.report,
    required this.isUpdating,
    this.compact = false,
    this.dense = false,
    this.overflowMenu = false,
  });

  final ReportEntity report;
  final bool isUpdating;
  final bool compact;
  final bool dense;
  final bool overflowMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    if (isUpdating) {
      return SizedBox(
        height: dense ? 28 : 32,
        width: dense ? 28 : 32,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.primary,
            ),
          ),
        ),
      );
    }

    void dispatch(String status) {
      context.read<ReportsBloc>().add(
            UpdateReportStatusEvent(reportId: report.id, status: status),
          );
    }

    final canView = ReportTargetNavigation.canOpen(report);

    if (dense) {
      if (overflowMenu) {
        return Align(
          alignment: AlignmentDirectional.centerEnd,
          child: _ModerationActionsMenu(
            report: report,
            canView: canView,
            onView: () => ReportTargetNavigation.open(context, report),
            onStatus: dispatch,
          ),
        );
      }

      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Wrap(
          spacing: 0,
          runSpacing: 2,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (canView)
              _DenseIconAction(
                tooltip: viewLabelFor(report, l10n),
                icon: _viewIcon(report),
                color: scheme.primary,
                onPressed: () => ReportTargetNavigation.open(context, report),
              ),
            if (!report.isResolved)
              _DenseIconAction(
                tooltip: l10n.t('resolve'),
                icon: Icons.check_circle_outline_rounded,
                color: scheme.primary,
                onPressed: () => dispatch('RESOLVED'),
              ),
            if (!report.isDismissed)
              _DenseIconAction(
                tooltip: l10n.t('ignore'),
                icon: Icons.do_not_disturb_on_outlined,
                color: scheme.onSurfaceVariant,
                onPressed: () => dispatch('DISMISSED'),
              ),
            if (!report.isPending)
              _DenseIconAction(
                tooltip: l10n.t('reopen'),
                icon: Icons.undo_rounded,
                color: scheme.tertiary,
                onPressed: () => dispatch('PENDING'),
              ),
          ],
        ),
      );
    }

    final buttons = <Widget>[
      if (canView)
        FilledButton.icon(
          onPressed: () => ReportTargetNavigation.open(context, report),
          icon: Icon(_viewIcon(report), size: 14),
          label: Text(viewLabelFor(report, l10n)),
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: 8,
            ),
            minimumSize: const Size(0, 32),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      if (!report.isResolved)
        OutlinedButton.icon(
          onPressed: () => dispatch('RESOLVED'),
          icon: Icon(
            Icons.check_circle_outline_rounded,
            size: 14,
            color: scheme.primary,
          ),
          label: Text(l10n.t('resolve')),
          style: _secondaryStyle(scheme, compact),
        ),
      if (!report.isDismissed)
        OutlinedButton.icon(
          onPressed: () => dispatch('DISMISSED'),
          icon: Icon(
            Icons.do_not_disturb_outlined,
            size: 14,
            color: scheme.onSurfaceVariant,
          ),
          label: Text(l10n.t('ignore')),
          style: _secondaryStyle(scheme, compact),
        ),
      if (!report.isPending)
        OutlinedButton.icon(
          onPressed: () => dispatch('PENDING'),
          icon: Icon(Icons.undo_rounded, size: 14, color: scheme.tertiary),
          label: Text(l10n.t('reopen')),
          style: _secondaryStyle(scheme, compact),
        ),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: compact ? WrapAlignment.start : WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: buttons,
    );
  }

  ButtonStyle _secondaryStyle(ColorScheme scheme, bool compact) =>
      OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: 8,
        ),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  IconData _viewIcon(ReportEntity r) => viewIconFor(r);

  static String viewLabelFor(ReportEntity r, AppLocalizations l10n) {
    return switch (r.targetType) {
      'comment' => l10n.t('viewComment'),
      'post' => l10n.t('viewPost'),
      'user' => l10n.t('viewUser'),
      _ => l10n.t('viewPost'),
    };
  }

  static IconData viewIconFor(ReportEntity r) {
    return switch (r.targetType) {
      'comment' => Icons.chat_bubble_outline_rounded,
      'post' => Icons.video_library_outlined,
      'user' => Icons.person_outline_rounded,
      _ => Icons.video_library_outlined,
    };
  }
}

class _DenseIconAction extends StatelessWidget {
  const _DenseIconAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      iconSize: 17,
      onPressed: onPressed,
      icon: Icon(icon, color: color),
    );
  }
}

class _ModerationActionsMenu extends StatelessWidget {
  const _ModerationActionsMenu({
    required this.report,
    required this.canView,
    required this.onView,
    required this.onStatus,
  });

  final ReportEntity report;
  final bool canView;
  final VoidCallback onView;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<_ModerationMenuAction>(
      tooltip: l10n.t('actions'),
      icon: Icon(Icons.more_horiz_rounded, color: scheme.onSurfaceVariant),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      itemBuilder: (context) => [
        if (canView)
          PopupMenuItem(
            value: _ModerationMenuAction.view,
            child: _MenuRow(
              icon: Icons.open_in_new_rounded,
              label: ReportActionBar.viewLabelFor(report, l10n),
            ),
          ),
        if (!report.isResolved)
          PopupMenuItem(
            value: _ModerationMenuAction.resolve,
            child: _MenuRow(
              icon: Icons.check_circle_outline_rounded,
              label: l10n.t('resolve'),
            ),
          ),
        if (!report.isDismissed)
          PopupMenuItem(
            value: _ModerationMenuAction.dismiss,
            child: _MenuRow(
              icon: Icons.do_not_disturb_on_outlined,
              label: l10n.t('ignore'),
            ),
          ),
        if (!report.isPending)
          PopupMenuItem(
            value: _ModerationMenuAction.reopen,
            child: _MenuRow(
              icon: Icons.undo_rounded,
              label: l10n.t('reopen'),
            ),
          ),
      ],
      onSelected: (action) {
        switch (action) {
          case _ModerationMenuAction.view:
            onView();
          case _ModerationMenuAction.resolve:
            onStatus('RESOLVED');
          case _ModerationMenuAction.dismiss:
            onStatus('DISMISSED');
          case _ModerationMenuAction.reopen:
            onStatus('PENDING');
        }
      },
    );
  }
}

enum _ModerationMenuAction { view, resolve, dismiss, reopen }

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}
