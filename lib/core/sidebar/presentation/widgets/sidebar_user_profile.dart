import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../localization/localization.dart';
import 'sidebar_tooltip.dart';

class SidebarUserProfile extends StatefulWidget {
  const SidebarUserProfile({
    super.key,
    required this.collapsed,
    this.onDestinationSelected,
    this.currentIndex,
  });

  final bool collapsed;
  final ValueChanged<int>? onDestinationSelected;
  final int? currentIndex;

  @override
  State<SidebarUserProfile> createState() => _SidebarUserProfileState();
}

class _SidebarUserProfileState extends State<SidebarUserProfile> {
  bool _hovered = false;
  bool _menuOpen = false;

  static const int profileTabIndex = 20;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final authState = context.watch<AuthBloc>().state;

    final name = authState is Authenticated
        ? authState.user.username
        : l10n.t('adminName');
    final email = authState is Authenticated
        ? authState.user.email
        : l10n.tOr('adminEmail', 'admin@dashboard.com');
    final role = l10n.t('adminRole');
    final isProfileSelected = widget.currentIndex == profileTabIndex;

    final avatar = CircleAvatar(
      radius: widget.collapsed ? 16 : 20,
      backgroundColor: isProfileSelected
          ? scheme.primary
          : scheme.primaryContainer,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'A',
        style: TextStyle(
          color: isProfileSelected
              ? scheme.onPrimary
              : scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    List<PopupMenuEntry<String>> buildMenuItems(BuildContext context) {
      return [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                email,
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: scheme.onSurface,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.tOr('profile', 'Profile'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                size: 18,
                color: scheme.error,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.t('logout'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: scheme.error,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    void handleMenuSelection(String value) {
      setState(() => _menuOpen = false);
      if (value == 'profile') {
        widget.onDestinationSelected?.call(profileTabIndex);
      } else if (value == 'logout') {
        _confirmLogout(context);
      }
    }

    if (widget.collapsed) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: SidebarTooltip(
          message: '$name\n$role',
          child: PopupMenuButton<String>(
            tooltip: l10n.tOr('profile_options', 'Profile options'),
            onOpened: () => setState(() => _menuOpen = true),
            onCanceled: () => setState(() => _menuOpen = false),
            onSelected: handleMenuSelection,
            itemBuilder: buildMenuItems,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsetsDirectional.fromSTEB(6, 0, 6, 12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (_hovered || _menuOpen || isProfileSelected)
                    ? scheme.surfaceContainerHigh
                    : scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (_hovered || _menuOpen || isProfileSelected)
                      ? scheme.primary.withValues(alpha: 0.35)
                      : scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Center(child: avatar),
            ),
          ),
        ),
      );
    }

    final profileCard = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 12),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: (_hovered || _menuOpen || isProfileSelected)
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (_hovered || _menuOpen || isProfileSelected)
              ? scheme.primary.withValues(alpha: 0.35)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => widget.onDestinationSelected?.call(profileTabIndex),
            borderRadius: BorderRadius.circular(20),
            child: avatar,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => widget.onDestinationSelected?.call(profileTabIndex),
              borderRadius: BorderRadius.circular(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isProfileSelected
                          ? FontWeight.w800
                          : FontWeight.w700,
                      color: isProfileSelected
                          ? scheme.primary
                          : scheme.onSurface,
                    ),
                  ),
                  Text(
                    role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz_rounded,
              size: 20,
              color: (_menuOpen || isProfileSelected)
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            onOpened: () => setState(() => _menuOpen = true),
            onCanceled: () => setState(() => _menuOpen = false),
            onSelected: handleMenuSelection,
            itemBuilder: buildMenuItems,
          ),
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: profileCard,
    );
  }

  void _confirmLogout(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('logout')),
        content: Text(l10n.t('logoutConfirmMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: Text(l10n.t('logout')),
          ),
        ],
      ),
    );
  }
}
