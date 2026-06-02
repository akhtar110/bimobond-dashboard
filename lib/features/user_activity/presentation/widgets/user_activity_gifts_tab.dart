import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/localization.dart';
import '../bloc/user_activity_bloc.dart';
import 'activity_empty_state.dart';
import 'activity_filter_chips.dart';
import 'user_activity_shimmer.dart';
import 'user_gift_card.dart';

class UserActivityGiftsTab extends StatefulWidget {
  const UserActivityGiftsTab({super.key, required this.isDark});

  final bool isDark;

  @override
  State<UserActivityGiftsTab> createState() => _UserActivityGiftsTabState();
}

class _UserActivityGiftsTabState extends State<UserActivityGiftsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final bloc = context.read<UserActivityBloc>();
    if (!bloc.state.giftsLoaded) {
      bloc.add(LoadGifts());
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
    if (state.giftsHasReachedMax || state.giftsLoadingMore) return;
    bloc.add(LoadMoreGifts());
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
                selected: state.giftFilter,
                onSelected: (v) =>
                    context.read<UserActivityBloc>().add(ChangeGiftFilter(v)),
                options: [
                  (value: 'all', label: l10n.t('filterAll')),
                  (value: 'sent', label: l10n.t('sent')),
                  (value: 'received', label: l10n.t('received')),
                ],
              ),
            ),
            Expanded(child: _buildBody(state, l10n)),
          ],
        );
      },
    );
  }

  Widget _buildBody(UserActivityState state, dynamic l10n) {
    if (state.giftsLoading && state.gifts.isEmpty) {
      return UserActivityListShimmer(isDark: widget.isDark);
    }

    if (state.giftsError != null && state.gifts.isEmpty) {
      return Center(child: Text(state.giftsError!));
    }

    if (state.gifts.isEmpty) {
      return ActivityEmptyState(
        icon: Icons.card_giftcard_outlined,
        message: l10n.t('noGiftsFound'),
        isDark: widget.isDark,
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.gifts.length + (state.giftsLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= state.gifts.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return UserGiftCard(
          transaction: state.gifts[index],
          isDark: widget.isDark,
        );
      },
    );
  }
}
