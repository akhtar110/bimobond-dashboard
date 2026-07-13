import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
import '../../../categories/presentation/bloc/categories_bloc.dart';
import '../../../notifications/presentation/bloc/user_notifications_bloc.dart';
import '../../../user_activity/presentation/bloc/user_activity_bloc.dart';
import '../../../user_activity/presentation/bloc/user_comments_bloc.dart';
import '../../../user_activity/presentation/bloc/user_likes_bloc.dart';
import '../../../user_activity/presentation/bloc/user_unified_activity_bloc.dart';
import '../../../promotions/presentation/bloc/location_intelligence_bloc.dart';
import '../../../search_history/presentation/bloc/search_history_bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/user_detail_bloc.dart';
import '../bloc/user_detail_event.dart';
import 'user_detail_screen.dart';

/// Keeps user-detail blocs alive for the pushed route lifetime.
class UserDetailRouteScope extends StatefulWidget {
  const UserDetailRouteScope({super.key, required this.user});

  final UserEntity user;

  @override
  State<UserDetailRouteScope> createState() => _UserDetailRouteScopeState();
}

class _UserDetailRouteScopeState extends State<UserDetailRouteScope> {
  late final UserDetailBloc _detailBloc;
  late final UserActivityBloc _activityBloc;
  late final UserCommentsBloc _commentsBloc;
  late final UserLikesBloc _likesBloc;
  late final UserUnifiedActivityBloc _unifiedActivityBloc;
  late final UserNotificationsBloc _notificationsBloc;
  late final CategoriesBloc _categoriesBloc;
  late final LocationIntelligenceBloc _locationBloc;
  late final SearchHistoryBloc _searchHistoryBloc;

  @override
  void initState() {
    super.initState();
    final user = widget.user;

    _detailBloc = di.sl<UserDetailBloc>()..add(LoadUserDetailEvent(user));
    if (kDebugMode) debugPrint('UserDetailBloc created');

    _activityBloc = di.sl<UserActivityBloc>()
      ..add(SetUserActivityUserId(user.id))
      ..add(LoadPosts());
    if (kDebugMode) {
      debugPrint('UserActivityBloc created — LoadPosts dispatched');
    }

    _commentsBloc = di.sl<UserCommentsBloc>()
      ..add(SetUserCommentsUserId(user.id));
    if (kDebugMode) debugPrint('UserCommentsBloc created');

    _likesBloc = di.sl<UserLikesBloc>()..add(SetUserLikesUserId(user.id));
    if (kDebugMode) debugPrint('UserLikesBloc created');

    _unifiedActivityBloc = di.sl<UserUnifiedActivityBloc>()
      ..add(SetUserUnifiedActivityUserId(user.id));
    if (kDebugMode) debugPrint('UserUnifiedActivityBloc created');

    _notificationsBloc = di.sl<UserNotificationsBloc>();
    if (kDebugMode) debugPrint('UserNotificationsBloc created');

    _categoriesBloc = di.sl<CategoriesBloc>()
      ..add(LoadCategoriesEvent(forCatalog: true));
    if (kDebugMode) {
      debugPrint(
        'CategoriesBloc created (user detail) — LoadCategories dispatched',
      );
    }

    _locationBloc = di.sl<LocationIntelligenceBloc>();
    if (kDebugMode) debugPrint('LocationIntelligenceBloc created');

    _searchHistoryBloc = di.sl<SearchHistoryBloc>();
    if (kDebugMode) debugPrint('SearchHistoryBloc created');
  }

  @override
  void dispose() {
    _detailBloc.close();
    _activityBloc.close();
    _commentsBloc.close();
    _likesBloc.close();
    _unifiedActivityBloc.close();
    _notificationsBloc.close();
    _categoriesBloc.close();
    _locationBloc.close();
    _searchHistoryBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('UserDetailRouteScope rebuilt');
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserDetailBloc>.value(value: _detailBloc),
        BlocProvider<UserActivityBloc>.value(value: _activityBloc),
        BlocProvider<UserCommentsBloc>.value(value: _commentsBloc),
        BlocProvider<UserLikesBloc>.value(value: _likesBloc),
        BlocProvider<UserUnifiedActivityBloc>.value(value: _unifiedActivityBloc),
        BlocProvider<UserNotificationsBloc>.value(value: _notificationsBloc),
        BlocProvider<CategoriesBloc>.value(value: _categoriesBloc),
        BlocProvider<LocationIntelligenceBloc>.value(value: _locationBloc),
        BlocProvider<SearchHistoryBloc>.value(value: _searchHistoryBloc),
      ],
      child: UserDetailScreen(user: widget.user),
    );
  }
}
