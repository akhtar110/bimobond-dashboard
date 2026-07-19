import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/state_widgets.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../../../wallets/presentation/utils/wallet_labels.dart';
import '../../../wallets/presentation/utils/wallets_responsive.dart';
import '../../../wallets/presentation/widgets/wallets_dashboard_widgets.dart';
import '../../../wallets/presentation/widgets/wallets_page_widgets.dart';
import '../bloc/platform_profit_bloc.dart';
import '../widgets/platform_profit_widgets.dart';

/// Max content width on very large desktop screens so the dashboard stays
/// readable instead of stretching edge to edge.
const double _kMaxContentWidth = 1480;

class PlatformProfitPage extends StatelessWidget {
  const PlatformProfitPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);

    return BlocBuilder<PlatformProfitBloc, PlatformProfitState>(
      builder: (context, state) {
        if (state is PlatformProfitLoading || state is PlatformProfitInitial) {
          return const WalletsDashboardShell(child: LoadingView());
        }
        if (state is PlatformProfitError) {
          return WalletsDashboardShell(
            child: ErrorView(
              message: state.message,
              retryLabel: walletL10nOr(context, 'retry', 'Retry'),
              onRetry: () => context
                  .read<PlatformProfitBloc>()
                  .add(const LoadPlatformProfit()),
            ),
          );
        }
        if (state is! PlatformProfitLoaded) return const SizedBox.shrink();
        return _PlatformProfitBody(state: state);
      },
    );
  }
}

class _PlatformProfitBody extends StatelessWidget {
  const _PlatformProfitBody({required this.state});

  final PlatformProfitLoaded state;

  @override
  Widget build(BuildContext context) {
    final metrics = walletsMetricsOf(context);
    final design = profitDesignOf(context);
    final data = state.data;

    Widget constrain(Widget child) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
            child: child,
          ),
        );

    final sections = <Widget>[
      if (data.giftRevenue != null || data.promotionRevenue != null)
        PlatformRevenueSummarySection(data: data),
      if (data.monetization != null)
        MonetizationAnalyticsSection(
          monetization: data.monetization!,
          coinsPerPriceUnit: data.coinsPerPriceUnit,
          breakdownData: data,
        ),
      if (data.giftRevenue != null)
        GiftRevenueSection(
          giftRevenue: data.giftRevenue!,
          coinsPerPriceUnit: data.coinsPerPriceUnit,
        ),
      if (data.promotionRevenue != null)
        PromotionRevenueSection(
          promotionRevenue: data.promotionRevenue!,
          coinsPerPriceUnit: data.coinsPerPriceUnit,
        ),
      if (data.monetization != null)
        PlatformLedgerSection(
          entries: data.monetization!.accountingByType,
          coinsPerPriceUnit: data.coinsPerPriceUnit,
        ),
    ];

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                metrics.pageHorizontalPadding,
                metrics.pageTopPadding,
                metrics.pageHorizontalPadding,
                design.sectionGap * 0.5,
              ),
              sliver: SliverToBoxAdapter(
                child: constrain(
                  _FadeIn(
                    child: WalletsPageHeader(
                      metrics: metrics,
                      title: walletL10nOr(context,
                        'walletProfitTitle',
                        'Platform Profit & Revenue',
                      ),
                      subtitle: walletL10nOr(context,
                        'walletProfitSubtitle',
                        'Platform earnings from gift commission, promotions, and fiat purchases.',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyFiltersDelegate(
                horizontalPadding: metrics.pageHorizontalPadding,
                barHeight: design.isMobile ? 50 : 56,
                child: constrain(
                  PlatformProfitFiltersBar(
                    preset: state.preset,
                    query: state.query,
                    refreshing: state.isRefreshing,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                metrics.pageHorizontalPadding,
                design.sectionGap * 0.75,
                metrics.pageHorizontalPadding,
                metrics.pageBottomPadding + design.sectionGap,
              ),
              sliver: SliverList.separated(
                itemCount: sections.length,
                separatorBuilder: (_, _) =>
                    SizedBox(height: design.sectionGap),
                itemBuilder: (context, index) => constrain(
                  _FadeIn(
                    delayMs: 60 * (index + 1),
                    child: sections[index],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (state.isRefreshing)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

/// Keeps the filters bar visible while the dashboard scrolls.
class _StickyFiltersDelegate extends SliverPersistentHeaderDelegate {
  const _StickyFiltersDelegate({
    required this.child,
    required this.barHeight,
    required this.horizontalPadding,
  });

  final Widget child;
  final double barHeight;
  final double horizontalPadding;

  double get _extent => barHeight + 12;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerLowest,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          6,
          horizontalPadding,
          6,
        ),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyFiltersDelegate oldDelegate) {
    return child != oldDelegate.child ||
        barHeight != oldDelegate.barHeight ||
        horizontalPadding != oldDelegate.horizontalPadding;
  }
}

/// Subtle one-shot fade/slide-in used for section reveal.
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child, this.delayMs = 0});

  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delayMs),
      curve: Interval(
        (delayMs / (320 + delayMs)).clamp(0.0, 0.9),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 10),
          child: c,
        ),
      ),
      child: child,
    );
  }
}
