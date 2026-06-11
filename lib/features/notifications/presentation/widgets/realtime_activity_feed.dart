import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/admin_notification_event_entity.dart';
import '../bloc/notifications_bloc.dart';
import '../utils/notification_labels.dart';

class RealtimeActivityFeed extends StatelessWidget {
  const RealtimeActivityFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.bolt_rounded,
                      color: scheme.onTertiaryContainer, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('notificationActivityFeedTitle'),
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        l10n.t('notificationActivityFeedSubtitle'),
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                BlocBuilder<NotificationsBloc, NotificationsState>(
                  buildWhen: (a, b) =>
                      a.socketConnected != b.socketConnected,
                  builder: (context, state) => _SocketStatusChip(
                    connected: state.socketConnected,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            BlocBuilder<NotificationsBloc, NotificationsState>(
              buildWhen: (a, b) => a.activityLog != b.activityLog,
              builder: (context, state) {
                if (state.activityLog.isEmpty) {
                  return _EmptyFeed(
                    scheme: scheme,
                    textTheme: textTheme,
                    l10n: l10n,
                  );
                }
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 480),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.activityLog.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    itemBuilder: (context, i) => _ActivityTile(
                      event: state.activityLog[i],
                      l10n: l10n,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SocketStatusChip extends StatelessWidget {
  const _SocketStatusChip({required this.connected});
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: connected
            ? Colors.green.withValues(alpha: 0.12)
            : scheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: connected
              ? Colors.green.withValues(alpha: 0.4)
              : scheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? Colors.green : scheme.error,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            connected ? l10n.t('live') : l10n.t('notificationOfflineShort'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: connected ? Colors.green.shade700 : scheme.error,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({
    required this.scheme,
    required this.textTheme,
    required this.l10n,
  });

  final ColorScheme scheme;
  final TextTheme textTheme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 48,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.t('notificationFeedEmpty'),
            style: textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('notificationFeedEmptySubtitle'),
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.event, required this.l10n});

  final AdminNotificationEventEntity event;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final scope = event.scope ?? 'unknown';
    final isAdmins = scope.toLowerCase().contains('admin');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isAdmins
                  ? scheme.primaryContainer
                  : scheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAdmins ? Icons.admin_panel_settings_rounded : Icons.campaign_rounded,
              size: 14,
              color: isAdmins
                  ? scheme.onPrimaryContainer
                  : scheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title ?? l10n.t('notificationNoTitle'),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.tArgs(
                          'notificationSentCountBadge',
                          {'count': '${event.sentCount}'},
                        ),
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (event.body != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.body!,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 11,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      notificationRelativeTime(l10n, event.receivedAt),
                      style: textTheme.labelSmall?.copyWith(
                        color:
                            scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isAdmins
                            ? scheme.primaryContainer.withValues(alpha: 0.6)
                            : scheme.tertiaryContainer
                                .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        scope,
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: isAdmins
                              ? scheme.onPrimaryContainer
                              : scheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
