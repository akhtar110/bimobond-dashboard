import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/chat_entities.dart';
import '../bloc/chat_management_bloc.dart';

Future<void> showChatFiltersPopover(
  BuildContext context,
  ChatManagementLoaded initialState,
) {
  final bloc = context.read<ChatManagementBloc>();

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => BlocProvider.value(
      value: bloc,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: _ChatFiltersPanel(initialState: initialState),
          ),
        ),
      ),
    ),
  );
}

class _ChatFiltersPanel extends StatefulWidget {
  const _ChatFiltersPanel({required this.initialState});

  final ChatManagementLoaded initialState;

  @override
  State<_ChatFiltersPanel> createState() => _ChatFiltersPanelState();
}

class _ChatFiltersPanelState extends State<_ChatFiltersPanel> {
  late ChatMessageTypeFilter _typeFilter;
  late ChatDeletedFilter _deletedFilter;

  @override
  void initState() {
    super.initState();
    _typeFilter = widget.initialState.messagesQuery.typeFilter;
    _deletedFilter = widget.initialState.messagesQuery.deletedFilter;
  }

  void _apply() {
    final bloc = context.read<ChatManagementBloc>();
    final current = widget.initialState.messagesQuery;

    if (_typeFilter != current.typeFilter) {
      bloc.add(MessagesTypeFilterChanged(_typeFilter));
    }
    if (_deletedFilter != current.deletedFilter) {
      bloc.add(MessagesDeletedFilterChanged(_deletedFilter));
    }
    Navigator.pop(context);
  }

  void _resetDrafts() {
    setState(() {
      _typeFilter = ChatMessageTypeFilter.all;
      _deletedFilter = ChatDeletedFilter.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<ChatManagementBloc>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 0),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.t('giftFiltersTitle'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                onPressed: () => Navigator.pop(context),
                tooltip: l10n.t('cancel'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SectionLabel(text: l10n.t('searchMessages')),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final filter in ChatMessageTypeFilter.values)
                    _CompactFilterChip(
                      label: _msgTypeLabel(l10n, filter),
                      selected: _typeFilter == filter,
                      onTap: () {
                        setState(() {
                          if (filter == ChatMessageTypeFilter.all ||
                              _typeFilter != filter) {
                            _typeFilter = filter;
                          } else {
                            _typeFilter = ChatMessageTypeFilter.all;
                          }
                        });
                      },
                    ),
                  _CompactFilterChip(
                    label: l10n.t('deletedMessagesOnly'),
                    selected: _deletedFilter == ChatDeletedFilter.deletedOnly,
                    onTap: () {
                      setState(() {
                        _deletedFilter =
                            _deletedFilter == ChatDeletedFilter.deletedOnly
                            ? ChatDeletedFilter.all
                            : ChatDeletedFilter.deletedOnly;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Row(
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  foregroundColor: scheme.onSurfaceVariant,
                ),
                onPressed: () {
                  _resetDrafts();
                  bloc.add(const ChatsFiltersReset());
                  // Also clear message filters when resetting.
                  bloc.add(
                    const MessagesTypeFilterChanged(ChatMessageTypeFilter.all),
                  );
                  bloc.add(
                    const MessagesDeletedFilterChanged(ChatDeletedFilter.all),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                label: Text(
                  l10n.t('resetFilters'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _apply,
                child: Text(
                  l10n.t('giftApplyFilters'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _msgTypeLabel(AppLocalizations l10n, ChatMessageTypeFilter filter) {
    return switch (filter) {
      ChatMessageTypeFilter.all => l10n.t('filterAll'),
      ChatMessageTypeFilter.text => l10n.t('chatMessageText'),
      ChatMessageTypeFilter.image => l10n.t('chatMessageImage'),
      ChatMessageTypeFilter.video => l10n.t('chatMessageVideo'),
      ChatMessageTypeFilter.audio => l10n.t('chatMessageAudio'),
      ChatMessageTypeFilter.postShare => l10n.t('chatMessagePostShare'),
      ChatMessageTypeFilter.location => l10n.t('chatMessageLocation'),
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _CompactFilterChip extends StatelessWidget {
  const _CompactFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.12)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.45)
                  : scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
