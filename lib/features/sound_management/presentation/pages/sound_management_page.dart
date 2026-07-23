import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../core/widgets/web_dashboard_layout.dart';
import '../../../../injection_container.dart' as di;
import '../../../promotions/presentation/widgets/promotions_dashboard_widgets.dart';
import '../../domain/entities/sound_entities.dart';
import '../../domain/entities/sound_group_entities.dart';
import '../bloc/bulk_sound_action_bloc.dart';
import '../bloc/sound_crud_bloc.dart';
import '../bloc/sound_groups_bloc.dart';
import '../bloc/sound_overview_bloc.dart';
import '../bloc/sounds_bloc.dart';
import '../utils/sound_audio_duration_parser.dart';
import '../utils/sound_audio_duration_web.dart';
import '../widgets/sound_compact_overview.dart';
import '../widgets/sound_confirm_dialogs.dart';
import '../widgets/sound_filters_panel.dart';
import '../widgets/sound_form_dialog.dart';
import '../widgets/sound_groups_tabs_bar.dart';
import '../widgets/sound_library_body.dart';
import '../widgets/sound_management_header.dart';
import '../widgets/sound_preview_scope.dart';

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
        BlocProvider(
          create: (_) =>
              di.sl<SoundGroupsBloc>()..add(const LoadSoundGroupsEvent()),
        ),
      ],
      child: const SoundPreviewHost(
        child: _SoundManagementView(),
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
  static const _desktopPaginationBreakpoint =
      WebDashboardLayout.desktopBreakpoint;
  static const _maxContentWidth = 1680.0;
  static const int maxAudioSizeBytes = 1024 * 1024;

  final _scrollController = ScrollController();
  String? _pendingSoundId;
  String? _pendingAssignGroupId;
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  bool get _useDesktopPagination =>
      MediaQuery.sizeOf(context).width > _desktopPaginationBreakpoint;

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    if (_useDesktopPagination) return;
    if (_selectedGroupId != null) return;

    final position = _scrollController.position;
    if (!position.hasContentDimensions || position.maxScrollExtent <= 0) {
      return;
    }
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<SoundsBloc>().add(const LoadMoreSoundsEvent());
    }
  }

  double _horizontalPadding(double width) {
    if (width < 400) return 10;
    if (width < 600) return 14;
    return 20;
  }

  double _verticalPadding(double width) {
    if (width < 400) return 10;
    if (width < 720) return 12;
    return 16;
  }

  double _sectionSpacing(double width) {
    if (width < 400) return 8;
    if (width < 720) return 10;
    return 12;
  }

  void _refreshOverview() {
    context
        .read<SoundOverviewBloc>()
        .add(const LoadSoundOverviewEvent(refresh: true));
  }

  void _refreshAll() {
    _refreshOverview();
    context.read<SoundsBloc>().add(const LoadSoundsEvent(refresh: true));
    context
        .read<SoundGroupsBloc>()
        .add(const LoadSoundGroupsEvent(refresh: true));
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

    final groupId = _pendingAssignGroupId;
    _pendingAssignGroupId = null;
    if (mutation == SoundLibraryMutation.created &&
        groupId != null &&
        state.sound != null) {
      _assignCreatedSoundToGroup(groupId, state.sound!);
    }
  }

  void _assignCreatedSoundToGroup(String groupId, SoundEntity sound) {
    final groupsState = context.read<SoundGroupsBloc>().state;
    if (groupsState is! SoundGroupsLoaded) return;

    SoundGroupEntity? group;
    for (final candidate in groupsState.groups) {
      if (candidate.id == groupId) {
        group = candidate;
        break;
      }
    }
    if (group == null) return;

    final members = [
      for (final member in group.sounds)
        SoundGroupMembershipItem(
          soundId: member.sound.id,
          sortOrder: member.sortOrder,
        ),
      SoundGroupMembershipItem(
        soundId: sound.id,
        sortOrder: group.sounds.length,
      ),
    ];

    context.read<SoundGroupsBloc>().add(
          ReplaceGroupSoundsEvent(groupId: groupId, sounds: members),
        );
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
    final base = switch (result.action) {
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
    if (result.action == 'DELETE' && result.skippedCount > 0) {
      return context.tr('soundBulkDeletedWithSkipped', {
        'count': '${result.successCount}',
        'skipped': '${result.skippedCount}',
      });
    }
    return base;
  }

  Future<void> _openAddDialog() async {
    final l10n = context.l10n;
    final groupsState = context.read<SoundGroupsBloc>().state;
    final groups = groupsState is SoundGroupsLoaded ? groupsState.groups : null;
    final result = await SoundFormDialog.show(context, groups: groups);
    if (!mounted || result == null) return;

    _pendingAssignGroupId = result.assignGroupId;

    if (result.uploadData != null) {
      final upload = result.uploadData!;
      if (upload.bytes.length > maxAudioSizeBytes) {
        _showSnack(l10n.t('soundAudioMaxSizeExceeded'), isError: true);
        if (mounted) await _openAddDialog();
        return;
      }
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
        behavior: SnackBarBehavior.floating,
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
              _pendingAssignGroupId = null;
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
        BlocListener<SoundGroupsBloc, SoundGroupsState>(
          listenWhen: (previous, current) =>
              current is SoundGroupsLoaded && current.feedbackMessage != null,
          listener: (context, state) {
            if (state is! SoundGroupsLoaded || state.feedbackMessage == null) {
              return;
            }
            final l10n = context.l10n;
            _showSnack(
              l10n.tOr(state.feedbackMessage!, state.feedbackMessage!),
              isError: state.feedbackIsError,
            );
            context
                .read<SoundGroupsBloc>()
                .add(const ClearSoundGroupsFeedbackEvent());
          },
        ),
      ],
      child: ColoredBox(
        color: scheme.surfaceContainerLowest,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final hPad = _horizontalPadding(width);
            final vPad = _verticalPadding(width);
            final sectionGap = _sectionSpacing(width);
            final compactHeader = width < 720;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsetsDirectional.fromSTEB(
                    hPad,
                    vPad,
                    hPad,
                    vPad,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SoundManagementHeader(
                        isLoading: false,
                        compact: compactHeader,
                        onAdd: _openAddDialog,
                        onRefresh: _refreshAll,
                      ),
                      SizedBox(height: sectionGap),
                      const _OverviewSection(),
                      SizedBox(height: sectionGap),
                      BlocSelector<SoundsBloc, SoundsState, SoundsQuery>(
                        selector: (state) => switch (state) {
                          SoundsLoaded(:final query) => query,
                          SoundsEmpty(:final query) => query,
                          _ => const SoundsQuery(),
                        },
                        builder: (context, query) {
                          return SoundFiltersPanel(query: query);
                        },
                      ),
                      SizedBox(height: sectionGap),
                      SoundGroupsTabsBar(
                        selectedGroupId: _selectedGroupId,
                        onGroupSelected: (group) {
                          setState(() => _selectedGroupId = group?.id);
                        },
                      ),
                      SizedBox(height: width < 520 ? 8 : 10),
                      SoundLibraryBody(
                        preview: preview,
                        useDesktopPagination: _useDesktopPagination,
                        selectedGroupId: _selectedGroupId,
                        onEdit: _openEditDialog,
                        onToggleActive: _toggleActive,
                        onDelete: _deleteSound,
                        onBulkAction: _bulkAction,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection();

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
          segments: state.overview.segments,
        );
      },
    );
  }
}
