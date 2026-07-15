import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/user_interest_entities.dart';
import 'user_interest_badges.dart';

class UserInterestsTopicsList extends StatelessWidget {
  const UserInterestsTopicsList({
    super.key,
    required this.interests,
    required this.notInterests,
  });

  final List<UserInterestEntity> interests;
  final List<UserInterestEntity> notInterests;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (interests.isEmpty && notInterests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.tOr('userInterestNoTopicsFound', 'No topics found'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: [
        if (interests.isNotEmpty) ...[
          _SectionHeader(
            title: l10n.tOr('userInterestInterestedTopics', 'Interested Topics'),
            count: interests.length,
            icon: Icons.favorite_rounded,
          ),
          const SizedBox(height: 8),
          for (final item in interests) UserInterestTopicCard(item: item),
          const SizedBox(height: 16),
        ],
        if (notInterests.isNotEmpty) ...[
          _SectionHeader(
            title: l10n.tOr(
              'userInterestNotInterestedTopics',
              'Not Interested Topics',
            ),
            count: notInterests.length,
            icon: Icons.heart_broken_rounded,
          ),
          const SizedBox(height: 8),
          for (final item in notInterests) UserInterestTopicCard(item: item),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
  });

  final String title;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class UserInterestTopicCard extends StatelessWidget {
  const UserInterestTopicCard({super.key, required this.item});

  final UserInterestEntity item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final iconUrl = MediaUrlResolver.resolve(item.category.iconUrl);
    final dateFmt = DateFormat.yMMMd().add_Hm();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;

            final meta = Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                UserInterestPreferenceBadge(
                  preference: item.preference,
                  compact: true,
                ),
                UserInterestSourceBadge(source: item.source, compact: true),
                UserInterestStatusBadge(
                  isActive: item.category.isActive,
                  compact: true,
                ),
              ],
            );

            final dates = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.tOr('createdAt', 'Created At')}: '
                  '${dateFmt.format(item.createdAt.toLocal())}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.tOr('updatedAt', 'Updated At')}: '
                  '${dateFmt.format(item.updatedAt.toLocal())}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            );

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryAvatar(iconUrl: iconUrl, name: item.category.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.category.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.category.slug,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      meta,
                      if (compact) ...[
                        const SizedBox(height: 8),
                        dates,
                      ],
                    ],
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 12),
                  dates,
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryAvatar extends StatelessWidget {
  const _CategoryAvatar({
    required this.iconUrl,
    required this.name,
  });

  final String? iconUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (iconUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: iconUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _Fallback(name: name, scheme: scheme),
        ),
      );
    }

    return _Fallback(name: name, scheme: scheme);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.name, required this.scheme});

  final String name;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: scheme.primary,
        ),
      ),
    );
  }
}
