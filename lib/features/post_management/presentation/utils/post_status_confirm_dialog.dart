import 'package:flutter/material.dart';
import 'post_status_update_dialog.dart';

/// Confirms then dispatches [UpdatePostStatusEvent] with reason and note.
Future<void> requestPostStatusChange(
  BuildContext context, {
  required String currentStatus,
  required String newStatus,
}) async {
  final next = newStatus.toUpperCase();
  if (currentStatus.toUpperCase() == next) return;

  await showPostStatusUpdateDialog(
    context,
    currentStatus: currentStatus,
    initialStatus: next,
  );
}
