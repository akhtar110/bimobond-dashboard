import 'package:bimo_bond_dashboard/features/auctions/domain/entities/auction_entity.dart';
import 'package:bimo_bond_dashboard/features/auctions/presentation/bloc/auction_detail_bloc.dart';
import 'package:bimo_bond_dashboard/features/auctions/presentation/pages/auction_detail_page.dart';
import 'package:bimo_bond_dashboard/features/post_management/domain/entities/post_management_route_args.dart';
import 'package:bimo_bond_dashboard/features/post_management/presentation/screens/post_management_detail_screen.dart';
import 'package:bimo_bond_dashboard/features/users/domain/entities/user_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/analytics/presentation/analytics_page.dart';
import '../../features/auth/domain/utils/dashboard_permissions.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../bloc/persistent_bloc_provider.dart';
import '../localization/localization.dart';
import '../routing/admin_detail_page_route.dart';
import '../sidebar/bloc/sidebar_bloc.dart';
import '../widgets/web_dashboard_layout.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/users/presentation/pages/user_detail_route_scope.dart';
import '../../features/users/presentation/pages/user_locations_page.dart';
import '../../features/users/presentation/pages/users_page.dart';
import '../../features/search_history/presentation/pages/search_history_page.dart';
import '../../features/search_management/presentation/pages/search_management_page.dart';
import '../../features/chat_management/presentation/pages/chat_management_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/create_post/presentation/pages/create_post_route_scope.dart';
import '../../features/categories/presentation/bloc/categories_bloc.dart';
import '../../features/posts/presentation/pages/posts_page.dart';
import '../../features/posts/presentation/utils/posts_page_refresh.dart';
import '../../features/auctions/presentation/pages/auctions_page.dart';
import '../../features/gifts/presentation/pages/gifts_page.dart';
import '../../features/wallets/presentation/pages/wallet_detail_page.dart';
import '../../features/wallets/presentation/pages/wallets_shell_page.dart';
import '../../features/promotions/presentation/pages/promotions_shell_page.dart';
import '../../features/gift_reports/presentation/pages/gift_report_detail_page.dart';
import '../../features/category_reports/presentation/pages/category_report_detail_page.dart';
import '../../features/post_reports/presentation/bloc/post_report_detail_bloc.dart';
import '../../features/post_reports/presentation/pages/post_report_detail_page.dart';
import '../../features/promotions/presentation/pages/campaign_detail_page.dart';
import '../../features/promotions/presentation/pages/promoted_post_analytics_page.dart';
import '../../features/sound_management/presentation/pages/sound_management_page.dart';
import '../../features/filters_effects/presentation/pages/filters_effects_page.dart';
import '../../features/stories/presentation/pages/stories_management_page.dart';
import '../../features/rbac/presentation/bloc/rbac_bloc.dart';
import '../../features/rbac/presentation/bloc/rbac_event.dart';
import '../../features/rbac/presentation/pages/rbac_dashboard_pages.dart';
import '../../features/rbac/presentation/utils/permission_manager.dart';
import '../../features/rbac/presentation/widgets/access_denied_view.dart';
import '../../features/security_logs/presentation/pages/logs_page.dart';
import '../../features/auction_reports/presentation/bloc/auction_report_detail_bloc.dart';
import '../../features/auction_reports/presentation/pages/auction_report_detail_page.dart';
import '../../features/user_reports/presentation/bloc/user_reports_bloc.dart';
import '../../features/user_reports/presentation/pages/user_report_detail_page.dart';
import '../../features/settings/presentation/bloc/settings_cubit.dart';
import '../../injection_container.dart' as di;

class AppRoutes {
  static const root = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const analytics = '/analytics';
  static const notifications = '/notifications';
  static const userDetail = '/user-detail';
  static const postManagementDetail = '/post-management-detail';
  static const auctionDetail = '/auction-detail';
  static const chatManagement = '/chat-management';
  static const createPost = '/create-post';
  static const giftReportDetail = '/gift-report-detail';
  static const categoryReportDetail = '/category-report-detail';
  static const userReportDetail = '/user-report-detail';
  static const postReportDetail = '/post-report-detail';
  static const auctionReportDetail = '/auction-report-detail';
  static const campaignDetail = '/campaign-detail';
  static const promotedPostAnalytics = '/promotions/posts';
  static const soundManagement = '/sound-management';
  static const walletDetail = '/wallet-detail';
}

class AppRouter {
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static Widget _homeShell() => BlocProvider.value(
    value: di.sl<RbacBloc>()..add(const LoadCurrentPermissions(force: true)),
    child: const HomeShell(),
  );

  /// Ensures [RbacBloc] is available and shows Access Denied when [canAccess]
  /// is false. Used for standalone routes outside [HomeShell].
  static Widget _guarded({
    required Widget child,
    required bool Function(BuildContext context) canAccess,
    bool requireAuthContext = false,
  }) {
    return BlocProvider.value(
      value: di.sl<RbacBloc>()..add(const LoadCurrentPermissions()),
      child: FeatureAccessBoundary(
        canAccess: canAccess,
        requireAuthContext: requireAuthContext,
        child: child,
      ),
    );
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => _homeShell());
      case AppRoutes.analytics:
        return MaterialPageRoute(
          builder: (_) => _guarded(
            canAccess: PermissionManager.canAccessStaffDashboard,
            child: const AnalyticsPage(),
          ),
        );
      case AppRoutes.notifications:
        return MaterialPageRoute(
          builder: (_) => _guarded(
            canAccess: PermissionManager.canAccessStaffDashboard,
            child: const NotificationsPage(),
          ),
        );
      case AppRoutes.userDetail:
        final user = settings.arguments as UserEntity;
        return MaterialPageRoute(
          builder: (_) => _guarded(
            canAccess: PermissionManager.canAccessAdminDashboard,
            child: UserDetailRouteScope(user: user),
          ),
        );
      case AppRoutes.postManagementDetail:
        {
          final deepLink = PostManagementRouteArgs.tryParseRouteName(
            settings.name,
          );
          final args =
              deepLink ??
              PostManagementRouteArgs.tryResolve(settings.arguments);
          if (args == null) {
            // Hot reload / route restore may replay this route without arguments.
            return MaterialPageRoute(
              settings: const RouteSettings(name: AppRoutes.root),
              builder: (_) => _homeShell(),
            );
          }
          return AdminDetailPageRoute(
            settings: settings,
            builder: (_) => _guarded(
              canAccess: PermissionManager.canAccessAdminDashboard,
              child: PersistentBlocProvider<CategoriesBloc>(
                debugLabel: 'PostManagementRoute',
                create: () =>
                    di.sl<CategoriesBloc>()
                      ..add(LoadCategoriesEvent(forCatalog: true)),
                child: PostManagementDetailScreen.fromArgs(args),
              ),
            ),
          );
        }
      case AppRoutes.auctionDetail:
        final auction = settings.arguments as AuctionEntity;
        return MaterialPageRoute(
          builder: (_) => _guarded(
            canAccess: PermissionManager.canReadAuctions,
            requireAuthContext: true,
            child: PersistentBlocProvider<AuctionDetailBloc>(
              debugLabel: 'AuctionDetailRoute',
              create: () => di.sl<AuctionDetailBloc>(),
              child: AuctionDetailPage(
                auctionId: auction.id,
                listPreview: auction,
              ),
            ),
          ),
        );
      case AppRoutes.campaignDetail:
        final campaignId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => _guarded(
            canAccess: PermissionManager.canAccessStaffDashboard,
            child: CampaignDetailPage(campaignId: campaignId),
          ),
        );
      case AppRoutes.promotedPostAnalytics:
        final postId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => _guarded(
            canAccess: PermissionManager.canAccessStaffDashboard,
            child: PromotedPostAnalyticsPage(postId: postId),
          ),
        );
      case AppRoutes.chatManagement:
        return MaterialPageRoute(
          builder: (_) => _guarded(
            canAccess: PermissionManager.canReadChatAdmin,
            requireAuthContext: true,
            child: const ChatManagementPage(),
          ),
        );
      case AppRoutes.soundManagement:
        return MaterialPageRoute(
          builder: (_) => _guarded(
            canAccess: PermissionManager.canManageSounds,
            requireAuthContext: true,
            child: const SoundManagementPage(),
          ),
        );
      case AppRoutes.walletDetail:
        final userId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => _guarded(
            canAccess: PermissionManager.canAccessAdminDashboard,
            child: WalletDetailPage(userId: userId),
          ),
        );
      case AppRoutes.createPost:
        return MaterialPageRoute(
          builder: (_) => _guarded(
            canAccess: PermissionManager.canAccessAdminDashboard,
            child: const CreatePostRouteScope(),
          ),
        );
      case AppRoutes.giftReportDetail:
        final giftId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => _guarded(
            canAccess: PermissionManager.canAccessStaffDashboard,
            child: GiftReportDetailPage(giftId: giftId),
          ),
        );
      case AppRoutes.categoryReportDetail:
        final categoryId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => _guarded(
            canAccess: PermissionManager.canAccessStaffDashboard,
            child: CategoryReportDetailPage(categoryId: categoryId),
          ),
        );
      case AppRoutes.userReportDetail:
        final userId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => _guarded(
            canAccess: PermissionManager.canAccessStaffDashboard,
            child: PersistentBlocProvider<UserReportsBloc>(
              debugLabel: 'UserReportDetailRoute',
              create: () => di.sl<UserReportsBloc>(),
              child: UserReportDetailPage(userId: userId),
            ),
          ),
        );
      case AppRoutes.postReportDetail:
        final postId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => _guarded(
            canAccess: PermissionManager.canAccessStaffDashboard,
            child: PersistentBlocProvider<PostReportDetailBloc>(
              debugLabel: 'PostReportDetailRoute',
              create: () => di.sl<PostReportDetailBloc>(),
              child: PostReportDetailPage(postId: postId),
            ),
          ),
        );
      case AppRoutes.auctionReportDetail:
        final auctionId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => _guarded(
            canAccess: PermissionManager.canAccessStaffDashboard,
            child: PersistentBlocProvider<AuctionReportDetailBloc>(
              debugLabel: 'AuctionReportDetailRoute',
              create: () => di.sl<AuctionReportDetailBloc>(),
              child: AuctionReportDetailPage(auctionId: auctionId),
            ),
          ),
        );
      case AppRoutes.root:
      default:
        return MaterialPageRoute(builder: (_) => _homeShell());
    }
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _tabCount = 21;
  int _index = 0;

  List<UserRole> _roles(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    if (auth is Authenticated) return auth.user.roles;
    return const [];
  }

  bool _canAccessRoles(List<UserRole> roles, Set<String> permissions) {
    // Prefer fine-grained RBAC; keep legacy admin fallback so the Security
    // menu still appears when /rbac/me has not loaded or is unavailable.
    if (permissions.contains(RbacPermissionKeys.manageRoles)) return true;
    return roles.includesAdmin;
  }

  bool _canAccessLogs(List<UserRole> roles, Set<String> permissions) {
    if (permissions.contains(RbacPermissionKeys.activityAdminRead)) {
      return true;
    }
    return roles.includesAdmin;
  }

  bool _canAccessCameraStudio(List<UserRole> roles, Set<String> permissions) {
    if (permissions.contains(RbacPermissionKeys.manageCameraStudio)) {
      return true;
    }
    return roles.includesAdmin;
  }

  bool _canAccessStories(List<UserRole> roles, Set<String> permissions) {
    if (permissions.contains(RbacPermissionKeys.readStories)) return true;
    return roles.includesAdmin;
  }

  bool _canAccessSounds(List<UserRole> roles, Set<String> permissions) {
    if (permissions.contains(RbacPermissionKeys.manageSounds)) return true;
    return roles.includesAdmin;
  }

  bool _tabVisible(
    int tabIndex,
    List<UserRole> roles,
    Set<String> permissions,
  ) {
    if (tabIndex == 16) {
      return _canAccessCameraStudio(roles, permissions);
    }
    if (tabIndex == 6) {
      return _canAccessStories(roles, permissions);
    }
    if (tabIndex == 13) {
      return _canAccessSounds(roles, permissions);
    }
    if (tabIndex == 18) {
      return _canAccessRoles(roles, permissions);
    }
    if (tabIndex == 19) {
      return _canAccessLogs(roles, permissions);
    }
    if (tabIndex == 2) {
      return permissions.contains(RbacPermissionKeys.readUsers) ||
          roles.includesAdmin;
    }
    return canAccessDashboardTab(tabIndex, roles);
  }

  int _firstAllowedTab(List<UserRole> roles, Set<String> permissions) {
    for (var i = 0; i < _tabCount; i++) {
      if (_tabVisible(i, roles, permissions)) return i;
    }
    return 0;
  }

  void _onIndexChanged(BuildContext context, int index) {
    final roles = _roles(context);
    final permissions =
        context.read<RbacBloc>().state.authContext?.permissionKeys ??
        const <String>{};
    if (!_tabVisible(index, roles, permissions)) return;
    setState(() => _index = index);
  }

  @override
  void initState() {
    super.initState();
    // Shell may be created before login; refresh RBAC once auth is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthBloc>().state;
      if (auth is Authenticated) {
        context.read<RbacBloc>().add(const LoadCurrentPermissions(force: true));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.read<RbacBloc>().add(
            const LoadCurrentPermissions(force: true),
          );
          final roles = state.user.roles;
          final permissions =
              context.read<RbacBloc>().state.authContext?.permissionKeys ??
              const <String>{};
          if (!_tabVisible(_index, roles, permissions)) {
            setState(() => _index = _firstAllowedTab(roles, permissions));
          }
        }
      },
      child: PersistentBlocProvider<SidebarBloc>(
        debugLabel: 'Sidebar',
        create: () => di.sl<SidebarBloc>(),
        child: BlocBuilder<RbacBloc, RbacState>(
          buildWhen: (previous, current) =>
              previous.authContext != current.authContext,
          builder: (context, rbacState) => BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final roles = authState is Authenticated
                  ? authState.user.roles
                  : const <UserRole>[];
              final permissions =
                  rbacState.authContext?.permissionKeys ?? const <String>{};
              final safeIndex = _tabVisible(_index, roles, permissions)
                  ? _index
                  : _firstAllowedTab(roles, permissions);
              if (safeIndex != _index) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _index = safeIndex);
                });
              }
              return _HomeShellChrome(
                index: safeIndex,
                roles: roles,
                permissions: permissions,
                onIndexChanged: (index) => _onIndexChanged(context, index),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Sidebar labels depend on locale; tab content is isolated in [_DashboardTabStack].
class _HomeShellChrome extends StatelessWidget {
  const _HomeShellChrome({
    required this.index,
    required this.roles,
    required this.permissions,
    required this.onIndexChanged,
  });

  final int index;
  final List<UserRole> roles;
  final Set<String> permissions;
  final ValueChanged<int> onIndexChanged;

  @override
  Widget build(BuildContext context) {
    // Rebuild sidebar labels when language changes.
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;
    bool tabVisible(int tabIndex) {
      if (tabIndex == 16) {
        return permissions.contains(RbacPermissionKeys.manageCameraStudio) ||
            roles.includesAdmin;
      }
      if (tabIndex == 6) {
        return permissions.contains(RbacPermissionKeys.readStories) ||
            roles.includesAdmin;
      }
      if (tabIndex == 13) {
        return permissions.contains(RbacPermissionKeys.manageSounds) ||
            roles.includesAdmin;
      }
      if (tabIndex == 18) {
        return permissions.contains(RbacPermissionKeys.manageRoles) ||
            roles.includesAdmin;
      }
      if (tabIndex == 19) {
        return permissions.contains(RbacPermissionKeys.activityAdminRead) ||
            roles.includesAdmin;
      }
      if (tabIndex == 2) {
        return permissions.contains(RbacPermissionKeys.readUsers) ||
            roles.includesAdmin;
      }
      return canAccessDashboardTab(tabIndex, roles);
    }

    return WebDashboardLayout(
      currentIndex: index,
      tabVisible: tabVisible,
      currentPage: _DashboardTabStack(
        key: const ValueKey('dashboard_tab_stack'),
        index: index,
      ),
      onDestinationSelected: onIndexChanged,
      items: [
        DashboardNavItem(
          icon: Icons.query_stats_outlined,
          selectedIcon: Icons.query_stats,
          label: l10n.t('analytics'),
        ),
        DashboardNavItem(
          icon: Icons.travel_explore_outlined,
          selectedIcon: Icons.travel_explore,
          label: l10n.tOr('searchManagement', 'Search Management'),
        ),
        DashboardNavItem(
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: l10n.t('users'),
        ),
        DashboardNavItem(
          icon: Icons.location_on_outlined,
          selectedIcon: Icons.location_on,
          label: l10n.tOr('userLocations', 'User Locations'),
        ),
        DashboardNavItem(
          icon: Icons.manage_search_outlined,
          selectedIcon: Icons.manage_search,
          label: l10n.tOr('searchHistory', 'Search History'),
        ),
        DashboardNavItem(
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view,
          label: l10n.t('posts'),
        ),
        DashboardNavItem(
          icon: Icons.auto_stories_outlined,
          selectedIcon: Icons.auto_stories,
          label: l10n.tOr('storiesManagement', 'Stories'),
        ),
        DashboardNavItem(
          icon: Icons.label_outlined,
          selectedIcon: Icons.label,
          label: l10n.t('categories'),
        ),
        DashboardNavItem(
          icon: Icons.forum_outlined,
          selectedIcon: Icons.forum,
          label: l10n.t('chatManagement'),
        ),
        DashboardNavItem(
          icon: Icons.gavel_outlined,
          selectedIcon: Icons.gavel,
          label: l10n.t('auctions'),
        ),
        DashboardNavItem(
          icon: Icons.card_giftcard_outlined,
          selectedIcon: Icons.card_giftcard,
          label: l10n.t('gifts'),
        ),
        DashboardNavItem(
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet,
          label: l10n.t('wallets'),
        ),
        DashboardNavItem(
          icon: Icons.campaign_outlined,
          selectedIcon: Icons.campaign,
          label: l10n.t('promotions'),
        ),
        DashboardNavItem(
          icon: Icons.library_music_outlined,
          selectedIcon: Icons.library_music_rounded,
          label: l10n.t('soundManagement'),
        ),
        DashboardNavItem(
          icon: Icons.flag_outlined,
          selectedIcon: Icons.flag,
          label: l10n.t('reports'),
        ),
        DashboardNavItem(
          icon: Icons.notifications_none,
          selectedIcon: Icons.notifications,
          label: l10n.t('notifications'),
        ),
        DashboardNavItem(
          icon: Icons.auto_awesome_outlined,
          selectedIcon: Icons.auto_awesome,
          label: l10n.t('filtersEffects'),
        ),
        DashboardNavItem(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: l10n.t('settings'),
        ),
        DashboardNavItem(
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          label: l10n.tOr('rbacRoles', 'Roles'),
        ),
        DashboardNavItem(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: l10n.tOr('securityLogs', 'Logs'),
        ),
        DashboardNavItem(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: l10n.tOr('profile', 'Profile'),
        ),
      ],
    );
  }
}

class _DashboardTabStack extends StatefulWidget {
  const _DashboardTabStack({super.key, required this.index});

  final int index;

  @override
  State<_DashboardTabStack> createState() => _DashboardTabStackState();
}

class _DashboardTabStackState extends State<_DashboardTabStack> {
  static const _tabCount = 21;
  final List<Widget?> _tabCache = List<Widget?>.filled(_tabCount, null);

  @override
  void didUpdateWidget(covariant _DashboardTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == postsDashboardTabIndex &&
        oldWidget.index != widget.index &&
        _tabCache[postsDashboardTabIndex] != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PostsPageRefreshScope.notify();
      });
    }
  }

  Widget _buildTabPage(int index) {
    // Stable keys: theme/locale updates must rebuild in place, not remount
    // tabs (remount reloads blocs and makes the Settings header jump).
    final page = switch (index) {
      0 => const AnalyticsPage(key: ValueKey('dashboard_tab_analytics')),
      1 => const SearchManagementPage(
        key: ValueKey('dashboard_tab_search_management'),
      ),
      2 => const UsersPage(key: ValueKey('dashboard_tab_users')),
      3 => const UserLocationsPage(
        key: ValueKey('dashboard_tab_user_locations'),
      ),
      4 => const SearchHistoryPage(
        key: ValueKey('dashboard_tab_search_history'),
      ),
      5 => const PostsPage(key: ValueKey('dashboard_tab_posts')),
      6 => const StoriesManagementPage(
        key: ValueKey('dashboard_tab_stories'),
      ),
      7 => const CategoriesPage(key: ValueKey('dashboard_tab_categories')),
      8 => const ChatManagementPage(key: ValueKey('dashboard_tab_chat')),
      9 => const AuctionsPage(key: ValueKey('dashboard_tab_auctions')),
      10 => const GiftsPage(key: ValueKey('dashboard_tab_gifts')),
      11 => const WalletsShellPage(key: ValueKey('dashboard_tab_wallets')),
      12 => const PromotionsShellPage(
        key: ValueKey('dashboard_tab_promotions'),
      ),
      13 => const SoundManagementPage(key: ValueKey('dashboard_tab_sounds')),
      14 => const ReportsPage(key: ValueKey('dashboard_tab_reports')),
      15 => const NotificationsPage(
        key: ValueKey('dashboard_tab_notifications'),
      ),
      16 => const FiltersEffectsPage(
        key: ValueKey('dashboard_tab_filters_effects'),
      ),
      17 => const SettingsPage(key: ValueKey('dashboard_tab_settings')),
      18 => const RbacRolesDashboardPage(
        key: ValueKey('dashboard_tab_rbac_roles'),
      ),
      19 => const LogsPage(key: ValueKey('dashboard_tab_security_logs')),
      20 => const ProfilePage(key: ValueKey('dashboard_tab_profile')),
      _ => const SizedBox.shrink(key: ValueKey('dashboard_tab_empty')),
    };
    return DashboardTabAccessBoundary(tabIndex: index, child: page);
  }

  Widget _tabAt(int index) {
    final cached = _tabCache[index];
    if (cached != null) return cached;

    if (index != widget.index) {
      return SizedBox.shrink(key: ValueKey('dashboard_tab_placeholder_$index'));
    }

    final page = _buildTabPage(index);
    _tabCache[index] = page;
    return page;
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      sizing: StackFit.expand,
      children: List.generate(_tabCount, _tabAt),
    );
  }
}
