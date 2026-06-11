import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import 'report_card_theme.dart';

/// Compact status pill for report cards (Stripe / Linear style).
class ReportStatusChip extends StatelessWidget {
  const ReportStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final style = ReportCardTheme.reportStatusStyle(
      scheme,
      status,
      l10n: l10n,
    );

    return Semantics(
      label: context.tr('reportStatusSemantic', {'status': style.label}),
      child: Tooltip(
        message: style.label,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: style.bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: style.fg.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(style.icon, size: compact ? 11 : 12, color: style.fg),
              if (!compact) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    style.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: style.fg,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
