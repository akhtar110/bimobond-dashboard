import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/localization/localization.dart';
import '../../../../reports/domain/entities/report_entity.dart';
import '../../bloc/post_management_bloc.dart';
import '../../utils/moderation_report_detail_sheet.dart';
import 'investigation_theme.dart';
import 'post_surface_card.dart';

class PostModerationReportsSection extends StatelessWidget {
  const PostModerationReportsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostManagementBloc, PostManagementState>(
      buildWhen: (prev, curr) {
        if (curr is! PostManagementLoaded) return false;
        if (prev is! PostManagementLoaded) return true;
        return prev.isModerationReportsLoading !=
                curr.isModerationReportsLoading ||
            prev.moderationReportsError != curr.moderationReportsError ||
            prev.moderationReportsTotal != curr.moderationReportsTotal ||
            prev.moderationReports.length != curr.moderationReports.length;
      },
      builder: (context, state) {
        if (state is! PostManagementLoaded) return const SizedBox.shrink();

        final l10n = context.l10n;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        return PostSurfaceCard(
          dense: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.tOr(
                        'postModerationReportsTitle',
                        'User reports',
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _ReportsCountBadge(
                    count: state.moderationReportsTotal,
                    loading: state.isModerationReportsLoading,
                  ),
                ],
              ),
              const SizedBox(height: InvestigationTheme.s8),
              if (state.isModerationReportsLoading &&
                  state.moderationReports.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              else if (state.moderationReportsError != null)
                Text(
                  state.moderationReportsError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                )
              else if (state.moderationReportsTotal == 0)
                Text(
                  l10n.tOr(
                    'postModerationReportsEmpty',
                    'No user reports have been submitted for this post.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else ...[
                Text(
                  l10n.tOr(
                    'postModerationReportsHint',
                    'Tap a report to view full details.',
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: InvestigationTheme.s8),
                ...state.moderationReports.map(
                  (report) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ReportListTile(
                      report: report,
                      onTap: () => showModerationReportDetailSheet(
                        context,
                        report: report,
                        postManagementBloc:
                            context.read<PostManagementBloc>(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ReportsCountBadge extends StatelessWidget {
  const _ReportsCountBadge({
    required this.count,
    required this.loading,
  });

  final int count;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: count > 0
            ? scheme.errorContainer.withValues(alpha: 0.85)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: loading && count == 0
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            )
          : Text(
              '$count ${l10n.tOr('reportsCount', 'Reports')}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: count > 0
                    ? scheme.onErrorContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
    );
  }
}

class _ReportListTile extends StatelessWidget {
  const _ReportListTile({
    required this.report,
    required this.onTap,
  });

  final ReportEntity report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateText =
        DateFormat.yMMMd().add_jm().format(report.createdAt.toLocal());

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.flag_outlined,
                size: 18,
                color: _statusColor(scheme, report.status),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.status} · $dateText',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(ColorScheme scheme, String status) {
    return switch (status) {
      'PENDING' => scheme.error,
      'RESOLVED' => scheme.primary,
      'DISMISSED' => scheme.onSurfaceVariant,
      _ => scheme.tertiary,
    };
  }
}
