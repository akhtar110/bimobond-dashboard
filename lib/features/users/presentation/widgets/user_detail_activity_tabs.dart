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
import '../utils/user_detail_layout_metrics.dart';
import 'user_detail_admin_actions_tab.dart';
import 'user_detail_violations_tab.dart';
import 'user_detail_interests_tab.dart';
import 'user_detail_locations_tab.dart';
import 'user_detail_search_history_tab.dart';
import 'user_detail_user_history_tab.dart';
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
    final size = MediaQuery.sizeOf(context);
    final metrics = userDetailLayoutMetrics(size.width);
    final contentHeight = metrics.activityContentHeight(size.height);

    final tabsSection = DefaultTabController(
      length: 15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(metrics.headerRadius),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: scheme.primary,
              unselectedLabelColor: scheme.onSurfaceVariant,
              indicatorColor: scheme.primary,
              indicatorWeight: 2.5,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: l10n.t('posts'), height: 40),
                Tab(text: l10n.t('comments'), height: 40),
                Tab(text: l10n.t('likes'), height: 40),
                Tab(text: l10n.t('mentions'), height: 40),
                Tab(text: l10n.t('activity'), height: 40),
                Tab(
                  text: l10n.tOr('userHistoryTab', 'User History'),
                  height: 40,
                ),
                Tab(
                  text: l10n.tOr('adminActionsTitle', 'Admin Actions'),
                  height: 40,
                ),
                Tab(
                  text: l10n.tOr('violationsHistoryTitle', 'Violations History'),
                  height: 40,
                ),
                Tab(text: l10n.t('auctions'), height: 40),
                Tab(text: l10n.t('gifts'), height: 40),
                Tab(text: l10n.t('devices'), height: 40),
                Tab(text: l10n.t('notifications'), height: 40),
                Tab(
                  text: l10n.tOr('userLocationsTab', 'Locations'),
                  height: 40,
                ),
                Tab(
                  text: l10n.tOr('searchHistoryTab', 'Search History'),
                  height: 40,
                ),
                Tab(
                  text: l10n.tOr(
                    'userInterestTopicsAndInterests',
                    'Topics & Interests',
                  ),
                  height: 40,
                ),
              ],
            ),
          ),
          SizedBox(height: metrics.sectionSpacing * 0.75),
          SizedBox(
            height: contentHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(metrics.headerRadius),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(metrics.headerRadius),
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
                    UserDetailUserHistoryTab(
                      user: user,
                      isDark: isDark,
                    ),
                    UserDetailAdminActionsTab(
                      user: user,
                      isDark: isDark,
                    ),
                    UserDetailViolationsTab(
                      user: user,
                      isDark: isDark,
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
                    UserDetailInterestsTab(user: user),
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
              SizedBox(height: metrics.sectionSpacing),
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
            SizedBox(width: metrics.sectionSpacing),
            Expanded(flex: 2, child: tabsSection),
          ],
        );
      },
    );
  }
}
