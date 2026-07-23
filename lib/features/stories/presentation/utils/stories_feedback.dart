import 'package:flutter/material.dart';

import '../bloc/stories_state.dart';
import 'stories_admin_l10n.dart';

/// Reads action feedback from [StoriesLoaded] / [StoriesEmpty] states.
abstract final class StoriesFeedback {
  static String? message(StoriesState state) => switch (state) {
        StoriesLoaded(:final feedbackMessage) => feedbackMessage,
        StoriesEmpty(:final feedbackMessage) => feedbackMessage,
        _ => null,
      };

  static bool isError(StoriesState state) => switch (state) {
        StoriesLoaded(:final feedbackIsError) => feedbackIsError,
        StoriesEmpty(:final feedbackIsError) => feedbackIsError,
        _ => false,
      };

  static bool hasFeedback(StoriesState state) => message(state) != null;

  static String resolveMessage(BuildContext context, String raw) =>
      switch (raw) {
        'storiesUpdateSuccess' => StoriesAdminL10n.updateSuccess(context),
        'storiesDeleteSuccess' => StoriesAdminL10n.deleteSuccess(context),
        _ => raw,
      };

  static void showSnackBar(BuildContext context, StoriesState state) {
    final raw = message(state);
    if (raw == null) return;

    final scheme = Theme.of(context).colorScheme;
    final hasError = isError(state);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          resolveMessage(context, raw),
          style: TextStyle(
            color: hasError ? scheme.onErrorContainer : scheme.onInverseSurface,
          ),
        ),
        backgroundColor:
            hasError ? scheme.errorContainer : scheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
