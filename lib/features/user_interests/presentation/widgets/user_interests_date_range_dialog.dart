import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

class UserInterestsDateRangePick {
  const UserInterestsDateRangePick.range(this.range) : clear = false;

  const UserInterestsDateRangePick.clear()
      : range = null,
        clear = true;

  final DateTimeRange? range;
  final bool clear;
}

Future<UserInterestsDateRangePick?> showUserInterestsDateRangeDialog(
  BuildContext context, {
  DateTime? initialFrom,
  DateTime? initialTo,
}) {
  return showDialog<UserInterestsDateRangePick>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => _UserInterestsDateRangeDialog(
      theme: Theme.of(dialogContext),
      initialFrom: initialFrom,
      initialTo: initialTo,
    ),
  );
}

class _UserInterestsDateRangeDialog extends StatefulWidget {
  const _UserInterestsDateRangeDialog({
    required this.theme,
    this.initialFrom,
    this.initialTo,
  });

  final ThemeData theme;
  final DateTime? initialFrom;
  final DateTime? initialTo;

  @override
  State<_UserInterestsDateRangeDialog> createState() =>
      _UserInterestsDateRangeDialogState();
}

class _UserInterestsDateRangeDialogState
    extends State<_UserInterestsDateRangeDialog> {
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _from = widget.initialFrom;
    _to = widget.initialTo;
  }

  String _fmt(DateTime? date) {
    if (date == null) return context.l10n.tOr('notSet', 'Not set');
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _from ?? _to ?? DateTime.now(),
      builder: (ctx, child) => Theme(data: widget.theme, child: child!),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _from = picked;
      if (_to != null && _to!.isBefore(picked)) _to = picked;
    });
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: _from ?? DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _to ?? _from ?? DateTime.now(),
      builder: (ctx, child) => Theme(data: widget.theme, child: child!),
    );
    if (picked == null || !mounted) return;
    setState(() => _to = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(l10n.tOr('dateRange', 'Date range')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.tOr('createdFrom', 'Created from')),
            subtitle: Text(_fmt(_from)),
            trailing: Icon(Icons.calendar_today_outlined, color: scheme.primary),
            onTap: _pickFrom,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.tOr('createdTo', 'Created to')),
            subtitle: Text(_fmt(_to)),
            trailing: Icon(Icons.calendar_today_outlined, color: scheme.primary),
            onTap: _pickTo,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const UserInterestsDateRangePick.clear(),
          ),
          child: Text(l10n.t('clear')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: _from == null || _to == null
              ? null
              : () => Navigator.pop(
                    context,
                    UserInterestsDateRangePick.range(
                      DateTimeRange(start: _from!, end: _to!),
                    ),
                  ),
          child: Text(l10n.t('apply')),
        ),
      ],
    );
  }
}
