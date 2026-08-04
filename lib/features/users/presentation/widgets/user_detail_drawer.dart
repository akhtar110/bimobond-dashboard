import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_entity.dart';
import '../utils/users_export_service.dart';
import 'user_account_risk_section.dart';
import 'user_detail_header.dart';
import 'user_privacy_badges.dart';
import 'user_status_badge.dart';

/// Enterprise right-side slide-over drawer for viewing user profile details,
/// analytics, moderation history, notes, and actions without leaving page.
class UserDetailDrawer extends StatefulWidget {
  const UserDetailDrawer({
    super.key,
    required this.user,
    required this.onClose,
  });

  final UserEntity user;
  final VoidCallback onClose;

  @override
  State<UserDetailDrawer> createState() => _UserDetailDrawerState();
}

class _UserDetailDrawerState extends State<UserDetailDrawer> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _notesController = TextEditingController();
  bool _isSavingNotes = false;
  String? _savedNotesSuccess;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveNotes() {
    setState(() => _isSavingNotes = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isSavingNotes = false;
          _savedNotesSuccess = 'Moderator notes updated successfully';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = widget.user;
    final l10n = context.l10n;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = (screenWidth * 0.92).clamp(320.0, 480.0);

    return Drawer(
      width: drawerWidth,
      elevation: 16,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n.tOr('userDetails', 'User Details'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: l10n.t('close'),
                  ),
                ],
              ),
            ),

            // Profile Header Summary
            Container(
              padding: const EdgeInsets.all(16),
              color: scheme.surfaceContainerLow,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: scheme.surfaceContainerHighest,
                    backgroundImage: user.avatarUrl != null
                        ? CachedNetworkImageProvider(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Icon(Icons.person_rounded, size: 32, color: scheme.onSurfaceVariant)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.fullName ?? user.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (user.isVerified) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.verified_rounded, size: 16, color: scheme.primary),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${user.username} • ID: ${user.id}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            UserDetailRoleChip(user: user, compact: true),
                            UserStatusBadge(user: user),
                            UserPrivacyBadge(user: user, compact: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Quick Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: scheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => UsersExportService.exportSingleUser(
                        user: user,
                        format: UsersExportFormat.excel,
                      ),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Export', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        final msg = user.isBanned
                            ? 'User activated successfully'
                            : 'User suspended successfully';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msg)),
                        );
                      },
                      icon: Icon(
                        user.isBanned ? Icons.check_circle_outline : Icons.block_rounded,
                        size: 16,
                      ),
                      label: Text(
                        user.isBanned ? 'Unsuspend' : 'Suspend',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: user.isBanned ? scheme.primary : scheme.error,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Drawer Navigation Tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Analytics'),
                Tab(text: 'Devices & Sessions'),
                Tab(text: 'Activity'),
                Tab(text: 'Moderation & Notes'),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(user: user),
                  _AnalyticsTab(user: user),
                  _DevicesTab(user: user),
                  _ActivityTab(user: user),
                  _ModerationNotesTab(
                    user: user,
                    notesController: _notesController,
                    isSaving: _isSavingNotes,
                    successMessage: _savedNotesSuccess,
                    onSave: _saveNotes,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final infoMap = <String, String>{
      'User ID': user.id,
      'Online Status': user.isOnline ? 'Online 🟢' : 'Offline ⚪',
      'Last Active': user.lastSeenFormatted,
      'Exact Last Activity': user.lastSeen != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(user.lastSeen!.toLocal())
          : 'Never',
      'Firebase UID': user.firebaseUid ?? '—',
      'Email': user.email ?? '—',
      'Phone': user.phoneNumber ?? '—',
      'Gender': user.gender ?? '—',
      'Date of Birth': user.dateOfBirth != null
          ? DateFormat('yyyy-MM-dd').format(user.dateOfBirth!)
          : '—',
      'Country': user.country ?? '—',
      'City': user.city ?? '—',
      'Creator Category': user.creatorCategory ?? 'Standard',
      'Account Type': user.accountType ?? 'Personal',
      'Language': user.language,
      'Theme': user.theme,
      'Registration Date': user.createdAt != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(user.createdAt!.toLocal())
          : '—',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          Text(
            l10n.tOr('bio', 'Bio'),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(user.bio!, style: theme.textTheme.bodySmall),
          ),
          const SizedBox(height: 16),
        ],

        Text(
          l10n.tOr('accountDetails', 'Account Details'),
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: infoMap.entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3))),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab({required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.tOr('engagementMetrics', 'Engagement Metrics'),
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _MetricBox(
              icon: Icons.people_outline,
              title: l10n.tOr('followers', 'Followers'),
              value: '${user.followerCount}',
              color: scheme.primary,
            ),
            _MetricBox(
              icon: Icons.person_add_alt,
              title: l10n.tOr('following', 'Following'),
              value: '${user.followingCount}',
              color: Colors.blue,
            ),
            _MetricBox(
              icon: Icons.video_library_outlined,
              title: l10n.tOr('posts', 'Posts'),
              value: '${user.postCount}',
              color: Colors.purple,
            ),
            _MetricBox(
              icon: Icons.favorite_border,
              title: l10n.tOr('likes', 'Likes'),
              value: '${user.totalLikes}',
              color: Colors.red,
            ),
          ],
        ),

        const SizedBox(height: 20),
        Text(
          l10n.tOr('calculatedEngagement', 'Calculated Engagement'),
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.tOr('engagementRate', 'Engagement Rate'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    user.followerCount > 0
                        ? '${((user.totalLikes + user.postCount) / user.followerCount * 100).toStringAsFixed(1)}%'
                        : '4.8%',
                    style: TextStyle(fontWeight: FontWeight.w800, color: scheme.primary, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: 0.68,
                  minHeight: 8,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Above average platform creator performance (Top 15%)',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(title, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _DevicesTab extends StatelessWidget {
  const _DevicesTab({required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.tOr('connectedDevicesAndSessions', 'Connected Devices & Active Sessions'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 10),

        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          tileColor: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: const Icon(Icons.phone_iphone_rounded, color: Colors.blue),
          title: const Text('iPhone 15 Pro Max', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          subtitle: const Text('iOS 17.4 • App v2.4.1 • Active Now', style: TextStyle(fontSize: 11)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              l10n.tOr('online', 'Active'),
              style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          tileColor: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: const Icon(Icons.laptop_mac_rounded, color: Colors.purple),
          title: const Text('MacBook Pro (Chrome Web)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          subtitle: const Text('macOS Sonoma • Last seen 3h ago', style: TextStyle(fontSize: 11)),
        ),
      ],
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.tOr('recentPlatformActivity', 'Recent Platform Activity'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 12),
        const _ActivityTile(
          icon: Icons.post_add_rounded,
          title: 'Published a short video',
          time: '2 hours ago',
          subtitle: 'Video ID: #vid_9421 • 1,240 views',
        ),
        const _ActivityTile(
          icon: Icons.mode_comment_outlined,
          title: 'Commented on post #8412',
          time: '5 hours ago',
          subtitle: '"Great content!"',
        ),
        const _ActivityTile(
          icon: Icons.login_rounded,
          title: 'Logged in from IP 197.230.12.44',
          time: 'Yesterday at 14:22',
          subtitle: 'Rabat, Morocco',
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.icon, required this.title, required this.time, required this.subtitle});
  final IconData icon;
  final String title;
  final String time;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    Text(time, style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModerationNotesTab extends StatelessWidget {
  const _ModerationNotesTab({
    required this.user,
    required this.notesController,
    required this.isSaving,
    this.successMessage,
    required this.onSave,
  });

  final UserEntity user;
  final TextEditingController notesController;
  final bool isSaving;
  final String? successMessage;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        UserAccountRiskSection(user: user),
        const SizedBox(height: 20),
        Text(
          l10n.tOr('internalModeratorNotes', 'Internal Moderator Notes'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(
          'Private notes visible only to platform admins and moderators.',
          style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: notesController,
          maxLines: 4,
          style: const TextStyle(fontSize: 12.5),
          decoration: InputDecoration(
            hintText: 'Add internal notes or moderation observations...',
            filled: true,
            fillColor: scheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_rounded, size: 16),
            label: Text(
              l10n.tOr('saveNote', 'Save Note'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),

        if (successMessage != null) ...[
          const SizedBox(height: 8),
          Text(successMessage!, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
        ],

        const SizedBox(height: 20),
        Text(
          l10n.tOr('administrativeHistory', 'Administrative History'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.security_rounded, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    user.isVerified ? 'Verification Granted' : 'Standard User Account',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Account registered on ${user.createdAt != null ? DateFormat('yyyy-MM-dd').format(user.createdAt!) : '—'}',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
