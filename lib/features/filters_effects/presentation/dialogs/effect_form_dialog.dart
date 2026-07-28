import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/effect_editor_bloc.dart';
import '../bloc/effect_editor_event.dart';
import '../bloc/effect_editor_state.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../utils/fe_api_errors.dart';
import '../widgets/effect_editor_basic_section.dart';
import '../widgets/effect_editor_composition_section.dart';
import '../widgets/effect_editor_preview_panel.dart';

Future<bool?> openEffectEditor(BuildContext context, {String? effectId}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => BlocProvider(
      create: (_) =>
          di.sl<EffectEditorBloc>()
            ..add(LoadEffectEditorEvent(effectId: effectId)),
      child: EffectFormDialog(effectId: effectId),
    ),
  );
}

void showEffectFormDialog(BuildContext context, {CameraEffectEntity? editing}) {
  openEffectEditor(context, effectId: editing?.id);
}

class EffectFormDialog extends StatelessWidget {
  const EffectFormDialog({super.key, this.effectId});

  final String? effectId;

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

  Future<void> _handleClose(
    BuildContext context,
    EffectEditorState state,
  ) async {
    final ready = state is EffectEditorReady ? state : null;
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
    return BlocListener<EffectEditorBloc, EffectEditorState>(
      listenWhen: (previous, current) {
        if (current is EffectEditorReady &&
            current.saveSucceeded &&
            (previous is! EffectEditorReady || !previous.saveSucceeded)) {
          return true;
        }
        if (current is EffectEditorReady &&
            current.submitError != null &&
            (previous is! EffectEditorReady ||
                previous.submitError != current.submitError)) {
          return true;
        }
        return false;
      },
      listener: (context, state) {
        if (state is! EffectEditorReady) return;
        if (state.saveSucceeded) {
          context.read<EffectEditorBloc>().add(
            const ClearEffectEditorSaveFlagEvent(),
          );
          Navigator.of(context).pop(true);
          return;
        }
        if (state.submitError != null) {
          final errorKey = state.submitError!;
          context.read<EffectEditorBloc>().add(
            const ClearEffectEditorSubmitErrorEvent(),
          );

          if (errorKey == feFilterEffectAlreadyExistsKey) {
            try {
              context.read<FiltersEffectsBloc>().add(
                ShowFiltersEffectsMessage(errorKey),
              );
              return;
            } catch (_) {
              // Fall through to a local dialog if the page bloc is unavailable.
            }
          }

          final l10n = context.l10n;
          final errorText = l10n.tOr(errorKey, errorKey);
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.tOr('error', 'Error')),
              content: Text(errorText),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.tOr('close', 'Close')),
                ),
              ],
            ),
          );
        }
      },
      child: BlocBuilder<EffectEditorBloc, EffectEditorState>(
        buildWhen: (previous, current) {
          if (previous.runtimeType != current.runtimeType) return true;
          if (current is EffectEditorReady && previous is EffectEditorReady) {
            return previous.isSaving != current.isSaving ||
                previous.effectId != current.effectId;
          }
          return false;
        },
        builder: (context, state) {
          final l10n = context.l10n;
          final ready = state is EffectEditorReady ? state : null;
          final screen = MediaQuery.sizeOf(context);
          final dialogWidth = (screen.width * 0.94).clamp(960.0, 1280.0);
          final dialogHeight = (screen.height * 0.88).clamp(520.0, 820.0);

          return AlertDialog(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    ready?.isEditing == true
                        ? l10n.tOr('feEditEffect', 'Edit effect')
                        : l10n.tOr('feCreateEffect', 'Create effect'),
                  ),
                ),
                IconButton(
                  tooltip: l10n.t('cancel'),
                  onPressed: state is EffectEditorLoading
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
              child: _EffectEditorDialogBody(effectId: effectId),
            ),
            actions: [
              TextButton(
                onPressed: state is EffectEditorLoading
                    ? null
                    : () => _handleClose(context, state),
                child: Text(l10n.t('cancel')),
              ),
              if (ready != null)
                FilledButton(
                  onPressed: ready.isSaving || ready.isUploadingAsset
                      ? null
                      : () => context.read<EffectEditorBloc>().add(
                          const SubmitEffectEditorEvent(),
                        ),
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

class _EffectEditorDialogBody extends StatelessWidget {
  const _EffectEditorDialogBody({required this.effectId});

  final String? effectId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EffectEditorBloc, EffectEditorState>(
      buildWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      builder: (context, state) {
        if (state is EffectEditorLoading) {
          return const Center(child: LoadingView());
        }

        if (state is EffectEditorError) {
          return Center(
            child: ErrorView(
              message: state.message,
              retryLabel: context.l10n.t('retry'),
              onRetry: () => context.read<EffectEditorBloc>().add(
                LoadEffectEditorEvent(effectId: effectId),
              ),
            ),
          );
        }

        if (state is! EffectEditorReady) {
          return const SizedBox.shrink();
        }

        return const _EffectEditorReadyBody();
      },
    );
  }
}

class _EffectEditorReadyBody extends StatelessWidget {
  const _EffectEditorReadyBody();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<EffectEditorBloc, EffectEditorState, bool>(
      selector: (state) => state is EffectEditorReady ? state.isSaving : false,
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
                      'feEffectSectionBasic',
                      'Basic information',
                    ),
                    child:
                        BlocSelector<
                          EffectEditorBloc,
                          EffectEditorState,
                          _BasicPanelState?
                        >(
                          selector: _selectBasicPanelState,
                          builder: (context, panelState) {
                            if (panelState == null)
                              return const SizedBox.shrink();
                            return SingleChildScrollView(
                              padding: const EdgeInsets.only(
                                right: 4,
                                bottom: 8,
                              ),
                              child: EffectEditorBasicSection(
                                key: ValueKey(
                                  panelState.ready.effectId ?? 'new-effect',
                                ),
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
                  flex: 40,
                  child: _DialogColumn(
                    title: context.l10n.tOr(
                      'feEffectSectionComposition',
                      'Effect composition',
                    ),
                    child:
                        BlocSelector<
                          EffectEditorBloc,
                          EffectEditorState,
                          _CompositionPanelState?
                        >(
                          selector: _selectCompositionPanelState,
                          builder: (context, panelState) {
                            if (panelState == null)
                              return const SizedBox.shrink();
                            return SingleChildScrollView(
                              padding: const EdgeInsets.only(
                                right: 4,
                                bottom: 8,
                              ),
                              child: EffectEditorCompositionSection(
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
                      'feEffectSectionPreview',
                      'Live preview',
                    ),
                    child: RepaintBoundary(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(right: 4, bottom: 8),
                        child: const EffectEditorPreviewPanel(embedded: true),
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

class _BasicPanelState {
  const _BasicPanelState({required this.ready});

  final EffectEditorReady ready;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _BasicPanelState) return false;
    final a = ready.form;
    final b = other.ready.form;
    return a.renderType == b.renderType &&
        a.previewColorHex == b.previewColorHex &&
        a.distortionPreset == b.distortionPreset &&
        a.isActive == b.isActive &&
        a.emoji == b.emoji &&
        a.assetUrl == b.assetUrl &&
        a.assetAsset == b.assetAsset &&
        ready.fieldErrors == other.ready.fieldErrors &&
        ready.isUploadingAsset == other.ready.isUploadingAsset &&
        ready.assetFileName == other.ready.assetFileName;
  }

  @override
  int get hashCode => Object.hash(
    ready.form.renderType,
    ready.form.previewColorHex,
    ready.form.distortionPreset,
    ready.form.isActive,
    ready.form.emoji,
    ready.form.assetUrl,
    ready.form.assetAsset,
    ready.fieldErrors,
    ready.isUploadingAsset,
    ready.assetFileName,
  );
}

_BasicPanelState? _selectBasicPanelState(EffectEditorState state) {
  if (state is! EffectEditorReady) return null;
  return _BasicPanelState(ready: state);
}

class _CompositionPanelState {
  const _CompositionPanelState({required this.ready});

  final EffectEditorReady ready;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _CompositionPanelState) return false;
    final a = ready.form;
    final b = other.ready.form;
    return a.renderType == b.renderType &&
        a.anchor == b.anchor &&
        a.stickers == b.stickers &&
        a.distortionPreset == b.distortionPreset &&
        ready.fieldErrors == other.ready.fieldErrors;
  }

  @override
  int get hashCode => Object.hash(
    ready.form.renderType,
    ready.form.anchor,
    ready.form.stickers,
    ready.form.distortionPreset,
    ready.fieldErrors,
  );
}

_CompositionPanelState? _selectCompositionPanelState(EffectEditorState state) {
  if (state is! EffectEditorReady) return null;
  return _CompositionPanelState(ready: state);
}

class _DialogColumn extends StatelessWidget {
  const _DialogColumn({required this.title, required this.child});

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
