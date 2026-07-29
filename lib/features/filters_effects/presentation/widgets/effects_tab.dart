import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../../core/widgets/dashboard/responsive_data_table.dart';
import '../../../../core/widgets/dashboard/status_chip.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../rbac/presentation/bloc/rbac_bloc.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../bloc/filters_effects_state.dart';
import '../dialogs/effect_form_dialog.dart';
import '../dialogs/fe_item_preview_dialog.dart';
import '../dialogs/fe_confirm_dialog.dart';
import '../utils/fe_display_filters.dart';
import '../utils/filters_effects_responsive.dart';
import '../utils/fe_effect_emoji_display.dart';
import 'fe_catalog_item_preview.dart' show feEffectRenderTypeLabel;
import 'fe_tab_scaffold.dart';

Future<void> _openEditor(BuildContext context, {String? effectId}) async {
  final saved = await openEffectEditor(context, effectId: effectId);
  if (!context.mounted) return;
  if (saved == true) {
    context.read<FiltersEffectsBloc>().add(const LoadCameraEffects());
    context.read<FiltersEffectsBloc>().add(
      ShowFiltersEffectsMessage(
        effectId == null
            ? 'feEffectCreatedSuccess'
            : 'feEffectUpdatedSuccess',
        isError: false,
      ),
    );
  }
}

class EffectsTab extends StatelessWidget {
  const EffectsTab({
    super.key,
    required this.loaded,
    required this.metrics,
    this.selectedCategoryId,
    this.onClearCategory,
  });

  final FiltersEffectsLoaded loaded;
  final FiltersEffectsLayoutMetrics metrics;
  final String? selectedCategoryId;
  final VoidCallback? onClearCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canManage = _canManage(context);
    final items = effectsForDisplay(
      pagedEffects: loaded.pagedEffects,
      effectCategories: loaded.effectCategories,
      query: loaded.query,
      selectedCategoryId: selectedCategoryId,
    );
    final selectionEnabled = canManage && !loaded.isBulkDeleting;
    final categorySelected = selectedCategoryId != null;

    final allVisibleSelected = items.isNotEmpty &&
        items.every((e) => loaded.selectedEffectIds.contains(e.id));
    final someVisibleSelected = items.any(
          (e) => loaded.selectedEffectIds.contains(e.id),
        ) &&
        !allVisibleSelected;

    if (items.isEmpty) {
      return Center(
        child: EmptyView(
          message: l10n.tOr(
            'feNoEffects',
            'No effects match your filters.',
          ),
        ),
      );
    }

    return FeTabScaffold(
      footer: categorySelected
          ? null
          : AppPaginationBar(
              currentPage: loaded.query.page,
              lastPage: loaded.effectsTotalPages,
              total: loaded.effectsTotalCount,
              pageSize: loaded.query.pageSize,
              itemCount: items.length,
              hideWhenSinglePage: false,
              borderRadius: BorderRadius.circular(12),
              onPageChanged: (page) => context.read<FiltersEffectsBloc>().add(
                FiltersEffectsFilterChanged(page: page),
              ),
            ),
      child: ResponsiveDataTable(
        mobileBreakpoint: 900,
        columns: [
          if (selectionEnabled)
            DataColumn(
              label: Checkbox(
                tristate: true,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                value: allVisibleSelected
                    ? true
                    : someVisibleSelected
                        ? null
                        : false,
                onChanged: (_) {
                  if (!categorySelected) {
                    context.read<FiltersEffectsBloc>().add(
                      const SelectAllVisibleEffectsEvent(),
                    );
                    return;
                  }
                  final bloc = context.read<FiltersEffectsBloc>();
                  for (final effect in items) {
                    final selected =
                        loaded.selectedEffectIds.contains(effect.id);
                    if (allVisibleSelected == selected) {
                      bloc.add(ToggleEffectSelectionEvent(effect.id));
                    }
                  }
                },
              ),
            ),
          DataColumn(label: Text(l10n.tOr('feColThumbnail', 'Thumb'))),
          DataColumn(label: Text(l10n.tOr('feColName', 'Name'))),
          DataColumn(label: Text(l10n.tOr('feColSlug', 'Slug'))),
          DataColumn(label: Text(l10n.tOr('feColRenderType', 'Render type'))),
          DataColumn(label: Text(l10n.tOr('feColStatus', 'Status'))),
          DataColumn(label: Text(l10n.tOr('feColSortOrder', 'Order'))),
          DataColumn(label: Text(l10n.tOr('feColActions', 'Actions'))),
        ],
        rows: [
          for (final effect in items)
            DataRow(
              selected: loaded.selectedEffectIds.contains(effect.id),
              cells: [
                if (selectionEnabled)
                  DataCell(
                    Checkbox(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: loaded.selectedEffectIds.contains(effect.id),
                      onChanged: (_) => context.read<FiltersEffectsBloc>().add(
                        ToggleEffectSelectionEvent(effect.id),
                      ),
                    ),
                  ),
                DataCell(
                  FeEffectEmojiDisplay.build(
                    emoji: effect.emoji,
                    assetUrl: effect.assetUrl,
                  ),
                ),
                DataCell(Text(effect.displayLabel)),
                DataCell(Text(effect.slug)),
                DataCell(
                  Text(feEffectRenderTypeLabel(context, effect.renderType)),
                ),
                DataCell(_statusChip(context, effect.isActive)),
                DataCell(Text('${effect.sortOrder}')),
                DataCell(
                  _EffectActionsMenu(effect: effect, canManage: canManage),
                ),
              ],
            ),
        ],
        mobileCards: [
          for (final effect in items)
            _EffectMobileCard(
              effect: effect,
              canManage: canManage,
              selectionEnabled: selectionEnabled,
              isSelected: loaded.selectedEffectIds.contains(effect.id),
            ),
        ],
      ),
    );
  }

  bool _canManage(BuildContext context) {
    context.select<RbacBloc, Set<String>?>(
      (b) => b.state.authContext?.permissionKeys,
    );
    return PermissionManager.canManageCameraStudio(context);
  }

  Widget _statusChip(BuildContext context, bool isActive) {
    final l10n = context.l10n;
    return DashboardStatusChip(
      label: isActive
          ? l10n.tOr('feActive', 'Active')
          : l10n.tOr('feInactive', 'Inactive'),
      tone: isActive
          ? DashboardStatusTone.success
          : DashboardStatusTone.neutral,
    );
  }
}

class _EffectActionsMenu extends StatelessWidget {
  const _EffectActionsMenu({required this.effect, required this.canManage});

  final CameraEffectEntity effect;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    if (!canManage) return const SizedBox.shrink();
    final l10n = context.l10n;
    final bloc = context.read<FiltersEffectsBloc>();

    return PopupMenuButton<String>(
      tooltip: l10n.tOr('feActions', 'Actions'),
      onSelected: (action) {
        switch (action) {
          case 'preview':
            showEffectPreviewDialog(context, effect);
          case 'edit':
            _openEditor(context, effectId: effect.id);
          case 'activate':
            bloc.add(ActivateCameraEffectEvent(effect.id));
          case 'deactivate':
            bloc.add(DeactivateCameraEffectEvent(effect.id));
          case 'delete':
            showFeConfirmDialog(
              context,
              title: l10n.tOr('feDeleteEffectTitle', 'Delete effect'),
              message: l10n.tOr(
                'feDeleteEffectMessage',
                'Delete this effect permanently?',
              ),
              onConfirm: () => bloc.add(DeleteCameraEffectEvent(effect.id)),
            );
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'preview',
          child: Text(l10n.tOr('fePreview', 'Preview')),
        ),
        PopupMenuItem(value: 'edit', child: Text(l10n.tOr('feEdit', 'Edit'))),
        PopupMenuItem(
          value: effect.isActive ? 'deactivate' : 'activate',
          child: Text(
            effect.isActive
                ? l10n.tOr('feDeactivate', 'Deactivate')
                : l10n.tOr('feActivate', 'Activate'),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(l10n.tOr('feDelete', 'Delete')),
        ),
      ],
    );
  }
}

class _EffectMobileCard extends StatelessWidget {
  const _EffectMobileCard({
    required this.effect,
    required this.canManage,
    required this.selectionEnabled,
    required this.isSelected,
  });

  final CameraEffectEntity effect;
  final bool canManage;
  final bool selectionEnabled;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSelected
            ? scheme.primaryContainer.withValues(alpha: 0.22)
            : scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (selectionEnabled) ...[
                  Checkbox(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: isSelected,
                    onChanged: (_) => context.read<FiltersEffectsBloc>().add(
                      ToggleEffectSelectionEvent(effect.id),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                FeEffectEmojiDisplay.build(
                  emoji: effect.emoji,
                  assetUrl: effect.assetUrl,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        effect.displayLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${effect.slug} · '
                        '${feEffectRenderTypeLabel(context, effect.renderType)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _EffectActionsMenu(effect: effect, canManage: canManage),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                DashboardStatusChip(
                  label: effect.isActive
                      ? l10n.tOr('feActive', 'Active')
                      : l10n.tOr('feInactive', 'Inactive'),
                  tone: effect.isActive
                      ? DashboardStatusTone.success
                      : DashboardStatusTone.neutral,
                ),
                Text(
                  '${l10n.tOr('feColSortOrder', 'Order')}: ${effect.sortOrder}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
