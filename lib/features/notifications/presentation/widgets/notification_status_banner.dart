import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/notifications_bloc.dart';

/// Displays a success or error banner that auto-dismisses.
class NotificationStatusBanner extends StatelessWidget {
  const NotificationStatusBanner({super.key});

  static const Color _snackForeground = Colors.white;

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationsBloc, NotificationsState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.hasSent) {
          _showBanner(context, state);
        } else if (state.hasScheduled) {
          _showScheduledBanner(context);
        } else if (state.hasError && state.errorMessage != null) {
          _showError(context, state.errorMessage!);
        }
      },
      child: const SizedBox.shrink(),
    );
  }

  double _snackBarWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = (width * 0.06).clamp(16.0, 32.0);
    final maxByBreakpoint = switch (width) {
      < 400 => width - horizontalPadding * 2,
      < 720 => width * 0.72,
      < 1200 => 360.0,
      _ => 380.0,
    };
    return maxByBreakpoint.clamp(200.0, width - horizontalPadding * 2);
  }

  EdgeInsetsDirectional _snackBarMargin(BuildContext context, double barWidth) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final inset = (size.width * 0.025).clamp(10.0, 20.0);
    final bottom = (size.height * 0.012).clamp(8.0, 16.0) + padding.bottom;
    final startInset =
        (size.width - barWidth - inset).clamp(inset, size.width - inset);
    return EdgeInsetsDirectional.only(
      bottom: bottom,
      start: startInset,
      end: inset,
    );
  }

  TextStyle _snackTextStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodySmall?.copyWith(
          color: _snackForeground,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
          height: 1.3,
        ) ??
        const TextStyle(
          color: _snackForeground,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
          height: 1.3,
        );
  }

  SnackBar _cornerSnackBar({
    required BuildContext context,
    required Widget content,
    required Color backgroundColor,
    required Duration duration,
  }) {
    final barWidth = _snackBarWidth(context);
    return SnackBar(
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: barWidth),
        child: content,
      ),
      margin: _snackBarMargin(context, barWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: _snackForeground.withValues(alpha: 0.12)),
      ),
      duration: duration,
    );
  }

  Widget _snackContent({
    required IconData icon,
    required String text,
    required TextStyle textStyle,
  }) {
    return Row(
      children: [
        Icon(icon, color: _snackForeground, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: textStyle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showBanner(BuildContext context, NotificationsState state) {
    final l10n = context.l10n;
    final result = state.lastResult;
    final count = result?.sentCount;
    final msg = count != null
        ? l10n.tArgs('notificationSentCount', {'count': '$count'})
        : l10n.t('notificationSuccessMessage');

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    const displayDuration = Duration(seconds: 4);
    messenger.showSnackBar(
      _cornerSnackBar(
        context: context,
        duration: displayDuration,
        backgroundColor: Colors.green.shade700,
        content: _snackContent(
          icon: Icons.check_circle_rounded,
          text: msg,
          textStyle: _snackTextStyle(context),
        ),
      ),
    );

    Future.delayed(displayDuration, () {
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      context.read<NotificationsBloc>().add(const ClearNotificationStatus());
    });
  }

  void _showScheduledBanner(BuildContext context) {
    final l10n = context.l10n;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    const displayDuration = Duration(seconds: 4);
    messenger.showSnackBar(
      _cornerSnackBar(
        context: context,
        duration: displayDuration,
        backgroundColor: Colors.deepPurple.shade700,
        content: _snackContent(
          icon: Icons.schedule_send_rounded,
          text: l10n.t('notificationScheduledSuccess'),
          textStyle: _snackTextStyle(context),
        ),
      ),
    );

    Future.delayed(displayDuration, () {
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      context.read<NotificationsBloc>().add(const ClearNotificationStatus());
    });
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      _cornerSnackBar(
        context: context,
        duration: const Duration(seconds: 6),
        backgroundColor: Theme.of(context).colorScheme.error,
        content: _snackContent(
          icon: Icons.error_outline_rounded,
          text: message,
          textStyle: _snackTextStyle(context),
        ),
      ),
    );
  }
}
