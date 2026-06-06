import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/report_entity.dart';
import '../bloc/reports_bloc.dart';

/// Moderation actions for a report card.
class ReportActionBar extends StatelessWidget {
  const ReportActionBar({
    super.key,
    required this.report,
    required this.isUpdating,
    required this.onViewTarget,
    this.compact = false,
  });

  final ReportEntity report;
  final bool isUpdating;
  final VoidCallback onViewTarget;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (isUpdating) {
      return const SizedBox(
        height: 32,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    void dispatch(String status) {
      context.read<ReportsBloc>().add(
            UpdateReportStatusEvent(reportId: report.id, status: status),
          );
    }

    final hasTarget = report.reportedUserId != null ||
        report.postId != null ||
        report.commentId != null;

    final buttons = <Widget>[
      if (hasTarget)
        FilledButton.icon(
          onPressed: onViewTarget,
          icon: Icon(_viewIcon(report), size: 14),
          label: Text(_viewLabel(report)),
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
          icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
          label: Text(l10n.t('resolve')),
          style: _secondaryStyle(compact),
        ),
      if (!report.isDismissed)
        OutlinedButton.icon(
          onPressed: () => dispatch('DISMISSED'),
          icon: const Icon(Icons.do_not_disturb_outlined, size: 14),
          label: Text(l10n.t('ignore')),
          style: _secondaryStyle(compact),
        ),
      if (!report.isPending)
        OutlinedButton.icon(
          onPressed: () => dispatch('PENDING'),
          icon: const Icon(Icons.undo_rounded, size: 14),
          label: const Text('Reopen'),
          style: _secondaryStyle(compact),
        ),
    ];

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: compact ? WrapAlignment.start : WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: buttons,
      ),
    );
  }

  ButtonStyle _secondaryStyle(bool compact) => OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: 8,
        ),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  String _viewLabel(ReportEntity r) {
    if (r.reportedUserId != null) return 'View User';
    if (r.commentId != null) return 'View Comment';
    return 'View Post';
  }

  IconData _viewIcon(ReportEntity r) {
    if (r.reportedUserId != null) return Icons.person_outline_rounded;
    if (r.commentId != null) return Icons.chat_bubble_outline_rounded;
    return Icons.video_library_outlined;
  }
}
