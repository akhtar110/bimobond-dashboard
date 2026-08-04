import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart';
import '../../../reports/domain/entities/report_entity.dart';
import '../../../reports/domain/usecases/get_report_details_usecase.dart';
import '../../../reports/domain/usecases/update_report_status_usecase.dart';
import '../../../reports/presentation/widgets/report_reporter_info.dart';
import '../../../reports/presentation/widgets/report_status_chip.dart';
import '../bloc/post_management_bloc.dart';

Future<void> showModerationReportDetailSheet(
  BuildContext context, {
  required ReportEntity report,
  PostManagementBloc? postManagementBloc,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _ModerationReportDetailSheet(
      report: report,
      postManagementBloc: postManagementBloc,
    ),
  );
}

class _ModerationReportDetailSheet extends StatefulWidget {
  const _ModerationReportDetailSheet({
    required this.report,
    this.postManagementBloc,
  });

  final ReportEntity report;
  final PostManagementBloc? postManagementBloc;

  @override
  State<_ModerationReportDetailSheet> createState() =>
      _ModerationReportDetailSheetState();
}

class _ModerationReportDetailSheetState
    extends State<_ModerationReportDetailSheet> {
  ReportEntity? _detail;
  String? _error;
  bool _loading = true;
  String? _updatingStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await sl<GetReportDetails>()(widget.report.id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _detail = widget.report;
        _loading = false;
      });
    }
  }

  Future<bool> _confirmReportActionDialog(
    BuildContext context,
    String newStatus,
  ) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (title, message, confirmLabel, confirmColor) = switch (newStatus) {
      'RESOLVED' => (
          l10n.tOr('confirmResolveTitle', 'Confirm Resolve Report'),
          l10n.tOr(
            'confirmResolveMessage',
            'Are you sure you want to mark this report as resolved?',
          ),
          l10n.t('resolve'),
          scheme.primary,
        ),
      'DISMISSED' => (
          l10n.tOr('confirmIgnoreTitle', 'Confirm Ignore Report'),
          l10n.tOr(
            'confirmIgnoreMessage',
            'Are you sure you want to ignore and dismiss this report?',
          ),
          l10n.t('ignore'),
          scheme.error,
        ),
      'PENDING' => (
          l10n.tOr('confirmReopenTitle', 'Confirm Reopen Report'),
          l10n.tOr(
            'confirmReopenMessage',
            'Are you sure you want to reopen this report as pending?',
          ),
          l10n.t('reopen'),
          scheme.tertiary,
        ),
      _ => (
          'Confirm Action',
          'Are you sure you want to proceed with this report update?',
          'Confirm',
          scheme.primary,
        ),
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_updatingStatus != null) return;

    final confirmed = await _confirmReportActionDialog(context, newStatus);
    if (!confirmed || !mounted) return;

    setState(() {
      _updatingStatus = newStatus;
      _error = null;
    });

    try {
      await sl<UpdateReportStatus>()(
        id: widget.report.id,
        status: newStatus,
      );
      if (!mounted) return;

      if (widget.postManagementBloc != null) {
        widget.postManagementBloc!.add(
          LoadPostModerationReportsEvent(refresh: true),
        );
      }

      final messenger = ScaffoldMessenger.of(context);
      final l10n = context.l10n;
      final msg = switch (newStatus) {
        'RESOLVED' =>
          l10n.tOr('reportResolved', 'Report marked as resolved'),
        'DISMISSED' => l10n.tOr('reportDismissed', 'Report ignored'),
        'PENDING' => l10n.tOr('reportReopened', 'Report reopened'),
        _ => 'Report status updated',
      };
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _updatingStatus = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final report = _detail ?? widget.report;
    final dateText =
        DateFormat.yMMMd().add_jm().format(report.createdAt.toLocal());

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: _loading
            ? const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.tOr(
                              'moderationReportDetail',
                              'Report details',
                            ),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        ReportStatusChip(status: report.status),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      l10n.tOr('reason', 'Reason'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.reason,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: l10n.tOr('reportId', 'Report ID'),
                      value: report.id,
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      label: l10n.tOr('date', 'Date'),
                      value: dateText,
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      label: l10n.tOr('type', 'Type'),
                      value: report.targetType.toUpperCase(),
                    ),
                    if (report.reporter != null) ...[
                      const SizedBox(height: 12),
                      ReportReporterInfo(reporter: report.reporter!),
                    ],
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Text(
                      l10n.tOr('moderationActions', 'MODERATION ACTIONS'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (report.status != 'RESOLVED')
                          FilledButton.icon(
                            onPressed: _updatingStatus != null
                                ? null
                                : () => _updateStatus('RESOLVED'),
                            icon: _updatingStatus == 'RESOLVED'
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 16,
                                  ),
                            label: Text(l10n.t('resolve')),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (report.status != 'DISMISSED')
                          OutlinedButton.icon(
                            onPressed: _updatingStatus != null
                                ? null
                                : () => _updateStatus('DISMISSED'),
                            icon: _updatingStatus == 'DISMISSED'
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.primary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.do_not_disturb_on_outlined,
                                    size: 16,
                                  ),
                            label: Text(l10n.t('ignore')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              foregroundColor: scheme.onSurface,
                              side: BorderSide(color: scheme.outlineVariant),
                            ),
                          ),
                        if (report.status != 'PENDING')
                          OutlinedButton.icon(
                            onPressed: _updatingStatus != null
                                ? null
                                : () => _updateStatus('PENDING'),
                            icon: _updatingStatus == 'PENDING'
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.tertiary,
                                    ),
                                  )
                                : Icon(
                                    Icons.undo_rounded,
                                    size: 16,
                                    color: scheme.tertiary,
                                  ),
                            label: Text(l10n.t('reopen')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              foregroundColor: scheme.tertiary,
                              side: BorderSide(
                                color: scheme.tertiary.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                      ),
                      child: Text(l10n.t('close')),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
