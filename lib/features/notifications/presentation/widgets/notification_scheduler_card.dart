import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/notifications_bloc.dart';
import '../utils/notification_schedule_utils.dart';

class NotificationSchedulerCard extends StatelessWidget {
  const NotificationSchedulerCard({super.key});

  Future<void> _pickDate(BuildContext context, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !context.mounted) return;

    final updated = DateTime(
      picked.year,
      picked.month,
      picked.day,
      current.hour,
      current.minute,
    );
    context.read<NotificationsBloc>().add(NotificationScheduleUpdated(updated));
  }

  Future<void> _pickTime(BuildContext context, DateTime current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked == null || !context.mounted) return;

    final updated = DateTime(
      current.year,
      current.month,
      current.day,
      picked.hour,
      picked.minute,
    );
    context.read<NotificationsBloc>().add(NotificationScheduleUpdated(updated));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<NotificationsBloc, NotificationsState>(
      buildWhen: (previous, current) =>
          previous.isScheduled != current.isScheduled ||
          previous.scheduledDateTime != current.scheduledDateTime,
      builder: (context, state) {
        final scheduledAt =
            state.scheduledDateTime ??
            NotificationScheduleUtils.defaultScheduledDateTime();
        final validation = state.isScheduled
            ? NotificationScheduleUtils.validationMessage(
                l10n,
                state.scheduledDateTime,
              )
            : null;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.65),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.t('notificationTimingTitle'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              RadioListTile<bool>(
                value: false,
                groupValue: state.isScheduled,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(l10n.t('notificationSendNow')),
                onChanged: (value) {
                  context.read<NotificationsBloc>().add(
                    const NotificationScheduleModeChanged(false),
                  );
                },
              ),
              RadioListTile<bool>(
                value: true,
                groupValue: state.isScheduled,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(l10n.t('notificationScheduleLater')),
                onChanged: (value) {
                  context.read<NotificationsBloc>().add(
                    const NotificationScheduleModeChanged(true),
                  );
                },
              ),
              if (state.isScheduled) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(context, scheduledAt),
                        icon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                        ),
                        label: Text(
                          DateFormat.yMMMd().format(scheduledAt),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(context, scheduledAt),
                        icon: const Icon(Icons.schedule_rounded, size: 18),
                        label: Text(DateFormat.jm().format(scheduledAt)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('notificationScheduledForLabel'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NotificationScheduleUtils.formatScheduledPreview(
                          l10n,
                          scheduledAt,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NotificationScheduleUtils.timezoneLabel(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (validation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    validation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}
