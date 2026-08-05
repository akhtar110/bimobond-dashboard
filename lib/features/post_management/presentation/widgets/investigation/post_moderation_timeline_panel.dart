import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/localization.dart';
import '../../../../posts/presentation/utils/post_date_format.dart';
import '../../../../post_reports/domain/entities/post_report_entities.dart';
import '../../../domain/entities/post_moderation_entities.dart';
import '../../bloc/post_management_bloc.dart';
import '../../utils/post_detail_labels.dart';
import 'investigation_theme.dart';

class PostModerationTimelinePanel extends StatelessWidget {
  const PostModerationTimelinePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PostManagementBloc, PostManagementState>(
      buildWhen: (prev, curr) {
        if (curr is! PostManagementLoaded) return false;
        if (prev is! PostManagementLoaded) return true;
        return prev.isTimelineLoading != curr.isTimelineLoading ||
            prev.timelineError != curr.timelineError ||
            prev.timelineEntries != curr.timelineEntries ||
            prev.isTimelineLoadingMore != curr.isTimelineLoadingMore ||
            prev.timelineHasMore != curr.timelineHasMore ||
            prev.analyticsDetail != curr.analyticsDetail;
      },
      builder: (context, state) {
        if (state is! PostManagementLoaded) {
          return const SizedBox.shrink();
        }

        final entries = _mergedTimelineEntries(state);

        if (state.isTimelineLoading && entries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state.timelineError != null && entries.isEmpty) {
          return _TimelineMessage(
            message: state.timelineError!,
            actionLabel: l10n.t('retry'),
            onAction: () => context.read<PostManagementBloc>().add(
                  LoadPostModerationTimelineEvent(refresh: true),
                ),
          );
        }

        if (entries.isEmpty) {
          return _TimelineMessage(
            message: l10n.tOr(
              'noModerationTimeline',
              'No moderation actions recorded yet.',
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...entries.map(
              (entry) => _TimelineItem(entry: entry),
            ),
            if (state.timelineHasMore && state.timelineEntries.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: InvestigationTheme.s8),
                child: Center(
                  child: state.isTimelineLoadingMore
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton.icon(
                          onPressed: () => context
                              .read<PostManagementBloc>()
                              .add(LoadMorePostModerationTimelineEvent()),
                          icon: const Icon(Icons.expand_more),
                          label: Text(l10n.tOr('loadMore', 'Load more')),
                        ),
                ),
              ),
          ],
        );
      },
    );
  }

  static List<PostModerationTimelineEntry> _mergedTimelineEntries(
    PostManagementLoaded state,
  ) {
    if (state.timelineEntries.isNotEmpty) {
      return state.timelineEntries;
    }

    final summary = state.analyticsDetail?.moderationSummary;
    if (summary == null || summary.actionTimeline.isEmpty) {
      return const [];
    }

    return summary.actionTimeline.map(_fromReportLog).toList();
  }

  static PostModerationTimelineEntry _fromReportLog(
    PostReportModerationLog log,
  ) {
    final moderator = log.moderator;
    return PostModerationTimelineEntry(
      id: log.id.isNotEmpty
          ? log.id
          : '${log.status}_${log.createdAt.millisecondsSinceEpoch}',
      status: log.status,
      reason: log.reason,
      note: log.note,
      createdAt: log.createdAt,
      moderator: moderator == null
          ? null
          : PostModerationActor(
              id: moderator.id,
              username: moderator.username,
              fullName: moderator.fullName,
              avatarUrl: moderator.avatarUrl,
            ),
    );
  }
}

class _TimelineMessage extends StatelessWidget {
  const _TimelineMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: InvestigationTheme.s12),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.entry});

  final PostModerationTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final statusColor = postStatusColorFromScheme(scheme, entry.status);
    final moderator = entry.moderator;
    final dateLabel = formatPostCreatedDateTime(
      entry.createdAt,
      locale: locale,
      compact: true,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: InvestigationTheme.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 48,
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ],
          ),
          const SizedBox(width: InvestigationTheme.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        postStatusLabel(l10n, entry.status),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    Text(
                      dateLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (moderator != null) ...[
                  const SizedBox(height: InvestigationTheme.s8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: scheme.primaryContainer,
                        backgroundImage: moderator.avatarUrl != null &&
                                moderator.avatarUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(moderator.avatarUrl!)
                            : null,
                        child: moderator.avatarUrl == null ||
                                moderator.avatarUrl!.isEmpty
                            ? Text(
                                moderator.displayName.isNotEmpty
                                    ? moderator.displayName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          moderator.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (entry.reason != null && entry.reason!.isNotEmpty) ...[
                  const SizedBox(height: InvestigationTheme.s8),
                  Text(
                    _reasonLabel(l10n, entry),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(_reasonText(l10n, entry)),
                ],
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: InvestigationTheme.s8),
                  Text(
                    l10n.tOr('internalNote', 'Internal Note'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(entry.note!),
                ],
                const Divider(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _reasonLabel(AppLocalizations l10n, PostModerationTimelineEntry entry) {
  final adminAction = formatModerationTimelineAdminAction(
    l10n,
    reason: entry.reason,
    changedFields: entry.changedFields,
  );
  if (adminAction != null) {
    return l10n.tOr('adminAction', 'Admin action');
  }
  return l10n.tOr('reason', 'Reason');
}

String _reasonText(AppLocalizations l10n, PostModerationTimelineEntry entry) {
  return formatModerationTimelineAdminAction(
        l10n,
        reason: entry.reason,
        changedFields: entry.changedFields,
      ) ??
      entry.reason!;
}
