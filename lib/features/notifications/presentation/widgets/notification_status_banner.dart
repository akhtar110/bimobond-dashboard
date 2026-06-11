import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/notifications_bloc.dart';

/// Displays a success or error banner that auto-dismisses.
class NotificationStatusBanner extends StatelessWidget {
  const NotificationStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationsBloc, NotificationsState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.hasSent) {
          _showBanner(context, state);
        } else if (state.hasError && state.errorMessage != null) {
          _showError(context, state.errorMessage!);
        }
      },
      child: const SizedBox.shrink(),
    );
  }

  void _showBanner(BuildContext context, NotificationsState state) {
    final l10n = context.l10n;
    final result = state.lastResult;
    final count = result?.sentCount;
    final msg = count != null
        ? l10n.tArgs('notificationSentCount', {'count': '$count'})
        : l10n.t('notificationSuccessMessage');

    ScaffoldMessenger.of(context).showSnackBar(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l10n.t('notificationDismiss'),
          textColor: Colors.white,
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );

    // Auto-reset after display
    Future.delayed(const Duration(seconds: 4), () {
      if (context.mounted) {
        context.read<NotificationsBloc>().add(const ClearNotificationStatus());
      }
    });
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}
