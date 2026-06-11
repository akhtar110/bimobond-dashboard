import 'reports_center_tab.dart';

sealed class ReportsInlineDetail {
  ReportsCenterTab get section;
}

final class UserReportsInlineDetail extends ReportsInlineDetail {
  UserReportsInlineDetail(this.userId);

  final String userId;

  @override
  ReportsCenterTab get section => ReportsCenterTab.users;
}

final class PostReportsInlineDetail extends ReportsInlineDetail {
  PostReportsInlineDetail(this.postId);

  final String postId;

  @override
  ReportsCenterTab get section => ReportsCenterTab.posts;
}

final class AuctionReportsInlineDetail extends ReportsInlineDetail {
  AuctionReportsInlineDetail(this.auctionId);

  final String auctionId;

  @override
  ReportsCenterTab get section => ReportsCenterTab.auctions;
}

final class GiftReportsInlineDetail extends ReportsInlineDetail {
  GiftReportsInlineDetail(this.giftId);

  final String giftId;

  @override
  ReportsCenterTab get section => ReportsCenterTab.gifts;
}

final class CategoryReportsInlineDetail extends ReportsInlineDetail {
  CategoryReportsInlineDetail(this.categoryId);

  final String categoryId;

  @override
  ReportsCenterTab get section => ReportsCenterTab.categories;
}
