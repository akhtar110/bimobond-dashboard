import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/report_entity.dart';
import 'report_card_theme.dart';

/// Compact reporter row with avatar or initials fallback.
class ReportReporterInfo extends StatelessWidget {
  const ReportReporterInfo({
    super.key,
    required this.reporter,
  });

  final ReportActorEntity reporter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final name = reporter.displayName;
    final initials = _initials(name);

    return Semantics(
      label: '${l10n.t('reporter')}: $name',
      child: Row(
        children: [
          Text(
            '${l10n.t('reporter')}:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ReportCardTheme.mutedText(scheme),
            ),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 12,
            backgroundColor: scheme.surfaceContainerHighest,
            backgroundImage: reporter.avatarUrl?.isNotEmpty == true
                ? NetworkImage(reporter.avatarUrl!)
                : null,
            child: reporter.avatarUrl?.isNotEmpty == true
                ? null
                : Text(
                    initials,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
}
