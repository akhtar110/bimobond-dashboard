import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';

class GiftPublishedAtPicker extends StatelessWidget {
  const GiftPublishedAtPicker({
    required this.value,
    required this.onTap,
    this.onClear,
    this.publisherName,
  });

  final DateTime? value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  /// Admin/user name shown beside the published date when available.
  final String? publisherName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final hasValue = value != null;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat('MMM d, yyyy  HH:mm', locale);
    final publisher = publisherName?.trim();
    final hasPublisher = publisher != null && publisher.isNotEmpty;

    final borderColor = hasValue ? scheme.primary : scheme.outlineVariant;
    final bgColor = hasValue
        ? scheme.primaryContainer.withValues(alpha: 0.35)
        : scheme.surfaceContainerLow;
    final textColor =
        hasValue ? scheme.primary : scheme.onSurfaceVariant;

    final dateText = hasValue
        ? dateFmt.format(value!.toLocal())
        : l10n.t('defaultsToNow');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded, size: 18, color: textColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.t('publishedAt'),
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(text: dateText),
                        if (hasPublisher) ...[
                          TextSpan(
                            text: ' ${l10n.tOr('by', 'by')} ',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: publisher,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.close_rounded, size: 16, color: textColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
