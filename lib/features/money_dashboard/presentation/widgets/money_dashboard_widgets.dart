import 'package:flutter/material.dart';

import '../../../../core/utils/coin_format.dart';
import '../../../../core/widgets/dashboard/empty_state_card.dart';
import '../../../../core/widgets/dashboard/responsive_stats_grid.dart';
import '../../../auction_reports/domain/entities/auction_report_entities.dart';
import '../../../auctions/presentation/widgets/auction_card.dart';
import '../../../gift_reports/domain/entities/gift_report_entities.dart';
import '../../../user_reports/domain/entities/user_report_entities.dart';
import '../../../wallets/presentation/utils/wallets_responsive.dart';
import '../../../wallets/presentation/widgets/wallets_dashboard_widgets.dart';
import '../../../wallets/presentation/widgets/wallets_page_widgets.dart';

class MoneyDashboardMetricsBlock extends StatelessWidget {
  const MoneyDashboardMetricsBlock({
    super.key,
    required this.title,
    this.subtitle,
    required this.cards,
    required this.metrics,
  });

  final String title;
  final String? subtitle;
  final List<Widget> cards;
  final WalletsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: metrics.toolbarFilterGap),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
        ],
        SizedBox(height: metrics.sectionGap + 4),
        WalletsDashboardCard(
          padding: EdgeInsets.all(metrics.cardPadding),
          child: ResponsiveStatsGrid(
            minTileWidth: metrics.isMobile ? 160 : 200,
            children: cards,
          ),
        ),
      ],
    );
  }
}

class MoneyDashboardTopGiftsSection extends StatelessWidget {
  const MoneyDashboardTopGiftsSection({
    super.key,
    required this.gifts,
    required this.metrics,
  });

  final List<GiftReportTopGiftSummary> gifts;
  final WalletsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final top = gifts.take(8).toList();

    return MoneyDashboardDataSection(
      metrics: metrics,
      title: 'Top gifts',
      subtitle: 'Highest revenue gifts in the selected period.',
      emptyIcon: Icons.card_giftcard_outlined,
      emptyTitle: 'No top gifts yet',
      emptyMessage: 'Gift revenue leaders will appear here.',
      isEmpty: gifts.isEmpty,
      resultCount: top.length,
      child: metrics.useCompactTable
          ? _TopGiftsCompactList(gifts: top)
          : _TopGiftsDesktopTable(gifts: top),
    );
  }
}

class MoneyDashboardTopUsersSection extends StatelessWidget {
  const MoneyDashboardTopUsersSection({
    super.key,
    required this.users,
    required this.metrics,
  });

  final List<UserReportListItemEntity> users;
  final WalletsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final top = users.take(8).toList();

    return MoneyDashboardDataSection(
      metrics: metrics,
      title: 'Top users',
      subtitle: 'Users ranked by followers with wallet balance.',
      emptyIcon: Icons.people_outline,
      emptyTitle: 'No top users yet',
      emptyMessage: 'Top users by followers will appear here.',
      isEmpty: users.isEmpty,
      resultCount: top.length,
      child: metrics.useCompactTable
          ? _TopUsersCompactList(users: top)
          : _TopUsersDesktopTable(users: top),
    );
  }
}

class MoneyDashboardTopAuctionsSection extends StatelessWidget {
  const MoneyDashboardTopAuctionsSection({
    super.key,
    required this.auctions,
    required this.metrics,
  });

  final List<AuctionReportListItem> auctions;
  final WalletsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final top = auctions.take(8).toList();

    return MoneyDashboardDataSection(
      metrics: metrics,
      title: 'Top auctions',
      subtitle: 'Auctions with the highest total gift spend.',
      emptyIcon: Icons.gavel_outlined,
      emptyTitle: 'No top auctions yet',
      emptyMessage: 'Leading auctions will appear here.',
      isEmpty: auctions.isEmpty,
      resultCount: top.length,
      child: metrics.useCompactTable
          ? _TopAuctionsCompactList(auctions: top)
          : _TopAuctionsDesktopTable(auctions: top),
    );
  }
}

class MoneyDashboardDataSection extends StatelessWidget {
  const MoneyDashboardDataSection({
    super.key,
    required this.metrics,
    required this.title,
    this.subtitle,
    required this.emptyIcon,
    required this.emptyTitle,
    this.emptyMessage,
    required this.isEmpty,
    required this.resultCount,
    required this.child,
  });

  final WalletsLayoutMetrics metrics;
  final String title;
  final String? subtitle;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptyMessage;
  final bool isEmpty;
  final int resultCount;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pad = metrics.cardPadding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: metrics.toolbarFilterGap),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
        ],
        SizedBox(height: metrics.sectionGap + 4),
        WalletsDashboardCard(
          padding: isEmpty ? EdgeInsets.all(pad) : EdgeInsets.zero,
          child: isEmpty
              ? EmptyStateCard(
                  title: emptyTitle,
                  message: emptyMessage,
                  icon: emptyIcon,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, pad, pad, 8),
                      child: Text(
                        '$resultCount results',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    child,
                  ],
                ),
        ),
      ],
    );
  }
}

class _TopGiftsCompactList extends StatelessWidget {
  const _TopGiftsCompactList({required this.gifts});

  final List<GiftReportTopGiftSummary> gifts;

  @override
  Widget build(BuildContext context) {
    return WalletsCompactListFrame(
      nestedInScrollView: true,
      itemCount: gifts.length,
      itemBuilder: (context, index) {
        final gift = gifts[index];
        return WalletsCompactCard(
          leading: _GiftThumbnail(gift: gift),
          title: gift.displayName,
          subtitle: '${gift.transactions} sends',
          trailing: Text(
            CoinFormat.coins(gift.spendCoins),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        );
      },
    );
  }
}

class _TopGiftsDesktopTable extends StatelessWidget {
  const _TopGiftsDesktopTable({required this.gifts});

  final List<GiftReportTopGiftSummary> gifts;

  @override
  Widget build(BuildContext context) {
    return _MoneyDashboardStripedTable(
      header: Row(
        children: [
          Expanded(flex: 4, child: WalletsTableHeaderLabel('Gift')),
          Expanded(child: WalletsTableHeaderLabel('Sends')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Revenue')),
        ],
      ),
      rows: [
        for (var i = 0; i < gifts.length; i++)
          WalletsHoverTableRow(
            striped: i.isOdd,
            child: Row(
              children: [
                Expanded(flex: 4, child: _GiftNameCell(gift: gifts[i])),
                Expanded(
                  child: Text(
                    '${gifts[i].transactions}',
                    style: walletsTableCellStyle(context),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    CoinFormat.coins(gifts[i].spendCoins),
                    style: walletsTableCellStyle(context)?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TopUsersCompactList extends StatelessWidget {
  const _TopUsersCompactList({required this.users});

  final List<UserReportListItemEntity> users;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return WalletsCompactListFrame(
      nestedInScrollView: true,
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final name =
            user.fullName?.isNotEmpty == true ? user.fullName! : user.username;

        return WalletsCompactCard(
          leading: _UserReportAvatar(user: user),
          title: name,
          subtitle: '@${user.username} · ${user.followerCount} followers',
          trailing: Text(
            CoinFormat.coins(user.walletBalanceCoins),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
          ),
        );
      },
    );
  }
}

class _TopUsersDesktopTable extends StatelessWidget {
  const _TopUsersDesktopTable({required this.users});

  final List<UserReportListItemEntity> users;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _MoneyDashboardStripedTable(
      header: Row(
        children: [
          Expanded(flex: 4, child: WalletsTableHeaderLabel('User')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Followers')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Balance')),
        ],
      ),
      rows: [
        for (var i = 0; i < users.length; i++)
          WalletsHoverTableRow(
            striped: i.isOdd,
            child: _TopUserRow(user: users[i], scheme: scheme),
          ),
      ],
    );
  }
}

class _TopUserRow extends StatelessWidget {
  const _TopUserRow({required this.user, required this.scheme});

  final UserReportListItemEntity user;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final cellStyle = walletsTableCellStyle(context);
    final name =
        user.fullName?.isNotEmpty == true ? user.fullName! : user.username;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Row(
            children: [
              _UserReportAvatar(user: user, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cellStyle?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cellStyle?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text('${user.followerCount}', style: cellStyle),
        ),
        Expanded(
          flex: 2,
          child: Text(
            CoinFormat.coins(user.walletBalanceCoins),
            style: cellStyle?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopAuctionsCompactList extends StatelessWidget {
  const _TopAuctionsCompactList({required this.auctions});

  final List<AuctionReportListItem> auctions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return WalletsCompactListFrame(
      nestedInScrollView: true,
      itemCount: auctions.length,
      itemBuilder: (context, index) {
        final auction = auctions[index];
        return WalletsCompactCard(
          title: auction.itemName,
          subtitle: '${auction.progressPercent}% raised',
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CoinFormat.coins(auction.currentTotalCoins),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
              ),
              const SizedBox(height: 6),
              AuctionStatusBadge(status: auction.status, compact: true),
            ],
          ),
        );
      },
    );
  }
}

class _TopAuctionsDesktopTable extends StatelessWidget {
  const _TopAuctionsDesktopTable({required this.auctions});

  final List<AuctionReportListItem> auctions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _MoneyDashboardStripedTable(
      header: Row(
        children: [
          Expanded(flex: 4, child: WalletsTableHeaderLabel('Item')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Status')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Raised')),
        ],
      ),
      rows: [
        for (var i = 0; i < auctions.length; i++)
          WalletsHoverTableRow(
            striped: i.isOdd,
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    auctions[i].itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: walletsTableCellStyle(context)
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AuctionStatusBadge(status: auctions[i].status),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    CoinFormat.coins(auctions[i].currentTotalCoins),
                    style: walletsTableCellStyle(context)?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MoneyDashboardStripedTable extends StatelessWidget {
  const _MoneyDashboardStripedTable({
    required this.header,
    required this.rows,
  });

  final Widget header;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: kWalletsTableHeaderHeight,
            color: scheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: header,
          ),
          ...[
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              rows[i],
            ],
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _GiftNameCell extends StatelessWidget {
  const _GiftNameCell({required this.gift});

  final GiftReportTopGiftSummary gift;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GiftThumbnail(gift: gift),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            gift.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: walletsTableCellStyle(context)?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _GiftThumbnail extends StatelessWidget {
  const _GiftThumbnail({required this.gift, this.size = 32});

  final GiftReportTopGiftSummary gift;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thumb = gift.thumbnailUrl;

    if (thumb != null && thumb.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 4),
        child: Image.network(
          thumb,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(scheme),
        ),
      );
    }

    return _fallback(scheme);
  }

  Widget _fallback(ColorScheme scheme) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Icon(
        Icons.card_giftcard_outlined,
        size: size * 0.5,
        color: scheme.onPrimaryContainer,
      ),
    );
  }
}

class _UserReportAvatar extends StatelessWidget {
  const _UserReportAvatar({required this.user, this.size = 36});

  final UserReportListItemEntity user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = user.avatarUrl;

    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 3),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(scheme),
        ),
      );
    }

    return _fallback(scheme);
  }

  Widget _fallback(ColorScheme scheme) {
    final name =
        user.fullName?.isNotEmpty == true ? user.fullName! : user.username;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
