import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/search_management_entities.dart';

Future<void> showSearchManagementDetailsDialog(
  BuildContext context, {
  required Object payload,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l10n.tOr('searchMgmtDetails', 'Details')),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: _DetailsBody(payload: payload),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(context.l10n.t('close')),
        ),
      ],
    ),
  );
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.payload});
  final Object payload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (payload is SearchHistoryEntryEntity) {
      final e = payload as SearchHistoryEntryEntity;
      return _kv(context, {
        'Query': e.query,
        'Category': e.category,
        'User': e.username ?? e.userId ?? '—',
        'Created': DateFormat.yMMMd().add_Hm().format(e.createdAt.toLocal()),
      });
    }
    if (payload is SearchUserHit) {
      final u = payload as SearchUserHit;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (u.avatarUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: CachedNetworkImage(
                imageUrl: u.avatarUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.person, color: scheme.primary),
                ),
              ),
            ),
          const SizedBox(height: 12),
          _kv(context, {
            'Username': u.username,
            'Name': u.displayName,
            'Followers': '${u.followerCount}',
            'Posts': '${u.postCount}',
            'Verified': u.isVerified ? 'Yes' : 'No',
          }),
        ],
      );
    }
    if (payload is SearchSoundHit) {
      final s = payload as SearchSoundHit;
      return _kv(context, {
        'Name': s.name,
        'Author': s.author ?? '—',
        'Uses': '${s.useCount}',
        'Duration': s.duration == null ? '—' : '${s.duration}s',
      });
    }
    if (payload is SearchHashtagHit) {
      final h = payload as SearchHashtagHit;
      return _kv(context, {
        'Hashtag': '#${h.name}',
        'Views': '${h.viewCount}',
        'Posts': '${h.postCount}',
      });
    }
    if (payload is SearchPostHit) {
      final p = payload as SearchPostHit;
      return _kv(context, {
        'Post': p.id,
        'Caption': p.description ?? '—',
        'Type': p.type ?? '—',
        'Views': '${p.viewCount}',
        'Likes': '${p.likeCount}',
        'Author': p.username ?? '—',
      });
    }
    if (payload is SearchTrendEntity) {
      final t = payload as SearchTrendEntity;
      return _kv(context, {
        'Query': t.query,
        'Category': t.category ?? '—',
        'Count': '${t.count}',
        'Score': t.score?.toStringAsFixed(2) ?? '—',
        'Location': [
          if (t.city != null) t.city,
          if (t.countryCode != null) t.countryCode,
        ].whereType<String>().join(', ').ifEmpty('—'),
      });
    }
    return Text(payload.toString());
  }

  Widget _kv(BuildContext context, Map<String, String> map) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in map.entries) ...[
          Text(
            entry.key,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            entry.value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
