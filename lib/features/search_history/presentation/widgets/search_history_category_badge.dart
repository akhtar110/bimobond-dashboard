import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

class SearchHistoryCategoryBadge extends StatelessWidget {
  const SearchHistoryCategoryBadge({
    super.key,
    required this.category,
  });

  final String category;

  Color _accent(ColorScheme scheme) {
    return switch (category.toUpperCase()) {
      'POSTS' => scheme.primary,
      'USERS' => scheme.secondary,
      'HASHTAGS' => scheme.tertiary,
      'SOUNDS' => scheme.primary,
      'AUCTIONS' => scheme.error,
      'LIVES' => scheme.secondary,
      'CHATS' => scheme.tertiary,
      _ => scheme.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final accent = _accent(scheme);
    final label = switch (category.toUpperCase()) {
      'POSTS' => l10n.t('posts'),
      'USERS' => l10n.t('users'),
      'HASHTAGS' => l10n.tOr('hashtags', 'Hashtags'),
      'SOUNDS' => l10n.tOr('soundManagement', 'Sounds'),
      'AUCTIONS' => l10n.t('auctions'),
      'LIVES' => l10n.tOr('lives', 'Lives'),
      'CHATS' => l10n.t('chatManagement'),
      _ => category,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
