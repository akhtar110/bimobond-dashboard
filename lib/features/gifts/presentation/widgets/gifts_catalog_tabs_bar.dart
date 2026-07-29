import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/gift_group_entities.dart';
import '../bloc/gift_groups_bloc.dart';
import 'gift_group_form_dialog.dart';
import 'gift_group_gifts_dialog.dart';

/// Horizontally scrollable gift-group tabs with create (+) action.
class GiftsCatalogTabsBar extends StatefulWidget {
  const GiftsCatalogTabsBar({
    super.key,
    this.selectedGroupId,
    required this.onGroupSelected,
  });

  final String? selectedGroupId;
  final ValueChanged<GiftGroupEntity?> onGroupSelected;

  @override
  State<GiftsCatalogTabsBar> createState() => _GiftsCatalogTabsBarState();
}

class _GiftsCatalogTabsBarState extends State<GiftsCatalogTabsBar> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onPointerScroll(PointerScrollEvent event) {
    if (!_scrollController.hasClients) return;
    final next = (_scrollController.offset + event.scrollDelta.dy)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.jumpTo(next);
  }

  Future<void> _createTab() async {
    final result = await GiftGroupFormDialog.show(context);
    if (!mounted || result?.createData == null) return;
    context.read<GiftGroupsBloc>().add(
          CreateGiftGroupEvent(result!.createData!),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<GiftGroupsBloc, GiftGroupsState>(
      builder: (context, groupsState) {
        final groups = groupsState is GiftGroupsLoaded
            ? groupsState.groups
            : const <GiftGroupEntity>[];
        final mutating =
            groupsState is GiftGroupsLoaded && groupsState.isMutating;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Listener(
            onPointerSignal: (signal) {
              if (signal is PointerScrollEvent) _onPointerScroll(signal);
            },
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterTabChip(
                          label: l10n.tOr('giftFilterAllShort', 'All'),
                          selected: widget.selectedGroupId == null,
                          onTap: () => widget.onGroupSelected(null),
                        ),
                        if (groups.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 28,
                            color: scheme.outlineVariant,
                          ),
                          const SizedBox(width: 8),
                        ],
                        for (var i = 0; i < groups.length; i++) ...[
                          _GroupTabChip(
                            group: groups[i],
                            selected: widget.selectedGroupId == groups[i].id,
                            enabled: !mutating,
                            allGroups: groups,
                            onTap: () {
                              final group = groups[i];
                              if (widget.selectedGroupId == group.id) {
                                widget.onGroupSelected(null);
                                return;
                              }
                              widget.onGroupSelected(group);
                            },
                          ),
                          if (i < groups.length - 1) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _AddTabButton(
                  enabled: !mutating,
                  onTap: _createTab,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddTabButton extends StatelessWidget {
  const _AddTabButton({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Tooltip(
      message: l10n.tOr('giftGroupCreate', 'Create tab'),
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.add_rounded,
              size: 22,
              color: enabled
                  ? scheme.onPrimaryContainer
                  : scheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterTabChip extends StatefulWidget {
  const _FilterTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FilterTabChip> createState() => _FilterTabChipState();
}

class _FilterTabChipState extends State<_FilterTabChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary
                  : _hovered
                      ? scheme.surfaceContainerHighest
                      : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? scheme.onPrimary : scheme.onSurface,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupTabChip extends StatefulWidget {
  const _GroupTabChip({
    required this.group,
    required this.selected,
    required this.enabled,
    required this.allGroups,
    required this.onTap,
  });

  final GiftGroupEntity group;
  final bool selected;
  final bool enabled;
  final List<GiftGroupEntity> allGroups;
  final VoidCallback onTap;

  @override
  State<_GroupTabChip> createState() => _GroupTabChipState();
}

class _GroupTabChipState extends State<_GroupTabChip> {
  bool _hovered = false;

  Future<void> _onMenu(String action) async {
    final group = widget.group;
    final bloc = context.read<GiftGroupsBloc>();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    switch (action) {
      case 'edit':
      case 'rename':
        final result = await GiftGroupFormDialog.show(context, group: group);
        if (!mounted || result?.updateData == null) return;
        bloc.add(
          UpdateGiftGroupEvent(groupId: group.id, data: result!.updateData!),
        );
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.tOr('giftGroupDeleteTitle', 'Delete tab?')),
            content: Text(
              l10n.tOr(
                'giftGroupDeleteMessage',
                'Memberships are removed; catalog gifts stay available.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.t('cancel')),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.t('delete')),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
        bloc.add(DeleteGiftGroupEvent(group.id));
      case 'duplicate':
        final stamp = DateTime.now().millisecondsSinceEpoch % 100000;
        final baseSlug = group.slug.trim().isEmpty ? 'tab' : group.slug.trim();
        bloc.add(
          CreateGiftGroupEvent(
            CreateGiftGroupData(
              name: '${group.name} ${l10n.tOr('giftGroupCopySuffix', 'Copy')}',
              slug: '${baseSlug}_copy_$stamp',
              iconUrl: group.iconUrl,
              sortOrder: group.sortOrder + 1,
              isActive: group.isActive,
            ),
          ),
        );
      case 'moveUp':
      case 'moveDown':
        final groups = [...widget.allGroups];
        final index = groups.indexWhere((g) => g.id == group.id);
        if (index < 0) return;
        final target = action == 'moveUp' ? index - 1 : index + 1;
        if (target < 0 || target >= groups.length) return;
        final item = groups.removeAt(index);
        groups.insert(target, item);
        bloc.add(
          ReorderGiftGroupsEvent([
            for (var i = 0; i < groups.length; i++)
              GiftGroupReorderItem(id: groups[i].id, sortOrder: i),
          ]),
        );
      case 'viewDetails':
        final items = await GiftGroupGiftsDialog.show(
          context,
          groupName: group.name,
          initialMembers: group.gifts,
        );
        if (!mounted || items == null) return;
        bloc.add(ReplaceGroupGiftsEvent(groupId: group.id, gifts: items));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selected;
    final groups = widget.allGroups;
    final index = groups.indexWhere((g) => g.id == widget.group.id);
    final canMoveUp = index > 0;
    final canMoveDown = index >= 0 && index < groups.length - 1;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary
              : _hovered
                  ? scheme.surfaceContainerHighest
                  : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: widget.enabled ? widget.onTap : null,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(10, 7, 6, 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TabIcon(
                      iconUrl: widget.group.iconUrl,
                      selected: selected,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.group.name,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color:
                                selected ? scheme.onPrimary : scheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              enabled: widget.enabled,
              tooltip: l10n.tOr('giftGroupTabMenu', 'Tab actions'),
              padding: EdgeInsets.zero,
              onSelected: _onMenu,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(l10n.tOr('edit', 'Edit')),
                ),
                PopupMenuItem(
                  value: 'rename',
                  child: Text(l10n.tOr('giftGroupRename', 'Rename')),
                ),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Text(l10n.tOr('giftGroupDuplicate', 'Duplicate')),
                ),
                PopupMenuItem(
                  value: 'moveUp',
                  enabled: canMoveUp,
                  child: Text(l10n.tOr('giftGroupMoveUp', 'Move up')),
                ),
                PopupMenuItem(
                  value: 'moveDown',
                  enabled: canMoveDown,
                  child: Text(l10n.tOr('giftGroupMoveDown', 'Move down')),
                ),
                PopupMenuItem(
                  value: 'viewDetails',
                  child: Text(l10n.tOr('giftGroupViewDetails', 'Manage Gifts')),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    l10n.t('delete'),
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(2, 6, 10, 6),
                child: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: selected
                      ? scheme.onPrimary
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({
    required this.iconUrl,
    required this.selected,
  });

  final String? iconUrl;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolved = resolveMediaUrl(iconUrl) ?? iconUrl?.trim();
    final hasIcon = resolved != null && resolved.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 22,
        height: 22,
        color: selected
            ? scheme.onPrimary.withValues(alpha: 0.18)
            : scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: hasIcon
            ? CachedNetworkImage(
                imageUrl: resolved,
                width: 22,
                height: 22,
                fit: BoxFit.cover,
                placeholder: (context, url) => Icon(
                  Icons.category_outlined,
                  size: 14,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.category_outlined,
                  size: 14,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              )
            : Icon(
                Icons.category_outlined,
                size: 14,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
      ),
    );
  }
}
