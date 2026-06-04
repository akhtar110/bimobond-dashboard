import 'package:bimo_bond_dashboard/features/auctions/domain/entities/auction_entity.dart';
import 'package:bimo_bond_dashboard/features/auctions/presentation/bloc/auction_detail_bloc.dart';
import 'package:bimo_bond_dashboard/features/auctions/presentation/pages/auction_detail_page.dart';
import 'package:bimo_bond_dashboard/features/post_management/domain/entities/post_management_route_args.dart';
import 'package:bimo_bond_dashboard/features/post_management/presentation/screens/post_management_detail_screen.dart';
import 'package:bimo_bond_dashboard/features/users/domain/entities/user_entity.dart';
import 'package:bimo_bond_dashboard/features/user_activity/presentation/bloc/user_activity_bloc.dart';
import 'package:bimo_bond_dashboard/features/user_activity/presentation/bloc/user_comments_bloc.dart';
import 'package:bimo_bond_dashboard/features/user_activity/presentation/bloc/user_likes_bloc.dart';
import 'package:bimo_bond_dashboard/features/user_activity/presentation/bloc/user_mentions_bloc.dart';
import 'package:bimo_bond_dashboard/features/user_activity/presentation/bloc/user_unified_activity_bloc.dart';
import 'package:bimo_bond_dashboard/features/users/presentation/bloc/user_detail_bloc.dart';
import 'package:bimo_bond_dashboard/features/users/presentation/pages/user_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/analytics/presentation/analytics_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../localization/localization.dart';
import '../widgets/web_dashboard_layout.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/users/presentation/pages/users_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/create_post/presentation/bloc/create_post_bloc.dart';
import '../../features/create_post/presentation/pages/create_post_page.dart';
import '../../features/categories/presentation/bloc/categories_bloc.dart';
import '../../features/posts/presentation/pages/posts_page.dart';
import '../../features/auctions/presentation/pages/auctions_page.dart';
import '../../features/gifts/presentation/pages/gifts_page.dart';
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
  static const createPost = '/create-post';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const HomeShell());
      case AppRoutes.analytics:
        return MaterialPageRoute(builder: (_) => const AnalyticsPage());
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsPage());
      case AppRoutes.userDetail:
        final user = settings.arguments as UserEntity;
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (ctx) => di.sl<UserDetailBloc>()
                  ..add(LoadUserDetailEvent(user)),
              ),
              BlocProvider(
                create: (ctx) {
                  final bloc = di.sl<UserActivityBloc>();
                  bloc.add(SetUserActivityUserId(user.id));
                  bloc.add(LoadPosts());
                  return bloc;
                },
              ),
              BlocProvider(
                create: (ctx) {
                  final bloc = di.sl<UserCommentsBloc>();
                  bloc.add(SetUserCommentsUserId(user.id));
                  return bloc;
                },
              ),
              BlocProvider(
                create: (ctx) {
                  final bloc = di.sl<UserLikesBloc>();
                  bloc.add(SetUserLikesUserId(user.id));
                  return bloc;
                },
              ),
              BlocProvider(
                create: (ctx) {
                  final bloc = di.sl<UserMentionsBloc>();
                  bloc.add(SetUserMentionsUserId(user.id));
                  return bloc;
                },
              ),
              BlocProvider(
                create: (ctx) {
                  final bloc = di.sl<UserUnifiedActivityBloc>();
                  bloc.add(SetUserUnifiedActivityUserId(user.id));
                  return bloc;
                },
              ),
            ],
            child: UserDetailScreen(user: user),
          ),
        );
      case AppRoutes.postManagementDetail: {
        final deepLink = PostManagementRouteArgs.tryParseRouteName(
          settings.name,
        );
        final args = deepLink ??
            PostManagementRouteArgs.resolve(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => PostManagementDetailScreen.fromArgs(args),
        );
      }
      case AppRoutes.auctionDetail:
        final auction = settings.arguments as AuctionEntity;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => di.sl<AuctionDetailBloc>(),
            child: AuctionDetailPage(auctionId: auction.id),
          ),
        );
      case AppRoutes.createPost:
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    di.sl<CreatePostBloc>()..add(CreatePostStarted()),
              ),
              BlocProvider(
                create: (_) =>
                    di.sl<CategoriesBloc>()..add(LoadCategoriesEvent()),
              ),
            ],
            child: const CreatePostPage(),
          ),
        );
      case AppRoutes.root:
      default:
        return MaterialPageRoute(builder: (_) => const HomeShell());
    }
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = <Widget>[
    DashboardPage(),
    UsersPage(),
    PostsPage(),
    CategoriesPage(),
    AuctionsPage(),
    GiftsPage(),
    ReportsPage(),
    AnalyticsPage(),
    NotificationsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = [
      l10n.t('dashboard'),
      l10n.t('users'),
      l10n.t('posts'),
      l10n.t('categories'),
      l10n.t('auctions'),
      l10n.t('gifts'),
      l10n.t('reports'),
      l10n.t('analytics'),
      l10n.t('notifications'),
      l10n.t('settings'),
    ];
    return WebDashboardLayout(
      title: labels[_index],
      currentIndex: _index,
      currentPage: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _pages[_index],
        ),
      ),
      onDestinationSelected: (index) => setState(() => _index = index),
      items: [
        DashboardNavItem(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: l10n.t('dashboard'),
        ),
        DashboardNavItem(
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: l10n.t('users'),
        ),
        DashboardNavItem(
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view,
          label: l10n.t('posts'),
        ),
        DashboardNavItem(
          icon: Icons.label_outlined,
          selectedIcon: Icons.label,
          label: l10n.t('categories'),
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
          icon: Icons.flag_outlined,
          selectedIcon: Icons.flag,
          label: l10n.t('reports'),
        ),
        DashboardNavItem(
          icon: Icons.query_stats_outlined,
          selectedIcon: Icons.query_stats,
          label: l10n.t('analytics'),
        ),
        DashboardNavItem(
          icon: Icons.notifications_none,
          selectedIcon: Icons.notifications,
          label: l10n.t('notifications'),
        ),
        DashboardNavItem(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: l10n.t('settings'),
        ),
      ],
    );
  }
}
