import 'package:flutter/material.dart';

import '../../../../core/routing/app_router.dart';
import '../../../auctions/domain/entities/auction_entity.dart';
import '../../../post_management/domain/entities/post_management_route_args.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/log_entity.dart';

enum LogTargetType {
  user,
  post,
  gift,
  auction,
  chat,
  report,
  wallet,
  category,
}

class LogNavigationTarget {
  const LogNavigationTarget({
    required this.type,
    required this.id,
    required this.labelEn,
    required this.labelAr,
    required this.icon,
    this.extras = const {},
  });

  final LogTargetType type;
  final String id;
  final String labelEn;
  final String labelAr;
  final IconData icon;
  final Map<String, dynamic> extras;

  String label(bool isArabic) => isArabic ? labelAr : labelEn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogNavigationTarget &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          id == other.id;

  @override
  int get hashCode => type.hashCode ^ id.hashCode;
}

abstract final class LogTargetNavigation {
  LogTargetNavigation._();

  static final RegExp _uuidRegex = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  );

  /// Resolves the primary navigation target for a log row.
  static LogNavigationTarget? resolve(LogEntity log) {
    final targets = resolveAll(log);
    return targets.isNotEmpty ? targets.first : null;
  }

  /// Resolves all actionable targets for chips (e.g. Open post, Open user, Open gift).
  static List<LogNavigationTarget> resolveAll(LogEntity log) {
    final results = <LogNavigationTarget>[];
    final seenKeys = <String>{};

    void addTarget(LogNavigationTarget target) {
      final key = '${target.type.name}:${target.id}';
      if (target.id.trim().isNotEmpty && seenKeys.add(key)) {
        results.add(target);
      }
    }

    final action = log.action.trim().toUpperCase();
    final targetType = log.targetType?.trim().toUpperCase();
    final targetId = log.targetId?.trim();
    final meta = log.meta ?? {};
    final raw = log.raw;

    final postId = _str(meta['postId']) ?? _str(raw['postId']);
    final commentId = _str(meta['commentId']) ?? _str(raw['commentId']);
    final giftId = _str(meta['giftId']) ?? _str(raw['giftId']);
    final receiverId = _str(meta['receiverId']) ?? _str(raw['receiverId']);
    final reportedUserId = _str(meta['reportedUserId']) ??
        _str(raw['reportedUserId']) ??
        _str(raw['targetUserId']) ??
        _str(meta['targetUserId']);
    final auctionId = _str(meta['auctionId']) ?? _str(raw['auctionId']);
    final chatId = _str(meta['chatId']) ?? _str(raw['chatId']);

    // --- Step 2 Special Action Handling ---
    if (action == 'GIFT_SEND') {
      if (postId != null && postId.isNotEmpty) addTarget(_postTarget(postId));
      if (auctionId != null && auctionId.isNotEmpty) addTarget(_auctionTarget(auctionId));
      if (receiverId != null && receiverId.isNotEmpty) addTarget(_userTarget(receiverId));
      if (giftId != null && giftId.isNotEmpty) addTarget(_giftTarget(giftId));
    } else if (action == 'REPORT_CREATE') {
      if (postId != null && postId.isNotEmpty) addTarget(_postTarget(postId));
      if (reportedUserId != null && reportedUserId.isNotEmpty) addTarget(_userTarget(reportedUserId));
      if (targetType == 'REPORT' && targetId != null && targetId.isNotEmpty) {
        addTarget(_reportTarget(targetId));
      }
    } else if (action == 'ADMIN_ACTION') {
      final path = _str(meta['path']) ?? _str(meta['routePath']) ?? '';
      final uuidMatch = _uuidRegex.firstMatch(path);
      final uuid = uuidMatch?.group(0);
      if (uuid != null && uuid.isNotEmpty) {
        if (path.contains('/users/')) addTarget(_userTarget(uuid));
        if (path.contains('/posts/')) addTarget(_postTarget(uuid));
        if (path.contains('/gifts/')) addTarget(_giftTarget(uuid));
        if (path.contains('/auctions/')) addTarget(_auctionTarget(uuid));
        if (path.contains('/reports/')) addTarget(_reportTarget(uuid));
        if (path.contains('/wallets/')) addTarget(_walletTarget(uuid));
        if (path.contains('/categories/')) addTarget(_categoryTarget(uuid));
      }
    } else if (action.startsWith('POST_')) {
      final id = (targetType == 'POST' ? targetId : null) ?? postId;
      if (id != null && id.isNotEmpty) addTarget(_postTarget(id));
    } else if (action.startsWith('COMMENT_')) {
      final pId = postId ?? (targetType == 'POST' ? targetId : null);
      final cId = commentId ?? (targetType == 'COMMENT' ? targetId : null);
      if (pId != null && pId.isNotEmpty) {
        addTarget(_postTarget(pId, commentId: cId));
      }
    } else if (_isUserAction(action)) {
      if (action != 'USER_DELETE' && action != 'DELETE') {
        final uId = (targetType == 'USER' ? targetId : null) ??
            reportedUserId ??
            (log.actorRole == 'USER' ? log.actorId : null);
        if (uId != null && uId.isNotEmpty) addTarget(_userTarget(uId));
      }
    } else if (action == 'MESSAGE_SEND') {
      final cId = chatId ?? (targetType == 'CHAT' ? targetId : null);
      if (cId != null && cId.isNotEmpty) addTarget(_chatTarget(cId));
    }

    // --- Step 1 & 3 Meta / TargetType Fallbacks ---
    if (postId != null && postId.isNotEmpty) addTarget(_postTarget(postId, commentId: commentId));
    if (auctionId != null && auctionId.isNotEmpty) addTarget(_auctionTarget(auctionId));
    if (giftId != null && giftId.isNotEmpty) addTarget(_giftTarget(giftId));
    if (chatId != null && chatId.isNotEmpty) addTarget(_chatTarget(chatId));
    if (receiverId != null && receiverId.isNotEmpty) addTarget(_userTarget(receiverId));
    if (reportedUserId != null && reportedUserId.isNotEmpty) addTarget(_userTarget(reportedUserId));

    if (targetType != null && targetId != null && targetId.isNotEmpty) {
      switch (targetType) {
        case 'POST':
          addTarget(_postTarget(targetId, commentId: commentId));
        case 'USER':
          addTarget(_userTarget(targetId));
        case 'GIFT':
          if (giftId != null && giftId.isNotEmpty) addTarget(_giftTarget(giftId));
        case 'REPORT':
          addTarget(_reportTarget(targetId));
        case 'COMMENT':
          if (postId != null && postId.isNotEmpty) {
            addTarget(_postTarget(postId, commentId: targetId));
          }
        case 'CHAT':
          addTarget(_chatTarget(targetId));
      }
    }

    // Unconditionally remove "Open report" targets ("NO THING CALLED OPEN REPORT")
    results.removeWhere((t) => t.type == LogTargetType.report);

    return results;
  }

  static bool _isUserAction(String action) {
    return const {
      'FOLLOW',
      'UNFOLLOW',
      'BLOCK_USER',
      'UNBLOCK_USER',
      'MUTE_USER',
      'UNMUTE_USER',
      'RESTRICT_USER',
      'UNRESTRICT_USER',
      'FOLLOW_REQUEST_SEND',
      'FOLLOW_REQUEST_CANCEL',
      'FOLLOW_REQUEST_ACCEPT',
      'FOLLOW_REQUEST_REJECT',
      'REMOVE_FOLLOWER',
      'PROFILE_VIEW',
      'USER_BAN',
      'USER_UNBAN',
      'USER_ADMIN_UPDATE',
      'USER_ROLES_UPDATE',
      'USER_PASSWORD_RESET_ADMIN',
      'USER_DELETE',
      'BAN',
      'UNBAN',
      'UPDATE',
      'ROLE_CHANGE',
      'RISK_LEVEL_CHANGE',
      'RESET_PASSWORD',
      'INTERNAL_NOTE',
      'DELETE',
    }.contains(action);
  }

  static LogNavigationTarget _userTarget(
    String userId, {
    String? username,
    String? fullName,
  }) =>
      LogNavigationTarget(
        type: LogTargetType.user,
        id: userId,
        labelEn: 'Open user',
        labelAr: 'فتح المستخدم',
        icon: Icons.person_outlined,
        extras: {
          if (username != null) 'username': username,
          if (fullName != null) 'fullName': fullName,
        },
      );

  static LogNavigationTarget _postTarget(String postId, {String? commentId}) =>
      LogNavigationTarget(
        type: LogTargetType.post,
        id: postId,
        labelEn: 'Open post',
        labelAr: 'فتح المنشور',
        icon: Icons.article_outlined,
        extras: {
          if (commentId != null) 'commentId': commentId,
        },
      );

  static LogNavigationTarget _giftTarget(String giftId) => LogNavigationTarget(
        type: LogTargetType.gift,
        id: giftId,
        labelEn: 'Open gift',
        labelAr: 'فتح الهدية',
        icon: Icons.card_giftcard_outlined,
      );

  static LogNavigationTarget _auctionTarget(String auctionId) =>
      LogNavigationTarget(
        type: LogTargetType.auction,
        id: auctionId,
        labelEn: 'Open auction',
        labelAr: 'فتح المزاد',
        icon: Icons.gavel_outlined,
      );

  static LogNavigationTarget _chatTarget(String chatId) => LogNavigationTarget(
        type: LogTargetType.chat,
        id: chatId,
        labelEn: 'Open chat',
        labelAr: 'فتح المحادثة',
        icon: Icons.chat_outlined,
      );

  static LogNavigationTarget _reportTarget(String reportId) => LogNavigationTarget(
        type: LogTargetType.report,
        id: reportId,
        labelEn: 'Open report',
        labelAr: 'فتح البلاغ',
        icon: Icons.report_outlined,
      );

  static LogNavigationTarget _walletTarget(String walletId) => LogNavigationTarget(
        type: LogTargetType.wallet,
        id: walletId,
        labelEn: 'Open wallet',
        labelAr: 'فتح المحفظة',
        icon: Icons.account_balance_wallet_outlined,
      );

  static LogNavigationTarget _categoryTarget(String categoryId) =>
      LogNavigationTarget(
        type: LogTargetType.category,
        id: categoryId,
        labelEn: 'Open category',
        labelAr: 'فتح القسم',
        icon: Icons.category_outlined,
      );

  /// Navigates to the resolved screen.
  static void open(BuildContext context, LogNavigationTarget target) {
    switch (target.type) {
      case LogTargetType.user:
        final user = UserEntity(
          id: target.id,
          username: target.extras['username']?.toString() ?? target.id,
          fullName: target.extras['fullName']?.toString(),
          avatarUrl: null,
          isVerified: false,
          isPrivate: false,
          allowComments: true,
          allowDirectMsgs: true,
          language: 'en',
          theme: 'light',
          followerCount: 0,
          followingCount: 0,
          postCount: 0,
          totalLikes: 0,
          isBanned: false,
          roles: const [UserRole.user],
        );
        Navigator.pushNamed(
          context,
          AppRoutes.userDetail,
          arguments: user,
        );
      case LogTargetType.post:
        final commentId = target.extras['commentId']?.toString();
        final args = PostManagementRouteArgs.fromMap({
          'postId': target.id,
          if (commentId != null) 'commentId': commentId,
          if (commentId != null) 'activity': 'comment',
        });
        Navigator.pushNamed(
          context,
          AppRoutes.postManagementDetail,
          arguments: args,
        );
      case LogTargetType.gift:
        Navigator.pushNamed(
          context,
          AppRoutes.giftReportDetail,
          arguments: target.id,
        );
      case LogTargetType.auction:
        final auction = AuctionEntity(
          id: target.id,
          hostId: '',
          startingPriceCoins: 0,
          targetPriceCoins: 0,
          currentTotalCoins: 0,
          status: 'ACTIVE',
          startedAt: DateTime.now(),
        );
        Navigator.pushNamed(
          context,
          AppRoutes.auctionDetail,
          arguments: auction,
        );
      case LogTargetType.chat:
        Navigator.pushNamed(
          context,
          AppRoutes.chatManagement,
        );
      case LogTargetType.report:
        Navigator.pushNamed(
          context,
          AppRoutes.postReportDetail,
          arguments: target.id,
        );
      case LogTargetType.wallet:
        Navigator.pushNamed(
          context,
          AppRoutes.walletDetail,
          arguments: target.id,
        );
      case LogTargetType.category:
        Navigator.pushNamed(
          context,
          AppRoutes.categoryReportDetail,
          arguments: target.id,
        );
    }
  }

  static String? _str(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }
}
