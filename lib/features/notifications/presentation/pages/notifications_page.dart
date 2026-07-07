import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/notifications_bloc.dart';
import '../widgets/notification_composer.dart';
import '../widgets/notification_feed_panel.dart';
import '../widgets/notification_status_banner.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('NotificationsPage rebuilt');
    return PersistentBlocProvider<NotificationsBloc>(
      debugLabel: 'NotificationsPage',
      create: () =>
          di.sl<NotificationsBloc>()..add(const ConnectAdminSocket()),
      child: const _NotificationsPageView(),
    );
  }
}

class _NotificationsPageView extends StatefulWidget {
  const _NotificationsPageView();

  @override
  State<_NotificationsPageView> createState() => _NotificationsPageViewState();
}

class _NotificationsPageViewState extends State<_NotificationsPageView> {
  @override
  void dispose() {
    context.read<NotificationsBloc>().add(const DisconnectAdminSocket());
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
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isDesktop = width >= 1200;
              final isTablet = width >= 768 && width < 1200;

              if (isDesktop) {
                return _DesktopNotificationsLayout(isDark: isDark);
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: _pagePadding(context, bottom: 0),
                      child: const _NotificationsHeader(),
                    ),
                  ),
                  SliverPadding(
                    padding: _pagePadding(context, top: 16, bottom: 16),
                    sliver: SliverToBoxAdapter(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1680),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _StatsRow(),
                              const SizedBox(height: 24),
                              const NotificationComposer(),
                              const SizedBox(height: 24),
                              NotificationFeedPanel(
                                isDark: isDark,
                                expandVertically: false,
                                minHeight: isTablet ? 640 : 520,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const NotificationStatusBanner(),
        ],
      ),
    );
  }
}

class _DesktopNotificationsLayout extends StatelessWidget {
  const _DesktopNotificationsLayout({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _pagePadding(context, top: 12, bottom: 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _NotificationsHeader(),
              const SizedBox(height: 24),
              const _StatsRow(),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(
                      width: 480,
                      child: NotificationComposer(
                        expandVertically: true,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: NotificationFeedPanel(
                        isDark: isDark,
                        expandVertically: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

EdgeInsetsDirectional _pagePadding(
  BuildContext context, {
  double top = 12,
  double bottom = 16,
}) {
  final horizontal = MediaQuery.sizeOf(context).width < 600 ? 12.0 : 24.0;
  return EdgeInsetsDirectional.fromSTEB(horizontal, top, horizontal, bottom);
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
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
    );
  }
}

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
        final broadcasts = state.activityLog
            .where((e) => !(e.scope?.contains('admin') ?? false))
            .length;
        final adminBroadcasts = state.activityLog
            .where((e) => e.scope?.contains('admin') ?? false)
            .length;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            const gap = 12.0;

            final cards = [
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
            ];

            if (width >= 900) {
              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            }

            final columns = width >= 640 ? 2 : 1;
            final itemWidth = columns == 1
                ? width
                : (width - gap) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: cards
                  .map((card) => SizedBox(width: itemWidth, child: card))
                  .toList(growable: false),
            );
          },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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
