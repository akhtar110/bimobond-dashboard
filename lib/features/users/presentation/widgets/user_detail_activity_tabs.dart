import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../notifications/presentation/bloc/user_notifications_bloc.dart';
import '../../../user_activity/presentation/widgets/user_activity_auctions_tab.dart';
import '../../../user_activity/presentation/widgets/user_activity_comments_subtabs.dart';
import '../../../user_activity/presentation/widgets/user_activity_devices_tab.dart';
import '../../../user_activity/presentation/widgets/user_activity_gifts_tab.dart';
import '../../../user_activity/presentation/widgets/user_activity_likes_subtabs.dart';
import '../../../user_activity/presentation/widgets/user_activity_mentions_subtabs.dart';
import '../../../user_activity/presentation/widgets/user_activity_notifications_tab.dart';
import '../../../user_activity/presentation/widgets/user_activity_posts_subtabs.dart';
import '../../../user_activity/presentation/widgets/user_activity_tab.dart';
import '../../domain/entities/user_entity.dart';
import 'user_detail_locations_tab.dart';
import 'user_detail_search_history_tab.dart';
import 'user_detail_personal_info.dart';

class UserDetailInfoActivitySection extends StatelessWidget {
  const UserDetailInfoActivitySection({
    super.key,
    required this.user,
    required this.isDark,
  });

  final UserEntity user;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final tabsSection = DefaultTabController(
      length: 11,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: scheme.primary,
              unselectedLabelColor: scheme.onSurfaceVariant,
              indicatorColor: scheme.primary,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: [
                Tab(text: l10n.t('posts')),
                Tab(text: l10n.t('comments')),
                Tab(text: l10n.t('likes')),
                Tab(text: l10n.t('mentions')),
                Tab(text: l10n.t('activity')),
                Tab(text: l10n.t('auctions')),
                Tab(text: l10n.t('gifts')),
                Tab(text: l10n.t('devices')),
                Tab(text: l10n.t('notifications')),
                Tab(text: l10n.tOr('userLocationsTab', 'Locations')),
                Tab(text: l10n.tOr('searchHistoryTab', 'Search History')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 860,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: TabBarView(
                  children: [
                    UserActivityPostsSubtabs(
                      userId: user.id,
                      isDark: isDark,
                      sourceUser: user,
                    ),
                    UserActivityCommentsSubtabs(
                      userId: user.id,
                      isDark: isDark,
                      sourceUser: user,
                    ),
                    UserActivityLikesSubtabs(
                      userId: user.id,
                      isDark: isDark,
                      sourceUser: user,
                    ),
                    UserActivityMentionsSubtabs(
                      userId: user.id,
                      isDark: isDark,
                      sourceUser: user,
                    ),
                    UserActivityTab(
                      isDark: isDark,
                      sourceUser: user,
                    ),
                    UserActivityAuctionsTab(isDark: isDark),
                    UserActivityGiftsTab(isDark: isDark),
                    UserActivityDevicesTab(isDark: isDark),
                    BlocProvider(
                      create: (_) =>
                          context.read<UserNotificationsBloc>(),
                      child: UserActivityNotificationsTab(
                        userId: user.id,
                        isDark: isDark,
                        sourceUser: user,
                      ),
                    ),
                    UserDetailLocationsTab(user: user),
                    UserDetailSearchHistoryTab(user: user),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UserDetailPersonalInfo(user: user),
              const SizedBox(height: 12),
              tabsSection,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: UserDetailPersonalInfo(user: user),
            ),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: tabsSection),
          ],
        );
      },
    );
  }
}
