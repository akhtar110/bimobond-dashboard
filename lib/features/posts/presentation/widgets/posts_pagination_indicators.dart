import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

class PostsLoadMoreIndicator extends StatelessWidget {
  const PostsLoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class PostsEndOfListLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final dividerColor = scheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 32, height: 1, color: dividerColor),
          const SizedBox(width: 12),
          Text(
            l10n.t('allPostsLoaded'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 32, height: 1, color: dividerColor),
        ],
      ),
    );
  }
}
