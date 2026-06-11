import '../../../../core/localization/localization.dart';

/// Localized copy for Reports Center investigation / detail panels.
abstract final class ReportDetailLabels {
  ReportDetailLabels._();

  // ── Shell titles ───────────────────────────────────────────────────────────

  static String userReportTitle(AppLocalizations l10n) =>
      l10n.tOr('reportDetailUserTitle', 'User report');

  static String userReportSubtitle(AppLocalizations l10n) =>
      l10n.tOr('reportDetailUserSubtitle', 'User investigation');

  static String postReportTitle(AppLocalizations l10n) =>
      l10n.tOr('reportDetailPostTitle', 'Post report');

  static String postReportSubtitle(AppLocalizations l10n) =>
      l10n.tOr('reportDetailPostSubtitle', 'Content investigation');

  static String auctionReportTitle(AppLocalizations l10n) =>
      l10n.tOr('reportDetailAuctionTitle', 'Auction report');

  static String auctionReportSubtitle(AppLocalizations l10n) =>
      l10n.tOr('reportDetailAuctionSubtitle', 'Auction investigation');

  static String giftReportTitle(AppLocalizations l10n) =>
      l10n.tOr('reportDetailGiftTitle', 'Gift report');

  static String giftReportSubtitle(AppLocalizations l10n) =>
      l10n.tOr('reportDetailGiftSubtitle', 'Gift investigation');

  static String categoryReportTitle(AppLocalizations l10n) =>
      l10n.tOr('reportDetailCategoryTitle', 'Category report');

  static String categoryReportSubtitle(AppLocalizations l10n) =>
      l10n.tOr('reportDetailCategorySubtitle', 'Category investigation');

  static String investigationWorkspace(AppLocalizations l10n) =>
      l10n.tOr('reportDetailInvestigationWorkspace', 'Investigation workspace');

  // ── Period controls ────────────────────────────────────────────────────────

  static String period(AppLocalizations l10n) =>
      l10n.tOr('reportDetailPeriod', 'Period');

  static String periodDaysShort(AppLocalizations l10n, int days) =>
      l10n.tOr('reportDetailPeriodDaysShort', '{days}d')
          .replaceAll('{days}', '$days');

  static String lastNDays(AppLocalizations l10n, int days, {bool selected = false}) {
    final label = l10n
        .tOr('reportDetailLastNDays', 'Last {days} days')
        .replaceAll('{days}', '$days');
    return selected ? '✓ $label' : label;
  }

  // ── Shared sections / empty states ─────────────────────────────────────────

  static String wallet(AppLocalizations l10n) =>
      l10n.tOr('analyticsWallet', 'Wallet');

  static String periodActivity(AppLocalizations l10n) =>
      l10n.tOr('reportDetailPeriodActivity', 'Period activity');

  static String recentPosts(AppLocalizations l10n) =>
      l10n.tOr('reportDetailRecentPosts', 'Recent posts');

  static String topPostsInPeriod(AppLocalizations l10n) =>
      l10n.tOr('reportDetailTopPostsInPeriod', 'Top posts in period');

  static String recentGiftsSent(AppLocalizations l10n) =>
      l10n.tOr('reportDetailRecentGiftsSent', 'Recent gifts sent');

  static String recentGiftsReceived(AppLocalizations l10n) =>
      l10n.tOr('reportDetailRecentGiftsReceived', 'Recent gifts received');

  static String devicesSection(AppLocalizations l10n, int total) =>
      l10n.tOr('reportDetailDevicesCount', 'Devices ({count})')
          .replaceAll('{count}', '$total');

  static String noRecentTransactions(AppLocalizations l10n) =>
      l10n.tOr('reportDetailNoRecentTransactions', 'No recent transactions');

  static String noDevices(AppLocalizations l10n) =>
      l10n.tOr('reportDetailNoDevices', 'No devices registered');

  static String noPosts(AppLocalizations l10n) =>
      l10n.tOr('reportDetailNoPosts', 'No posts');

  static String noGiftTransactions(AppLocalizations l10n) =>
      l10n.tOr('reportDetailNoGiftTransactions', 'No gift transactions');

  static String postFallback(AppLocalizations l10n, String id) =>
      l10n.tOr('reportDetailPostFallback', 'Post {id}').replaceAll('{id}', id);

  static String giftFallback(AppLocalizations l10n, String id) =>
      l10n.tOr('reportDetailGiftFallback', 'Gift {id}').replaceAll('{id}', id);

  static String unknown(AppLocalizations l10n) =>
      l10n.tOr('reportDetailUnknown', 'Unknown');

  static String giftLabel(AppLocalizations l10n) =>
      l10n.tOr('reportDetailGiftLabel', 'Gift');

  static String viewsLikesComments(
    AppLocalizations l10n, {
    required int views,
    required int likes,
    required int comments,
  }) =>
      l10n
          .tOr(
            'reportDetailViewsLikesComments',
            '{views} views · {likes} likes · {comments} comments',
          )
          .replaceAll('{views}', '$views')
          .replaceAll('{likes}', '$likes')
          .replaceAll('{comments}', '$comments');

  // ── User metrics / profile ─────────────────────────────────────────────────

  static String giftsSent(AppLocalizations l10n) =>
      l10n.tOr('reportDetailGiftsSent', 'Gifts sent');

  static String giftsReceived(AppLocalizations l10n) =>
      l10n.tOr('reportDetailGiftsReceived', 'Gifts received');

  static String viewsAllTime(AppLocalizations l10n) =>
      l10n.tOr('reportDetailViewsAllTime', 'Views (all time)');

  static String postsInPeriod(AppLocalizations l10n) =>
      l10n.tOr('reportDetailPostsInPeriod', 'Posts in period');

  static String unreadNotifications(AppLocalizations l10n) =>
      l10n.tOr('reportDetailUnreadNotifications', 'Unread notifications');

  static String country(AppLocalizations l10n) =>
      l10n.tOr('reportDetailCountry', 'Country');

  // ── User period activity rows ──────────────────────────────────────────────

  static String postsCreated(AppLocalizations l10n) =>
      l10n.tOr('reportDetailPostsCreated', 'Posts created');

  static String commentsMade(AppLocalizations l10n) =>
      l10n.tOr('reportDetailCommentsMade', 'Comments made');

  static String likesGiven(AppLocalizations l10n) =>
      l10n.tOr('reportDetailLikesGiven', 'Likes given');

  static String repostsMade(AppLocalizations l10n) =>
      l10n.tOr('reportDetailRepostsMade', 'Reposts made');

  static String viewsOnPosts(AppLocalizations l10n) =>
      l10n.tOr('reportDetailViewsOnPosts', 'Views on posts');

  static String likesOnPosts(AppLocalizations l10n) =>
      l10n.tOr('reportDetailLikesOnPosts', 'Likes on posts');

  static String commentsOnPosts(AppLocalizations l10n) =>
      l10n.tOr('reportDetailCommentsOnPosts', 'Comments on posts');

  static String newFollowers(AppLocalizations l10n) =>
      l10n.tOr('reportDetailNewFollowers', 'New followers');

  static String auctionsHosted(AppLocalizations l10n) =>
      l10n.tOr('reportDetailAuctionsHosted', 'Auctions hosted');

  static String auctionsWon(AppLocalizations l10n) =>
      l10n.tOr('reportDetailAuctionsWon', 'Auctions won');

  // ── Post report ──────────────────────────────────────────────────────────

  static String recentComments(AppLocalizations l10n) =>
      l10n.tOr('reportDetailRecentComments', 'Recent comments');

  static String noRecentComments(AppLocalizations l10n) =>
      l10n.tOr('reportDetailNoRecentComments', 'No recent comments');

  static String recentLikes(AppLocalizations l10n) =>
      l10n.tOr('reportDetailRecentLikes', 'Recent likes');

  static String noRecentLikes(AppLocalizations l10n) =>
      l10n.tOr('reportDetailNoRecentLikes', 'No recent likes');

  static String recentGifts(AppLocalizations l10n) =>
      l10n.tOr('reportDetailRecentGifts', 'Recent gifts');

  static String noRecentGifts(AppLocalizations l10n) =>
      l10n.tOr('reportDetailNoRecentGifts', 'No recent gifts');

  static String ad(AppLocalizations l10n) =>
      l10n.tOr('reportDetailAd', 'Ad');

  static String story(AppLocalizations l10n) =>
      l10n.tOr('reportDetailStory', 'Story');

  static String auctionable(AppLocalizations l10n) =>
      l10n.tOr('reportDetailAuctionable', 'Auctionable');

  static String engagementInRange(AppLocalizations l10n) =>
      l10n.tOr('reportDetailEngagementInRange', 'Engagement in selected date range');

  static String saves(AppLocalizations l10n) =>
      l10n.tOr('reportDetailSaves', 'Saves');

  static String moderationFlags(AppLocalizations l10n) =>
      l10n.tOr('reportDetailModerationFlags', 'Moderation flags');

  static String moderationFlagsTotal(AppLocalizations l10n, int total) =>
      l10n
          .tOr('reportDetailModerationFlagsTotal', '{total} total user-submitted reports')
          .replaceAll('{total}', '$total');

  static String noModerationFlags(AppLocalizations l10n) =>
      l10n.tOr('reportDetailNoModerationFlags', 'No recent moderation flags');

  static String allTimeCount(AppLocalizations l10n, String count) =>
      l10n.tOr('reportDetailAllTimeCount', '{count} all-time')
          .replaceAll('{count}', count);

  static String moderationFlagsCount(AppLocalizations l10n, int count) =>
      l10n
          .tOr('reportDetailModerationFlagsCount', '{count} moderation flags')
          .replaceAll('{count}', '$count');

  static String savesCount(AppLocalizations l10n, String count) =>
      l10n.tOr('reportDetailSavesCount', '{count} saves')
          .replaceAll('{count}', count);

  static String giftsDuetsCount(AppLocalizations l10n, int gifts, int duets) =>
      l10n
          .tOr('reportDetailGiftsDuetsCount', '{gifts} gifts · {duets} duets')
          .replaceAll('{gifts}', '$gifts')
          .replaceAll('{duets}', '$duets');

  // ── Auction report ─────────────────────────────────────────────────────────

  static String recentBids(AppLocalizations l10n) =>
      l10n.tOr('reportDetailRecentBids', 'Recent bids');

  static String noRecentBids(AppLocalizations l10n) =>
      l10n.tOr('reportDetailNoRecentBids', 'No recent bids');

  static String targetPrice(AppLocalizations l10n, String amount) =>
      l10n.tOr('reportDetailTargetPrice', 'Target {amount}')
          .replaceAll('{amount}', amount);

  static String startPrice(AppLocalizations l10n, String amount) =>
      l10n.tOr('reportDetailStartPrice', 'Start {amount}')
          .replaceAll('{amount}', amount);

  static String winnerUser(AppLocalizations l10n, String username) =>
      l10n.tOr('reportDetailWinnerUser', 'Winner @{username}')
          .replaceAll('{username}', username);

  static String postLinked(AppLocalizations l10n) =>
      l10n.tOr('reportDetailPostLinked', 'Post linked');

  static String liveLinked(AppLocalizations l10n) =>
      l10n.tOr('reportDetailLiveLinked', 'Live linked');

  static String raised(AppLocalizations l10n) =>
      l10n.tOr('reportDetailRaised', 'Raised');

  static String remaining(AppLocalizations l10n, String amount) =>
      l10n.tOr('reportDetailRemaining', '{amount} remaining')
          .replaceAll('{amount}', amount);

  static String target(AppLocalizations l10n) =>
      l10n.tOr('reportDetailTarget', 'Target');

  static String percentComplete(AppLocalizations l10n, num percent) =>
      l10n.tOr('reportDetailPercentComplete', '{percent}% complete')
          .replaceAll('{percent}', '$percent');

  static String bids(AppLocalizations l10n) =>
      l10n.tOr('reportDetailBids', 'Bids');

  static String allTimeManualBids(AppLocalizations l10n) =>
      l10n.tOr('reportDetailAllTimeManualBids', 'All-time manual bids');

  static String giftTransactions(AppLocalizations l10n) =>
      l10n.tOr('reportDetailGiftTransactions', 'Gift transactions');

  static String auctionProgress(AppLocalizations l10n) =>
      l10n.tOr('reportDetailAuctionProgress', 'Auction progress');

  static String ofAmount(AppLocalizations l10n, String current, String target) =>
      l10n
          .tOr('reportDetailOfAmount', '{current} of {target}')
          .replaceAll('{current}', current)
          .replaceAll('{target}', target);

  static String percentToTarget(AppLocalizations l10n, num percent, String amount) =>
      l10n
          .tOr('reportDetailPercentToTarget', '{percent}% · {amount} to target')
          .replaceAll('{percent}', '$percent')
          .replaceAll('{amount}', amount);

  static String bidsAndGiftsInRange(AppLocalizations l10n) =>
      l10n.tOr('reportDetailBidsAndGiftsInRange', 'Bids and gifts in selected date range');

  static String contribution(AppLocalizations l10n) =>
      l10n.tOr('reportDetailContribution', 'Contribution');

  static String giftSpend(AppLocalizations l10n) =>
      l10n.tOr('reportDetailGiftSpend', 'Gift spend');

  static String topContributors(AppLocalizations l10n) =>
      l10n.tOr('reportDetailTopContributors', 'Top contributors');

  static String topContributorsSubtitle(AppLocalizations l10n) =>
      l10n.tOr('reportDetailTopContributorsSubtitle', 'Top senders by total contribution');

  static String noContributorsYet(AppLocalizations l10n) =>
      l10n.tOr('reportDetailNoContributorsYet', 'No contributors yet');

  static String giftsCount(AppLocalizations l10n, int count) =>
      l10n.tOr('reportDetailGiftsCount', '{count} gifts')
          .replaceAll('{count}', '$count');

  // ── Gift report ──────────────────────────────────────────────────────────

  static String allTimeSpend(AppLocalizations l10n) =>
      l10n.tOr('reportDetailAllTimeSpend', 'All-time spend');

  static String periodSends(AppLocalizations l10n, int days) =>
      l10n.tOr('reportDetailPeriodSendsDays', 'Period sends ({days} d)')
          .replaceAll('{days}', '$days');

  static String periodSpend(AppLocalizations l10n) =>
      l10n.tOr('reportDetailPeriodSpend', 'Period spend');

  static String inventoryQty(AppLocalizations l10n) =>
      l10n.tOr('reportDetailInventoryQty', 'Inventory qty');

  static String contextBreakdown(AppLocalizations l10n) =>
      l10n.tOr('reportDetailContextBreakdown', 'Context breakdown');

  static String live(AppLocalizations l10n) =>
      l10n.tOr('reportDetailLive', 'Live');

  static String direct(AppLocalizations l10n) =>
      l10n.tOr('reportDetailDirect', 'Direct');

  static String topSenders(AppLocalizations l10n) =>
      l10n.tOr('reportDetailTopSenders', 'Top senders');

  static String topReceivers(AppLocalizations l10n) =>
      l10n.tOr('reportDetailTopReceivers', 'Top receivers');

  static String noSendersYet(AppLocalizations l10n) =>
      l10n.tOr('reportDetailNoSendersYet', 'No senders yet');

  static String noReceiversYet(AppLocalizations l10n) =>
      l10n.tOr('reportDetailNoReceiversYet', 'No receivers yet');

  static String sendsCount(AppLocalizations l10n, int count) =>
      l10n.tOr('reportDetailSendsCount', '{count} sends')
          .replaceAll('{count}', '$count');

  static String receivesCount(AppLocalizations l10n, int count) =>
      l10n.tOr('reportDetailReceivesCount', '{count} receives')
          .replaceAll('{count}', '$count');

  // ── Category report ──────────────────────────────────────────────────────

  static String directPosts(AppLocalizations l10n) =>
      l10n.tOr('reportDetailDirectPosts', 'Direct posts');

  static String periodPosts(AppLocalizations l10n, int days) =>
      l10n.tOr('reportDetailPeriodPostsDays', 'Period posts ({days} d)')
          .replaceAll('{days}', '$days');

  static String subcategories(AppLocalizations l10n) =>
      l10n.tOr('reportDetailSubcategories', 'Subcategories');

  static String topPosts(AppLocalizations l10n) =>
      l10n.tOr('reportDetailTopPosts', 'Top posts');

  static String topAuthors(AppLocalizations l10n) =>
      l10n.tOr('reportDetailTopAuthors', 'Top authors');

  static String noAuthors(AppLocalizations l10n) =>
      l10n.tOr('reportDetailNoAuthors', 'No authors');

  static String viewsCount(AppLocalizations l10n, String count) =>
      l10n.tOr('reportDetailViewsCount', '{count} views')
          .replaceAll('{count}', count);

  static String postsCount(AppLocalizations l10n, int count) =>
      l10n.tOr('reportDetailPostsCount', '{count} posts')
          .replaceAll('{count}', '$count');
}
