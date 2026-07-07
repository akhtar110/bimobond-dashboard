import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../users/domain/entities/user_entity.dart';
import 'activity_filter_chips.dart';
import 'user_activity_posts_tab.dart';
import 'user_activity_reposts_tab.dart';

/// Posts tab with two sub-views — "Posts" and "Reposts" — selected via
/// filter chips. Both sub-views are kept alive in an [IndexedStack] so
/// switching never discards already-loaded data.
class UserActivityPostsSubtabs extends StatefulWidget {
  const UserActivityPostsSubtabs({
    super.key,
    required this.userId,
    required this.isDark,
    this.sourceUser,
  });

  final String userId;
  final bool isDark;
  final UserEntity? sourceUser;

  @override
  State<UserActivityPostsSubtabs> createState() =>
      _UserActivityPostsSubtabsState();
}

class _UserActivityPostsSubtabsState
    extends State<UserActivityPostsSubtabs> {
  String _selected = 'posts';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ActivityFilterChips(
            isDark: widget.isDark,
            selected: _selected,
            onSelected: (value) => setState(() => _selected = value),
            options: [
              (value: 'posts', label: l10n.t('posts')),
              (value: 'reposts', label: l10n.t('reposts')),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selected == 'posts' ? 0 : 1,
            children: [
              UserActivityPostsTab(
                userId: widget.userId,
                isDark: widget.isDark,
                sourceUser: widget.sourceUser,
              ),
              UserActivityRepostsTab(
                userId: widget.userId,
                isDark: widget.isDark,
                sourceUser: widget.sourceUser,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
