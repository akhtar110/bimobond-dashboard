import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/sound_group_entities.dart';
import '../../../promotions/presentation/widgets/promotions_dashboard_widgets.dart';
import '../bloc/sound_groups_bloc.dart';
import 'sound_group_form_dialog.dart';
import 'sound_group_sounds_dialog.dart';
import 'sound_preview_widgets.dart';

class SoundGroupsPanel extends StatelessWidget {
  const SoundGroupsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<SoundGroupsBloc, SoundGroupsState>(
      listenWhen: (previous, current) =>
          current is SoundGroupsLoaded && current.feedbackMessage != null,
      listener: (context, state) {
        if (state is! SoundGroupsLoaded || state.feedbackMessage == null) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.tOr(state.feedbackMessage!, state.feedbackMessage!),
            ),
            backgroundColor:
                state.feedbackIsError ? Theme.of(context).colorScheme.error : null,
          ),
        );
        context.read<SoundGroupsBloc>().add(const ClearSoundGroupsFeedbackEvent());
      },
      builder: (context, state) {
        if (state is SoundGroupsLoading) {
          return const Padding(
            padding: EdgeInsets.all(PromotionsSpace.xl),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is SoundGroupsError) {
          return Padding(
            padding: const EdgeInsets.all(PromotionsSpace.xl),
            child: ErrorView(
              message: state.message,
              retryLabel: l10n.t('retry'),
              onRetry: () => context
                  .read<SoundGroupsBloc>()
                  .add(const LoadSoundGroupsEvent()),
            ),
          );
        }
        if (state is! SoundGroupsLoaded) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PromotionsSpace.md,
                PromotionsSpace.md,
                PromotionsSpace.md,
                PromotionsSpace.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.tOr('soundGroupsTitle', 'Library shelves'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.t('refresh'),
                    onPressed: state.isMutating
                        ? null
                        : () => context
                            .read<SoundGroupsBloc>()
                            .add(const LoadSoundGroupsEvent(refresh: true)),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                  ),
                  FilledButton.icon(
                    onPressed: state.isMutating ? null : () => _createGroup(context),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.tOr('soundGroupAddTitle', 'Add group')),
                  ),
                ],
              ),
            ),
            if (state.isRefreshing || state.isMutating)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  PromotionsSpace.md,
                  0,
                  PromotionsSpace.md,
                  PromotionsSpace.sm,
                ),
                child: LinearProgressIndicator(),
              ),
            if (state.groups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    l10n.tOr('soundGroupsEmpty', 'No shelves yet'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
                    : (oldIndex, newIndex) =>
                        _reorderGroups(context, state.groups, oldIndex, newIndex),
                itemCount: state.groups.length,
                itemBuilder: (context, index) {
                  final group = state.groups[index];
                  return _SoundGroupTile(
                    key: ValueKey(group.id),
                    group: group,
                    index: index,
                    enabled: !state.isMutating,
                  );
                },
              ),
            const SizedBox(height: PromotionsSpace.md),
          ],
        );
      },
    );
  }

  Future<void> _createGroup(BuildContext context) async {
    final result = await SoundGroupFormDialog.show(context);
    if (!context.mounted || result?.createData == null) return;
    context
        .read<SoundGroupsBloc>()
        .add(CreateSoundGroupEvent(result!.createData!));
  }

  void _reorderGroups(
    BuildContext context,
    List<SoundGroupEntity> groups,
    int oldIndex,
    int newIndex,
  ) {
    if (newIndex > oldIndex) newIndex -= 1;
    final reordered = [...groups];
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    final payload = [
      for (var i = 0; i < reordered.length; i++)
        SoundGroupReorderItem(id: reordered[i].id, sortOrder: i),
    ];
    context.read<SoundGroupsBloc>().add(ReorderSoundGroupsEvent(payload));
  }
}

class _SoundGroupTile extends StatelessWidget {
  const _SoundGroupTile({
    super.key,
    required this.group,
    required this.index,
    required this.enabled,
  });

  final SoundGroupEntity group;
  final int index;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PromotionsSpace.md,
        vertical: PromotionsSpace.sm,
      ),
      child: DashboardCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: PromotionsSpace.md),
          childrenPadding: const EdgeInsets.fromLTRB(
            PromotionsSpace.md,
            0,
            PromotionsSpace.md,
            PromotionsSpace.sm,
          ),
          leading: ReorderableDragStartListener(
            index: index,
            enabled: enabled,
            child: Icon(
              Icons.drag_handle_rounded,
              color: enabled ? scheme.onSurfaceVariant : scheme.outline,
            ),
          ),
          title: Text(
            group.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${group.slug} · ${group.soundCount} ${l10n.tOr('soundGroupSoundsCount', 'sounds')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SoundStatusBadge(isActive: group.isActive),
              PopupMenuButton<String>(
                enabled: enabled,
                onSelected: (action) => _handleAction(context, action),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(l10n.t('edit')),
                  ),
                  PopupMenuItem(
                    value: 'sounds',
                    child: Text(l10n.tOr('soundGroupManageSounds', 'Manage sounds')),
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
            if (group.sounds.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: PromotionsSpace.sm),
                child: Text(
                  l10n.tOr('soundGroupNoMembers', 'No sounds in this shelf'),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              )
            else
              for (final member in group.sounds)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text('#${member.sortOrder + 1}'),
                  title: Text(
                    member.sound.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(member.sound.author),
                  trailing: SoundStatusBadge(isActive: member.sound.isActive),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    final bloc = context.read<SoundGroupsBloc>();
    switch (action) {
      case 'edit':
        final result = await SoundGroupFormDialog.show(context, group: group);
        if (!context.mounted || result?.updateData == null) return;
        bloc.add(
          UpdateSoundGroupEvent(groupId: group.id, data: result!.updateData!),
        );
      case 'sounds':
        final items = await SoundGroupSoundsDialog.show(
          context,
          groupName: group.name,
          initialMembers: group.sounds,
        );
        if (!context.mounted || items == null) return;
        bloc.add(ReplaceGroupSoundsEvent(groupId: group.id, sounds: items));
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.l10n.tOr('soundGroupDeleteTitle', 'Delete group?')),
            content: Text(
              context.l10n.tOr(
                'soundGroupDeleteMessage',
                'Memberships are removed; library sounds stay available.',
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
        bloc.add(DeleteSoundGroupEvent(group.id));
    }
  }
}
