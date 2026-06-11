import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/notifications_bloc.dart';
import '../widgets/notification_composer.dart';
import '../widgets/notification_feed_panel.dart';
import '../widgets/notification_status_banner.dart';
import '../widgets/realtime_activity_feed.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<NotificationsBloc>();
    _bloc.add(const ConnectAdminSocket());
  }

  @override
  void dispose() {
    _bloc.add(const DisconnectAdminSocket());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  theme.scaffoldBackgroundColor,
                  const Color(0xFF0D1117),
                  primary.withValues(alpha: 0.04),
                ]
              : [
                  const Color(0xFFF7F9FC),
                  const Color(0xFFEEF2FF).withValues(alpha: 0.5),
                  Colors.white,
                ],
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1680),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: _pagePadding(context, bottom: 0),
                      child: const _NotificationsHeader(),
                    ),
                  ),
                  SliverPadding(
                    padding: _pagePadding(context, top: 14, bottom: 16),
                    sliver: SliverToBoxAdapter(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          // Desktop: 2-column layout
                          if (width > 1100) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(
                                  flex: 3,
                                  child: NotificationComposer(),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      const _StatsRow(),
                                      const SizedBox(height: 16),
                                      const RealtimeActivityFeed(),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                          // Tablet / small: stacked
                          return const Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StatsRow(),
                              SizedBox(height: 16),
                              NotificationComposer(),
                              SizedBox(height: 16),
                              RealtimeActivityFeed(),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  // ── Global notification feed with filters ────────────────
                  SliverPadding(
                    padding: _pagePadding(context, top: 8, bottom: 24),
                    sliver: SliverToBoxAdapter(
                      child: Builder(
                        builder: (context) {
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          return NotificationFeedPanel(isDark: isDark);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Status banner listener
          const NotificationStatusBanner(),
        ],
      ),
    );
  }
}

EdgeInsetsDirectional _pagePadding(
  BuildContext context, {
  double top = 12,
  double bottom = 16,
}) {
  final horizontal = MediaQuery.sizeOf(context).width < 600 ? 12.0 : 16.0;
  return EdgeInsetsDirectional.fromSTEB(horizontal, top, horizontal, bottom);
}

// ──────────────────────────────────────────────────────────
// Page header
// ──────────────────────────────────────────────────────────

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('notificationsPageTitle'),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.t('notificationsPageSubtitle'),
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        BlocBuilder<NotificationsBloc, NotificationsState>(
          buildWhen: (a, b) => a.socketConnected != b.socketConnected,
          builder: (context, state) => _LiveBadge(
            connected: state.socketConnected,
          ),
        ),
      ],
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.connected});
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: connected
            ? Colors.green.withValues(alpha: 0.1)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: connected
              ? Colors.green.withValues(alpha: 0.4)
              : scheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (connected)
            _PulsingDot()
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.outlineVariant,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            connected
                ? l10n.t('notificationSocketLive')
                : l10n.t('notificationSocketOffline'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: connected ? Colors.green.shade700 : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Quick stats row
// ──────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<NotificationsBloc, NotificationsState>(
      buildWhen: (a, b) => a.activityLog != b.activityLog,
      builder: (context, state) {
        final totalSent = state.activityLog.fold<int>(
          0,
          (sum, e) => sum + e.sentCount,
        );
        final broadcasts =
            state.activityLog.where((e) => !(e.scope?.contains('admin') ?? false)).length;
        final adminBroadcasts =
            state.activityLog.where((e) => e.scope?.contains('admin') ?? false).length;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatChip(
              label: l10n.t('notificationStatSentSession'),
              value: '$totalSent',
              icon: Icons.send_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            _StatChip(
              label: l10n.t('notificationStatBroadcastEvents'),
              value: '$broadcasts',
              icon: Icons.campaign_rounded,
              color: Colors.orange,
            ),
            _StatChip(
              label: l10n.t('notificationStatAdminBroadcasts'),
              value: '$adminBroadcasts',
              icon: Icons.admin_panel_settings_rounded,
              color: Colors.teal,
            ),
          ],
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
