import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/responsive_data_table.dart';
import '../../../../core/widgets/dashboard/status_chip.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/domain/utils/dashboard_permissions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../bloc/filters_effects_state.dart';
import '../dialogs/effect_form_dialog.dart';
import '../dialogs/fe_item_preview_dialog.dart';
import '../dialogs/fe_confirm_dialog.dart';
import '../utils/filters_effects_responsive.dart';
import 'fe_tab_scaffold.dart';
import 'filters_tab.dart';

class EffectsTab extends StatelessWidget {
  const EffectsTab({
    super.key,
    required this.loaded,
    required this.metrics,
  });

  final FiltersEffectsLoaded loaded;
  final FiltersEffectsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canManage = _canManage(context);
    final items = loaded.pagedEffects;
    final dateFmt = DateFormat.yMMMd();

    if (loaded.filteredEffects.isEmpty) {
      return Center(
        child: EmptyView(
          message: l10n.tOr('feNoEffects', 'No effects match your filters.'),
        ),
      );
    }

    return FeTabScaffold(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canManage)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: () => showEffectFormDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.tOr('feCreateEffect', 'Create effect')),
              ),
            ),
          if (canManage) SizedBox(height: metrics.filterGap),
        ],
      ),
      footer: FePaginationBar(
        page: loaded.query.page,
        totalPages: loaded.effectsTotalPages,
        totalItems: loaded.filteredEffects.length,
        metrics: metrics,
      ),
      child: ResponsiveDataTable(
        mobileBreakpoint: 900,
        columns: [
          DataColumn(label: Text(l10n.tOr('feColSlug', 'Slug'))),
          DataColumn(label: Text(l10n.tOr('feColEffectType', 'Type'))),
          DataColumn(label: Text(l10n.tOr('feColLabelKey', 'Label key'))),
          DataColumn(label: Text(l10n.tOr('feColEmoji', 'Emoji'))),
          DataColumn(label: Text(l10n.tOr('feColStatus', 'Status'))),
          DataColumn(label: Text(l10n.tOr('feColFlags', 'Flags'))),
          DataColumn(label: Text(l10n.tOr('feColSortOrder', 'Order'))),
          DataColumn(label: Text(l10n.tOr('feColUpdated', 'Updated'))),
          DataColumn(label: Text(l10n.tOr('feColActions', 'Actions'))),
        ],
        rows: [
          for (final effect in items)
            DataRow(
              cells: [
                DataCell(Text(effect.slug)),
                DataCell(Text(_effectTypeLabel(context, effect.effectType))),
                DataCell(Text(effect.labelKey)),
                DataCell(Text(effect.emoji ?? '—')),
                DataCell(_statusChip(context, effect.isActive)),
                DataCell(Text(_flagsLabel(context, effect))),
                DataCell(Text('${effect.sortOrder}')),
                DataCell(Text(
                  effect.updatedAt != null
                      ? dateFmt.format(effect.updatedAt!.toLocal())
                      : '—',
                )),
                DataCell(_actionsMenu(context, effect, canManage)),
              ],
            ),
        ],
        mobileCards: [
          for (final effect in items)
            _EffectMobileCard(
              effect: effect,
              effectTypeLabel: _effectTypeLabel(context, effect.effectType),
              canManage: canManage,
            ),
        ],
      ),
    );
  }

  bool _canManage(BuildContext context) {
    final roles = context.select<AuthBloc, List<UserRole>>((b) {
      final state = b.state;
      if (state is Authenticated) return state.user.roles;
      return const <UserRole>[];
    });
    return canManageFiltersEffects(roles);
  }

  Widget _statusChip(BuildContext context, bool isActive) {
    final l10n = context.l10n;
    return DashboardStatusChip(
      label: isActive
          ? l10n.tOr('feActive', 'Active')
          : l10n.tOr('feInactive', 'Inactive'),
      tone: isActive ? DashboardStatusTone.success : DashboardStatusTone.neutral,
    );
  }

  String _effectTypeLabel(BuildContext context, String value) {
    final l10n = context.l10n;
    return switch (CameraEffectTypeApi.normalize(value)) {
      CameraEffectTypeApi.screenOverlay =>
        l10n.tOr('feEffectTypeScreenOverlay', 'Screen overlay'),
      _ => l10n.tOr('feEffectTypeFaceAr', 'Face AR'),
    };
  }

  String _flagsLabel(BuildContext context, CameraEffectEntity effect) {
    final l10n = context.l10n;
    final flags = <String>[];
    if (effect.requiresFaceDetection) {
      flags.add(l10n.tOr('feFlagFaceDetection', 'Face detection'));
    }
    if (effect.isScreenEffect) {
      flags.add(l10n.tOr('feFlagScreenEffect', 'Screen effect'));
    }
    return flags.isEmpty ? '—' : flags.join(', ');
  }

  Widget _actionsMenu(
    BuildContext context,
    CameraEffectEntity effect,
    bool canManage,
  ) {
    if (!canManage) return const SizedBox.shrink();
    final l10n = context.l10n;
    final bloc = context.read<FiltersEffectsBloc>();

    return PopupMenuButton<String>(
      onSelected: (action) {
        switch (action) {
          case 'preview':
            showEffectPreviewDialog(context, effect);
          case 'edit':
            showEffectFormDialog(context, editing: effect);
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
        PopupMenuItem(
          value: 'edit',
          child: Text(l10n.tOr('feEdit', 'Edit')),
        ),
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
    required this.effectTypeLabel,
    required this.canManage,
  });

  final CameraEffectEntity effect;
  final String effectTypeLabel;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: ListTile(
        title: Text(effect.labelKey),
        subtitle: Text('${effect.slug} · $effectTypeLabel'),
        trailing: canManage
            ? IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => showEffectFormDialog(context, editing: effect),
              )
            : null,
      ),
    );
  }
}
