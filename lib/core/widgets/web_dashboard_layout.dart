import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../localization/localization.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';

class DashboardNavItem {
  const DashboardNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class WebDashboardLayout extends StatelessWidget {
  const WebDashboardLayout({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.currentPage,
    required this.title,
    required this.onDestinationSelected,
  });

  final List<DashboardNavItem> items;
  final int currentIndex;
  final Widget currentPage;
  final String title;
  final ValueChanged<int> onDestinationSelected;

  static const _desktopBreakpoint = 1000.0;
  static const _sidebarWidth = 260.0;
  static const _topbarHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > _desktopBreakpoint;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final content = _DashboardContent(
      showTopbar: isDesktop,
      topbarHeight: _topbarHeight,
      title: title,
      child: currentPage,
    );

    if (!isDesktop) {
      return Scaffold(
        drawer: _Sidebar(
          width: _sidebarWidth,
          items: items,
          currentIndex: currentIndex,
          isRtl: isRtl,
          onDestinationSelected: (index) {
            Navigator.of(context).maybePop();
            onDestinationSelected(index);
          },
        ),
        appBar: AppBar(
          toolbarHeight: _topbarHeight,
          title: Text(title),
          actions: const [_AdminAvatar()],
        ),
        body: content,
      );
    }

    return Scaffold(
      body: Row(
        children: isRtl
            ? [
                Expanded(child: content),
                _Sidebar(
                  width: _sidebarWidth,
                  items: items,
                  currentIndex: currentIndex,
                  isRtl: isRtl,
                  onDestinationSelected: onDestinationSelected,
                ),
              ]
            : [
                _Sidebar(
                  width: _sidebarWidth,
                  items: items,
                  currentIndex: currentIndex,
                  isRtl: isRtl,
                  onDestinationSelected: onDestinationSelected,
                ),
                Expanded(child: content),
              ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.showTopbar,
    required this.topbarHeight,
    required this.title,
    required this.child,
  });

  final bool showTopbar;
  final double topbarHeight;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTopbar)
          Container(
            height: topbarHeight,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.18),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const _AdminAvatar(),
              ],
            ),
          ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1480),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(28, 24, 28, 24),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.width,
    required this.items,
    required this.currentIndex,
    required this.isRtl,
    required this.onDestinationSelected,
  });

  final double width;
  final List<DashboardNavItem> items;
  final int currentIndex;
  final bool isRtl;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
        border: BorderDirectional(
          end: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.22),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 16, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 18),
                child: Text(
                  context.l10n.t('bimoBondAdmin'),
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final selected = index == currentIndex;
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: selected
                              ? theme.colorScheme.primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: Icon(selected ? item.selectedIcon : item.icon),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          onTap: () => onDestinationSelected(index),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(height: 4),
                  itemCount: items.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'logout') {
            context.read<AuthBloc>().add(AuthLogoutRequested());
          }
        },
        itemBuilder: (context) {
          final l10n = context.l10n;
          return [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 20),
                  const SizedBox(width: 12),
                  Text(l10n.t('profile')),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 20, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(
                    l10n.t('logout'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ];
        },
        child: const CircleAvatar(
          radius: 17,
          child: Icon(Icons.admin_panel_settings, size: 19),
        ),
      ),
    );
  }
}
