import '../../../auctions/domain/entities/auction_entity.dart';
import '../../../users/domain/entities/user_post_entity.dart';
import '../../domain/entities/paginated_page.dart';
import '../../domain/entities/user_activity_item_entity.dart';
import '../../domain/entities/user_comment_entity.dart';
import '../../domain/entities/user_device_entity.dart';
import '../../domain/entities/user_gift_transaction_entity.dart';
import '../../domain/entities/user_like_entity.dart';
import '../../domain/entities/user_mention_entity.dart';
import '../../domain/entities/user_repost_entity.dart';
import '../../domain/repositories/user_activity_repository.dart';
import '../datasources/user_activity_remote_data_source.dart';

class UserActivityRepositoryImpl implements UserActivityRepository {
  UserActivityRepositoryImpl(this._remote);

  final UserActivityRemoteDataSource _remote;

  @override
  Future<PaginatedPage<UserPostEntity>> getUserPosts(
    String userId, {
    required int page,
    required int limit,
  }) =>
      _remote.getUserPosts(userId, page: page, limit: limit);

  @override
  Future<PaginatedPage<AuctionEntity>> getUserAuctions(
    String userId, {
    required int page,
    required int limit,
    required String type,
  }) =>
      _remote.getUserAuctions(userId, page: page, limit: limit, type: type);

  @override
  Future<PaginatedPage<UserGiftTransactionEntity>> getUserGifts(
    String userId, {
    required int page,
    required int limit,
    required String direction,
  }) =>
      _remote.getUserGifts(
        userId,
        page: page,
        limit: limit,
        direction: direction,
      );

  @override
  Future<PaginatedPage<UserDeviceEntity>> getUserDevices(
    String userId, {
    required int page,
    required int limit,
  }) =>
      _remote.getUserDevices(userId, page: page, limit: limit);

  @override
  Future<PaginatedPage<UserCommentEntity>> getUserComments(
    String userId, {
    required int page,
    required int limit,
    String type = 'received',
  }) =>
      _remote.getUserComments(userId, page: page, limit: limit, type: type);

  @override
  Future<PaginatedPage<UserLikeEntity>> getUserLikes(
    String userId, {
    required int page,
    required int limit,
    String type = 'received',
  }) =>
      _remote.getUserLikes(userId, page: page, limit: limit, type: type);

  @override
  Future<PaginatedPage<UserMentionEntity>> getUserMentions(
    String userId, {
    required int page,
    required int limit,
    String type = 'received',
  }) =>
      _remote.getUserMentions(
        userId,
        page: page,
        limit: limit,
        type: type,
      );

  @override
  Future<PaginatedPage<UserActivityItemEntity>> getUserActivityFeed(
    String userId, {
    required int page,
    required int limit,
  }) =>
      _remote.getUserActivityFeed(userId, page: page, limit: limit);

  @override
  Future<PaginatedPage<UserRepostEntity>> getUserReposts(
    String userId, {
    required int page,
    required int limit,
  }) =>
      _remote.getUserReposts(userId, page: page, limit: limit);

  @override
  Future<void> deleteRepostAsAdmin(String repostId) =>
      _remote.deleteRepostAsAdmin(repostId);
}
