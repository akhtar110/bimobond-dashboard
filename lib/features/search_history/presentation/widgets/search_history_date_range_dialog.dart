import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

class SearchHistoryDateRangePick {
  const SearchHistoryDateRangePick.range(this.range)
      : clear = false;

  const SearchHistoryDateRangePick.clear()
      : range = null,
        clear = true;

  final DateTimeRange? range;
  final bool clear;
}

Future<SearchHistoryDateRangePick?> showSearchHistoryDateRangeDialog(
  BuildContext context, {
  DateTime? initialFrom,
  DateTime? initialTo,
}) {
  return showDialog<SearchHistoryDateRangePick>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => _SearchHistoryDateRangeDialog(
      theme: Theme.of(dialogContext),
      initialFrom: initialFrom,
      initialTo: initialTo,
    ),
  );
}

class _SearchHistoryDateRangeDialog extends StatefulWidget {
  const _SearchHistoryDateRangeDialog({
    required this.theme,
    this.initialFrom,
    this.initialTo,
  });

  final ThemeData theme;
  final DateTime? initialFrom;
  final DateTime? initialTo;

  @override
  State<_SearchHistoryDateRangeDialog> createState() =>
      _SearchHistoryDateRangeDialogState();
}

class _SearchHistoryDateRangeDialogState
    extends State<_SearchHistoryDateRangeDialog> {
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _from = widget.initialFrom;
    _to = widget.initialTo;
  }

  String _fmt(DateTime? date) {
    if (date == null) {
      return context.l10n.tOr('notSet', 'Not set');
    }
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
      if (_to != null && _to!.isBefore(_from!)) {
        _to = _from;
      }
    });
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _to ?? _from ?? DateTime.now(),
      builder: (ctx, child) => Theme(data: widget.theme, child: child!),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _to = picked;
      if (_from != null && _from!.isAfter(_to!)) {
        _from = _to;
      }
    });
  }

  void _apply() {
    if (_from == null || _to == null) {
      Navigator.pop(context);
      return;
    }

    var from = _from!;
    var to = _to!;
    if (from.isAfter(to)) {
      final swapped = from;
      from = to;
      to = swapped;
    }

    Navigator.pop(
      context,
      SearchHistoryDateRangePick.range(DateTimeRange(start: from, end: to)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.t('dateRange')),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DatePickRow(
              label: l10n.t('searchHistoryDateFrom'),
              value: _fmt(_from),
              onTap: _pickFrom,
            ),
            const SizedBox(height: 10),
            _DatePickRow(
              label: l10n.t('searchHistoryDateTo'),
              value: _fmt(_to),
              onTap: _pickTo,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.t('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const SearchHistoryDateRangePick.clear(),
          ),
          child: Text(l10n.t('clear')),
        ),
        FilledButton(
          onPressed: _apply,
          child: Text(l10n.t('apply')),
        ),
      ],
    );
  }
}

class _DatePickRow extends StatelessWidget {
  const _DatePickRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_rounded, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
