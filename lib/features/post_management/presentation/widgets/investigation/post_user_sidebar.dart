import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/localization/localization.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../injection_container.dart';
import '../../../../users/domain/entities/user_entity.dart';
import '../../../../users/presentation/bloc/users_bloc.dart';
import 'post_surface_card.dart';

/// Sticky left column: activity user profile + quick moderation actions.
class PostUserSidebar extends StatelessWidget {
  const PostUserSidebar({
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
    final isAdmin = user.roles.contains(UserRole.admin);
    final displayName = (user.fullName != null && user.fullName!.isNotEmpty)
        ? user.fullName!
        : user.username;

    return PostSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.t('activityUser'),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundImage: user.avatarUrl != null
                  ? CachedNetworkImageProvider(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 28),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '@${user.username}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              if (user.isVerified)
                _chip(Icons.verified_rounded, l10n.t('verified'), Colors.blue),
              _chip(
                Icons.shield_outlined,
                isAdmin ? l10n.t('roleAdmin') : l10n.t('roleUser'),
                theme.colorScheme.secondary,
              ),
              _chip(
                user.isBanned ? Icons.block : Icons.check_circle_outline,
                user.isBanned ? l10n.t('banned') : l10n.t('active'),
                user.isBanned ? Colors.red : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _statRow(l10n.t('followers'), user.followerCount),
          _statRow(l10n.t('following'), user.followingCount),
          _statRow(l10n.t('posts'), user.postCount),
          if (user.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.t('joined')}: ${DateFormat('MMM d, yyyy').format(user.createdAt!)}',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            l10n.t('quickModeration'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          BlocProvider(
            create: (_) => sl<UsersBloc>(),
            child: _QuickActions(user: user, isAdmin: isAdmin),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.user, required this.isAdmin});

  final UserEntity user;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<UsersBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonalIcon(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.userDetail,
            arguments: user,
          ),
          icon: const Icon(Icons.person_outline, size: 18),
          label: Text(l10n.t('viewFullProfile')),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => bloc.add(ToggleBanUserEvent(user.id)),
          icon: Icon(user.isBanned ? Icons.lock_open : Icons.block, size: 18),
          label: Text(user.isBanned ? l10n.t('unban') : l10n.t('ban')),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => bloc.add(
            isAdmin ? DemoteUserEvent(user.id) : PromoteUserEvent(user.id),
          ),
          icon: Icon(
            isAdmin ? Icons.arrow_downward : Icons.arrow_upward,
            size: 18,
          ),
          label: Text(isAdmin ? l10n.t('demote') : l10n.t('promote')),
        ),
      ],
    );
  }
}
