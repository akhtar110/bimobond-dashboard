import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/gift_entity.dart';
import '../../domain/entities/gift_group_entities.dart';
import '../../domain/usecases/get_admin_gifts_usecase.dart';
import '../bloc/gift_group_gifts_cubit.dart';

class GiftGroupGiftsDialog extends StatelessWidget {
  const GiftGroupGiftsDialog({
    super.key,
    required this.groupName,
    required this.initialMembers,
  });

  final String groupName;
  final List<GiftGroupMemberEntity> initialMembers;

  static Future<List<GiftGroupMembershipItem>?> show(
    BuildContext context, {
    required String groupName,
    required List<GiftGroupMemberEntity> initialMembers,
  }) {
    return showDialog<List<GiftGroupMembershipItem>>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => GiftGroupGiftsCubit(
          getAdminGifts: di.sl<GetAdminGifts>(),
          initialMembers: initialMembers,
        )..load(),
        child: GiftGroupGiftsDialog(
          groupName: groupName,
          initialMembers: initialMembers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.tOr('giftGroupManageGiftsTitle', 'Manage gifts')),
      content: SizedBox(
        width: 520,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              groupName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            const _GiftGroupGiftsSearchField(),
            const SizedBox(height: 8),
            const _GiftGroupGiftsSelectionToolbar(),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<GiftGroupGiftsCubit, GiftGroupGiftsState>(
                buildWhen: (previous, current) =>
                    previous.loading != current.loading ||
                    previous.error != current.error ||
                    previous.available != current.available ||
                    previous.orderedIds != current.orderedIds ||
                    previous.searchQuery != current.searchQuery,
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.error != null) {
                    return Center(
                      child: Text(
                        state.error!,
                        style: TextStyle(color: scheme.error),
                      ),
                    );
                  }
                  final filtered = state.filteredAvailable;
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.tOr('noGiftsFound', 'No gifts found'),
                      ),
                    );
                  }
                  return _GiftGroupGiftsList(
                    gifts: filtered,
                    orderedIds: state.orderedIds,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('cancel')),
        ),
        BlocSelector<GiftGroupGiftsCubit, GiftGroupGiftsState, bool>(
          selector: (state) => state.loading,
          builder: (context, loading) {
            return FilledButton(
              onPressed: loading
                  ? null
                  : () {
                      final items =
                          context.read<GiftGroupGiftsCubit>().state.membershipItems;
                      Navigator.of(context).pop(items);
                    },
              child: Text(l10n.t('save')),
            );
          },
        ),
      ],
    );
  }
}

class _GiftGroupGiftsSearchField extends StatefulWidget {
  const _GiftGroupGiftsSearchField();

  @override
  State<_GiftGroupGiftsSearchField> createState() =>
      _GiftGroupGiftsSearchFieldState();
}

class _GiftGroupGiftsSearchFieldState extends State<_GiftGroupGiftsSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<GiftGroupGiftsCubit>().state.searchQuery,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      controller: _controller,
      onChanged: context.read<GiftGroupGiftsCubit>().setSearchQuery,
      decoration: InputDecoration(
        hintText: l10n.tOr('searchGifts', 'Search gifts…'),
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        isDense: true,
      ),
    );
  }
}

class _GiftGroupGiftsSelectionToolbar extends StatelessWidget {
  const _GiftGroupGiftsSelectionToolbar();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<GiftGroupGiftsCubit, GiftGroupGiftsState>(
      buildWhen: (previous, current) =>
          previous.loading != current.loading ||
          previous.orderedIds != current.orderedIds ||
          previous.available != current.available ||
          previous.searchQuery != current.searchQuery,
      builder: (context, state) {
        final cubit = context.read<GiftGroupGiftsCubit>();
        return Row(
          children: [
            Expanded(
              child: Text(
                l10n.tOr('giftGroupSelectedCount', '{count} selected')
                    .replaceAll('{count}', '${state.orderedIds.length}'),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            TextButton.icon(
              onPressed: state.loading || state.filteredAvailable.isEmpty
                  ? null
                  : cubit.selectAllFiltered,
              icon: const Icon(Icons.select_all_rounded, size: 16),
              label: Text(l10n.tOr('selectAll', 'Select all')),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: state.orderedIds.isEmpty ? null : cubit.clearAll,
              icon: const Icon(Icons.clear_all_rounded, size: 16),
              label: Text(l10n.tOr('clearAll', 'Clear all')),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GiftGroupGiftsList extends StatelessWidget {
  const _GiftGroupGiftsList({
    required this.gifts,
    required this.orderedIds,
  });

  final List<GiftEntity> gifts;
  final List<String> orderedIds;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: gifts.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final gift = gifts[index];
        final selected = orderedIds.contains(gift.id);
        final order = selected ? orderedIds.indexOf(gift.id) + 1 : null;
        return CheckboxListTile(
          value: selected,
          onChanged: (_) =>
              context.read<GiftGroupGiftsCubit>().toggleGift(gift.id),
          secondary: order != null
              ? CircleAvatar(
                  radius: 12,
                  child: Text(
                    '$order',
                    style: const TextStyle(fontSize: 11),
                  ),
                )
              : null,
          title: Text(
            gift.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('${gift.priceCoins} coins'),
        );
      },
    );
  }
}
