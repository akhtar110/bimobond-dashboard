import 'package:dio/dio.dart';
import '../../../auctions/data/models/auction_model.dart';
import '../../../auctions/domain/entities/auction_entity.dart';
import '../../../users/data/models/user_post_model.dart';
import '../../../users/domain/entities/user_post_entity.dart';
import '../../domain/entities/paginated_page.dart';
import '../../domain/entities/user_activity_item_entity.dart';
import '../../domain/entities/user_comment_entity.dart';
import '../../domain/entities/user_device_entity.dart';
import '../../domain/entities/user_gift_transaction_entity.dart';
import '../../domain/entities/user_like_entity.dart';
import '../../domain/entities/user_mention_entity.dart';
import '../models/user_activity_item_model.dart';
import '../models/user_comment_model.dart';
import '../models/user_device_model.dart';
import '../models/user_gift_transaction_model.dart';
import '../models/user_like_model.dart';
import '../models/user_mention_model.dart';
import '../models/user_repost_model.dart';
import '../../domain/entities/user_repost_entity.dart';

abstract class UserActivityRemoteDataSource {
  Future<PaginatedPage<UserPostEntity>> getUserPosts(
    String userId, {
    required int page,
    required int limit,
  });

  Future<PaginatedPage<AuctionEntity>> getUserAuctions(
    String userId, {
    required int page,
    required int limit,
    required String type,
  });

  Future<PaginatedPage<UserGiftTransactionEntity>> getUserGifts(
    String userId, {
    required int page,
    required int limit,
    required String direction,
  });

  Future<PaginatedPage<UserDeviceEntity>> getUserDevices(
    String userId, {
    required int page,
    required int limit,
  });

  /// [type] must be `'made'` (comments this user wrote) or
  /// `'received'` (comments left on this user's posts). Defaults to `'received'`.
  Future<PaginatedPage<UserCommentEntity>> getUserComments(
    String userId, {
    required int page,
    required int limit,
    String type = 'received',
  });

  /// [type] must be `'made'` (likes this user gave) or
  /// `'received'` (likes on this user's posts). Defaults to `'received'`.
  Future<PaginatedPage<UserLikeEntity>> getUserLikes(
    String userId, {
    required int page,
    required int limit,
    String type = 'received',
  });

  /// [type] must be `'made'`, `'received'`, or `'all'`. Defaults to `'received'`.
  Future<PaginatedPage<UserMentionEntity>> getUserMentions(
    String userId, {
    required int page,
    required int limit,
    String type = 'received',
  });

  Future<PaginatedPage<UserActivityItemEntity>> getUserActivityFeed(
    String userId, {
    required int page,
    required int limit,
  });

  Future<PaginatedPage<UserRepostEntity>> getUserReposts(
    String userId, {
    required int page,
    required int limit,
  });

  Future<void> deleteRepostAsAdmin(String repostId);
}

class UserActivityRemoteDataSourceImpl implements UserActivityRemoteDataSource {
  UserActivityRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PaginatedPage<UserPostEntity>> getUserPosts(
    String userId, {
    required int page,
    required int limit,
  }) async {
    final response = await _dio.get(
      '/posts/admin/all',
      queryParameters: {
        'userId': userId,
        'page': page,
        'limit': limit,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final model = UserPostsResponseModel.fromJson(data);
    return _pageFromMeta(model.data, model.meta);
  }

  @override
  Future<PaginatedPage<AuctionEntity>> getUserAuctions(
    String userId, {
    required int page,
    required int limit,
    required String type,
  }) async {
    final response = await _dio.get(
      '/users/admin/$userId/auctions',
      queryParameters: {'page': page, 'limit': limit, 'type': type},
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['auctions'] as List? ?? [])
        .map((e) => AuctionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _pageFromMeta(items, data['meta'] as Map<String, dynamic>?);
  }

  @override
  Future<PaginatedPage<UserGiftTransactionEntity>> getUserGifts(
    String userId, {
    required int page,
    required int limit,
    required String direction,
  }) async {
    final response = await _dio.get(
      '/users/admin/$userId/gifts',
      queryParameters: {
        'page': page,
        'limit': limit,
        'direction': direction,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['transactions'] as List? ?? [])
        .map(
          (e) => UserGiftTransactionModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
    return _pageFromMeta(items, data['meta'] as Map<String, dynamic>?);
  }

  @override
  Future<PaginatedPage<UserDeviceEntity>> getUserDevices(
    String userId, {
    required int page,
    required int limit,
  }) async {
    final response = await _dio.get(
      '/users/admin/$userId/devices',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['devices'] as List? ?? [])
        .map((e) => UserDeviceModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _pageFromMeta(items, data['meta'] as Map<String, dynamic>?);
  }

  @override
  Future<PaginatedPage<UserCommentEntity>> getUserComments(
    String userId, {
    required int page,
    required int limit,
    String type = 'received',
  }) async {
    final response = await _dio.get(
      '/users/$userId/comments',
      queryParameters: {'page': page, 'limit': limit, 'type': type},
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['comments'] as List? ?? [])
        .map((e) => UserCommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _pageFromMeta(items, data['meta'] as Map<String, dynamic>?);
  }

  @override
  Future<PaginatedPage<UserLikeEntity>> getUserLikes(
    String userId, {
    required int page,
    required int limit,
    String type = 'received',
  }) async {
    final response = await _dio.get(
      '/users/$userId/likes',
      queryParameters: {'page': page, 'limit': limit, 'type': type},
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['likes'] as List? ?? [])
        .map((e) => UserLikeModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _pageFromMeta(items, data['meta'] as Map<String, dynamic>?);
  }

  @override
  Future<PaginatedPage<UserMentionEntity>> getUserMentions(
    String userId, {
    required int page,
    required int limit,
    String type = 'received',
  }) async {
    final response = await _dio.get(
      '/users/$userId/mentions',
      queryParameters: {
        'page': page,
        'limit': limit,
        'type': type,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['mentions'] as List? ?? [])
        .map((e) => UserMentionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _pageFromMeta(items, data['meta'] as Map<String, dynamic>?);
  }

  @override
  Future<PaginatedPage<UserActivityItemEntity>> getUserActivityFeed(
    String userId, {
    required int page,
    required int limit,
  }) async {
    final response = await _dio.get(
      '/users/admin/$userId/activity',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['activities'] as List? ?? [])
        .map((e) => UserActivityItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _pageFromMeta(items, data['meta'] as Map<String, dynamic>?);
  }

  @override
  Future<PaginatedPage<UserRepostEntity>> getUserReposts(
    String userId, {
    required int page,
    required int limit,
  }) async {
    final response = await _dio.get(
      '/users/admin/$userId/reposts',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>? ?? {};
    return UserRepostFeedResponse.fromJson(data).toPaginatedPage();
  }

  @override
  Future<void> deleteRepostAsAdmin(String repostId) async {
    await _dio.delete('/posts/admin/reposts/$repostId');
  }

  PaginatedPage<T> _pageFromMeta<T>(
    List<T> items,
    Map<String, dynamic>? meta,
  ) {
    final m = meta ?? {};
    return PaginatedPage<T>(
      items: items,
      page: _int(m['page']) ?? 1,
      // API may return either "lastPage" or "totalPages" — accept both.
      lastPage: _int(m['lastPage']) ?? _int(m['totalPages']) ?? 1,
      total: _int(m['total']) ?? items.length,
    );
  }

  int? _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
