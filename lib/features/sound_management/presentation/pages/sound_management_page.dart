import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/bulk_sound_action_bloc.dart';
import '../bloc/sound_crud_bloc.dart';
import '../bloc/sound_overview_bloc.dart';
import '../bloc/sounds_bloc.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../injection_container.dart' as di;
import '../../../promotions/presentation/widgets/promotions_dashboard_widgets.dart';
import '../../../promotions/presentation/widgets/promotions_shared_widgets.dart';
import '../../domain/entities/sound_entities.dart';
import '../services/sound_preview_service.dart';
import '../utils/sound_audio_duration_parser.dart';
import '../utils/sound_audio_duration_web.dart';
import '../widgets/sound_compact_overview.dart';
import '../widgets/sound_confirm_dialogs.dart';
import '../widgets/sound_form_dialog.dart';
import '../widgets/sound_preview_scope.dart';
import '../widgets/sound_skeleton.dart';
import '../widgets/sounds_table.dart';

class SoundManagementPage extends StatelessWidget {
  const SoundManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              di.sl<SoundOverviewBloc>()..add(const LoadSoundOverviewEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<SoundsBloc>()..add(const LoadSoundsEvent()),
        ),
        BlocProvider(create: (_) => di.sl<SoundCrudBloc>()),
        BlocProvider(create: (_) => di.sl<BulkSoundActionBloc>()),
      ],
      child: SoundPreviewHost(
        child: const _SoundManagementView(),
      ),
    );
  }
}

class _SoundManagementView extends StatefulWidget {
  const _SoundManagementView();

  @override
  State<_SoundManagementView> createState() => _SoundManagementViewState();
}

class _SoundManagementViewState extends State<_SoundManagementView> {
  String? _pendingSoundId;

  void _refreshOverview() {
    context
        .read<SoundOverviewBloc>()
        .add(const LoadSoundOverviewEvent(refresh: true));
  }

  void _refreshAll() {
    _refreshOverview();
    context.read<SoundsBloc>().add(const LoadSoundsEvent(refresh: true));
  }

  void _applyCrudSuccess(SoundCrudSuccess state) {
    final mutation = switch (state.operation) {
      SoundCrudOperation.create => SoundLibraryMutation.created,
      SoundCrudOperation.update => SoundLibraryMutation.updated,
      SoundCrudOperation.delete => SoundLibraryMutation.deleted,
      SoundCrudOperation.activate => SoundLibraryMutation.activated,
      SoundCrudOperation.deactivate => SoundLibraryMutation.deactivated,
    };

    final soundId = (state.sound?.id.isNotEmpty ?? false)
        ? state.sound!.id
        : _pendingSoundId;

    context.read<SoundsBloc>().add(
          ApplySoundLibraryMutationEvent(
            mutation: mutation,
            sound: state.sound,
            soundIds: soundId != null ? [soundId] : const [],
          ),
        );
    _pendingSoundId = null;
    _refreshOverview();
  }

  void _applyBulkSuccess(BulkSoundActionSuccess state) {
    final result = state.result;
    final mutation = switch (result.action) {
      'ACTIVATE' => SoundLibraryMutation.bulkActivated,
      'DEACTIVATE' => SoundLibraryMutation.bulkDeactivated,
      'DELETE' => SoundLibraryMutation.bulkDeleted,
      _ => null,
    };
    if (mutation == null) return;

    context.read<SoundsBloc>().add(
          ApplySoundLibraryMutationEvent(
            mutation: mutation,
            soundIds: result.soundIds,
          ),
        );
    _refreshOverview();
  }

  Future<int?> _resolveAudioDuration({
    int? existingDuration,
    List<int>? bytes,
    String? filename,
    String? audioUrl,
  }) async {
    if (existingDuration != null && existingDuration > 0) {
      return existingDuration;
    }
    if (bytes != null && filename != null) {
      final parsed = parseAudioDurationFromBytes(bytes, filename);
      if (parsed != null && parsed > 0) return parsed;
      return probeAudioDurationFromBytes(bytes, filename);
    }
    if (audioUrl != null && audioUrl.trim().isNotEmpty) {
      return probeAudioDurationFromPath(audioUrl.trim());
    }
    return null;
  }

  String _crudSuccessMessage(SoundCrudOperation operation) {
    final l10n = context.l10n;
    return switch (operation) {
      SoundCrudOperation.create => l10n.t('soundCreatedSuccess'),
      SoundCrudOperation.update => l10n.t('soundUpdatedSuccess'),
      SoundCrudOperation.delete => l10n.t('soundDeletedSuccess'),
      SoundCrudOperation.activate => l10n.t('soundActivatedSuccess'),
      SoundCrudOperation.deactivate => l10n.t('soundDeactivatedSuccess'),
    };
  }

  String _bulkSuccessMessage(BulkSoundActionResultEntity result) {
    return switch (result.action) {
      'ACTIVATE' => context.tr('soundBulkActivatedSuccess', {
          'count': '${result.successCount}',
        }),
      'DEACTIVATE' => context.tr('soundBulkDeactivatedSuccess', {
          'count': '${result.successCount}',
        }),
      'DELETE' => context.tr('soundBulkDeletedSuccess', {
          'count': '${result.successCount}',
        }),
      _ => context.tr('soundBulkSuccess', {
          'count': '${result.successCount}',
        }),
    };
  }

  Future<void> _openAddDialog() async {
    final l10n = context.l10n;
    final result = await SoundFormDialog.show(context);
    if (!mounted || result == null) return;

    if (result.uploadData != null) {
      final upload = result.uploadData!;
      final duration = await _resolveAudioDuration(
        existingDuration: upload.duration,
        bytes: upload.bytes,
        filename: upload.filename,
      );
      if (!mounted) return;
      if (duration == null || duration <= 0) {
        _showSnack(l10n.t('soundCouldNotReadDuration'), isError: true);
        return;
      }
      context.read<SoundCrudBloc>().add(
            UploadSoundEvent(
              UploadSoundData(
                bytes: upload.bytes,
                filename: upload.filename,
                name: upload.name,
                author: upload.author,
                duration: duration,
                coverBytes: upload.coverBytes,
                coverFilename: upload.coverFilename,
              ),
            ),
          );
      return;
    }

    if (result.createData != null) {
      final create = result.createData!;
      final duration = await _resolveAudioDuration(
        existingDuration: create.duration,
        audioUrl: create.audioUrl,
      );
      if (!mounted) return;
      if (duration == null || duration <= 0) {
        _showSnack(l10n.t('soundCouldNotReadDuration'), isError: true);
        return;
      }
      context.read<SoundCrudBloc>().add(
            CreateSoundEvent(
              CreateSoundData(
                name: create.name,
                author: create.author,
                audioUrl: create.audioUrl,
                duration: duration,
                coverUrl: create.coverUrl,
                isActive: create.isActive,
              ),
            ),
          );
    }
  }

  Future<void> _openEditDialog(SoundEntity sound) async {
    final result = await SoundFormDialog.show(context, sound: sound);
    if (!mounted || result?.updateData == null) return;
    _pendingSoundId = sound.id;
    context.read<SoundCrudBloc>().add(
          UpdateSoundEvent(soundId: sound.id, data: result!.updateData!),
        );
  }

  Future<void> _toggleActive(SoundEntity sound) async {
    final confirmed = await confirmSoundToggleActive(
      context,
      activate: !sound.isActive,
    );
    if (!confirmed || !mounted) return;
    _pendingSoundId = sound.id;
    final crud = context.read<SoundCrudBloc>();
    if (sound.isActive) {
      crud.add(DeactivateSoundEvent(sound.id));
    } else {
      crud.add(ActivateSoundEvent(sound.id));
    }
  }

  Future<void> _deleteSound(SoundEntity sound) async {
    final confirmed = await confirmSoundDelete(context);
    if (!confirmed || !mounted) return;
    _pendingSoundId = sound.id;
    context.read<SoundCrudBloc>().add(DeleteSoundEvent(sound.id));
  }

  Future<void> _bulkAction(BulkSoundActionType action) async {
    final soundsState = context.read<SoundsBloc>().state;
    if (soundsState is! SoundsLoaded || soundsState.selectedIds.isEmpty) return;

    final confirmed = await confirmBulkSoundAction(
      context,
      action: action,
      count: soundsState.selectedCount,
    );
    if (!confirmed || !mounted) return;

    context.read<BulkSoundActionBloc>().add(
          ExecuteBulkSoundActionEvent(
            soundIds: soundsState.selectedIds.toList(),
            action: action,
          ),
        );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = context.soundPreview;
    final scheme = Theme.of(context).colorScheme;

    return MultiBlocListener(
      listeners: [
        BlocListener<SoundCrudBloc, SoundCrudState>(
          listener: (context, state) {
            if (state is SoundCrudSuccess) {
              _showSnack(_crudSuccessMessage(state.operation));
              _applyCrudSuccess(state);
              context.read<SoundCrudBloc>().add(const ResetSoundCrudEvent());
              context.read<SoundsBloc>().add(const ClearSoundSelectionEvent());
            } else if (state is SoundCrudError) {
              _pendingSoundId = null;
              _showSnack(state.message, isError: true);
              context.read<SoundCrudBloc>().add(const ResetSoundCrudEvent());
            }
          },
        ),
        BlocListener<BulkSoundActionBloc, BulkSoundActionState>(
          listener: (context, state) {
            if (state is BulkSoundActionSuccess) {
              _showSnack(_bulkSuccessMessage(state.result));
              _applyBulkSuccess(state);
              context.read<SoundsBloc>().add(const ClearSoundSelectionEvent());
            } else if (state is BulkSoundActionError) {
              _showSnack(state.message, isError: true);
            }
          },
        ),
      ],
      child: PromotionsDashboardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _PageHeader(
              onAdd: _openAddDialog,
              onRefresh: _refreshAll,
            ),
            const SizedBox(height: PromotionsSpace.sm),
            _OverviewSection(),
            const SizedBox(height: PromotionsSpace.sm),
            DashboardCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PromotionsSpace.md,
                      PromotionsSpace.md,
                      PromotionsSpace.md,
                      PromotionsSpace.sm,
                    ),
                    child: _CompactLibraryFilters(onRefresh: _refreshAll),
                  ),
                  Divider(
                    height: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                  _LibraryContent(
                    preview: preview,
                    onEdit: _openEditDialog,
                    onToggleActive: _toggleActive,
                    onDelete: _deleteSound,
                    onBulkAction: _bulkAction,
                  ),
                ],
              ),
            ),
            const SizedBox(height: PromotionsSpace.xxl),
          ],
        ),
      ),
    );
  }
}

class _LibraryContent extends StatelessWidget {
  const _LibraryContent({
    required this.preview,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
    required this.onBulkAction,
  });

  final SoundPreviewService preview;
  final ValueChanged<SoundEntity> onEdit;
  final ValueChanged<SoundEntity> onToggleActive;
  final ValueChanged<SoundEntity> onDelete;
  final ValueChanged<BulkSoundActionType> onBulkAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
            if (state is SoundsEmpty) {
              if (state.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(PromotionsSpace.lg),
                  child: SoundTableSkeleton(),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 56),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.library_music_outlined,
                      size: 44,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.t('soundNoResults'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              );
            }
            if (state is! SoundsLoaded) {
              return const Padding(
                padding: EdgeInsets.all(PromotionsSpace.lg),
                child: SoundTableSkeleton(),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    sounds: state.sounds,
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
                _PaginationBar(
                  page: state.meta.page,
                  totalPages: state.meta.totalPages,
                  total: state.meta.total,
                  onPage: (p) => context
                      .read<SoundsBloc>()
                      .add(LoadSoundsEvent(page: p)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.onAdd,
    required this.onRefresh,
  });

  final VoidCallback onAdd;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.t('soundManagementTitle'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
          ),
        ),
        IconButton(
          tooltip: l10n.t('refresh'),
          onPressed: onRefresh,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.refresh_rounded, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: 4),
        FilledButton.icon(
          onPressed: onAdd,
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.t('soundAddTitle')),
        ),
      ],
    );
  }
}

class _OverviewSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<SoundOverviewBloc, SoundOverviewState>(
      builder: (context, state) {
        if (state is SoundOverviewLoading) {
          return const SoundCompactOverviewSkeleton();
        }
        if (state is SoundOverviewError) {
          return DashboardCard(
            padding: const EdgeInsets.all(PromotionsSpace.lg),
            child: ErrorView(
              message: state.message,
              retryLabel: l10n.t('retry'),
              onRetry: () => context
                  .read<SoundOverviewBloc>()
                  .add(const LoadSoundOverviewEvent()),
            ),
          );
        }
        if (state is! SoundOverviewLoaded) {
          return const SizedBox.shrink();
        }

        return SoundCompactOverview(
          sounds: state.overview.sounds,
          usage: state.overview.usage,
        );
      },
    );
  }
}

class _CompactLibraryFilters extends StatelessWidget {
  const _CompactLibraryFilters({required this.onRefresh});

  final VoidCallback onRefresh;

  static const _controlHeight = 36.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<SoundsBloc, SoundsState, SoundsQuery>(
      selector: (state) => switch (state) {
        SoundsLoaded(:final query) => query,
        SoundsEmpty(:final query) => query,
        _ => const SoundsQuery(),
      },
      builder: (context, query) {
        final hasFilters = (query.search != null && query.search!.isNotEmpty) ||
            query.isActive != null;

        return LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 720;

            final search = _CompactSearchField(
              hint: l10n.t('soundSearchHint'),
              initialValue: query.search ?? '',
              onChanged: (q) =>
                  context.read<SoundsBloc>().add(SearchSoundsEvent(q)),
            );

            final sort = _CompactFilterDropdown(
              hint: l10n.t('sortBy'),
              value: query.sort.apiValue,
              items: SoundSortMode.values.map((s) => s.apiValue).toList(),
              itemLabel: (v) => switch (SoundSortMode.values.firstWhere(
                    (s) => s.apiValue == v,
                    orElse: () => SoundSortMode.trending,
                  )) {
                SoundSortMode.trending => l10n.t('soundSortTrending'),
                SoundSortMode.recent => l10n.t('soundSortRecent'),
                SoundSortMode.alphabetical => l10n.t('soundSortName'),
              },
              onChanged: (v) {
                if (v == null) return;
                final sort = SoundSortMode.values.firstWhere(
                  (s) => s.apiValue == v,
                  orElse: () => SoundSortMode.trending,
                );
                context.read<SoundsBloc>().add(SortSoundsEvent(sort));
              },
            );

            final status = _CompactFilterDropdown(
              hint: l10n.t('status'),
              value: query.isActive == null
                  ? null
                  : (query.isActive! ? 'active' : 'inactive'),
              items: const [null, 'active', 'inactive'],
              itemLabel: (v) => switch (v) {
                'active' => l10n.t('soundStatusActive'),
                'inactive' => l10n.t('soundStatusHidden'),
                _ => l10n.t('all'),
              },
              onChanged: (v) => context.read<SoundsBloc>().add(
                    FilterSoundsActiveEvent(
                      v == null ? null : v == 'active',
                    ),
                  ),
            );

            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  search,
                  const SizedBox(height: PromotionsSpace.sm),
                  Row(
                    children: [
                      Expanded(child: sort),
                      const SizedBox(width: PromotionsSpace.sm),
                      Expanded(child: status),
                      if (hasFilters) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: l10n.t('clearFilters'),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => context
                              .read<SoundsBloc>()
                              .add(const ClearSoundsFiltersEvent()),
                          icon: Icon(
                            Icons.filter_alt_off_outlined,
                            size: 18,
                            color: scheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 3, child: search),
                const SizedBox(width: PromotionsSpace.sm),
                SizedBox(width: 148, child: sort),
                const SizedBox(width: PromotionsSpace.sm),
                SizedBox(width: 120, child: status),
                if (hasFilters) ...[
                  IconButton(
                    tooltip: l10n.t('clearFilters'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context
                        .read<SoundsBloc>()
                        .add(const ClearSoundsFiltersEvent()),
                    icon: Icon(
                      Icons.filter_alt_off_outlined,
                      size: 18,
                      color: scheme.error,
                    ),
                  ),
                ] else
                  IconButton(
                    tooltip: l10n.t('refresh'),
                    visualDensity: VisualDensity.compact,
                    onPressed: onRefresh,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
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

class _CompactSearchField extends StatefulWidget {
  const _CompactSearchField({
    required this.hint,
    required this.onChanged,
    this.initialValue = '',
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final String initialValue;

  @override
  State<_CompactSearchField> createState() => _CompactSearchFieldState();
}

class _CompactSearchFieldState extends State<_CompactSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_CompactSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: _CompactLibraryFilters._controlHeight,
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          setState(() {});
          widget.onChanged(value);
        },
        style: Theme.of(context).textTheme.bodySmall,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                  icon: Icon(Icons.close_rounded, size: 16, color: scheme.onSurfaceVariant),
                )
              : null,
          isDense: true,
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: scheme.primary, width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _CompactFilterDropdown extends StatelessWidget {
  const _CompactFilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String hint;
  final String? value;
  final List<String?> items;
  final String Function(String?) itemLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final safeValue = items.contains(value) ? value : null;

    return Container(
      height: _CompactLibraryFilters._controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safeValue,
          isExpanded: true,
          isDense: true,
          hint: Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
            overflow: TextOverflow.ellipsis,
          ),
          icon: Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          items: items
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(
                    itemLabel(v),
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.total,
    required this.onPage,
  });

  final int page;
  final int totalPages;
  final int total;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 520;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PromotionsSpace.lg,
        vertical: PromotionsSpace.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              compact
                  ? 'Page $page / $totalPages'
                  : '$total sounds · Page $page of $totalPages',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          IconButton(
            onPressed: page > 1 ? () => onPage(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: page < totalPages ? () => onPage(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
