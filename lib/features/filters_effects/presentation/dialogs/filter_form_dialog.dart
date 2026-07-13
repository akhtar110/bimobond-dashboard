import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';



import '../../../../core/localization/localization.dart';

import '../../../../core/widgets/state_widgets.dart';

import '../../../../injection_container.dart' as di;

import '../../domain/entities/filters_effects_entities.dart';

import '../bloc/filter_editor_bloc.dart';

import '../bloc/filter_editor_event.dart';

import '../bloc/filter_editor_state.dart';

import '../widgets/filter_editor_basic_section.dart';

import '../widgets/filter_editor_color_matrix_section.dart';

import '../widgets/filter_editor_preview_panel.dart';

import '../widgets/filter_editor_settings_section.dart';



Future<bool?> openFilterEditor(BuildContext context, {String? filterId}) {

  return showDialog<bool>(

    context: context,

    barrierDismissible: false,

    builder: (ctx) => BlocProvider(

      create: (_) => di.sl<FilterEditorBloc>()

        ..add(LoadFilterEditorEvent(filterId: filterId)),

      child: FilterFormDialog(filterId: filterId),

    ),

  );

}



void showFilterFormDialog(

  BuildContext context, {

  CameraFilterEntity? editing,

}) {

  openFilterEditor(context, filterId: editing?.id);

}



class FilterFormDialog extends StatelessWidget {

  const FilterFormDialog({super.key, this.filterId});



  final String? filterId;



  Future<bool> _confirmDiscard(BuildContext context) async {

    final l10n = context.l10n;

    final result = await showDialog<bool>(

      context: context,

      builder: (ctx) => AlertDialog(

        title: Text(l10n.tOr('feDiscardChangesTitle', 'Discard changes?')),

        content: Text(

          l10n.tOr(

            'feDiscardChangesMessage',

            'You have unsaved changes. Leave without saving?',

          ),

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.of(ctx).pop(false),

            child: Text(l10n.t('cancel')),

          ),

          FilledButton(

            onPressed: () => Navigator.of(ctx).pop(true),

            child: Text(l10n.tOr('feDiscard', 'Discard')),

          ),

        ],

      ),

    );

    return result ?? false;

  }



  Future<void> _handleClose(BuildContext context, FilterEditorState state) async {

    final ready = state is FilterEditorReady ? state : null;

    if (ready != null && ready.hasUnsavedChanges) {

      final discard = await _confirmDiscard(context);

      if (!discard || !context.mounted) return;

    }

    if (context.mounted) {

      Navigator.of(context).pop();

    }

  }



  @override

  Widget build(BuildContext context) {

    return BlocListener<FilterEditorBloc, FilterEditorState>(

      listenWhen: (previous, current) {

        if (current is FilterEditorReady &&

            current.saveSucceeded &&

            (previous is! FilterEditorReady || !previous.saveSucceeded)) {

          return true;

        }

        if (current is FilterEditorReady &&

            current.submitError != null &&

            (previous is! FilterEditorReady ||

                previous.submitError != current.submitError)) {

          return true;

        }

        return false;

      },

      listener: (context, state) {

        if (state is! FilterEditorReady) return;

        if (state.saveSucceeded) {

          context

              .read<FilterEditorBloc>()

              .add(const ClearFilterEditorSaveFlagEvent());

          Navigator.of(context).pop(true);

          return;

        }

        if (state.submitError != null) {

          final scheme = Theme.of(context).colorScheme;

          ScaffoldMessenger.of(context)

            ..hideCurrentSnackBar()

            ..showSnackBar(

              SnackBar(

                content: Text(

                  state.submitError!,

                  style: TextStyle(color: scheme.onError),

                ),

                backgroundColor: scheme.error,

                behavior: SnackBarBehavior.floating,

              ),

            );

          context

              .read<FilterEditorBloc>()

              .add(const ClearFilterEditorSubmitErrorEvent());

        }

      },

      child: BlocBuilder<FilterEditorBloc, FilterEditorState>(
        buildWhen: (previous, current) {
          if (previous.runtimeType != current.runtimeType) return true;
          if (current is FilterEditorReady && previous is FilterEditorReady) {
            return previous.isSaving != current.isSaving ||
                previous.filterId != current.filterId;
          }
          return false;
        },
        builder: (context, state) {

          final l10n = context.l10n;

          final ready = state is FilterEditorReady ? state : null;

          final screen = MediaQuery.sizeOf(context);

          final dialogWidth = (screen.width * 0.94).clamp(960.0, 1280.0);

          final dialogHeight = (screen.height * 0.88).clamp(520.0, 820.0);



          return AlertDialog(

            title: Row(

              children: [

                Expanded(

                  child: Text(

                    ready?.isEditing == true

                        ? l10n.tOr('feEditFilter', 'Edit filter')

                        : l10n.tOr('feCreateFilter', 'Create filter'),

                  ),

                ),

                IconButton(

                  tooltip: l10n.t('cancel'),

                  onPressed: state is FilterEditorLoading

                      ? null

                      : () => _handleClose(context, state),

                  icon: const Icon(Icons.close_rounded),

                ),

              ],

            ),

            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),

            content: SizedBox(

              width: dialogWidth,

              height: dialogHeight,

              child: _FilterEditorDialogBody(filterId: filterId),

            ),

            actions: [

              TextButton(

                onPressed: state is FilterEditorLoading

                    ? null

                    : () => _handleClose(context, state),

                child: Text(l10n.t('cancel')),

              ),

              if (ready != null)

                FilledButton(

                  onPressed: ready.isSaving || ready.isUploadingThumbnail
                      ? null
                      : () => context
                          .read<FilterEditorBloc>()
                          .add(const SubmitFilterEditorEvent()),
                  child: ready.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.tOr('feSave', 'Save')),

                ),

            ],

          );

        },

      ),

    );

  }

}



class _FilterEditorDialogBody extends StatelessWidget {
  const _FilterEditorDialogBody({required this.filterId});

  final String? filterId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterEditorBloc, FilterEditorState>(
      buildWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      builder: (context, state) {
        if (state is FilterEditorLoading) {
          return const Center(child: LoadingView());
        }

        if (state is FilterEditorError) {
          return Center(
            child: ErrorView(
              message: state.message,
              retryLabel: context.l10n.t('retry'),
              onRetry: () => context.read<FilterEditorBloc>().add(
                    LoadFilterEditorEvent(filterId: filterId),
                  ),
            ),
          );
        }

        if (state is! FilterEditorReady) {
          return const SizedBox.shrink();
        }

        return const _FilterEditorReadyBody();
      },
    );
  }
}

class _FilterEditorReadyBody extends StatelessWidget {
  const _FilterEditorReadyBody();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<FilterEditorBloc, FilterEditorState, bool>(
      selector: (state) =>
          state is FilterEditorReady ? state.isSaving : false,
      builder: (context, isSaving) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 34,
                  child: _DialogColumn(
                    title: context.l10n.tOr(
                      'feFilterSectionBasic',
                      'Basic information',
                    ),
                    child: BlocSelector<FilterEditorBloc, FilterEditorState,
                        _FilterBasicPanelState?>(
                      selector: _selectFilterBasicPanelState,
                      builder: (context, panelState) {
                        if (panelState == null) return const SizedBox.shrink();
                        final ready = panelState.ready;
                        return SingleChildScrollView(
                          padding: const EdgeInsets.only(right: 4, bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilterEditorBasicSection(
                                key: ValueKey(ready.filterId ?? 'new-filter'),
                                state: ready,
                                embedded: true,
                              ),
                              if (ready.colorMatrix.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                FilterEditorColorMatrixSection(
                                  colorMatrix: ready.colorMatrix,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                VerticalDivider(width: 1, color: scheme.outlineVariant),
                Expanded(
                  flex: 40,
                  child: _DialogColumn(
                    title: context.l10n.tOr(
                      'feFilterSectionSettings',
                      'Filter settings',
                    ),
                    child: BlocSelector<FilterEditorBloc, FilterEditorState,
                        _SettingsPanelState?>(
                      selector: _selectSettingsPanelState,
                      builder: (context, panelState) {
                        if (panelState == null) {
                          return const SizedBox.shrink();
                        }
                        return SingleChildScrollView(
                          padding: const EdgeInsets.only(right: 4, bottom: 8),
                          child: FilterEditorSettingsSection(
                            state: panelState.ready,
                            embedded: true,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                VerticalDivider(width: 1, color: scheme.outlineVariant),
                Expanded(
                  flex: 30,
                  child: _DialogColumn(
                    title: context.l10n.tOr(
                      'feFilterSectionPreview',
                      'Preview',
                    ),
                    child: RepaintBoundary(
                      child: BlocSelector<FilterEditorBloc, FilterEditorState,
                          _FilterPreviewPanelState?>(
                        selector: _selectFilterPreviewPanelState,
                        builder: (context, panelState) {
                          if (panelState == null) {
                            return const SizedBox.shrink();
                          }
                          return SingleChildScrollView(
                            padding:
                                const EdgeInsets.only(right: 4, bottom: 8),
                            child: FilterEditorPreviewPanel(
                              state: panelState.ready,
                              embedded: true,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (isSaving)
              const ColoredBox(
                color: Color(0x44000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }
}

class _FilterBasicPanelState {
  const _FilterBasicPanelState({required this.ready});

  final FilterEditorReady ready;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _FilterBasicPanelState) return false;
    final a = ready.form;
    final b = other.ready.form;
    return a.previewColorHex == b.previewColorHex &&
        a.engineKey == b.engineKey &&
        a.thumbnailUrl == b.thumbnailUrl &&
        a.isOriginal == b.isOriginal &&
        a.isBeautyDefault == b.isBeautyDefault &&
        a.isActive == b.isActive &&
        ready.isUploadingThumbnail == other.ready.isUploadingThumbnail &&
        ready.thumbnailFileName == other.ready.thumbnailFileName &&
        ready.fieldErrors == other.ready.fieldErrors &&
        ready.colorMatrix == other.ready.colorMatrix;
  }

  @override
  int get hashCode => Object.hash(
        ready.form.previewColorHex,
        ready.form.engineKey,
        ready.form.thumbnailUrl,
        ready.form.isOriginal,
        ready.form.isBeautyDefault,
        ready.form.isActive,
        ready.isUploadingThumbnail,
        ready.thumbnailFileName,
        ready.fieldErrors,
        ready.colorMatrix,
      );
}

_FilterBasicPanelState? _selectFilterBasicPanelState(FilterEditorState state) {
  if (state is! FilterEditorReady) return null;
  return _FilterBasicPanelState(ready: state);
}

class _SettingsPanelState {
  const _SettingsPanelState({required this.ready});

  final FilterEditorReady ready;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _SettingsPanelState) return false;
    final a = ready;
    final b = other.ready;
    return a.schema == b.schema &&
        a.settingsSearchQuery == b.settingsSearchQuery &&
        a.expandedGroups == b.expandedGroups &&
        a.allGroupsExpanded == b.allGroupsExpanded &&
        a.form.filterSettings == b.form.filterSettings;
  }

  @override
  int get hashCode => Object.hash(
        ready.schema,
        ready.settingsSearchQuery,
        ready.expandedGroups,
        ready.allGroupsExpanded,
        ready.form.filterSettings,
      );
}

_SettingsPanelState? _selectSettingsPanelState(FilterEditorState state) {
  if (state is! FilterEditorReady) return null;
  return _SettingsPanelState(ready: state);
}

class _FilterPreviewPanelState {
  const _FilterPreviewPanelState({required this.ready});

  final FilterEditorReady ready;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _FilterPreviewPanelState) return false;
    final a = ready.form;
    final b = other.ready.form;
    return a.previewColorHex == b.previewColorHex &&
        a.engineKey == b.engineKey &&
        a.thumbnailUrl == b.thumbnailUrl &&
        a.customLabel == b.customLabel &&
        a.labelKey == b.labelKey &&
        a.slug == b.slug &&
        a.filterSettings == b.filterSettings &&
        ready.schema == other.ready.schema &&
        ready.colorMatrix == other.ready.colorMatrix;
  }

  @override
  int get hashCode => Object.hash(
        ready.form.previewColorHex,
        ready.form.engineKey,
        ready.form.thumbnailUrl,
        ready.form.customLabel,
        ready.form.labelKey,
        ready.form.slug,
        ready.form.filterSettings,
        ready.schema,
        ready.colorMatrix,
      );
}

_FilterPreviewPanelState? _selectFilterPreviewPanelState(
  FilterEditorState state,
) {
  if (state is! FilterEditorReady) return null;
  return _FilterPreviewPanelState(ready: state);
}

class _DialogColumn extends StatelessWidget {

  const _DialogColumn({

    required this.title,

    required this.child,

  });



  final String title;

  final Widget child;



  @override

  Widget build(BuildContext context) {

    final scheme = Theme.of(context).colorScheme;



    return Padding(

      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          Text(

            title,

            style: Theme.of(context).textTheme.titleSmall?.copyWith(

                  fontWeight: FontWeight.w700,

                  color: scheme.primary,

                ),

          ),

          const SizedBox(height: 8),

          Expanded(child: child),

        ],

      ),

    );

  }

}

