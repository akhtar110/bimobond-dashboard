import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/localization.dart';
import '../../../user_activity/presentation/widgets/user_activity_auctions_tab.dart';
import '../../../user_activity/presentation/widgets/user_activity_comments_tab.dart';
import '../../../user_activity/presentation/widgets/user_activity_devices_tab.dart';
import '../../../user_activity/presentation/widgets/user_activity_gifts_tab.dart';
import '../../../user_activity/presentation/widgets/user_activity_likes_tab.dart';
import '../../../user_activity/presentation/widgets/user_activity_mentions_tab.dart';
import '../../../user_activity/presentation/widgets/user_activity_posts_tab.dart';
import '../../../user_activity/presentation/widgets/user_activity_tab.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/user_detail_bloc.dart';
import '../bloc/users_bloc.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.user});

  final UserEntity user;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.t('userDetails'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<UserDetailBloc, UserDetailState>(
        builder: (context, state) {
          if (state is UserDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UserDetailError) {
            return Center(child: Text(state.message));
          }

          if (state is UserDetailLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, state.userDetail.user, isDark),
                  const SizedBox(height: 32),
                  _buildStatsGrid(context, state.userDetail.user, isDark),
                  const SizedBox(height: 32),
                  _buildInfoAndActivityTabs(
                    context,
                    state.userDetail.user,
                    isDark,
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserEntity user, bool isDark) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        final avatar = Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primary, primary.withValues(alpha: 0.5)],
                ),
              ),
              child: CircleAvatar(
                radius: isCompact ? 40 : 60,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: user.avatarUrl != null
                    ? CachedNetworkImageProvider(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Icon(
                        Icons.person,
                        size: isCompact ? 40 : 60,
                        color: Colors.grey,
                      )
                    : null,
              ),
            ),
            if (user.isVerified)
              Positioned(
                bottom: isCompact ? 2 : 4,
                right: isCompact ? 2 : 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: isCompact ? 12 : 16,
                  ),
                ),
              ),
          ],
        );

        final content = Expanded(
          flex: isCompact ? 0 : 1,
          child: Column(
            crossAxisAlignment: isCompact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: isCompact
                    ? WrapAlignment.center
                    : WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    user.fullName ?? user.username,
                    style:
                        (isCompact
                                ? theme.textTheme.headlineSmall
                                : theme.textTheme.displaySmall)
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                  ),
                  _buildRoleChip(user, isDark),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '@${user.username}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              if (user.bio != null)
                Text(
                  user.bio!,
                  textAlign: isCompact ? TextAlign.center : TextAlign.start,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? Colors.grey.shade300
                        : const Color(0xFF475569),
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: isCompact
                    ? WrapAlignment.center
                    : WrapAlignment.start,
                children: [
                  _buildActionBtn(
                    context,
                    user.isBanned
                        ? context.l10n.t('unban')
                        : context.l10n.t('ban'),
                    user.isBanned ? Colors.green : Colors.red,
                    () => context.read<UsersBloc>().add(
                      ToggleBanUserEvent(user.id),
                    ),
                  ),
                  _buildActionBtn(
                    context,
                    user.roles.contains(UserRole.admin)
                        ? context.l10n.t('demote')
                        : context.l10n.t('promote'),
                    theme.colorScheme.primary,
                    () => user.roles.contains(UserRole.admin)
                        ? context.read<UsersBloc>().add(
                            DemoteUserEvent(user.id),
                          )
                        : context.read<UsersBloc>().add(
                            PromoteUserEvent(user.id),
                          ),
                  ),
                ],
              ),
            ],
          ),
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isCompact
              ? Column(children: [avatar, const SizedBox(height: 24), content])
              : Row(children: [avatar, const SizedBox(width: 32), content]),
        );
      },
    );
  }

  Widget _buildRoleChip(UserEntity user, bool isDark) {
    final l10n = context.l10n;
    final isAdmin = user.roles.contains(UserRole.admin);
    final isMod = user.roles.contains(UserRole.moderator);
    final color = isAdmin
        ? Colors.amber
        : (isMod ? Colors.purple : Colors.blue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isAdmin
            ? l10n.t('roleBadgeAdmin')
            : (isMod ? l10n.t('roleBadgeModerator') : l10n.t('roleBadgeUser')),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActionBtn(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStatsGrid(BuildContext context, UserEntity user, bool isDark) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 1000) {
          crossAxisCount = 2;
        }

        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: crossAxisCount == 1 ? 4.0 : 2.5,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              context,
              l10n.t('followers'),
              user.followerCount.toString(),
              Icons.people_alt_rounded,
              Colors.blue,
              isDark,
            ),
            _buildStatCard(
              context,
              l10n.t('following'),
              user.followingCount.toString(),
              Icons.person_add_alt_1_rounded,
              Colors.purple,
              isDark,
            ),
            _buildStatCard(
              context,
              l10n.t('posts'),
              user.postCount.toString(),
              Icons.video_collection_rounded,
              Colors.orange,
              isDark,
            ),
            _buildStatCard(
              context,
              l10n.t('totalLikes'),
              user.totalLikes.toString(),
              Icons.favorite_rounded,
              Colors.pink,
              isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoAndActivityTabs(
    BuildContext context,
    UserEntity user,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final tabsSection = DefaultTabController(
      length: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor:
                  isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              indicatorColor: theme.colorScheme.primary,
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 900,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: TabBarView(
                  children: [
                    UserActivityPostsTab(
                      userId: user.id,
                      isDark: isDark,
                    ),
                    UserActivityCommentsTab(isDark: isDark),
                    UserActivityLikesTab(isDark: isDark),
                    UserActivityMentionsTab(isDark: isDark),
                    UserActivityTab(isDark: isDark),
                    UserActivityAuctionsTab(isDark: isDark),
                    UserActivityGiftsTab(isDark: isDark),
                    UserActivityDevicesTab(isDark: isDark),
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
              _buildPersonalInfo(context, user, isDark),
              const SizedBox(height: 32),
              tabsSection,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: _buildPersonalInfo(context, user, isDark),
            ),
            const SizedBox(width: 32),
            Expanded(flex: 2, child: tabsSection),
          ],
        );
      },
    );
  }

  Widget _buildPersonalInfo(
    BuildContext context,
    UserEntity user,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('accountInformation'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoItem(
            context,
            l10n.t('emailAddress'),
            user.email ?? l10n.t('notProvided'),
            Icons.email_outlined,
            isDark,
          ),
          _buildInfoItem(
            context,
            l10n.t('phoneNumber'),
            user.phoneNumber ?? l10n.t('notProvided'),
            Icons.phone_outlined,
            isDark,
          ),
          _buildInfoItem(
            context,
            l10n.t('firebaseUid'),
            user.firebaseUid ?? l10n.t('notAvailable'),
            Icons.fingerprint,
            isDark,
          ),
          _buildInfoItem(
            context,
            l10n.t('joinedOn'),
            user.createdAt != null
                ? dateFormat.format(user.createdAt!)
                : l10n.t('notAvailable'),
            Icons.calendar_today_outlined,
            isDark,
          ),

          const Divider(height: 48),
          _buildSectionTitle(context, l10n.t('personalDetails'), isDark),
          const SizedBox(height: 20),
          _buildInfoItem(
            context,
            l10n.t('gender'),
            user.gender ?? l10n.t('notSpecified'),
            Icons.person_outline,
            isDark,
          ),
          _buildInfoItem(
            context,
            l10n.t('birthday'),
            user.dateOfBirth != null
                ? dateFormat.format(user.dateOfBirth!)
                : l10n.t('notSpecified'),
            Icons.cake_outlined,
            isDark,
          ),
          _buildInfoItem(
            context,
            l10n.t('location'),
            _formatLocation(context, user),
            Icons.location_on_outlined,
            isDark,
          ),

          const Divider(height: 48),
          _buildSectionTitle(context, l10n.t('socialProfiles'), isDark),
          const SizedBox(height: 20),
          _buildInfoItem(
            context,
            l10n.t('instagram'),
            user.instagramUrl ?? l10n.t('notLinked'),
            Icons.camera_alt_outlined,
            isDark,
          ),
          _buildInfoItem(
            context,
            l10n.t('youtube'),
            user.youtubeUrl ?? l10n.t('notLinked'),
            Icons.play_circle_outline,
            isDark,
          ),

          const Divider(height: 48),
          _buildSectionTitle(context, l10n.t('privacyAndSettings'), isDark),
          const SizedBox(height: 20),
          _buildInfoItem(
            context,
            l10n.t('accountPrivacy'),
            user.isPrivate ? l10n.t('private') : l10n.t('public'),
            Icons.lock_outline,
            isDark,
          ),
          _buildInfoItem(
            context,
            l10n.t('allowCommentsLabel'),
            user.allowComments ? l10n.t('yes') : l10n.t('no'),
            Icons.comment_outlined,
            isDark,
          ),
          _buildInfoItem(
            context,
            l10n.t('directMessages'),
            user.allowDirectMsgs
                ? l10n.t('everyone')
                : l10n.t('followers'),
            Icons.message_outlined,
            isDark,
          ),
          _buildInfoItem(
            context,
            l10n.t('language'),
            user.language.toUpperCase(),
            Icons.language_outlined,
            isDark,
          ),

          if (user.isBanned) ...[
            const Divider(height: 48),
            _buildSectionTitle(
              context,
              l10n.t('moderationStatus'),
              isDark,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            _buildInfoItem(
              context,
              l10n.t('banStatus'),
              l10n.t('banned'),
              Icons.gavel_rounded,
              isDark,
              valueColor: Colors.red,
            ),
            _buildInfoItem(
              context,
              l10n.t('banReason'),
              user.banReason ?? l10n.t('noReasonProvided'),
              Icons.info_outline,
              isDark,
            ),
            _buildInfoItem(
              context,
              l10n.t('bannedUntil'),
              user.bannedUntil != null
                  ? dateFormat.format(user.bannedUntil!)
                  : l10n.t('permanent'),
              Icons.timer_off_outlined,
              isDark,
            ),
          ],
        ],
      ),
    );
  }

  String _formatLocation(BuildContext context, UserEntity user) {
    final parts = [
      user.city,
      user.region,
      user.country,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.isEmpty
        ? context.l10n.t('notProvided')
        : parts.join(', ');
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    bool isDark, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: color ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    bool isDark, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        valueColor ??
                        (isDark ? Colors.white : const Color(0xFF1E293B)),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
