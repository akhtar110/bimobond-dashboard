import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../users/domain/entities/user_entity.dart';
import 'activity_filter_chips.dart';
import 'user_activity_mentions_tab.dart';

/// Filter chips for mentions made and received — same pattern as
/// [UserActivityLikesSubtabs] / [UserActivityCommentsSubtabs].
class UserActivityMentionsSubtabs extends StatefulWidget {
  const UserActivityMentionsSubtabs({
    super.key,
    required this.userId,
    required this.isDark,
    this.sourceUser,
  });

  final String userId;
  final bool isDark;
  final UserEntity? sourceUser;

  @override
  State<UserActivityMentionsSubtabs> createState() =>
      _UserActivityMentionsSubtabsState();
}

class _UserActivityMentionsSubtabsState extends State<UserActivityMentionsSubtabs> {
  String _selected = 'made';

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
              (value: 'made', label: l10n.tOr('mentionsMade', 'Mentions Made')),
              (
                value: 'received',
                label: l10n.tOr('mentionsReceived', 'Mentions Received'),
              ),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selected == 'made' ? 0 : 1,
            children: [
              UserActivityMentionsTab(
                userId: widget.userId,
                isDark: widget.isDark,
                type: 'made',
                sourceUser: widget.sourceUser,
              ),
              UserActivityMentionsTab(
                userId: widget.userId,
                isDark: widget.isDark,
                type: 'received',
                sourceUser: widget.sourceUser,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
