import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/posts_bloc.dart';

String postsDeleteConfirmMessage(AppLocalizations l10n) {
  final fallback = l10n.locale.languageCode == 'ar'
      ? 'هل أنت متأكد أنك تريد حذف هذه المنشورات؟'
      : 'Are you sure you want to delete these posts?';
  return l10n.tOr('postsConfirmDeleteMessage', fallback);
}

String postsStatusConfirmMessage(AppLocalizations l10n, String statusLabel) {
  final fallback = l10n.locale.languageCode == 'ar'
      ? 'هل أنت متأكد أنك تريد تغيير حالة هذه المنشورات إلى "$statusLabel"؟'
      : 'Are you sure you want to change the status of these posts to "$statusLabel"?';
  final template = l10n.tOr('postsConfirmStatusMessage', fallback);
  return template.replaceAll('{status}', statusLabel);
}

Future<bool> confirmPostAdminAction(
  BuildContext context, {
  required String title,
  required String message,
  bool destructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      final isAr = l10n.locale.languageCode == 'ar';
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.tOr('cancel', isAr ? 'إلغاء' : 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: scheme.error)
                : null,
            child: Text(l10n.tOr('confirmAction', isAr ? 'تأكيد' : 'Confirm')),
          ),
        ],
      );
    },
  );

  return result == true;
}

int selectedPostsCount(BuildContext context) {
  final state = context.read<PostsBloc>().state;
  if (state is PostsLoaded) return state.selectedCount;
  return 0;
}

bool isDestructivePostStatus(String status) {
  switch (status.toUpperCase()) {
    case 'BANNED':
    case 'HIDDEN':
    case 'ARCHIVED':
      return true;
    default:
      return false;
  }
}
