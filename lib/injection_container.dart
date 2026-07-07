import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'core/config/api_config.dart';
import 'core/utils/media_url_resolver.dart';
import 'features/auth/data/datasource/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/save_session_usecase.dart';
import 'features/auth/domain/usecases/login_with_google_usecase.dart';
import 'features/auth/presentation/bloc/login_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/data/datasource/auth_local_data_source.dart';

import 'features/settings/presentation/bloc/settings_cubit.dart';
import 'features/settings/data/datasources/app_preferences_local_datasource.dart';
import 'features/settings/data/datasources/app_settings_remote_datasource.dart';
import 'features/settings/data/datasources/economy_settings_remote_datasource.dart';
import 'features/settings/data/repositories/app_settings_repository_impl.dart';
import 'features/settings/data/repositories/economy_settings_repository_impl.dart';
import 'features/settings/domain/repositories/app_settings_repository.dart';
import 'features/settings/domain/repositories/economy_settings_repository.dart';
import 'features/settings/domain/usecases/app_setting_usecases.dart';
import 'features/settings/domain/usecases/economy_setting_usecases.dart';
import 'features/settings/presentation/bloc/app_settings_bloc.dart';
import 'features/settings/presentation/bloc/economy_settings_bloc.dart';
import 'core/sidebar/bloc/sidebar_bloc.dart';

import 'features/user_reports/data/datasources/user_reports_remote_data_source.dart';
import 'features/user_reports/data/repositories/user_reports_repository_impl.dart';
import 'features/user_reports/domain/repositories/user_reports_repository.dart';
import 'features/user_reports/domain/usecases/get_user_report_detail.dart';
import 'features/user_reports/domain/usecases/get_user_reports_list.dart';
import 'features/user_reports/domain/usecases/get_user_reports_overview.dart';
import 'features/user_reports/presentation/bloc/user_reports_bloc.dart';

import 'features/post_reports/data/datasources/post_reports_remote_datasource.dart';
import 'features/post_reports/data/repositories/post_reports_repository_impl.dart';
import 'features/post_reports/domain/repositories/post_reports_repository.dart';
import 'features/post_reports/domain/usecases/get_post_report_detail.dart';
import 'features/post_reports/domain/usecases/get_post_reports_list.dart';
import 'features/post_reports/domain/usecases/get_post_reports_overview.dart';
import 'features/post_reports/presentation/bloc/post_report_detail_bloc.dart';
import 'features/post_reports/presentation/bloc/post_reports_bloc.dart';
import 'features/post_reports/presentation/services/post_report_media_lookup.dart';

import 'features/auction_reports/data/datasources/auction_reports_remote_datasource.dart';
import 'features/auction_reports/data/repositories/auction_reports_repository_impl.dart';
import 'features/auction_reports/domain/repositories/auction_reports_repository.dart';
import 'features/auction_reports/domain/usecases/get_auction_report_detail.dart';
import 'features/auction_reports/domain/usecases/get_auction_reports_list.dart';
import 'features/auction_reports/domain/usecases/get_auction_reports_overview.dart';
import 'features/auction_reports/presentation/bloc/auction_report_detail_bloc.dart';
import 'features/auction_reports/presentation/bloc/auction_reports_bloc.dart';

import 'features/reports/presentation/bloc/reports_center_overview_cubit.dart';

import 'features/users/data/datasources/users_remote_data_source.dart';
import 'features/users/data/repositories/users_repository_impl.dart';
import 'features/users/domain/repositories/users_repository.dart';
import 'features/users/domain/usecases/bulk_activate_users.dart';
import 'features/users/domain/usecases/bulk_delete_users.dart';
import 'features/users/domain/usecases/bulk_demote_users.dart';
import 'features/users/domain/usecases/bulk_promote_users.dart';
import 'features/users/domain/usecases/bulk_suspend_users.dart';
import 'features/users/domain/usecases/ban_user.dart';
import 'features/users/domain/usecases/delete_user.dart';
import 'features/users/domain/usecases/demote_user.dart';
import 'features/users/domain/usecases/get_user_by_id.dart';
import 'features/users/domain/usecases/get_user_follow_list.dart';
import 'features/users/domain/usecases/get_user_posts.dart';
import 'features/users/domain/usecases/get_users.dart';
import 'features/users/domain/usecases/promote_to_admin.dart';
import 'features/users/domain/usecases/updte_role.dart';
import 'features/users/domain/usecases/unban_user.dart';
import 'features/users/presentation/bloc/users_bloc.dart';
import 'features/users/presentation/bloc/user_detail_bloc.dart';

import 'features/search_history/data/datasources/search_history_remote_datasource.dart';
import 'features/search_history/data/repositories/search_history_repository_impl.dart';
import 'features/search_history/domain/repositories/search_history_repository.dart';
import 'features/search_history/domain/usecases/search_history_usecases.dart';
import 'features/search_history/presentation/bloc/search_history_bloc.dart';

import 'features/filters_effects/data/datasources/filters_effects_remote_datasource.dart';
import 'features/filters_effects/data/repositories/filters_effects_repository_impl.dart';
import 'features/filters_effects/domain/repositories/filters_effects_repository.dart';
import 'features/filters_effects/domain/usecases/filters_effects_usecases.dart';
import 'features/filters_effects/presentation/bloc/filters_effects_bloc.dart';

import 'features/user_activity/data/datasources/user_activity_remote_data_source.dart';
import 'features/user_activity/data/repositories/user_activity_repository_impl.dart';
import 'features/user_activity/domain/repositories/user_activity_repository.dart';
import 'features/user_activity/domain/usecases/get_user_activity_auctions.dart';
import 'features/user_activity/domain/usecases/get_user_activity_devices.dart';
import 'features/user_activity/domain/usecases/get_user_activity_feed.dart';
import 'features/user_activity/domain/usecases/get_user_activity_gifts.dart';
import 'features/user_activity/domain/usecases/get_user_activity_posts.dart';
import 'features/user_activity/domain/usecases/delete_repost_admin.dart';
import 'features/user_activity/domain/usecases/get_user_activity_reposts.dart';
import 'features/user_activity/domain/usecases/get_user_comments.dart';
import 'features/user_activity/domain/usecases/get_user_likes.dart';
import 'features/user_activity/domain/usecases/get_user_mentions.dart';
import 'features/user_activity/presentation/bloc/user_activity_bloc.dart';
import 'features/user_activity/presentation/bloc/user_comments_bloc.dart';
import 'features/user_activity/presentation/bloc/user_likes_bloc.dart';
import 'features/user_activity/presentation/bloc/user_mentions_bloc.dart';
import 'features/user_activity/presentation/bloc/user_unified_activity_bloc.dart';

import 'features/post_management/data/datasources/post_management_remote_datasource.dart';
import 'features/post_management/data/repositories/post_management_repository_impl.dart';
import 'features/post_management/domain/repositories/post_management_repository.dart';
import 'features/post_management/domain/usecases/ban_post_usecase.dart';
import 'features/post_management/domain/usecases/delete_managed_post.dart';
import 'features/post_management/domain/usecases/get_managed_post_by_id.dart';
import 'features/post_management/domain/usecases/hide_post_usecase.dart';
import 'features/post_management/domain/usecases/update_managed_post.dart';
import 'features/post_management/domain/usecases/update_post_details_usecase.dart';
import 'features/post_management/domain/usecases/delete_comment_admin.dart';
import 'features/post_management/domain/usecases/get_post_comments.dart';
import 'features/post_management/domain/usecases/get_post_engagement_users.dart';
import 'features/post_management/domain/usecases/update_post_status_usecase.dart';
import 'features/post_management/presentation/bloc/post_management_bloc.dart';

import 'features/categories/data/datasources/categories_remote_datasource.dart';
import 'features/categories/data/repositories/categories_repository_impl.dart';
import 'features/categories/domain/repositories/categories_repository.dart';
import 'features/categories/domain/usecases/create_category_usecase.dart';
import 'features/categories/domain/usecases/delete_category_usecase.dart';
import 'features/categories/domain/usecases/get_all_categories_usecase.dart';
import 'features/categories/domain/usecases/update_category_usecase.dart';
import 'features/categories/presentation/bloc/categories_bloc.dart';

import 'features/chat_management/data/datasources/chat_management_remote_datasource.dart';
import 'features/chat_management/data/datasources/chat_socket_service.dart';
import 'features/chat_management/data/repositories/chat_management_repository_impl.dart';
import 'features/chat_management/domain/repositories/chat_management_repository.dart';
import 'features/chat_management/domain/usecases/chat_management_usecases.dart';
import 'features/chat_management/presentation/bloc/chat_management_bloc.dart';

import 'features/posts/data/datasources/bulk_posts_remote_datasource.dart';
import 'features/posts/data/datasources/bulk_posts_remote_datasource_impl.dart';
import 'features/posts/data/datasources/posts_remote_data_source.dart';
import 'features/posts/data/repositories/bulk_post_repository_impl.dart';
import 'features/posts/data/repositories/post_repository_impl.dart';
import 'features/posts/domain/repositories/bulk_post_repository.dart';
import 'features/posts/domain/repositories/post_repository.dart';
import 'features/posts/domain/usecases/bulk_post_action_usecase.dart';
import 'features/posts/domain/usecases/get_all_posts_usecase.dart';
import 'features/posts/domain/usecases/update_posts_status_usecase.dart';
import 'features/posts/domain/usecases/update_posts_visibility_usecase.dart';
import 'features/posts/presentation/bloc/posts_bloc.dart';

import 'features/stories/data/datasources/stories_remote_data_source.dart';
import 'features/stories/data/repositories/stories_repository_impl.dart';
import 'features/stories/domain/repositories/stories_repository.dart';
import 'features/stories/domain/usecases/get_active_stories.dart';
import 'features/stories/presentation/bloc/stories_bloc.dart';

import 'features/create_post/data/datasources/create_post_auxiliary_remote_data_source.dart';
import 'features/create_post/data/datasources/create_post_remote_data_source.dart';
import 'features/create_post/data/repositories/create_post_repository_impl.dart';
import 'features/create_post/domain/repositories/create_post_repository.dart';
import 'features/create_post/domain/services/create_post_media_filter_service.dart';
import 'features/create_post/domain/services/create_post_media_upload_service.dart';
import 'features/create_post/domain/services/create_post_thumbnail_service.dart';
import 'features/create_post/domain/usecases/create_post_auxiliary_usecases.dart';
import 'features/create_post/domain/usecases/create_post_usecase.dart';
import 'features/create_post/domain/usecases/submit_create_post_usecase.dart';
import 'features/create_post/domain/usecases/upload_post_media_usecase.dart';
import 'features/create_post/presentation/bloc/create_post_bloc.dart';
import 'features/posts/data/datasources/video_thumbnail_local_data_source.dart';
import 'features/posts/data/datasources/video_thumbnail_local_data_source_impl.dart';
import 'features/posts/data/repositories/video_thumbnail_repository_impl.dart';
import 'features/posts/domain/repositories/video_thumbnail_repository.dart';
import 'features/posts/domain/usecases/video_thumbnail_usecases.dart';

import 'features/videos/data/datasources/videos_remote_data_source.dart';
import 'features/videos/data/repositories/videos_repository_impl.dart';
import 'features/videos/domain/repositories/videos_repository.dart';
import 'features/videos/domain/usecases/delete_video.dart';
import 'features/videos/domain/usecases/get_videos.dart';
import 'features/videos/presentation/bloc/videos_bloc.dart';

import 'features/auctions/data/datasources/auction_socket_service.dart';
import 'features/auctions/data/datasources/auctions_remote_datasource.dart';
import 'features/auctions/data/repositories/auctions_repository_impl.dart';
import 'features/auctions/domain/repositories/auctions_repository.dart';
import 'features/auctions/domain/usecases/ban_auction_usecase.dart';
import 'features/auctions/domain/usecases/cancel_auction_usecase.dart';
import 'features/auctions/domain/usecases/create_auction_usecase.dart';
import 'features/auctions/domain/usecases/get_active_auctions_usecase.dart';
import 'features/auctions/domain/usecases/get_all_auctions_usecase.dart';
import 'features/auctions/domain/usecases/get_auction_details_usecase.dart';
import 'features/auctions/domain/usecases/host_cancel_auction_usecase.dart';
import 'features/auctions/domain/usecases/host_update_auction_usecase.dart';
import 'features/auctions/domain/usecases/preview_auction_pricing_usecase.dart';
import 'features/auctions/domain/usecases/resolve_auction_usecase.dart';
import 'features/auctions/domain/usecases/update_auction_usecase.dart';
import 'features/auctions/presentation/bloc/auction_detail_bloc.dart';
import 'features/auctions/presentation/bloc/auctions_bloc.dart';
import 'features/auctions/presentation/services/auction_image_lookup.dart';

import 'features/reports/data/datasources/reports_remote_datasource.dart';
import 'features/reports/data/repositories/reports_repository_impl.dart';
import 'features/reports/domain/repositories/reports_repository.dart';
import 'features/reports/domain/usecases/get_reports_usecase.dart';
import 'features/reports/domain/usecases/get_report_details_usecase.dart';
import 'features/reports/domain/usecases/update_report_status_usecase.dart';
import 'features/reports/presentation/bloc/reports_bloc.dart';

import 'features/analytics/data/datasources/analytics_remote_datasource.dart';
import 'features/analytics/data/repositories/analytics_repository_impl.dart';
import 'features/analytics/domain/repositories/analytics_repository.dart';
import 'features/analytics/domain/usecases/analytics_usecases.dart';
import 'features/analytics/presentation/bloc/analytics_bloc.dart';

import 'features/gifts/data/datasources/gifts_remote_datasource.dart';
import 'features/gifts/data/repositories/gifts_repository_impl.dart';
import 'features/gifts/domain/repositories/gifts_repository.dart';
import 'features/gifts/domain/usecases/bulk_gift_action_usecase.dart';
import 'features/gifts/domain/usecases/create_gift_usecase.dart';
import 'features/gifts/domain/usecases/delete_gift_usecase.dart';
import 'features/gifts/domain/usecases/get_admin_gifts_usecase.dart';
import 'features/gifts/domain/usecases/update_gift_usecase.dart';
import 'features/gifts/presentation/bloc/gifts_bloc.dart';

import 'features/wallets/data/datasources/wallets_remote_datasource.dart';
import 'features/wallets/data/repositories/wallets_repository_impl.dart';
import 'features/wallets/domain/repositories/wallets_repository.dart';
import 'features/wallets/domain/usecases/wallet_usecases.dart';
import 'features/wallets/presentation/bloc/coin_packages_bloc.dart';
import 'features/wallets/presentation/bloc/economy_bloc.dart';
import 'features/wallets/presentation/bloc/fiat_purchases_bloc.dart';
import 'features/wallets/presentation/bloc/ledger_bloc.dart';
import 'features/wallets/presentation/bloc/wallet_detail_bloc.dart';
import 'features/wallets/presentation/bloc/wallet_overview_bloc.dart';
import 'features/wallets/presentation/bloc/wallets_list_bloc.dart';
import 'features/wallets/presentation/bloc/withdrawals_bloc.dart';
import 'features/money_dashboard/domain/usecases/load_money_dashboard_usecase.dart';
import 'features/money_dashboard/presentation/bloc/money_dashboard_bloc.dart';
import 'features/users/domain/entities/user_entity.dart';

import 'features/promotions/data/datasources/promotions_remote_datasource.dart';
import 'features/promotions/data/repositories/promotions_repository_impl.dart';
import 'features/promotions/domain/repositories/promotions_repository.dart';
import 'features/promotions/domain/usecases/promotion_usecases.dart';
import 'features/promotions/presentation/bloc/campaign_detail_bloc.dart';
import 'features/promotions/presentation/bloc/campaigns_bloc.dart';
import 'features/promotions/presentation/bloc/location_intelligence_bloc.dart';
import 'features/promotions/presentation/bloc/packages_bloc.dart';
import 'features/promotions/presentation/bloc/promoted_post_detail_bloc.dart';
import 'features/promotions/presentation/bloc/promoted_posts_bloc.dart';
import 'features/promotions/presentation/bloc/promotion_analytics_bloc.dart';
import 'features/promotions/presentation/bloc/promotions_overview_bloc.dart';

import 'features/sound_management/data/datasources/sound_management_remote_datasource.dart';
import 'features/sound_management/data/repositories/sound_management_repository_impl.dart';
import 'features/sound_management/domain/repositories/sound_management_repository.dart';
import 'features/sound_management/domain/usecases/sound_usecases.dart';
import 'features/sound_management/presentation/bloc/bulk_sound_action_bloc.dart';
import 'features/sound_management/presentation/bloc/sound_crud_bloc.dart';
import 'features/sound_management/presentation/bloc/sound_overview_bloc.dart';
import 'features/sound_management/presentation/bloc/sounds_bloc.dart';

import 'features/gift_reports/data/datasources/gift_reports_remote_datasource.dart';
import 'features/gift_reports/data/repositories/gift_reports_repository_impl.dart';
import 'features/gift_reports/domain/repositories/gift_reports_repository.dart';
import 'features/gift_reports/domain/usecases/get_gift_report_detail_usecase.dart';
import 'features/gift_reports/domain/usecases/get_gift_reports_list_usecase.dart';
import 'features/gift_reports/domain/usecases/get_gift_reports_overview_usecase.dart';
import 'features/gift_reports/presentation/bloc/gift_report_detail_bloc.dart';
import 'features/gift_reports/presentation/bloc/gift_reports_bloc.dart';

import 'features/category_reports/data/datasources/category_reports_remote_datasource.dart';
import 'features/category_reports/data/repositories/category_reports_repository_impl.dart';
import 'features/category_reports/domain/repositories/category_reports_repository.dart';
import 'features/category_reports/domain/usecases/get_category_report_detail_usecase.dart';
import 'features/category_reports/domain/usecases/get_category_reports_list_usecase.dart';
import 'features/category_reports/domain/usecases/get_category_reports_overview_usecase.dart';
import 'features/category_reports/presentation/bloc/category_report_detail_bloc.dart';
import 'features/category_reports/presentation/bloc/category_reports_bloc.dart';

import 'features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'features/notifications/data/datasources/notifications_socket_service.dart';
import 'features/notifications/data/repositories/notifications_repository_impl.dart';
import 'features/notifications/domain/repositories/notifications_repository.dart';
import 'features/notifications/domain/usecases/notifications_usecases.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';
import 'features/notifications/presentation/bloc/user_notifications_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  final apiBaseUrl = ApiConfig.resolve();
  final socketBaseUrl = ApiConfig.resolveSocketBaseUrl();

  if (kDebugMode) {
    debugPrint('API base URL: $apiBaseUrl');
    debugPrint('Socket base URL: $socketBaseUrl');
  }

  // Initialise media URL resolver so relative API paths become absolute URLs
  // before they reach CachedNetworkImage / VideoPlayerController.
  MediaUrlResolver.init(apiBaseUrl);

  // =========================
  // Firebase
  // =========================
  sl.registerLazySingleton<FirebaseAuth>(
        () => FirebaseAuth.instance,
  );

  sl.registerLazySingleton<FlutterSecureStorage>(
        () => const FlutterSecureStorage(),
  );

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // =========================
  // Dio (GLOBAL API CLIENT)
  // =========================
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        // Do NOT set Content-Type here — Dio sets it automatically:
        //   • Map / JSON body  →  application/json
        //   • FormData         →  multipart/form-data; boundary=...
        // A hard-coded global value conflicts with multipart uploads in Dio 5.x.
      ),
    );

    /// 🔐 GLOBAL TOKEN INTERCEPTOR
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = ApiConfig.resolve();

          if (ApiConfig.requiresHostedApiSetup()) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                message: ApiConfig.missingConfigMessage,
              ),
            );
            return;
          }

          try {
            final user = FirebaseAuth.instance.currentUser;

            if (user != null) {
              final token = await user.getIdToken();
              options.headers['Authorization'] = 'Bearer $token';
            }

            // ngrok free tier returns an HTML interstitial unless this is set.
            final base = options.baseUrl.toLowerCase();
            final uri = options.uri.toString().toLowerCase();
            if (base.contains('ngrok') || uri.contains('ngrok')) {
              options.headers['ngrok-skip-browser-warning'] = 'true';
            }
          } catch (e) {
            debugPrint("Auth interceptor error: $e");
          }

          handler.next(options);
        },
      ),
    );

    /// 📝 REQUEST / RESPONSE LOGGER (remove in production)
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint('[Dio] $obj'),
      ),
    );

    return dio;
  });

  // =========================
  // Settings
  // =========================
  sl.registerLazySingleton<AppPreferencesLocalDataSource>(
    () => AppPreferencesLocalDataSourceImpl(sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<SettingsCubit>(
    () => SettingsCubit(sl<AppPreferencesLocalDataSource>()),
  );

  sl.registerLazySingleton<EconomySettingsRemoteDataSource>(
    () => EconomySettingsRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<EconomySettingsRepository>(
    () => EconomySettingsRepositoryImpl(sl<EconomySettingsRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetEconomySettingUseCase>(
    () => GetEconomySettingUseCase(sl<EconomySettingsRepository>()),
  );
  sl.registerLazySingleton<UpdateEconomySettingUseCase>(
    () => UpdateEconomySettingUseCase(sl<EconomySettingsRepository>()),
  );
  sl.registerFactory<EconomySettingsBloc>(
    () => EconomySettingsBloc(
      getSetting: sl<GetEconomySettingUseCase>(),
      updateSetting: sl<UpdateEconomySettingUseCase>(),
    ),
  );

  sl.registerLazySingleton<AppSettingsRemoteDataSource>(
    () => AppSettingsRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<AppSettingsRepository>(
    () => AppSettingsRepositoryImpl(sl<AppSettingsRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => ListAppSettingsUseCase(sl<AppSettingsRepository>()),
  );
  sl.registerLazySingleton(
    () => CreateAppSettingUseCase(sl<AppSettingsRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateAppSettingUseCase(sl<AppSettingsRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteAppSettingUseCase(sl<AppSettingsRepository>()),
  );
  sl.registerFactory<AppSettingsBloc>(
    () => AppSettingsBloc(
      listSettings: sl<ListAppSettingsUseCase>(),
      createSetting: sl<CreateAppSettingUseCase>(),
      updateSetting: sl<UpdateAppSettingUseCase>(),
      deleteSetting: sl<DeleteAppSettingUseCase>(),
    ),
  );

  // =========================================================
  // AUTH MODULE
  // =========================================================

  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSource(
      sl<FirebaseAuth>(),
      sl<Dio>(),
    ),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
        () => AuthLocalDataSourceImpl(sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      sl<AuthRemoteDataSource>(),
      sl<AuthLocalDataSource>(),
    ),
  );

  sl.registerLazySingleton<LoginUseCase>(
        () => LoginUseCase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<LoginWithGoogleUseCase>(
        () => LoginWithGoogleUseCase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<LogoutUseCase>(
        () => LogoutUseCase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<SaveSessionUseCase>(
        () => SaveSessionUseCase(sl<AuthRepository>()),
  );

  sl.registerFactory<LoginBloc>(
        () => LoginBloc(
      loginUseCase: sl<LoginUseCase>(),
      loginWithGoogleUseCase: sl<LoginWithGoogleUseCase>(),
      saveSessionUseCase: sl<SaveSessionUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      firebaseAuth: sl<FirebaseAuth>(),
    ),
  );

  sl.registerLazySingleton<AuthBloc>(
        () => AuthBloc(sl<AuthRepository>()),
  );

  // =========================================================
  // USERS MODULE
  // =========================================================

  sl.registerLazySingleton<UsersRemoteDataSource>(
        () => UsersRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<UsersRepository>(
        () => UsersRepositoryImpl(sl<UsersRemoteDataSource>()),
  );

  /// USE CASES
  sl.registerLazySingleton(() => GetUserById(sl<UsersRepository>()));
  sl.registerLazySingleton(() => GetUserPosts(sl<UsersRepository>()));
  sl.registerLazySingleton(() => GetUserFollowList(sl<UsersRepository>()));
  sl.registerLazySingleton(() => GetUsers(sl<UsersRepository>()));
  sl.registerLazySingleton(() => BanUser(sl<UsersRepository>()));
  sl.registerLazySingleton(() => UnbanUser(sl<UsersRepository>()));
  sl.registerLazySingleton(() => PromoteUser(sl<UsersRepository>()));
  sl.registerLazySingleton(() => DemoteUser(sl<UsersRepository>()));
  sl.registerLazySingleton(() => UpdateUserRoles(sl<UsersRepository>()));
  sl.registerLazySingleton(() => DeleteUser(sl<UsersRepository>()));
  sl.registerLazySingleton(() => BulkSuspendUsers(sl<UsersRepository>()));
  sl.registerLazySingleton(() => BulkActivateUsers(sl<UsersRepository>()));
  sl.registerLazySingleton(() => BulkDeleteUsers(sl<UsersRepository>()));
  sl.registerLazySingleton(() => BulkPromoteUsers(sl<UsersRepository>()));
  sl.registerLazySingleton(() => BulkDemoteUsers(sl<UsersRepository>()));

  /// BLOC
  sl.registerFactory(
        () => UserDetailBloc(
      getUserById: sl<GetUserById>(),
      getUserPosts: sl<GetUserPosts>(),
    ),
  );

  // =========================================================
  // USER ACTIVITY MODULE
  // =========================================================

  sl.registerLazySingleton<UserActivityRemoteDataSource>(
        () => UserActivityRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<UserActivityRepository>(
        () => UserActivityRepositoryImpl(sl<UserActivityRemoteDataSource>()),
  );

  sl.registerLazySingleton(
        () => GetUserActivityPosts(sl<UserActivityRepository>()),
  );
  sl.registerLazySingleton(
        () => GetUserActivityReposts(sl<UserActivityRepository>()),
  );
  sl.registerLazySingleton(
        () => DeleteRepostAdmin(sl<UserActivityRepository>()),
  );
  sl.registerLazySingleton(
        () => GetUserActivityAuctions(sl<UserActivityRepository>()),
  );
  sl.registerLazySingleton(
        () => GetUserActivityGifts(sl<UserActivityRepository>()),
  );
  sl.registerLazySingleton(
        () => GetUserActivityDevices(sl<UserActivityRepository>()),
  );
  sl.registerLazySingleton(
        () => GetUserComments(sl<UserActivityRepository>()),
  );
  sl.registerLazySingleton(
        () => GetUserLikes(sl<UserActivityRepository>()),
  );
  sl.registerLazySingleton(
        () => GetUserMentions(sl<UserActivityRepository>()),
  );
  sl.registerLazySingleton(
        () => GetUserActivityFeed(sl<UserActivityRepository>()),
  );

  sl.registerFactory(
        () => UserActivityBloc(
      getPosts: sl<GetUserActivityPosts>(),
      getReposts: sl<GetUserActivityReposts>(),
      getAuctions: sl<GetUserActivityAuctions>(),
      getGifts: sl<GetUserActivityGifts>(),
      getDevices: sl<GetUserActivityDevices>(),
      deleteRepostAdmin: sl<DeleteRepostAdmin>(),
    ),
  );
  sl.registerFactory(
        () => UserCommentsBloc(getUserComments: sl<GetUserComments>()),
  );
  sl.registerFactory(
        () => UserLikesBloc(getUserLikes: sl<GetUserLikes>()),
  );
  sl.registerFactory(
        () => UserMentionsBloc(getUserMentions: sl<GetUserMentions>()),
  );
  sl.registerFactory(
        () => UserUnifiedActivityBloc(
      getUserActivityFeed: sl<GetUserActivityFeed>(),
    ),
  );

  sl.registerFactory(
        () => UsersBloc(
      getUsers: sl<GetUsers>(),
      banUser: sl<BanUser>(),
      unbanUser: sl<UnbanUser>(),
      promoteUser: sl<PromoteUser>(),
      demoteUser: sl<DemoteUser>(),
      updateUserRoles: sl<UpdateUserRoles>(),
      deleteUser: sl<DeleteUser>(),
      bulkSuspendUsers: sl<BulkSuspendUsers>(),
      bulkActivateUsers: sl<BulkActivateUsers>(),
      bulkDeleteUsers: sl<BulkDeleteUsers>(),
      bulkPromoteUsers: sl<BulkPromoteUsers>(),
      bulkDemoteUsers: sl<BulkDemoteUsers>(),
    ),
  );

  // =========================================================
  // SEARCH HISTORY MODULE
  // =========================================================

  sl.registerLazySingleton<SearchHistoryRemoteDataSource>(
    () => SearchHistoryRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<SearchHistoryRepository>(
    () => SearchHistoryRepositoryImpl(sl<SearchHistoryRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => GetSearchHistoryOverviewUseCase(sl<SearchHistoryRepository>()),
  );
  sl.registerLazySingleton(
    () => GetSearchHistoryUseCase(sl<SearchHistoryRepository>()),
  );
  sl.registerLazySingleton(
    () => GetUserSearchHistoryUseCase(sl<SearchHistoryRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteSearchHistoryUseCase(sl<SearchHistoryRepository>()),
  );
  sl.registerLazySingleton(
    () => ClearSearchHistoryUseCase(sl<SearchHistoryRepository>()),
  );
  sl.registerLazySingleton(
    () => BulkSearchHistoryUseCase(sl<SearchHistoryRepository>()),
  );
  sl.registerFactory(
    () => SearchHistoryBloc(
      getOverview: sl<GetSearchHistoryOverviewUseCase>(),
      getSearchHistory: sl<GetSearchHistoryUseCase>(),
      getUserSearchHistory: sl<GetUserSearchHistoryUseCase>(),
      deleteSearchHistory: sl<DeleteSearchHistoryUseCase>(),
      clearSearchHistory: sl<ClearSearchHistoryUseCase>(),
      bulkSearchHistory: sl<BulkSearchHistoryUseCase>(),
    ),
  );

  // =========================================================
  // FILTERS & EFFECTS MODULE
  // =========================================================

  sl.registerLazySingleton<FiltersEffectsRemoteDataSource>(
    () => FiltersEffectsRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<FiltersEffectsRepository>(
    () => FiltersEffectsRepositoryImpl(sl<FiltersEffectsRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => GetFiltersEffectsOverviewUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetFiltersEffectsCatalogUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetCameraFiltersUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => CreateCameraFilterUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateCameraFilterUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteCameraFilterUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => ActivateCameraFilterUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => DeactivateCameraFilterUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetCameraFilterCategoriesUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => CreateCameraFilterCategoryUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateCameraFilterCategoryUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteCameraFilterCategoryUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => ReorderCameraFilterCategoriesUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => AssignFiltersToCategoryUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetCameraEffectsUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => CreateCameraEffectUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateCameraEffectUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteCameraEffectUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => ActivateCameraEffectUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => DeactivateCameraEffectUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetCameraEffectCategoriesUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => CreateCameraEffectCategoryUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateCameraEffectCategoryUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteCameraEffectCategoryUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => ReorderCameraEffectCategoriesUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => AssignEffectsToCategoryUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => PublishFiltersEffectsCatalogUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerLazySingleton(
    () => SeedFiltersEffectsCatalogUseCase(sl<FiltersEffectsRepository>()),
  );
  sl.registerFactory(
    () => FiltersEffectsBloc(
      getOverview: sl<GetFiltersEffectsOverviewUseCase>(),
      getCatalog: sl<GetFiltersEffectsCatalogUseCase>(),
      getFilters: sl<GetCameraFiltersUseCase>(),
      createFilter: sl<CreateCameraFilterUseCase>(),
      updateFilter: sl<UpdateCameraFilterUseCase>(),
      deleteFilter: sl<DeleteCameraFilterUseCase>(),
      activateFilter: sl<ActivateCameraFilterUseCase>(),
      deactivateFilter: sl<DeactivateCameraFilterUseCase>(),
      getFilterCategories: sl<GetCameraFilterCategoriesUseCase>(),
      createFilterCategory: sl<CreateCameraFilterCategoryUseCase>(),
      updateFilterCategory: sl<UpdateCameraFilterCategoryUseCase>(),
      deleteFilterCategory: sl<DeleteCameraFilterCategoryUseCase>(),
      reorderFilterCategories: sl<ReorderCameraFilterCategoriesUseCase>(),
      assignFiltersToCategory: sl<AssignFiltersToCategoryUseCase>(),
      getEffects: sl<GetCameraEffectsUseCase>(),
      createEffect: sl<CreateCameraEffectUseCase>(),
      updateEffect: sl<UpdateCameraEffectUseCase>(),
      deleteEffect: sl<DeleteCameraEffectUseCase>(),
      activateEffect: sl<ActivateCameraEffectUseCase>(),
      deactivateEffect: sl<DeactivateCameraEffectUseCase>(),
      getEffectCategories: sl<GetCameraEffectCategoriesUseCase>(),
      createEffectCategory: sl<CreateCameraEffectCategoryUseCase>(),
      updateEffectCategory: sl<UpdateCameraEffectCategoryUseCase>(),
      deleteEffectCategory: sl<DeleteCameraEffectCategoryUseCase>(),
      reorderEffectCategories: sl<ReorderCameraEffectCategoriesUseCase>(),
      assignEffectsToCategory: sl<AssignEffectsToCategoryUseCase>(),
      publishCatalog: sl<PublishFiltersEffectsCatalogUseCase>(),
      seedCatalog: sl<SeedFiltersEffectsCatalogUseCase>(),
    ),
  );

  // =========================================================
  // POST MANAGEMENT MODULE (admin edit/moderate user posts)
  // =========================================================

  sl.registerLazySingleton<PostManagementRemoteDataSource>(
    () => PostManagementRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<PostManagementRepository>(
    () => PostManagementRepositoryImpl(sl<PostManagementRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetManagedPostById(sl<PostManagementRepository>()));
  sl.registerLazySingleton(() => UpdateManagedPost(sl<PostManagementRepository>()));
  sl.registerLazySingleton(() => DeleteManagedPost(sl<PostManagementRepository>()));
  sl.registerLazySingleton(() => UpdatePostDetails(sl<PostManagementRepository>()));
  sl.registerLazySingleton(() => HidePost(sl<PostManagementRepository>()));
  sl.registerLazySingleton(() => BanPost(sl<PostManagementRepository>()));
  sl.registerLazySingleton(() => UpdatePostStatus(sl<PostManagementRepository>()));
  sl.registerLazySingleton(() => GetPostComments(sl<PostManagementRepository>()));
  sl.registerLazySingleton(() => DeleteCommentAdmin(sl<PostManagementRepository>()));
  sl.registerLazySingleton(() => GetPostEngagementUsers(sl<PostManagementRepository>()));

  sl.registerFactory(
    () => PostManagementBloc(
      getManagedPostById: sl<GetManagedPostById>(),
      getUserById: sl<GetUserById>(),
      updateManagedPost: sl<UpdateManagedPost>(),
      deleteManagedPost: sl<DeleteManagedPost>(),
      updatePostDetails: sl<UpdatePostDetails>(),
      hidePost: sl<HidePost>(),
      banPost: sl<BanPost>(),
      updatePostStatus: sl<UpdatePostStatus>(),
      getPostComments: sl<GetPostComments>(),
      deleteCommentAdmin: sl<DeleteCommentAdmin>(),
      getPostEngagementUsers: sl<GetPostEngagementUsers>(),
    ),
  );

  // =========================================================
  // CATEGORIES MODULE
  // =========================================================

  sl.registerLazySingleton<CategoriesRemoteDataSource>(
    () => CategoriesRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<CategoriesRepository>(
    () => CategoriesRepositoryImpl(sl<CategoriesRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetAllCategories(sl<CategoriesRepository>()));
  sl.registerLazySingleton(() => CreateCategory(sl<CategoriesRepository>()));
  sl.registerLazySingleton(() => UpdateCategory(sl<CategoriesRepository>()));
  sl.registerLazySingleton(() => DeleteCategory(sl<CategoriesRepository>()));

  sl.registerFactory(
    () => CategoriesBloc(
      getAllCategories: sl<GetAllCategories>(),
      createCategory: sl<CreateCategory>(),
      updateCategory: sl<UpdateCategory>(),
      deleteCategory: sl<DeleteCategory>(),
    ),
  );

  // =========================================================
  // POSTS MODULE (admin listing — all posts from all users)
  // =========================================================

  sl.registerLazySingleton<PostsRemoteDataSource>(
    () => PostsRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<BulkPostsRemoteDataSource>(
    () => BulkPostsRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<BulkPostRepository>(
    () => BulkPostRepositoryImpl(sl<BulkPostsRemoteDataSource>()),
  );

  sl.registerLazySingleton<PostListRepository>(
    () => PostListRepositoryImpl(sl<PostsRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetAllPosts(sl<PostListRepository>()));
  sl.registerLazySingleton(
    () => BulkPostActionUseCase(sl<BulkPostRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdatePostsStatusUseCase(sl<BulkPostActionUseCase>()),
  );
  sl.registerLazySingleton(
    () => UpdatePostsVisibilityUseCase(sl<BulkPostActionUseCase>()),
  );

  sl.registerFactory(
    () => PostsBloc(
      getAllPosts: sl<GetAllPosts>(),
      bulkPostAction: sl<BulkPostActionUseCase>(),
    ),
  );

  // =========================================================
  // STORIES MODULE (active stories on posts page)
  // =========================================================

  sl.registerLazySingleton<StoriesRemoteDataSource>(
    () => StoriesRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<StoriesRepository>(
    () => StoriesRepositoryImpl(sl<StoriesRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetActiveStories(sl<StoriesRepository>()));

  sl.registerFactory(
    () => StoriesBloc(getActiveStories: sl<GetActiveStories>()),
  );

  // =========================================================
  // CREATE POST MODULE
  // =========================================================

  sl.registerLazySingleton<CreatePostRemoteDataSource>(
    () => CreatePostRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<CreatePostAuxiliaryRemoteDataSource>(
    () => CreatePostAuxiliaryRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<CreatePostRepository>(
    () => CreatePostRepositoryImpl(
      sl<CreatePostRemoteDataSource>(),
      sl<CreatePostAuxiliaryRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton(() => UploadPostMedia(sl<CreatePostRepository>()));
  sl.registerLazySingleton(() => CreatePost(sl<CreatePostRepository>()));
  sl.registerLazySingleton(
    () => CreatePostMediaUploadService(sl<UploadPostMedia>()),
  );
  sl.registerLazySingleton(() => const CreatePostMediaFilterService());
  sl.registerLazySingleton(
    () => SearchCreatePostSounds(sl<CreatePostRepository>()),
  );
  sl.registerLazySingleton(
    () => GetTrendingCreatePostSounds(sl<CreatePostRepository>()),
  );
  sl.registerLazySingleton(
    () => UploadCreatePostSound(sl<CreatePostRepository>()),
  );
  sl.registerLazySingleton(
    () => SearchCreatePostLocations(sl<CreatePostRepository>()),
  );

  sl.registerLazySingleton<VideoThumbnailLocalDataSource>(
    () => VideoThumbnailLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<VideoThumbnailRepository>(
    () => VideoThumbnailRepositoryImpl(
      sl<VideoThumbnailLocalDataSource>(),
      sl<CreatePostRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => GenerateVideoThumbnailUseCase(sl<VideoThumbnailRepository>()),
  );
  sl.registerLazySingleton(
    () => UploadThumbnailUseCase(sl<VideoThumbnailRepository>()),
  );
  sl.registerLazySingleton(
    () => CreatePostThumbnailService(sl<GenerateVideoThumbnailUseCase>()),
  );
  sl.registerLazySingleton(
    () => SubmitCreatePost(
      uploadService: sl<CreatePostMediaUploadService>(),
      thumbnailService: sl<CreatePostThumbnailService>(),
      uploadThumbnail: sl<UploadThumbnailUseCase>(),
      createPost: sl<CreatePost>(),
      mediaFilterService: sl<CreatePostMediaFilterService>(),
    ),
  );

  sl.registerFactory(
    () => CreatePostBloc(
      uploadService: sl<CreatePostMediaUploadService>(),
      thumbnailService: sl<CreatePostThumbnailService>(),
      submitCreatePost: sl<SubmitCreatePost>(),
      mediaFilterService: sl<CreatePostMediaFilterService>(),
      searchSounds: sl<SearchCreatePostSounds>(),
      getTrendingSounds: sl<GetTrendingCreatePostSounds>(),
      uploadSound: sl<UploadCreatePostSound>(),
      searchLocations: sl<SearchCreatePostLocations>(),
    ),
  );

  // =========================================================
  // VIDEOS MODULE
  // =========================================================

  sl.registerLazySingleton<VideosRemoteDataSource>(
        () => VideosRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<VideosRepository>(
        () => VideosRepositoryImpl(sl<VideosRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetVideos(sl<VideosRepository>()));
  sl.registerLazySingleton(() => DeleteVideo(sl<VideosRepository>()));

  sl.registerFactory(
        () => VideosBloc(
      getVideos: sl<GetVideos>(),
      deleteVideo: sl<DeleteVideo>(),
    ),
  );

  // =========================================================
  // AUCTIONS MODULE
  // =========================================================

  sl.registerLazySingleton<AuctionSocketService>(
    () => AuctionSocketService(socketBaseUrl),
  );

  sl.registerLazySingleton<AuctionsRemoteDataSource>(
    () => AuctionsRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<AuctionsRepository>(
    () => AuctionsRepositoryImpl(sl<AuctionsRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetAllAuctions(sl<AuctionsRepository>()));
  sl.registerLazySingleton(() => GetAuctionDetails(sl<AuctionsRepository>()));
  sl.registerLazySingleton(() => AdminCancelAuction(sl<AuctionsRepository>()));
  sl.registerLazySingleton(() => AdminBanAuction(sl<AuctionsRepository>()));
  sl.registerLazySingleton(() => PreviewAuctionPricing(sl<AuctionsRepository>()));
  sl.registerLazySingleton(() => GetActiveAuctions(sl<AuctionsRepository>()));
  sl.registerLazySingleton(() => CreateAuction(sl<AuctionsRepository>()));
  sl.registerLazySingleton(() => HostUpdateAuction(sl<AuctionsRepository>()));
  sl.registerLazySingleton(() => HostCancelAuction(sl<AuctionsRepository>()));
  sl.registerLazySingleton(() => AdminUpdateAuction(sl<AuctionsRepository>()));
  sl.registerLazySingleton(() => AdminResolveAuction(sl<AuctionsRepository>()));

  sl.registerLazySingleton(
    () => AuctionImageLookup(sl<GetManagedPostById>(), sl<Dio>()),
  );

  sl.registerFactory(
    () => AuctionsBloc(
      getAllAuctions: sl<GetAllAuctions>(),
      cancelAuction: sl<AdminCancelAuction>(),
    ),
  );

  sl.registerFactory(
    () => AuctionDetailBloc(
      getAuctionDetails: sl<GetAuctionDetails>(),
      cancelAuction: sl<AdminCancelAuction>(),
      banAuction: sl<AdminBanAuction>(),
      updateAuction: sl<AdminUpdateAuction>(),
      resolveAuction: sl<AdminResolveAuction>(),
      previewPricing: sl<PreviewAuctionPricing>(),
      socketService: sl<AuctionSocketService>(),
    ),
  );

  // =========================================================
  // GIFTS MODULE
  // =========================================================

  sl.registerLazySingleton<GiftsRemoteDataSource>(
    () => GiftsRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<GiftsRepository>(
    () => GiftsRepositoryImpl(sl<GiftsRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetAdminGifts(sl<GiftsRepository>()));
  sl.registerLazySingleton(() => CreateGift(sl<GiftsRepository>()));
  sl.registerLazySingleton(() => UpdateGift(sl<GiftsRepository>()));
  sl.registerLazySingleton(() => DeleteGift(sl<GiftsRepository>()));
  sl.registerLazySingleton(() => BulkGiftActionUseCase(sl<GiftsRepository>()));

  sl.registerFactory(
    () => GiftsBloc(
      getAdminGifts: sl<GetAdminGifts>(),
      createGift: sl<CreateGift>(),
      updateGift: sl<UpdateGift>(),
      deleteGift: sl<DeleteGift>(),
      bulkGiftAction: sl<BulkGiftActionUseCase>(),
    ),
  );

  // =========================================================
  // WALLETS MODULE
  // =========================================================

  sl.registerLazySingleton<WalletsRemoteDataSource>(
    () => WalletsRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<WalletsRepository>(
    () => WalletsRepositoryImpl(sl<WalletsRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetEconomyUseCase(sl<WalletsRepository>()));
  sl.registerLazySingleton(
    () => GetWalletOverviewUseCase(sl<WalletsRepository>()),
  );
  sl.registerLazySingleton(() => GetWalletsUseCase(sl<WalletsRepository>()));
  sl.registerLazySingleton(() => GetWalletDetailUseCase(sl<WalletsRepository>()));
  sl.registerLazySingleton(
    () => AdjustWalletBalanceUseCase(sl<WalletsRepository>()),
  );
  sl.registerLazySingleton(() => GetLedgerUseCase(sl<WalletsRepository>()));
  sl.registerLazySingleton(
    () => GetFiatPurchasesUseCase(sl<WalletsRepository>()),
  );
  sl.registerLazySingleton(() => GetWithdrawalsUseCase(sl<WalletsRepository>()));
  sl.registerLazySingleton(() => GetCoinPackagesUseCase(sl<WalletsRepository>()));
  sl.registerLazySingleton(
    () => CreateCoinPackageUseCase(sl<WalletsRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateCoinPackageUseCase(sl<WalletsRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteCoinPackageUseCase(sl<WalletsRepository>()),
  );

  sl.registerFactory(() => EconomyBloc(getEconomy: sl<GetEconomyUseCase>()));

  sl.registerLazySingleton(
    () => LoadMoneyDashboardUseCase(
      getEconomy: sl<GetEconomyUseCase>(),
      getMonetization: sl<GetAdminMonetizationAnalytics>(),
      getGiftReportsOverview: sl<GetGiftReportsOverview>(),
      getPromotionsOverview: sl<GetPromotionsOverviewUseCase>(),
      getAuctionReportsOverview: sl<GetAuctionReportsOverview>(),
      getUserReportsOverview: sl<GetUserReportsOverview>(),
      getEconomySetting: sl<GetEconomySettingUseCase>(),
    ),
  );
  sl.registerFactoryParam<MoneyDashboardBloc, List<UserRole>, void>(
    (roles, _) => MoneyDashboardBloc(
      loadDashboard: sl<LoadMoneyDashboardUseCase>(),
      roles: roles,
    ),
  );
  sl.registerFactory(
    () => WalletOverviewBloc(getOverview: sl<GetWalletOverviewUseCase>()),
  );
  sl.registerFactory(
    () => WalletsListBloc(getWallets: sl<GetWalletsUseCase>()),
  );
  sl.registerFactory(
    () => WalletDetailBloc(
      getDetail: sl<GetWalletDetailUseCase>(),
      adjustBalance: sl<AdjustWalletBalanceUseCase>(),
    ),
  );
  sl.registerFactory(() => LedgerBloc(getLedger: sl<GetLedgerUseCase>()));
  sl.registerFactory(
    () => FiatPurchasesBloc(getPurchases: sl<GetFiatPurchasesUseCase>()),
  );
  sl.registerFactory(
    () => WithdrawalsBloc(getWithdrawals: sl<GetWithdrawalsUseCase>()),
  );
  sl.registerFactory(
    () => CoinPackagesBloc(
      getPackages: sl<GetCoinPackagesUseCase>(),
      createPackage: sl<CreateCoinPackageUseCase>(),
      updatePackage: sl<UpdateCoinPackageUseCase>(),
      deletePackage: sl<DeleteCoinPackageUseCase>(),
    ),
  );

  // =========================================================
  // PROMOTIONS MODULE
  // =========================================================

  sl.registerLazySingleton<PromotionsRemoteDataSource>(
    () => PromotionsRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<LocationIntelligenceRemoteDataSource>(
    () => LocationIntelligenceRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<PromotionsRepository>(
    () => PromotionsRepositoryImpl(sl<PromotionsRemoteDataSource>()),
  );
  sl.registerLazySingleton<LocationIntelligenceRepository>(
    () => LocationIntelligenceRepositoryImpl(
      sl<LocationIntelligenceRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton(() => GetPromotionsOverviewUseCase(sl<PromotionsRepository>()));
  sl.registerLazySingleton(() => GetCampaignsUseCase(sl<PromotionsRepository>()));
  sl.registerLazySingleton(() => GetCampaignDetailUseCase(sl<PromotionsRepository>()));
  sl.registerLazySingleton(() => GetCampaignStatsUseCase(sl<PromotionsRepository>()));
  sl.registerLazySingleton(() => GetCampaignImpressionsUseCase(sl<PromotionsRepository>()));
  sl.registerLazySingleton(() => UpdateCampaignUseCase(sl<PromotionsRepository>()));
  sl.registerLazySingleton(() => UpdateCampaignStatusUseCase(sl<PromotionsRepository>()));
  sl.registerLazySingleton(() => DeleteCampaignUseCase(sl<PromotionsRepository>()));
  sl.registerLazySingleton(() => BulkCampaignActionUseCase(sl<PromotionsRepository>()));
  sl.registerLazySingleton(() => GetPackagesUseCase(sl<PromotionsRepository>()));
  sl.registerLazySingleton(() => CreatePackageUseCase(sl<PromotionsRepository>()));
  sl.registerLazySingleton(() => UpdatePackageUseCase(sl<PromotionsRepository>()));
  sl.registerLazySingleton(() => TogglePackageStatusUseCase(sl<PromotionsRepository>()));
  sl.registerLazySingleton(
    () => GetLocationHistoryUseCase(sl<LocationIntelligenceRepository>()),
  );
  sl.registerLazySingleton(
    () => GetMovementPathUseCase(sl<LocationIntelligenceRepository>()),
  );
  sl.registerLazySingleton(() => GetPromotedPostsUseCase(sl<PromotionsRepository>()));
  sl.registerLazySingleton(
    () => GetPromotedPostDetailUseCase(sl<PromotionsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetPromotedPostStatsUseCase(sl<PromotionsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetAdminPromotedPostStatsUseCase(sl<PromotionsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetSingleCampaignStatsUseCase(sl<PromotionsRepository>()),
  );

  sl.registerFactory(
    () => PromotionsOverviewBloc(
      getOverview: sl<GetPromotionsOverviewUseCase>(),
      getCampaigns: sl<GetCampaignsUseCase>(),
    ),
  );
  sl.registerFactory(
    () => CampaignsBloc(
      getCampaigns: sl<GetCampaignsUseCase>(),
      updateStatus: sl<UpdateCampaignStatusUseCase>(),
      deleteCampaign: sl<DeleteCampaignUseCase>(),
    ),
  );
  sl.registerFactory(() => BulkActionsBloc(bulkAction: sl<BulkCampaignActionUseCase>()));
  sl.registerFactory(
    () => CampaignDetailBloc(
      getDetail: sl<GetCampaignDetailUseCase>(),
      getStats: sl<GetCampaignStatsUseCase>(),
      getImpressions: sl<GetCampaignImpressionsUseCase>(),
      updateCampaign: sl<UpdateCampaignUseCase>(),
      updateStatus: sl<UpdateCampaignStatusUseCase>(),
      deleteCampaign: sl<DeleteCampaignUseCase>(),
    ),
  );
  sl.registerFactory(
    () => PackagesBloc(
      getPackages: sl<GetPackagesUseCase>(),
      createPackage: sl<CreatePackageUseCase>(),
      updatePackage: sl<UpdatePackageUseCase>(),
      toggleStatus: sl<TogglePackageStatusUseCase>(),
    ),
  );
  sl.registerFactory(
    () => LocationIntelligenceBloc(
      getUsers: sl<GetUsers>(),
      getHistory: sl<GetLocationHistoryUseCase>(),
      getMovement: sl<GetMovementPathUseCase>(),
    ),
  );
  sl.registerFactory(
    () => PromotedPostsBloc(getPromotedPosts: sl<GetPromotedPostsUseCase>()),
  );
  sl.registerFactory(
    () => PromotedPostDetailBloc(getDetail: sl<GetPromotedPostDetailUseCase>()),
  );
  sl.registerFactory(
    () => PromotionAnalyticsBloc(
      getAdminStats: sl<GetAdminPromotedPostStatsUseCase>(),
      updateStatus: sl<UpdateCampaignStatusUseCase>(),
      getCampaignStats: sl<GetSingleCampaignStatsUseCase>(),
    ),
  );

  // =========================================================
  // SOUND MANAGEMENT MODULE
  // =========================================================

  sl.registerLazySingleton<SoundManagementRemoteDataSource>(
    () => SoundManagementRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<SoundManagementRepository>(
    () => SoundManagementRepositoryImpl(sl<SoundManagementRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetSoundOverviewUseCase(sl<SoundManagementRepository>()));
  sl.registerLazySingleton(() => GetSoundsUseCase(sl<SoundManagementRepository>()));
  sl.registerLazySingleton(() => CreateSoundUseCase(sl<SoundManagementRepository>()));
  sl.registerLazySingleton(() => UploadSoundUseCase(sl<SoundManagementRepository>()));
  sl.registerLazySingleton(() => UpdateSoundUseCase(sl<SoundManagementRepository>()));
  sl.registerLazySingleton(() => ActivateSoundUseCase(sl<SoundManagementRepository>()));
  sl.registerLazySingleton(() => DeactivateSoundUseCase(sl<SoundManagementRepository>()));
  sl.registerLazySingleton(() => DeleteSoundUseCase(sl<SoundManagementRepository>()));
  sl.registerLazySingleton(() => BulkSoundActionUseCase(sl<SoundManagementRepository>()));

  sl.registerFactory(
    () => SoundOverviewBloc(getOverview: sl<GetSoundOverviewUseCase>()),
  );
  sl.registerFactory(
    () => SoundsBloc(getSounds: sl<GetSoundsUseCase>()),
  );
  sl.registerFactory(
    () => SoundCrudBloc(
      createSound: sl<CreateSoundUseCase>(),
      uploadSound: sl<UploadSoundUseCase>(),
      updateSound: sl<UpdateSoundUseCase>(),
      deleteSound: sl<DeleteSoundUseCase>(),
      activateSound: sl<ActivateSoundUseCase>(),
      deactivateSound: sl<DeactivateSoundUseCase>(),
    ),
  );
  sl.registerFactory(
    () => BulkSoundActionBloc(bulkAction: sl<BulkSoundActionUseCase>()),
  );

  // =========================================================
  // GIFT REPORTS MODULE
  // =========================================================

  sl.registerLazySingleton<GiftReportsRemoteDataSource>(
    () => GiftReportsRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<GiftReportsRepository>(
    () => GiftReportsRepositoryImpl(sl<GiftReportsRemoteDataSource>()),
  );

  sl.registerLazySingleton(
    () => GetGiftReportsOverview(sl<GiftReportsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetGiftReportsList(sl<GiftReportsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetGiftReportDetail(sl<GiftReportsRepository>()),
  );

  sl.registerFactory(
    () => GiftReportsBloc(
      getOverview: sl<GetGiftReportsOverview>(),
      getList: sl<GetGiftReportsList>(),
    ),
  );

  sl.registerFactory(
    () => GiftReportDetailBloc(getDetail: sl<GetGiftReportDetail>()),
  );

  // =========================================================
  // CATEGORY REPORTS MODULE
  // =========================================================

  sl.registerLazySingleton<CategoryReportsRemoteDataSource>(
    () => CategoryReportsRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<CategoryReportsRepository>(
    () => CategoryReportsRepositoryImpl(sl<CategoryReportsRemoteDataSource>()),
  );

  sl.registerLazySingleton(
    () => GetCategoryReportsOverview(sl<CategoryReportsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetCategoryReportsList(sl<CategoryReportsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetCategoryReportDetail(sl<CategoryReportsRepository>()),
  );

  sl.registerFactory(
    () => CategoryReportsBloc(
      getOverview: sl<GetCategoryReportsOverview>(),
      getList: sl<GetCategoryReportsList>(),
    ),
  );

  sl.registerFactory(
    () => CategoryReportDetailBloc(getDetail: sl<GetCategoryReportDetail>()),
  );

  // =========================================================
  // REPORTS MODULE
  // =========================================================

  sl.registerLazySingleton<ReportsRemoteDataSource>(
    () => ReportsRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<ReportsRepository>(
    () => ReportsRepositoryImpl(sl<ReportsRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetReports(sl<ReportsRepository>()));
  sl.registerLazySingleton(
      () => GetReportDetails(sl<ReportsRepository>()));
  sl.registerLazySingleton(
      () => UpdateReportStatus(sl<ReportsRepository>()));

  sl.registerFactory(
    () => ReportsBloc(
      getReports: sl<GetReports>(),
      updateReportStatus: sl<UpdateReportStatus>(),
    ),
  );

  // =========================================================
  // ANALYTICS MODULE
  // =========================================================

  sl.registerLazySingleton<AnalyticsRemoteDataSource>(
    () => AnalyticsRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(sl<AnalyticsRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetAdminOverview(sl<AnalyticsRepository>()));
  sl.registerLazySingleton(
    () => GetAdminUsersAnalytics(sl<AnalyticsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetAdminPostsAnalytics(sl<AnalyticsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetAdminEngagementAnalytics(sl<AnalyticsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetAdminMonetizationAnalytics(sl<AnalyticsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetAdminAuctionsAnalytics(sl<AnalyticsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetAdminReportsAnalytics(sl<AnalyticsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetAdminCategoriesAnalytics(sl<AnalyticsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetAdminGrowthAnalytics(sl<AnalyticsRepository>()),
  );

  sl.registerFactory(
    () => AnalyticsBloc(
      getAdminOverview: sl<GetAdminOverview>(),
      getAdminUsersAnalytics: sl<GetAdminUsersAnalytics>(),
      getAdminPostsAnalytics: sl<GetAdminPostsAnalytics>(),
      getAdminEngagementAnalytics: sl<GetAdminEngagementAnalytics>(),
      getAdminMonetizationAnalytics: sl<GetAdminMonetizationAnalytics>(),
      getAdminAuctionsAnalytics: sl<GetAdminAuctionsAnalytics>(),
      getAdminReportsAnalytics: sl<GetAdminReportsAnalytics>(),
      getAdminCategoriesAnalytics: sl<GetAdminCategoriesAnalytics>(),
      getAdminGrowthAnalytics: sl<GetAdminGrowthAnalytics>(),
    ),
  );

  // =========================================================
  // NOTIFICATIONS MODULE
  // =========================================================

  sl.registerLazySingleton(
    () => NotificationsSocketService(socketBaseUrl),
  );

  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(
      remoteDataSource: sl<NotificationsRemoteDataSource>(),
      socketService: sl<NotificationsSocketService>(),
    ),
  );

  sl.registerLazySingleton(
    () => SendNotification(sl<NotificationsRepository>()),
  );
  sl.registerLazySingleton(
    () => SendBulkNotification(sl<NotificationsRepository>()),
  );
  sl.registerLazySingleton(
    () => BroadcastNotification(sl<NotificationsRepository>()),
  );
  sl.registerLazySingleton(
    () => BroadcastAdminsNotification(sl<NotificationsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetAllNotifications(sl<NotificationsRepository>()),
  );
  sl.registerLazySingleton(
    () => ScheduleNotification(sl<NotificationsRepository>()),
  );

  sl.registerFactory(
    () => NotificationsBloc(
      sendNotification: sl<SendNotification>(),
      sendBulkNotification: sl<SendBulkNotification>(),
      broadcastNotification: sl<BroadcastNotification>(),
      broadcastAdminsNotification: sl<BroadcastAdminsNotification>(),
      scheduleNotification: sl<ScheduleNotification>(),
      repository: sl<NotificationsRepository>(),
      getUsers: sl<GetUsers>(),
      getAllNotifications: sl<GetAllNotifications>(),
    ),
  );

  sl.registerFactory(
    () => UserNotificationsBloc(
      getAllNotifications: sl<GetAllNotifications>(),
    ),
  );

  // =========================================================
  // USER REPORTS MODULE
  // =========================================================

  sl.registerLazySingleton<UserReportsRemoteDataSource>(
    () => UserReportsRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<UserReportsRepository>(
    () => UserReportsRepositoryImpl(sl<UserReportsRemoteDataSource>()),
  );

  sl.registerLazySingleton(
    () => GetUserReportsOverview(sl<UserReportsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetUserReportsList(sl<UserReportsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetUserReportDetail(sl<UserReportsRepository>()),
  );

  sl.registerFactory(
    () => UserReportsBloc(
      getOverview: sl<GetUserReportsOverview>(),
      getList: sl<GetUserReportsList>(),
      getDetail: sl<GetUserReportDetail>(),
    ),
  );

  // =========================================================
  // POST REPORTS MODULE
  // =========================================================

  sl.registerLazySingleton<PostReportsRemoteDataSource>(
    () => PostReportsRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<PostReportsRepository>(
    () => PostReportsRepositoryImpl(sl<PostReportsRemoteDataSource>()),
  );

  sl.registerLazySingleton(
    () => GetPostReportsOverview(sl<PostReportsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetPostReportsList(sl<PostReportsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetPostReportDetail(sl<PostReportsRepository>()),
  );

  sl.registerLazySingleton(
    () => PostReportMediaLookup(
      sl<GetPostReportDetail>(),
      sl<Dio>(),
    ),
  );

  sl.registerFactory(
    () => PostReportsBloc(
      getPostReportsList: sl<GetPostReportsList>(),
      getPostReportsOverview: sl<GetPostReportsOverview>(),
    ),
  );

  sl.registerFactory(
    () => PostReportDetailBloc(
      getPostReportDetail: sl<GetPostReportDetail>(),
    ),
  );

  // =========================================================
  // AUCTION REPORTS MODULE
  // =========================================================

  sl.registerLazySingleton<AuctionReportsRemoteDataSource>(
    () => AuctionReportsRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<AuctionReportsRepository>(
    () => AuctionReportsRepositoryImpl(sl<AuctionReportsRemoteDataSource>()),
  );

  sl.registerLazySingleton(
    () => GetAuctionReportsOverview(sl<AuctionReportsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetAuctionReportsList(sl<AuctionReportsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetAuctionReportDetail(sl<AuctionReportsRepository>()),
  );

  sl.registerFactory(
    () => AuctionReportsBloc(
      getAuctionReportsList: sl<GetAuctionReportsList>(),
      getAuctionReportsOverview: sl<GetAuctionReportsOverview>(),
    ),
  );

  sl.registerFactory(
    () => AuctionReportDetailBloc(
      getAuctionReportDetail: sl<GetAuctionReportDetail>(),
    ),
  );

  // =========================================================
  // REPORTS CENTER OVERVIEW
  // =========================================================

  // =========================================================
  // CHAT MANAGEMENT MODULE
  // =========================================================

  sl.registerLazySingleton(
    () => ChatSocketService(socketBaseUrl),
  );

  sl.registerLazySingleton<ChatManagementRemoteDataSource>(
    () => ChatManagementRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<ChatManagementRepository>(
    () => ChatManagementRepositoryImpl(sl<ChatManagementRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetAllChats(sl<ChatManagementRepository>()));
  sl.registerLazySingleton(() => GetChatById(sl<ChatManagementRepository>()));
  sl.registerLazySingleton(() => GetChatMessages(sl<ChatManagementRepository>()));
  sl.registerLazySingleton(() => UpdateChat(sl<ChatManagementRepository>()));
  sl.registerLazySingleton(() => DeleteChat(sl<ChatManagementRepository>()));
  sl.registerLazySingleton(() => DeleteChatMessage(sl<ChatManagementRepository>()));
  sl.registerLazySingleton(() => BulkChatModeration(sl<ChatManagementRepository>()));

  sl.registerFactory(
    () => ChatManagementBloc(
      getAllChats: sl<GetAllChats>(),
      getChatById: sl<GetChatById>(),
      getChatMessages: sl<GetChatMessages>(),
      updateChat: sl<UpdateChat>(),
      deleteChat: sl<DeleteChat>(),
      deleteChatMessage: sl<DeleteChatMessage>(),
      bulkChatModeration: sl<BulkChatModeration>(),
      socketService: sl<ChatSocketService>(),
    ),
  );

  sl.registerFactory(SidebarBloc.new);

  sl.registerFactory(
    () => ReportsCenterOverviewCubit(
      getUserReportsOverview: sl<GetUserReportsOverview>(),
      getPostReportsOverview: sl<GetPostReportsOverview>(),
      getAuctionReportsOverview: sl<GetAuctionReportsOverview>(),
      getGiftReportsOverview: sl<GetGiftReportsOverview>(),
      getCategoryReportsOverview: sl<GetCategoryReportsOverview>(),
      getAdminReportsAnalytics: sl<GetAdminReportsAnalytics>(),
    ),
  );
}