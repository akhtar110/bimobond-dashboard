import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'core/utils/media_url_resolver.dart';
import 'features/auth/data/datasource/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/login_with_google_usecase.dart';
import 'features/auth/presentation/bloc/login_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'features/auth/data/datasource/auth_local_data_source.dart';

import 'features/settings/presentation/bloc/settings_cubit.dart';

import 'features/users/data/datasources/users_remote_data_source.dart';
import 'features/users/data/repositories/users_repository_impl.dart';
import 'features/users/domain/repositories/users_repository.dart';
import 'features/users/domain/usecases/ban_user.dart';
import 'features/users/domain/usecases/delete_user.dart';
import 'features/users/domain/usecases/demote_user.dart';
import 'features/users/domain/usecases/get_user_by_id.dart';
import 'features/users/domain/usecases/get_user_posts.dart';
import 'features/users/domain/usecases/get_users.dart';
import 'features/users/domain/usecases/promote_to_admin.dart';
import 'features/users/domain/usecases/unban_user.dart';
import 'features/users/presentation/bloc/users_bloc.dart';
import 'features/users/presentation/bloc/user_detail_bloc.dart';

import 'features/user_activity/data/datasources/user_activity_remote_data_source.dart';
import 'features/user_activity/data/repositories/user_activity_repository_impl.dart';
import 'features/user_activity/domain/repositories/user_activity_repository.dart';
import 'features/user_activity/domain/usecases/get_user_activity_auctions.dart';
import 'features/user_activity/domain/usecases/get_user_activity_devices.dart';
import 'features/user_activity/domain/usecases/get_user_activity_feed.dart';
import 'features/user_activity/domain/usecases/get_user_activity_gifts.dart';
import 'features/user_activity/domain/usecases/get_user_activity_posts.dart';
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

import 'features/posts/data/datasources/posts_remote_data_source.dart';
import 'features/posts/data/repositories/post_repository_impl.dart';
import 'features/posts/domain/repositories/post_repository.dart';
import 'features/posts/domain/usecases/get_all_posts_usecase.dart';
import 'features/posts/presentation/bloc/posts_bloc.dart';

import 'features/create_post/data/datasources/create_post_remote_data_source.dart';
import 'features/create_post/data/repositories/create_post_repository_impl.dart';
import 'features/create_post/domain/repositories/create_post_repository.dart';
import 'features/create_post/domain/services/create_post_media_upload_service.dart';
import 'features/create_post/domain/usecases/create_post_usecase.dart';
import 'features/create_post/domain/usecases/submit_create_post_usecase.dart';
import 'features/create_post/domain/usecases/upload_post_media_usecase.dart';
import 'features/create_post/presentation/bloc/create_post_bloc.dart';

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
import 'features/auctions/domain/usecases/cancel_auction_usecase.dart';
import 'features/auctions/domain/usecases/get_all_auctions_usecase.dart';
import 'features/auctions/domain/usecases/get_auction_details_usecase.dart';
import 'features/auctions/domain/usecases/resolve_auction_usecase.dart';
import 'features/auctions/presentation/bloc/auction_detail_bloc.dart';
import 'features/auctions/presentation/bloc/auctions_bloc.dart';

import 'features/reports/data/datasources/reports_remote_datasource.dart';
import 'features/reports/data/repositories/reports_repository_impl.dart';
import 'features/reports/domain/repositories/reports_repository.dart';
import 'features/reports/domain/usecases/get_reports_usecase.dart';
import 'features/reports/domain/usecases/get_report_details_usecase.dart';
import 'features/reports/domain/usecases/update_report_status_usecase.dart';
import 'features/reports/presentation/bloc/reports_bloc.dart';

import 'features/gifts/data/datasources/gifts_remote_datasource.dart';
import 'features/gifts/data/repositories/gifts_repository_impl.dart';
import 'features/gifts/domain/repositories/gifts_repository.dart';
import 'features/gifts/domain/usecases/create_gift_usecase.dart';
import 'features/gifts/domain/usecases/delete_gift_usecase.dart';
import 'features/gifts/domain/usecases/get_admin_gifts_usecase.dart';
import 'features/gifts/domain/usecases/update_gift_usecase.dart';
import 'features/gifts/presentation/bloc/gifts_bloc.dart';

final sl = GetIt.instance;

const _apiBaseUrlFromEnv = String.fromEnvironment('API_BASE_URL');

String _resolveApiBaseUrl() {
  if (_apiBaseUrlFromEnv.isNotEmpty) {
    return _apiBaseUrlFromEnv;
  }

  // if (kIsWeb) {
  //   return Uri.base.origin;
  // }

  return 'http://192.168.1.123:3000';
}

Future<void> init() async {
  // Initialise media URL resolver so relative API paths become absolute URLs
  // before they reach CachedNetworkImage / VideoPlayerController.
  MediaUrlResolver.init(_resolveApiBaseUrl());

  // =========================
  // Firebase
  // =========================
  sl.registerLazySingleton<FirebaseAuth>(
        () => FirebaseAuth.instance,
  );

  sl.registerLazySingleton<FlutterSecureStorage>(
        () => const FlutterSecureStorage(),
  );

  // =========================
  // Dio (GLOBAL API CLIENT)
  // =========================
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _resolveApiBaseUrl(),
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
          try {
            final user = FirebaseAuth.instance.currentUser;

            if (user != null) {
              final token = await user.getIdToken();
              options.headers['Authorization'] = 'Bearer $token';
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
  sl.registerLazySingleton<SettingsCubit>(
    SettingsCubit.new,
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

  sl.registerFactory<LoginBloc>(
        () => LoginBloc(
      sl<LoginUseCase>(),
      sl<LoginWithGoogleUseCase>(),
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
  sl.registerLazySingleton(() => GetUsers(sl<UsersRepository>()));
  sl.registerLazySingleton(() => BanUser(sl<UsersRepository>()));
  sl.registerLazySingleton(() => UnbanUser(sl<UsersRepository>()));
  sl.registerLazySingleton(() => PromoteUser(sl<UsersRepository>()));
  sl.registerLazySingleton(() => DemoteUser(sl<UsersRepository>()));
  sl.registerLazySingleton(() => DeleteUser(sl<UsersRepository>()));

  /// BLOC
  sl.registerFactory(
        () => UserDetailBloc(
      getUserById: sl<GetUserById>(),
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
      getAuctions: sl<GetUserActivityAuctions>(),
      getGifts: sl<GetUserActivityGifts>(),
      getDevices: sl<GetUserActivityDevices>(),
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
      deleteUser: sl<DeleteUser>(),
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

  sl.registerFactory(
    () => PostManagementBloc(
      getManagedPostById: sl<GetManagedPostById>(),
      updateManagedPost: sl<UpdateManagedPost>(),
      deleteManagedPost: sl<DeleteManagedPost>(),
      updatePostDetails: sl<UpdatePostDetails>(),
      hidePost: sl<HidePost>(),
      banPost: sl<BanPost>(),
      updatePostStatus: sl<UpdatePostStatus>(),
      getPostComments: sl<GetPostComments>(),
      deleteCommentAdmin: sl<DeleteCommentAdmin>(),
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

  sl.registerLazySingleton<PostListRepository>(
    () => PostListRepositoryImpl(sl<PostsRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetAllPosts(sl<PostListRepository>()));

  sl.registerFactory(
    () => PostsBloc(getAllPosts: sl<GetAllPosts>()),
  );

  // =========================================================
  // CREATE POST MODULE
  // =========================================================

  sl.registerLazySingleton<CreatePostRemoteDataSource>(
    () => CreatePostRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<CreatePostRepository>(
    () => CreatePostRepositoryImpl(sl<CreatePostRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => UploadPostMedia(sl<CreatePostRepository>()));
  sl.registerLazySingleton(() => CreatePost(sl<CreatePostRepository>()));
  sl.registerLazySingleton(
    () => CreatePostMediaUploadService(sl<UploadPostMedia>()),
  );
  sl.registerLazySingleton(
    () => SubmitCreatePost(
      uploadService: sl<CreatePostMediaUploadService>(),
      createPost: sl<CreatePost>(),
    ),
  );

  sl.registerFactory(
    () => CreatePostBloc(
      uploadService: sl<CreatePostMediaUploadService>(),
      submitCreatePost: sl<SubmitCreatePost>(),
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
    () => AuctionSocketService(_resolveApiBaseUrl()),
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
  sl.registerLazySingleton(() => AdminResolveAuction(sl<AuctionsRepository>()));

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
      resolveAuction: sl<AdminResolveAuction>(),
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

  sl.registerFactory(
    () => GiftsBloc(
      getAdminGifts: sl<GetAdminGifts>(),
      createGift: sl<CreateGift>(),
      updateGift: sl<UpdateGift>(),
      deleteGift: sl<DeleteGift>(),
    ),
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
}