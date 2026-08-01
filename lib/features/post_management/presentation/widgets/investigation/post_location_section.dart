import 'package:flutter/material.dart';

import '../../../../../core/localization/localization.dart';
import '../../../domain/entities/managed_post_location_entity.dart';
import 'investigation_theme.dart';

/// Compact location block — embed inside [PostContentSection] (no own card).
class PostLocationSection extends StatelessWidget {
  const PostLocationSection({
    super.key,
    required this.location,
    this.showHeader = true,
  });

  final ManagedPostLocationEntity? location;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primaryLabel = managedPostLocationLabel(location);
    final rows = location != null
        ? managedPostLocationDetailRows(location!)
        : const <
            ({String labelKey, String fallbackLabel, String value})>[];

    if (primaryLabel == null && rows.isEmpty) {
      return Text(
        l10n.tOr(
          'postLocationNotAvailable',
          'No location attached to this post.',
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Text(
            l10n.t('location'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: InvestigationTheme.s8),
        ],
        if (primaryLabel != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 16,
                color: scheme.tertiary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  primaryLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        if (rows.isNotEmpty) ...[
          SizedBox(height: primaryLabel != null ? InvestigationTheme.s8 : 0),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumn = constraints.maxWidth >= 360;
              if (twoColumn) {
                return Wrap(
                  spacing: InvestigationTheme.s8,
                  runSpacing: InvestigationTheme.s8,
                  children: rows
                      .map(
                        (row) => _LocationFactChip(
                          label: l10n.tOr(row.labelKey, row.fallbackLabel),
                          value: row.value,
                          width: constraints.maxWidth >= 520
                              ? (constraints.maxWidth - InvestigationTheme.s8) /
                                  2
                              : constraints.maxWidth,
                        ),
                      )
                      .toList(growable: false),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows
                    .map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: InvestigationTheme.s4,
                        ),
                        child: _LocationFactInline(
                          label: l10n.tOr(row.labelKey, row.fallbackLabel),
                          value: row.value,
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _LocationFactChip extends StatelessWidget {
  const _LocationFactChip({
    required this.label,
    required this.value,
    required this.width,
  });

  final String label;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width.clamp(140, 280),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: InvestigationTheme.s8,
          vertical: InvestigationTheme.s8,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationFactInline extends StatelessWidget {
  const _LocationFactInline({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(fontSize: 12, color: scheme.onSurface, height: 1.25),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
