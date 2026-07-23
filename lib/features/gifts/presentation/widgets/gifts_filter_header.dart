import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

/// Panel header: title, reset-all, close.
class GiftsFilterHeader extends StatelessWidget {
  const GiftsFilterHeader({
    super.key,
    required this.onResetAll,
    required this.onClose,
  });

  final VoidCallback onResetAll;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      child: Row(
        children: [
          Icon(Icons.tune_rounded, size: 20, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.tOr('giftFiltersTitle', 'Filters'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          TextButton(
            onPressed: onResetAll,
            style: TextButton.styleFrom(
              foregroundColor: scheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.tOr('giftFilterResetAll', 'Reset All'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          IconButton(
            tooltip: l10n.tOr('close', 'Close'),
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
