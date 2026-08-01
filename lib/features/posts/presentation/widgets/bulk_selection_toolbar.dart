import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../features/post_management/presentation/utils/post_detail_labels.dart';
import '../bloc/posts_bloc.dart';
import 'bulk_post_confirm_dialog.dart';
import 'post_list_location.dart';

/// Compact glassmorphism bulk-action bar for post selection.
class BulkSelectionToolbar extends StatelessWidget {
  const BulkSelectionToolbar({super.key});

  static const _iconSize = 22.0;
  static const _actionSize = 34.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocSelector<PostsBloc, PostsState, _SelectionToolbarData>(
      selector: (state) {
        if (state is! PostsLoaded || !state.isSelectionMode) {
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

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : scheme.outlineVariant.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: PostCardPremiumColors.accentGold.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              IgnorePointer(
                ignoring: data.isPerformingBulkAction,
                child: Opacity(
                  opacity: data.isPerformingBulkAction ? 0.5 : 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final collapse = constraints.maxWidth < 420;
                      final wrap = constraints.maxWidth < 560 && !collapse;

                      final countLabel = Text(
                        context.tr('postsSelectedCount', {
                          'count': '${data.selectedCount}',
                        }),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                              fontSize: 13,
                            ),
                      );

                      final selectAll = _GlassIconAction(
                        icon: Icons.select_all_rounded,
                        tooltip: l10n.tOr('selectAll', 'Select All'),
                        onPressed: () => context
                            .read<PostsBloc>()
                            .add(SelectAllPostsEvent()),
                      );

                      final clear = _GlassIconAction(
                        icon: Icons.deselect_rounded,
                        tooltip: l10n.t('clearSelection'),
                        onPressed: () => context
                            .read<PostsBloc>()
                            .add(ClearSelectionEvent()),
                      );

                      final status = _ChangeStatusIconButton(l10n: l10n);
                      final delete = _DeleteIconButton(l10n: l10n);

                      if (collapse) {
                        return Row(
                          children: [
                            _SelectAllCheckbox(data: data),
                            const SizedBox(width: 6),
                            Flexible(child: countLabel),
                            const SizedBox(width: 4),
                            selectAll,
                            clear,
                            _OverflowActionsMenu(
                              l10n: l10n,
                              statusOptions: _ChangeStatusIconButton.options,
                            ),
                          ],
                        );
                      }

                      final actions = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          selectAll,
                          clear,
                          status,
                          delete,
                        ],
                      );

                      if (wrap) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                _SelectAllCheckbox(data: data),
                                const SizedBox(width: 6),
                                Flexible(child: countLabel),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: actions,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          _SelectAllCheckbox(data: data),
                          const SizedBox(width: 6),
                          Flexible(child: countLabel),
                          const SizedBox(width: 4),
                          actions,
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
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
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

class _SelectAllCheckbox extends StatelessWidget {
  const _SelectAllCheckbox({required this.data});

  final _SelectionToolbarData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Checkbox(
        tristate: true,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
        ),
        activeColor: PostCardPremiumColors.accentGold,
        checkColor: PostCardPremiumColors.black,
        value: data.allVisibleSelected
            ? true
            : data.someVisibleSelected
                ? null
                : false,
        onChanged: (_) =>
            context.read<PostsBloc>().add(SelectAllPostsEvent()),
      ),
    );
  }
}

class _GlassIconAction extends StatefulWidget {
  const _GlassIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  State<_GlassIconAction> createState() => _GlassIconActionState();
}

class _GlassIconActionState extends State<_GlassIconAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = widget.destructive
        ? scheme.error
        : (_hovered
            ? PostCardPremiumColors.accentGold
            : scheme.onSurface.withValues(alpha: 0.82));

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: BulkSelectionToolbar._actionSize,
            height: BulkSelectionToolbar._actionSize,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hovered
                  ? (widget.destructive
                      ? scheme.error.withValues(alpha: 0.12)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05)))
                  : Colors.transparent,
              border: Border.all(
                color: _hovered
                    ? (widget.destructive
                        ? scheme.error.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: isDark ? 0.22 : 0.55))
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              widget.icon,
              size: BulkSelectionToolbar._iconSize,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChangeStatusIconButton extends StatelessWidget {
  const _ChangeStatusIconButton({required this.l10n});

  final AppLocalizations l10n;

  static const options = [
    _StatusOption('PUBLISHED', PublishSelectedPostsEvent.new),
    _StatusOption('DRAFT', DraftSelectedPostsEvent.new),
    _StatusOption('BANNED', BanSelectedPostsEvent.new),
    _StatusOption('HIDDEN', HideSelectedPostsEvent.new),
    _StatusOption('UNDER_REVIEW', UnderReviewSelectedPostsEvent.new),
    _StatusOption('ARCHIVED', ArchiveSelectedPostsEvent.new),
  ];

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return _GlassIconAction(
          icon: Icons.swap_horiz_rounded,
          tooltip: l10n.tOr('changeStatus', 'Change Status'),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
      menuChildren: options
          .map(
            (opt) => MenuItemButton(
              onPressed: () => applyStatus(context, l10n, opt),
              child: Row(
                children: [
                  Icon(
                    postStatusIcon(opt.status),
                    size: 16,
                    color: postStatusColor(opt.status),
                  ),
                  const SizedBox(width: 8),
                  Text(postStatusLabel(l10n, opt.status)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  static Future<void> applyStatus(
    BuildContext context,
    AppLocalizations l10n,
    _StatusOption opt,
  ) async {
    final count = selectedPostsCount(context);
    if (count == 0) return;

    final statusLabel = postStatusLabel(l10n, opt.status);
    final message = postsStatusConfirmMessage(l10n, statusLabel);

    final confirmed = await confirmPostAdminAction(
      context,
      title: l10n.tOr('changeStatus', 'Change Status'),
      message: message,
      destructive: isDestructivePostStatus(opt.status),
    );
    if (!confirmed || !context.mounted) return;

    context.read<PostsBloc>().add(opt.event());
  }
}

class _DeleteIconButton extends StatelessWidget {
  const _DeleteIconButton({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _GlassIconAction(
      icon: Icons.delete_outline_rounded,
      tooltip: l10n.t('delete'),
      destructive: true,
      onPressed: () => confirmDelete(context, l10n),
    );
  }

  static Future<void> confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    if (selectedPostsCount(context) == 0) return;

    final confirmed = await confirmPostAdminAction(
      context,
      title: l10n.tOr('delete', 'Delete'),
      message: postsDeleteConfirmMessage(l10n),
      destructive: true,
    );
    if (confirmed && context.mounted) {
      context.read<PostsBloc>().add(DeleteSelectedPostsEvent());
    }
  }
}

class _OverflowActionsMenu extends StatelessWidget {
  const _OverflowActionsMenu({
    required this.l10n,
    required this.statusOptions,
  });

  final AppLocalizations l10n;
  final List<_StatusOption> statusOptions;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return _GlassIconAction(
          icon: Icons.more_horiz_rounded,
          tooltip: l10n.tOr('moreActions', 'More actions'),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
      menuChildren: [
        SubmenuButton(
          menuChildren: statusOptions
              .map(
                (opt) => MenuItemButton(
                  onPressed: () =>
                      _ChangeStatusIconButton.applyStatus(context, l10n, opt),
                  child: Row(
                    children: [
                      Icon(
                        postStatusIcon(opt.status),
                        size: 16,
                        color: postStatusColor(opt.status),
                      ),
                      const SizedBox(width: 8),
                      Text(postStatusLabel(l10n, opt.status)),
                    ],
                  ),
                ),
              )
              .toList(),
          child: Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, size: 18),
              const SizedBox(width: 8),
              Text(l10n.tOr('changeStatus', 'Change Status')),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () => _DeleteIconButton.confirmDelete(context, l10n),
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.t('delete'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusOption {
  const _StatusOption(this.status, this.event);

  final String status;
  final PostsEvent Function() event;
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
