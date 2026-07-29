import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/notifications_bloc.dart';
import '../widgets/notification_composer.dart';
import '../widgets/notification_feed_panel.dart';

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
  static const _successSnackBarDuration = Duration(seconds: 3);
  static const _errorSnackBarDuration = Duration(seconds: 6);

  @override
  void dispose() {
    context.read<NotificationsBloc>().add(const DisconnectAdminSocket());
    super.dispose();
  }

  void _clearStatusAfterSnackBar(
    BuildContext context,
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller,
  ) {
    controller.closed.then((_) {
      if (!context.mounted) return;
      context.read<NotificationsBloc>().add(const ClearNotificationStatus());
    });
  }

  void _showStatusSnackBar(BuildContext context, NotificationsState state) {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    if (state.hasSent) {
      final result = state.lastResult;
      final count = result?.sentCount;
      final msg = count != null
          ? l10n.tArgs('notificationSentCount', {'count': '$count'})
          : l10n.t('notificationSuccessMessage');

      final controller = messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: _successSnackBarDuration,
        ),
      );
      _clearStatusAfterSnackBar(context, controller);
      return;
    }

    if (state.hasScheduled) {
      final controller = messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.schedule_send_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.t('notificationScheduledSuccess'))),
            ],
          ),
          backgroundColor: Colors.deepPurple.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: _successSnackBarDuration,
        ),
      );
      _clearStatusAfterSnackBar(context, controller);
      return;
    }

    if (state.hasError && state.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(state.errorMessage!)),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: _errorSnackBarDuration,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return BlocListener<NotificationsBloc, NotificationsState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: _showStatusSnackBar,
      child: Container(
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 1200;
            final isTablet = width >= 768 && width < 1200;
            final compact = width < 720;

            if (isDesktop) {
              return _DesktopNotificationsLayout(
                isDark: isDark,
                compact: compact,
              );
            }

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: _pagePadding(context, top: 8, bottom: 12),
                  sliver: SliverToBoxAdapter(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1680),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _NotificationsHeader(compact: compact),
                            SizedBox(height: compact ? 8 : 12),
                            const NotificationComposer(),
                            SizedBox(height: compact ? 12 : 16),
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
      ),
    );
  }
}

class _DesktopNotificationsLayout extends StatelessWidget {
  const _DesktopNotificationsLayout({
    required this.isDark,
    this.compact = false,
  });

  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _pagePadding(context, top: 8, bottom: 16),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NotificationsHeader(compact: compact),
              SizedBox(height: compact ? 8 : 12),
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
  double top = 8,
  double bottom = 12,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final horizontal = width < 600
      ? 10.0
      : width < 900
          ? 16.0
          : 20.0;
  return EdgeInsetsDirectional.fromSTEB(horizontal, top, horizontal, bottom);
}

/// Compact title-only top bar — no subtitle or stat cards.
class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
      child: Text(
        l10n.t('notificationsPageTitle'),
        style: (compact ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)
            ?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.45,
          color: scheme.onSurface,
          height: 1.05,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
