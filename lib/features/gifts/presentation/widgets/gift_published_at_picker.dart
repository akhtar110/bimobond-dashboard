import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';

class GiftPublishedAtPicker extends StatelessWidget {
  const GiftPublishedAtPicker({
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final DateTime? value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final hasValue = value != null;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat('MMM d, yyyy  HH:mm', locale);

    final borderColor = hasValue ? scheme.primary : scheme.outlineVariant;
    final bgColor = hasValue
        ? scheme.primaryContainer.withValues(alpha: 0.35)
        : scheme.surfaceContainerLow;
    final textColor =
        hasValue ? scheme.primary : scheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  Text(
                    hasValue
                        ? dateFmt.format(value!.toLocal())
                        : l10n.t('defaultsToNow'),
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
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
