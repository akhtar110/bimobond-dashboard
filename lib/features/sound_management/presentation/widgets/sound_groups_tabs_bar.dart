import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/sound_group_entities.dart';
import '../bloc/sound_groups_bloc.dart';
import 'sound_group_form_dialog.dart';
import 'sound_group_sounds_dialog.dart';

/// Horizontally scrollable sound-group tabs with create (+) action.
class SoundGroupsTabsBar extends StatefulWidget {
  const SoundGroupsTabsBar({
    super.key,
    this.selectedGroupId,
    required this.onGroupSelected,
  });

  final String? selectedGroupId;
  final ValueChanged<SoundGroupEntity?> onGroupSelected;

  @override
  State<SoundGroupsTabsBar> createState() => _SoundGroupsTabsBarState();
}

class _SoundGroupsTabsBarState extends State<SoundGroupsTabsBar> {
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

  Future<void> _createGroup() async {
    final result = await SoundGroupFormDialog.show(context);
    if (!mounted || result?.createData == null) return;
    context.read<SoundGroupsBloc>().add(
          CreateSoundGroupEvent(result!.createData!),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<SoundGroupsBloc, SoundGroupsState>(
      builder: (context, groupsState) {
        final groups = groupsState is SoundGroupsLoaded
            ? groupsState.groups
            : const <SoundGroupEntity>[];
        final mutating =
            groupsState is SoundGroupsLoaded && groupsState.isMutating;

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
                        _AllTabChip(
                          label: l10n.tOr('soundFilterAllSounds', 'All Sounds'),
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
                _AddGroupButton(
                  enabled: !mutating,
                  onTap: _createGroup,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddGroupButton extends StatelessWidget {
  const _AddGroupButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Tooltip(
      message: l10n.tOr('soundGroupAddTitle', 'Add group'),
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

class _AllTabChip extends StatefulWidget {
  const _AllTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AllTabChip> createState() => _AllTabChipState();
}

class _AllTabChipState extends State<_AllTabChip> {
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

  final SoundGroupEntity group;
  final bool selected;
  final bool enabled;
  final List<SoundGroupEntity> allGroups;
  final VoidCallback onTap;

  @override
  State<_GroupTabChip> createState() => _GroupTabChipState();
}

class _GroupTabChipState extends State<_GroupTabChip> {
  bool _hovered = false;

  Future<void> _onMenu(String action) async {
    final group = widget.group;
    final bloc = context.read<SoundGroupsBloc>();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    switch (action) {
      case 'edit':
      case 'rename':
        final result = await SoundGroupFormDialog.show(context, group: group);
        if (!mounted || result?.updateData == null) return;
        bloc.add(
          UpdateSoundGroupEvent(groupId: group.id, data: result!.updateData!),
        );
      case 'manage':
        final items = await SoundGroupSoundsDialog.show(
          context,
          groupName: group.name,
          initialMembers: group.sounds,
        );
        if (!mounted || items == null) return;
        bloc.add(ReplaceGroupSoundsEvent(groupId: group.id, sounds: items));
      case 'duplicate':
        final stamp = DateTime.now().millisecondsSinceEpoch % 100000;
        final baseSlug = group.slug.trim().isEmpty ? 'group' : group.slug.trim();
        bloc.add(
          CreateSoundGroupEvent(
            CreateSoundGroupData(
              name: '${group.name} ${l10n.tOr('soundGroupCopySuffix', 'Copy')}',
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
          ReorderSoundGroupsEvent([
            for (var i = 0; i < groups.length; i++)
              SoundGroupReorderItem(id: groups[i].id, sortOrder: i),
          ]),
        );
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.tOr('soundGroupDeleteTitle', 'Delete group?')),
            content: Text(
              l10n.tOr(
                'soundGroupDeleteMessage',
                'Memberships are removed; library sounds stay available.',
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
        bloc.add(DeleteSoundGroupEvent(group.id));
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
                    const SizedBox(width: 6),
                    Text(
                      '${widget.group.soundCount}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: selected
                                ? scheme.onPrimary.withValues(alpha: 0.85)
                                : scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              enabled: widget.enabled,
              tooltip: l10n.tOr('soundGroupTabMenu', 'Group actions'),
              padding: EdgeInsets.zero,
              onSelected: _onMenu,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Text(l10n.tOr('soundGroupRename', 'Rename group')),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Text(l10n.t('edit')),
                ),
                PopupMenuItem(
                  value: 'manage',
                  child: Text(
                    l10n.tOr('soundGroupManageSounds', 'Manage sounds'),
                  ),
                ),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Text(l10n.tOr('soundGroupDuplicate', 'Duplicate')),
                ),
                if (canMoveUp)
                  PopupMenuItem(
                    value: 'moveUp',
                    child: Text(l10n.tOr('soundGroupMoveUp', 'Move up')),
                  ),
                if (canMoveDown)
                  PopupMenuItem(
                    value: 'moveDown',
                    child: Text(l10n.tOr('soundGroupMoveDown', 'Move down')),
                  ),
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
                  Icons.library_music_outlined,
                  size: 14,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.library_music_outlined,
                  size: 14,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              )
            : Icon(
                Icons.library_music_outlined,
                size: 14,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
      ),
    );
  }
}
