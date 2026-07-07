import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/chat_management_bloc.dart';

/// Selection bar with select-all / clear controls — matches [UsersSelectionHeader].
class ChatsSelectionHeader extends StatelessWidget {
  const ChatsSelectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<ChatManagementBloc, ChatManagementState, _SelectionBarData>(
      selector: (state) {
        if (state is! ChatManagementLoaded || !state.hasChatSelection) {
          return const _SelectionBarData.hidden();
        }
        return _SelectionBarData(
          selectedCount: state.selectedChatIds.length,
          allVisibleSelected: state.allChatsSelected,
          someVisibleSelected: state.someChatsSelected,
          isSubmitting: state.isSubmitting,
        );
      },
      builder: (context, data) {
        if (!data.visible) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
          ),
          child: IgnorePointer(
            ignoring: data.isSubmitting,
            child: Opacity(
              opacity: data.isSubmitting ? 0.55 : 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 520;
                  final bloc = context.read<ChatManagementBloc>();

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
                            : (_) => bloc.add(const ChatsSelectAllToggled()),
                      ),
                      Flexible(
                        child: Text(
                          context.tr('chatsSelectedCount', {
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
                          label: l10n.t('selectAllChats'),
                          onPressed: data.isSubmitting
                              ? null
                              : () => bloc.add(const ChatsSelectAllVisible()),
                        ),
                        _ToolbarLink(
                          icon: Icons.clear_all_rounded,
                          label: l10n.t('clearSelection'),
                          onPressed: data.isSubmitting || data.selectedCount == 0
                              ? null
                              : () => bloc.add(const ChatSelectionCleared()),
                        ),
                      ] else ...[
                        IconButton(
                          tooltip: l10n.t('selectAllChats'),
                          icon: const Icon(Icons.select_all_rounded, size: 20),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: data.isSubmitting
                              ? null
                              : () => bloc.add(const ChatsSelectAllVisible()),
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
                              : () => bloc.add(const ChatSelectionCleared()),
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

class _SelectionBarData {
  const _SelectionBarData({
    required this.selectedCount,
    required this.allVisibleSelected,
    required this.someVisibleSelected,
    required this.isSubmitting,
  }) : visible = true;

  const _SelectionBarData.hidden()
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
