import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/chat_management_bloc.dart';
import 'chat_ui_shared.dart';

/// Selection bar with select-all / clear controls for the messages panel.
class MessagesSelectionHeader extends StatelessWidget {
  const MessagesSelectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<ChatManagementBloc, ChatManagementState,
        _MessagesSelectionBarData>(
      selector: (state) {
        if (state is! ChatManagementLoaded || !state.hasMessageSelection) {
          return const _MessagesSelectionBarData.hidden();
        }
        return _MessagesSelectionBarData(
          selectedCount: state.selectedMessageIds.length,
          allVisibleSelected: state.allMessagesSelected,
          someVisibleSelected: state.someMessagesSelected,
          isSubmitting: state.isSubmitting,
        );
      },
      builder: (context, data) {
        if (!data.visible) return const SizedBox.shrink();

        final bloc = context.read<ChatManagementBloc>();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.errorContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
          ),
          child: IgnorePointer(
            ignoring: data.isSubmitting,
            child: Opacity(
              opacity: data.isSubmitting ? 0.55 : 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 620;

                  return Row(
                    children: [
                      Checkbox(
                        tristate: true,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: data.allVisibleSelected
                            ? true
                            : data.someVisibleSelected
                                ? null
                                : false,
                        onChanged: data.isSubmitting
                            ? null
                            : (_) =>
                                bloc.add(const MessagesSelectAllToggled()),
                      ),
                      Flexible(
                        child: Text(
                          context.tr('messagesSelectedCount', {
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
                          label: l10n.t('selectAllMessages'),
                          onPressed: data.isSubmitting
                              ? null
                              : () =>
                                  bloc.add(const MessagesSelectAllVisible()),
                        ),
                        _ToolbarLink(
                          icon: Icons.clear_all_rounded,
                          label: l10n.t('clearSelection'),
                          onPressed: data.isSubmitting || data.selectedCount == 0
                              ? null
                              : () => bloc.add(const MessageSelectionCleared()),
                        ),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.errorContainer,
                            foregroundColor: scheme.onErrorContainer,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: data.isSubmitting
                              ? null
                              : () async {
                                  final ok = await confirmChatModerationAction(
                                    context,
                                    title: l10n.t('deleteMessagesTitle'),
                                    message: context.tr(
                                      'deleteMessagesConfirm',
                                      {'count': '${data.selectedCount}'},
                                    ),
                                    destructive: true,
                                  );
                                  if (ok && context.mounted) {
                                    bloc.add(const MessagesBulkDeleteRequested());
                                  }
                                },
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: Text(l10n.t('delete')),
                        ),
                      ] else ...[
                        IconButton(
                          tooltip: l10n.t('selectAllMessages'),
                          icon: const Icon(Icons.select_all_rounded, size: 20),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: data.isSubmitting
                              ? null
                              : () =>
                                  bloc.add(const MessagesSelectAllVisible()),
                        ),
                        IconButton(
                          tooltip: l10n.t('clearSelection'),
                          icon: const Icon(Icons.clear_all_rounded, size: 20),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: data.isSubmitting || data.selectedCount == 0
                              ? null
                              : () => bloc.add(const MessageSelectionCleared()),
                        ),
                        IconButton(
                          tooltip: l10n.t('delete'),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: scheme.onErrorContainer,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: data.isSubmitting
                              ? null
                              : () async {
                                  final ok = await confirmChatModerationAction(
                                    context,
                                    title: l10n.t('deleteMessagesTitle'),
                                    message: context.tr(
                                      'deleteMessagesConfirm',
                                      {'count': '${data.selectedCount}'},
                                    ),
                                    destructive: true,
                                  );
                                  if (ok && context.mounted) {
                                    bloc.add(const MessagesBulkDeleteRequested());
                                  }
                                },
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
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
  final VoidCallback? onPressed;

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

class _MessagesSelectionBarData {
  const _MessagesSelectionBarData({
    required this.selectedCount,
    required this.allVisibleSelected,
    required this.someVisibleSelected,
    required this.isSubmitting,
  }) : visible = true;

  const _MessagesSelectionBarData.hidden()
      : selectedCount = 0,
        allVisibleSelected = false,
        someVisibleSelected = false,
        isSubmitting = false,
        visible = false;

  final int selectedCount;
  final bool allVisibleSelected;
  final bool someVisibleSelected;
  final bool isSubmitting;
  final bool visible;
}
