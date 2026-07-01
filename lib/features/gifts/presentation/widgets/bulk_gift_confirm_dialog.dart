import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/gifts_bloc.dart';

String giftsDeleteConfirmMessage(AppLocalizations l10n) {
  final fallback = l10n.locale.languageCode == 'ar'
      ? 'هل أنت متأكد أنك تريد حذف هذه الهدايا؟'
      : 'Are you sure you want to delete these gifts?';
  return l10n.tOr('giftsConfirmDeleteMessage', fallback);
}

String giftsActivateConfirmMessage(AppLocalizations l10n) {
  final fallback = l10n.locale.languageCode == 'ar'
      ? 'هل أنت متأكد أنك تريد تفعيل هذه الهدايا؟'
      : 'Are you sure you want to activate these gifts?';
  return l10n.tOr('giftsConfirmActivateMessage', fallback);
}

String giftsDeactivateConfirmMessage(AppLocalizations l10n) {
  final fallback = l10n.locale.languageCode == 'ar'
      ? 'هل أنت متأكد أنك تريد إلغاء تفعيل هذه الهدايا؟'
      : 'Are you sure you want to deactivate these gifts?';
  return l10n.tOr('giftsConfirmDeactivateMessage', fallback);
}

Future<bool> confirmGiftAdminAction(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

int selectedGiftsCount(BuildContext context) {
  final state = context.read<GiftsBloc>().state;
  if (state is GiftsLoaded) return state.selectedCount;
  return 0;
}
