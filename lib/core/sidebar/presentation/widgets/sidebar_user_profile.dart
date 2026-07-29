import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../localization/localization.dart';
import 'sidebar_tooltip.dart';

class SidebarUserProfile extends StatefulWidget {
  const SidebarUserProfile({super.key, required this.collapsed});

  final bool collapsed;

  @override
  State<SidebarUserProfile> createState() => _SidebarUserProfileState();
}

class _SidebarUserProfileState extends State<SidebarUserProfile> {
  bool _hovered = false;
  bool _menuOpen = false;

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

    final avatar = CircleAvatar(
      radius: widget.collapsed ? 16 : 20,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'A',
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final profileCard = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: EdgeInsetsDirectional.fromSTEB(
        widget.collapsed ? 6 : 12,
        0,
        widget.collapsed ? 6 : 12,
        12,
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        widget.collapsed ? 4 : 12,
        10,
        widget.collapsed ? 4 : 10,
        10,
      ),
      decoration: BoxDecoration(
        color: _hovered || _menuOpen
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (_hovered || _menuOpen)
              ? scheme.primary.withValues(alpha: 0.25)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: widget.collapsed
          ? Center(child: avatar)
          : Row(
              children: [
                avatar,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onOpened: () => setState(() => _menuOpen = true),
                  onCanceled: () => setState(() => _menuOpen = false),
                  onSelected: (value) {
                    setState(() => _menuOpen = false);
                    if (value == 'logout') _confirmLogout(context);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Text(
                        email,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded,
                              size: 18, color: scheme.error),
                          const SizedBox(width: 8),
                          Text(l10n.t('logout')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );

    final wrapped = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.collapsed
          ? SidebarTooltip(
              message: '$name\n$role',
              child: GestureDetector(
                onTap: () => _confirmLogout(context),
                child: profileCard,
              ),
            )
          : profileCard,
    );

    return wrapped;
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
