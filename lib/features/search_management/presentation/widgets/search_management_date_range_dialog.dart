import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';

class SearchManagementDateRangePick {
  const SearchManagementDateRangePick({
    this.range,
    this.clear = false,
  });

  final DateTimeRange? range;
  final bool clear;
}

Future<SearchManagementDateRangePick?> showSearchManagementDateRangeDialog(
  BuildContext context, {
  DateTime? initialFrom,
  DateTime? initialTo,
}) async {
  final l10n = context.l10n;
  final now = DateTime.now();
  DateTime? from = initialFrom;
  DateTime? to = initialTo;

  return showDialog<SearchManagementDateRangePick>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final fmt = DateFormat.yMMMd();
          return AlertDialog(
            title: Text(l10n.tOr('searchMgmtDateRange', 'Date range')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.tOr('searchMgmtDateFrom', 'From')),
                  subtitle: Text(from == null ? '—' : fmt.format(from!)),
                  trailing: const Icon(Icons.calendar_today_outlined, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: from ?? now,
                      firstDate: DateTime(2020),
                      lastDate: now.add(const Duration(days: 1)),
                    );
                    if (picked != null) setLocal(() => from = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.tOr('searchMgmtDateTo', 'To')),
                  subtitle: Text(to == null ? '—' : fmt.format(to!)),
                  trailing: const Icon(Icons.calendar_today_outlined, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: to ?? from ?? now,
                      firstDate: from ?? DateTime(2020),
                      lastDate: now.add(const Duration(days: 1)),
                    );
                    if (picked != null) setLocal(() => to = picked);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  ctx,
                  const SearchManagementDateRangePick(clear: true),
                ),
                child: Text(l10n.tOr('clear', 'Clear')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.t('cancel')),
              ),
              FilledButton(
                onPressed: from != null && to != null
                    ? () => Navigator.pop(
                          ctx,
                          SearchManagementDateRangePick(
                            range: DateTimeRange(start: from!, end: to!),
                          ),
                        )
                    : null,
                child: Text(l10n.tOr('apply', 'Apply')),
              ),
            ],
          );
        },
      );
    },
  );
}
