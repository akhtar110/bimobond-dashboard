import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../promotions/presentation/widgets/promotions_dashboard_widgets.dart';
import '../../../promotions/presentation/widgets/promotions_shared_widgets.dart';
import '../../domain/entities/sound_entities.dart';
import '../../domain/entities/sound_group_entities.dart';
import '../bloc/bulk_sound_action_bloc.dart';
import '../bloc/sound_groups_bloc.dart';
import '../bloc/sounds_bloc.dart';
import '../services/sound_preview_service.dart';
import '../utils/sound_display_filters.dart';
import 'sound_selected_group_banner.dart';
import 'sound_skeleton.dart';
import 'sounds_table.dart';

/// Library body: bulk toolbar + table + pagination (group-aware).
class SoundLibraryBody extends StatelessWidget {
  const SoundLibraryBody({
    super.key,
    required this.preview,
    required this.useDesktopPagination,
    required this.selectedGroupId,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
    required this.onBulkAction,
  });

  final SoundPreviewService preview;
  final bool useDesktopPagination;
  final String? selectedGroupId;
  final ValueChanged<SoundEntity> onEdit;
  final ValueChanged<SoundEntity> onToggleActive;
  final ValueChanged<SoundEntity> onDelete;
  final ValueChanged<BulkSoundActionType> onBulkAction;

  SoundGroupEntity? _resolveGroup(SoundGroupsState groupsState) {
    if (selectedGroupId == null || groupsState is! SoundGroupsLoaded) {
      return null;
    }
    for (final group in groupsState.groups) {
      if (group.id == selectedGroupId) return group;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groupsState = context.watch<SoundGroupsBloc>().state;
    final selectedGroup = _resolveGroup(groupsState);

    return BlocBuilder<BulkSoundActionBloc, BulkSoundActionState>(
      builder: (context, bulkState) {
        final running = bulkState is BulkSoundActionRunning;
        return BlocBuilder<SoundsBloc, SoundsState>(
          builder: (context, state) {
            if (state is SoundsLoading) {
              return const Padding(
                padding: EdgeInsets.all(PromotionsSpace.lg),
                child: SoundTableSkeleton(),
              );
            }
            if (state is SoundsError) {
              return Padding(
                padding: const EdgeInsets.all(PromotionsSpace.xl),
                child: ErrorView(
                  message: state.message,
                  retryLabel: l10n.t('retry'),
                  onRetry: () =>
                      context.read<SoundsBloc>().add(const LoadSoundsEvent()),
                ),
              );
            }

            final query = switch (state) {
              SoundsLoaded(:final query) => query,
              SoundsEmpty(:final query) => query,
              _ => const SoundsQuery(),
            };

            final librarySounds =
                state is SoundsLoaded ? state.sounds : const <SoundEntity>[];
            final displayed = soundsForDisplay(
              librarySounds: librarySounds,
              query: query,
              selectedGroup: selectedGroup,
            );

            if (state is SoundsEmpty ||
                (state is SoundsLoaded && displayed.isEmpty)) {
              if (state is SoundsEmpty && state.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(PromotionsSpace.lg),
                  child: SoundTableSkeleton(),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (selectedGroup != null)
                    SoundSelectedGroupBanner(group: selectedGroup),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 56),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.library_music_outlined,
                          size: 44,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.t('soundNoResults'),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            if (state is! SoundsLoaded) {
              return const Padding(
                padding: EdgeInsets.all(PromotionsSpace.lg),
                child: SoundTableSkeleton(),
              );
            }

            final showPagination = useDesktopPagination &&
                selectedGroup == null &&
                (state.meta.total > 0 || state.sounds.isNotEmpty);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedGroup != null)
                  SoundSelectedGroupBanner(group: selectedGroup),
                if (state.selectedCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PromotionsSpace.md,
                      PromotionsSpace.md,
                      PromotionsSpace.md,
                      0,
                    ),
                    child: BulkActionToolbar(
                      selectedCount: state.selectedCount,
                      allVisibleSelected: state.allVisibleSelected,
                      someVisibleSelected: state.someVisibleSelected,
                      onSelectAll: () => context
                          .read<SoundsBloc>()
                          .add(const SelectAllSoundsEvent()),
                      onClear: () => context
                          .read<SoundsBloc>()
                          .add(const ClearSoundSelectionEvent()),
                      actions: [
                        FilledButton.tonal(
                          onPressed: running
                              ? null
                              : () =>
                                  onBulkAction(BulkSoundActionType.activate),
                          child: Text(l10n.t('soundBulkActivate')),
                        ),
                        FilledButton.tonal(
                          onPressed: running
                              ? null
                              : () =>
                                  onBulkAction(BulkSoundActionType.deactivate),
                          child: Text(l10n.t('soundBulkDeactivate')),
                        ),
                        FilledButton(
                          onPressed: running
                              ? null
                              : () => onBulkAction(BulkSoundActionType.delete),
                          child: Text(l10n.t('soundBulkDelete')),
                        ),
                      ],
                    ),
                  ),
                if (state.isRefreshing || running)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                      PromotionsSpace.md,
                      PromotionsSpace.sm,
                      PromotionsSpace.md,
                      0,
                    ),
                    child: LinearProgressIndicator(),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PromotionsSpace.md,
                    PromotionsSpace.sm,
                    PromotionsSpace.md,
                    PromotionsSpace.md,
                  ),
                  child: SoundsTable(
                    sounds: displayed,
                    selectedIds: state.selectedIds,
                    preview: preview,
                    onToggleSelection: (id) => context
                        .read<SoundsBloc>()
                        .add(ToggleSoundSelectionEvent(id)),
                    onSelectAll: () => context
                        .read<SoundsBloc>()
                        .add(const SelectAllSoundsEvent()),
                    onEdit: onEdit,
                    onToggleActive: onToggleActive,
                    onDelete: onDelete,
                  ),
                ),
                if (showPagination)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PromotionsSpace.md,
                      0,
                      PromotionsSpace.md,
                      PromotionsSpace.md,
                    ),
                    child: AppPaginationBar(
                      currentPage: state.meta.page < 1 ? 1 : state.meta.page,
                      lastPage: state.meta.totalPages < 1
                          ? 1
                          : state.meta.totalPages,
                      total: state.meta.total > 0
                          ? state.meta.total
                          : state.sounds.length,
                      pageSize: state.meta.limit > 0
                          ? state.meta.limit
                          : state.query.limit,
                      itemCount: state.sounds.length,
                      hideWhenSinglePage: false,
                      borderRadius: BorderRadius.circular(12),
                      onPageChanged: (page) => context
                          .read<SoundsBloc>()
                          .add(LoadSoundsEvent(page: page)),
                    ),
                  ),
                if (!useDesktopPagination &&
                    selectedGroup == null &&
                    state.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.only(bottom: PromotionsSpace.md),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
