import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/gifts_bloc.dart';
import 'bulk_gift_confirm_dialog.dart';

/// Compact selection bar with bulk activate/deactivate + delete actions.
class GiftsBulkSelectionToolbar extends StatelessWidget {
  const GiftsBulkSelectionToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<GiftsBloc, GiftsState, _SelectionToolbarData>(
      selector: (state) {
        if (state is! GiftsLoaded || !state.isSelectionMode) {
          return const _SelectionToolbarData.hidden();
        }
        return _SelectionToolbarData(
          selectedCount: state.selectedCount,
          allVisibleSelected: state.allVisibleSelected,
          someVisibleSelected: state.someVisibleSelected,
          isPerformingBulkAction: state.isPerformingBulkAction,
        );
      },
      builder: (context, data) {
        if (!data.visible) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
          ),
          child: Stack(
            children: [
              IgnorePointer(
                ignoring: data.isPerformingBulkAction,
                child: Opacity(
                  opacity: data.isPerformingBulkAction ? 0.55 : 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 720;
                      return Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Checkbox(
                                  tristate: true,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  value: data.allVisibleSelected
                                      ? true
                                      : data.someVisibleSelected
                                          ? null
                                          : false,
                                  onChanged: (_) => context
                                      .read<GiftsBloc>()
                                      .add(SelectAllGiftsEvent()),
                                ),
                                Flexible(
                                  child: Text(
                                    context.tr('giftsSelectedCount', {
                                      'count': '${data.selectedCount}',
                                    }),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (!narrow) ...[
                                  _ToolbarLink(
                                    icon: Icons.select_all_rounded,
                                    label: l10n.t('selectAllVisible'),
                                    onPressed: () => context
                                        .read<GiftsBloc>()
                                        .add(SelectAllGiftsEvent()),
                                  ),
                                  _ToolbarLink(
                                    icon: Icons.clear_all_rounded,
                                    label: l10n.t('clearSelection'),
                                    onPressed: () => context
                                        .read<GiftsBloc>()
                                        .add(ClearGiftSelectionEvent()),
                                  ),
                                ] else ...[
                                  IconButton(
                                    tooltip: l10n.t('selectAllVisible'),
                                    icon: const Icon(
                                      Icons.select_all_rounded,
                                      size: 20,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    onPressed: () => context
                                        .read<GiftsBloc>()
                                        .add(SelectAllGiftsEvent()),
                                  ),
                                  IconButton(
                                    tooltip: l10n.t('clearSelection'),
                                    icon: const Icon(
                                      Icons.clear_all_rounded,
                                      size: 20,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    onPressed: () => context
                                        .read<GiftsBloc>()
                                        .add(ClearGiftSelectionEvent()),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          _ChangeStatusButton(l10n: l10n, compact: narrow),
                          const SizedBox(width: 6),
                          _DeleteButton(l10n: l10n, compact: narrow),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (data.isPerformingBulkAction)
                const Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ToolbarLink extends StatelessWidget {
  const _ToolbarLink({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 17),
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
    );
  }
}

class _ChangeStatusButton extends StatelessWidget {
  const _ChangeStatusButton({required this.l10n, this.compact = false});

  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MenuAnchor(
      builder: (context, controller, child) {
        return OutlinedButton.icon(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: 8,
            ),
            minimumSize: Size(compact ? 0 : 64, 34),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(color: scheme.outlineVariant),
          ),
          icon: const Icon(Icons.arrow_drop_down_rounded, size: 18),
          label: Text(
            compact ? l10n.t('status') : l10n.t('changeStatus'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        );
      },
      menuChildren: [
        MenuItemButton(
          onPressed: () => _confirmActivate(context),
          child: Row(
            children: [
              Icon(Icons.visibility_rounded, size: 16, color: scheme.tertiary),
              const SizedBox(width: 8),
              Text(l10n.t('activate')),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () => _confirmDeactivate(context),
          child: Row(
            children: [
              Icon(Icons.visibility_off_rounded,
                  size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Text(l10n.t('deactivate')),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmActivate(BuildContext context) async {
    if (selectedGiftsCount(context) == 0) return;

    final confirmed = await confirmGiftAdminAction(
      context,
      title: l10n.t('activate'),
      message: giftsActivateConfirmMessage(l10n),
    );
    if (confirmed && context.mounted) {
      context.read<GiftsBloc>().add(ActivateSelectedGiftsEvent());
    }
  }

  Future<void> _confirmDeactivate(BuildContext context) async {
    if (selectedGiftsCount(context) == 0) return;

    final confirmed = await confirmGiftAdminAction(
      context,
      title: l10n.t('deactivate'),
      message: giftsDeactivateConfirmMessage(l10n),
    );
    if (confirmed && context.mounted) {
      context.read<GiftsBloc>().add(DeactivateSelectedGiftsEvent());
    }
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.l10n, this.compact = false});

  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return compact
        ? IconButton.filledTonal(
            onPressed: () => _confirmDelete(context),
            tooltip: l10n.t('delete'),
            style: IconButton.styleFrom(
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.onErrorContainer,
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(34, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
          )
        : FilledButton.tonalIcon(
            onPressed: () => _confirmDelete(context),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(64, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.onErrorContainer,
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 17),
            label: Text(
              l10n.t('delete'),
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    if (selectedGiftsCount(context) == 0) return;

    final confirmed = await confirmGiftAdminAction(
      context,
      title: l10n.tOr('delete', 'Delete'),
      message: giftsDeleteConfirmMessage(l10n),
      destructive: true,
    );
    if (confirmed && context.mounted) {
      context.read<GiftsBloc>().add(DeleteSelectedGiftsEvent());
    }
  }
}

class _SelectionToolbarData {
  const _SelectionToolbarData({
    required this.selectedCount,
    required this.allVisibleSelected,
    required this.someVisibleSelected,
    required this.isPerformingBulkAction,
  }) : visible = true;

  const _SelectionToolbarData.hidden()
      : selectedCount = 0,
        allVisibleSelected = false,
        someVisibleSelected = false,
        isPerformingBulkAction = false,
        visible = false;

  final int selectedCount;
  final bool allVisibleSelected;
  final bool someVisibleSelected;
  final bool isPerformingBulkAction;
  final bool visible;
}
