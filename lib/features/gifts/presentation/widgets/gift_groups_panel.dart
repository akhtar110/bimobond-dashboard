import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/gift_group_entities.dart';
import '../bloc/gift_groups_bloc.dart';
import '../utils/gifts_page_layout.dart';
import 'gift_group_form_dialog.dart';
import 'gift_group_gifts_dialog.dart';

class GiftGroupsPanel extends StatelessWidget {
  const GiftGroupsPanel({super.key, required this.screenWidth});

  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final pad = giftsPageHorizontalPadding(screenWidth);

    return BlocConsumer<GiftGroupsBloc, GiftGroupsState>(
      listenWhen: (previous, current) =>
          current is GiftGroupsLoaded && current.feedbackMessage != null,
      listener: (context, state) {
        if (state is! GiftGroupsLoaded || state.feedbackMessage == null) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.tOr(state.feedbackMessage!, state.feedbackMessage!),
            ),
            backgroundColor:
                state.feedbackIsError ? scheme.error : null,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.read<GiftGroupsBloc>().add(const ClearGiftGroupsFeedbackEvent());
      },
      builder: (context, state) {
        if (state is GiftGroupsLoading) {
          return Padding(
            padding: EdgeInsets.all(pad),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state is GiftGroupsError) {
          return Padding(
            padding: EdgeInsets.all(pad),
            child: ErrorView(
              message: state.message,
              retryLabel: l10n.t('retry'),
              onRetry: () => context
                  .read<GiftGroupsBloc>()
                  .add(const LoadGiftGroupsEvent()),
            ),
          );
        }
        if (state is! GiftGroupsLoaded) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(pad, 10, pad, 0),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.tOr('giftGroupsTitle', 'Gift panel tabs'),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.t('refresh'),
                        onPressed: state.isMutating
                            ? null
                            : () => context.read<GiftGroupsBloc>().add(
                                  const LoadGiftGroupsEvent(refresh: true),
                                ),
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                      ),
                      FilledButton.icon(
                        onPressed:
                            state.isMutating ? null : () => _createGroup(context),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(l10n.tOr('giftGroupAddTitle', 'Add tab')),
                      ),
                    ],
                  ),
                ),
                if (state.isRefreshing || state.isMutating)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: LinearProgressIndicator(),
                  ),
                if (state.groups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        l10n.tOr('giftGroupsEmpty', 'No tabs yet'),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    onReorder: state.isMutating
                        ? (_, __) {}
                        : (oldIndex, newIndex) => _reorderGroups(
                              context,
                              state.groups,
                              oldIndex,
                              newIndex,
                            ),
                    itemCount: state.groups.length,
                    itemBuilder: (context, index) {
                      final group = state.groups[index];
                      return _GiftGroupTile(
                        key: ValueKey(group.id),
                        group: group,
                        index: index,
                        enabled: !state.isMutating,
                      );
                    },
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createGroup(BuildContext context) async {
    final result = await GiftGroupFormDialog.show(context);
    if (!context.mounted || result?.createData == null) return;
    context
        .read<GiftGroupsBloc>()
        .add(CreateGiftGroupEvent(result!.createData!));
  }

  void _reorderGroups(
    BuildContext context,
    List<GiftGroupEntity> groups,
    int oldIndex,
    int newIndex,
  ) {
    if (newIndex > oldIndex) newIndex -= 1;
    final reordered = [...groups];
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    final payload = [
      for (var i = 0; i < reordered.length; i++)
        GiftGroupReorderItem(id: reordered[i].id, sortOrder: i),
    ];
    context.read<GiftGroupsBloc>().add(ReorderGiftGroupsEvent(payload));
  }
}

class _GiftGroupTile extends StatelessWidget {
  const _GiftGroupTile({
    super.key,
    required this.group,
    required this.index,
    required this.enabled,
  });

  final GiftGroupEntity group;
  final int index;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          leading: ReorderableDragStartListener(
            index: index,
            enabled: enabled,
            child: Icon(
              Icons.drag_handle_rounded,
              color: enabled ? scheme.onSurfaceVariant : scheme.outline,
            ),
          ),
          title: Row(
            children: [
              _GroupIcon(iconUrl: group.iconUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  group.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${group.slug} · ${group.giftCount} ${l10n.tOr('giftGroupGiftsCount', 'gifts')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActiveChip(isActive: group.isActive),
              PopupMenuButton<String>(
                enabled: enabled,
                onSelected: (action) => _handleAction(context, action),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(l10n.t('edit')),
                  ),
                  PopupMenuItem(
                    value: 'gifts',
                    child: Text(l10n.tOr('giftGroupManageGifts', 'Manage gifts')),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      l10n.t('delete'),
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            if (group.gifts.isEmpty)
              Text(
                l10n.tOr('giftGroupNoMembers', 'No gifts in this tab'),
                style: TextStyle(color: scheme.onSurfaceVariant),
              )
            else
              for (final member in group.gifts)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(
                    width: 36,
                    height: 36,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: member.gift.thumbnailUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: Text(
                    member.gift.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${member.gift.priceCoins} coins'),
                  trailing: _ActiveChip(isActive: member.gift.isActive),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    final bloc = context.read<GiftGroupsBloc>();
    switch (action) {
      case 'edit':
        final result = await GiftGroupFormDialog.show(context, group: group);
        if (!context.mounted || result?.updateData == null) return;
        bloc.add(
          UpdateGiftGroupEvent(groupId: group.id, data: result!.updateData!),
        );
      case 'gifts':
        final items = await GiftGroupGiftsDialog.show(
          context,
          groupName: group.name,
          initialMembers: group.gifts,
        );
        if (!context.mounted || items == null) return;
        bloc.add(ReplaceGroupGiftsEvent(groupId: group.id, gifts: items));
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.l10n.tOr('giftGroupDeleteTitle', 'Delete tab?')),
            content: Text(
              context.l10n.tOr(
                'giftGroupDeleteMessage',
                'Memberships are removed; catalog gifts stay available.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(context.l10n.t('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(context.l10n.t('delete')),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        bloc.add(DeleteGiftGroupEvent(group.id));
    }
  }
}

class _GroupIcon extends StatelessWidget {
  const _GroupIcon({required this.iconUrl});

  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolved = resolveMediaUrl(iconUrl) ?? iconUrl?.trim();
    final hasIcon = resolved != null && resolved.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        color: scheme.surfaceContainerHighest,
        child: hasIcon
            ? CachedNetworkImage(
                imageUrl: resolved,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Icon(
                  Icons.category_outlined,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              )
            : Icon(
                Icons.category_outlined,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Live' : 'Hidden',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isActive
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
