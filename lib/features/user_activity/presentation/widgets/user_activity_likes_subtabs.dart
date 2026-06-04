import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../users/domain/entities/user_entity.dart';
import 'activity_filter_chips.dart';
import 'user_activity_likes_tab.dart';

/// Shows a filter-chip row (matching Auctions / Gifts tab style) above a
/// [UserActivityLikesTab] that loads data via BLoC → UseCase → API.
///
/// Both "made" and "received" views are kept alive in an [IndexedStack] so
/// switching between them never discards already-loaded data.
class UserActivityLikesSubtabs extends StatefulWidget {
  const UserActivityLikesSubtabs({
    super.key,
    required this.userId,
    required this.isDark,
    this.sourceUser,
  });

  final String userId;
  final bool isDark;
  final UserEntity? sourceUser;

  @override
  State<UserActivityLikesSubtabs> createState() =>
      _UserActivityLikesSubtabsState();
}

class _UserActivityLikesSubtabsState extends State<UserActivityLikesSubtabs> {
  String _selected = 'made';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Filter chips — same pattern as Auctions / Gifts tabs ────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ActivityFilterChips(
            isDark: widget.isDark,
            selected: _selected,
            onSelected: (value) => setState(() => _selected = value),
            options: [
              (value: 'made', label: l10n.t('likesMade')),
              (value: 'received', label: l10n.t('likesReceived')),
            ],
          ),
        ),

        // ── Content — IndexedStack keeps both BLoCs alive ───────────────
        Expanded(
          child: IndexedStack(
            index: _selected == 'made' ? 0 : 1,
            children: [
              UserActivityLikesTab(
                userId: widget.userId,
                isDark: widget.isDark,
                type: 'made',
                sourceUser: widget.sourceUser,
              ),
              UserActivityLikesTab(
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
