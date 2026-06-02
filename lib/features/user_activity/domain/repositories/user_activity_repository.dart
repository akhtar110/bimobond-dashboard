import '../../../auctions/domain/entities/auction_entity.dart';
import '../../../users/domain/entities/user_post_entity.dart';
import '../entities/paginated_page.dart';
import '../entities/user_activity_item_entity.dart';
import '../entities/user_comment_entity.dart';
import '../entities/user_device_entity.dart';
import '../entities/user_gift_transaction_entity.dart';
import '../entities/user_like_entity.dart';
import '../entities/user_mention_entity.dart';

abstract class UserActivityRepository {
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

  Future<PaginatedPage<UserCommentEntity>> getUserComments(
    String userId, {
    required int page,
    required int limit,
  });

  Future<PaginatedPage<UserLikeEntity>> getUserLikes(
    String userId, {
    required int page,
    required int limit,
  });

  Future<PaginatedPage<UserMentionEntity>> getUserMentions(
    String userId, {
    required int page,
    required int limit,
  });

  Future<PaginatedPage<UserActivityItemEntity>> getUserActivityFeed(
    String userId, {
    required int page,
    required int limit,
  });
}
