import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../bloc/user_activity_bloc.dart';
import 'activity_empty_state.dart';
import 'activity_filter_chips.dart';
import 'user_activity_shimmer.dart';
import 'user_auction_card.dart';

class UserActivityAuctionsTab extends StatefulWidget {
  const UserActivityAuctionsTab({super.key, required this.isDark});

  final bool isDark;

  @override
  State<UserActivityAuctionsTab> createState() => _UserActivityAuctionsTabState();
}

class _UserActivityAuctionsTabState extends State<UserActivityAuctionsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final bloc = context.read<UserActivityBloc>();
    if (!bloc.state.auctionsLoaded) {
      bloc.add(LoadAuctions());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 200) return;

    final bloc = context.read<UserActivityBloc>();
    final state = bloc.state;
    if (state.auctionsHasReachedMax || state.auctionsLoadingMore) return;
    bloc.add(LoadMoreAuctions());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<UserActivityBloc, UserActivityState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: ActivityFilterChips(
                isDark: widget.isDark,
                selected: state.auctionFilter,
                onSelected: (v) =>
                    context.read<UserActivityBloc>().add(ChangeAuctionFilter(v)),
                options: [
                  (value: 'all', label: l10n.t('filterAll')),
                  (value: 'hosted', label: l10n.t('hosted')),
                  (value: 'won', label: l10n.t('won')),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(context, state, l10n),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    UserActivityState state,
    dynamic l10n,
  ) {
    if (state.auctionsLoading && state.auctions.isEmpty) {
      return UserActivityListShimmer(isDark: widget.isDark);
    }

    if (state.auctionsError != null && state.auctions.isEmpty) {
      return Center(child: Text(state.auctionsError!));
    }

    if (state.auctions.isEmpty) {
      return ActivityEmptyState(
        icon: Icons.gavel_outlined,
        message: l10n.t('noAuctionsFound'),
        isDark: widget.isDark,
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.auctions.length + (state.auctionsLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= state.auctions.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final auction = state.auctions[index];
        return UserAuctionCard(
          auction: auction,
          isDark: widget.isDark,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.auctionDetail,
            arguments: auction,
          ),
        );
      },
    );
  }
}
