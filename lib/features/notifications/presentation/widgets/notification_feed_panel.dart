import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/notification_filters.dart';
import '../bloc/notifications_bloc.dart';
import '../utils/notification_labels.dart';
import 'notification_item_card.dart';

/// Full notification feed panel with filters — used on [NotificationsPage].
class NotificationFeedPanel extends StatefulWidget {
  const NotificationFeedPanel({
    super.key,
    required this.isDark,
    this.expandVertically = false,
    this.minHeight = 520,
  });

  final bool isDark;
  final bool expandVertically;
  final double minHeight;

  @override
  State<NotificationFeedPanel> createState() => _NotificationFeedPanelState();
}

class _NotificationFeedPanelState extends State<NotificationFeedPanel> {
  final ScrollController _scroll = ScrollController();
  Timer? _debounce;

  static const _notifTypes = <String>[
    'ALL',
    'POST_LIKE',
    'COMMENT',
    'COMMENT_LIKE',
    'FOLLOW',
    'MENTION',
    'REPOST',
    'ADMIN_MESSAGE',
    'BROADCAST',
    'SYSTEM',
  ];

  String _selectedType = 'ALL';
  String _readFilter = 'ALL'; // ALL | READ | UNREAD

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Initial load
    context
        .read<NotificationsBloc>()
        .add(const FetchNotificationsRequested());
  }

  @override
  void dispose() {
    _scroll.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels < pos.maxScrollExtent - 200) return;
    context
        .read<NotificationsBloc>()
        .add(const LoadMoreNotificationsRequested());
  }

  void _applyFilters() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final filters = NotificationFilters(
        type: _selectedType == 'ALL' ? null : _selectedType,
        isRead: _readFilter == 'ALL'
            ? null
            : _readFilter == 'READ',
      );
      context
          .read<NotificationsBloc>()
          .add(FilterNotificationsChanged(filters));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      constraints: widget.expandVertically
          ? null
          : BoxConstraints(minHeight: widget.minHeight),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDark
              ? Colors.grey.shade800
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active_rounded,
                  size: 20,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.t('notificationGlobalFeedTitle'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: widget.isDark
                        ? Colors.white
                        : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                BlocBuilder<NotificationsBloc, NotificationsState>(
                  buildWhen: (a, b) =>
                      a.notificationsLoading != b.notificationsLoading,
                  builder: (context, state) => IconButton(
                    icon: state.notificationsLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    tooltip: l10n.t('refresh'),
                    onPressed: state.notificationsLoading
                        ? null
                        : () => context.read<NotificationsBloc>().add(
                              const RefreshNotificationsRequested(),
                            ),
                  ),
                ),
              ],
            ),
          ),

          // ── Filters ─────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _FilterDropdown<String>(
                  value: _selectedType,
                  items: _notifTypes,
                  label: (v) => notificationFeedTypeLabel(l10n, v),
                  onChanged: (v) {
                    setState(() => _selectedType = v!);
                    _applyFilters();
                  },
                  isDark: widget.isDark,
                  icon: Icons.category_outlined,
                ),
                _ReadToggle(
                  selected: _readFilter,
                  isDark: widget.isDark,
                  onChanged: (v) {
                    setState(() => _readFilter = v);
                    _applyFilters();
                  },
                ),
                BlocBuilder<NotificationsBloc, NotificationsState>(
                  buildWhen: (a, b) => a.filters != b.filters,
                  builder: (context, state) {
                    if (state.filters.isEmpty) return const SizedBox.shrink();
                    return ActionChip(
                      avatar: const Icon(Icons.clear_rounded, size: 14),
                      label: Text(l10n.t('notificationClearFilters')),
                      onPressed: () {
                        setState(() {
                          _selectedType = 'ALL';
                          _readFilter = 'ALL';
                        });
                        context
                            .read<NotificationsBloc>()
                            .add(const ClearNotificationFilters());
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          if (widget.expandVertically)
            Expanded(child: _buildFeedBody(context))
          else
            _buildFeedBody(context),
        ],
      ),
    );
  }

  Widget _buildFeedBody(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<NotificationsBloc, NotificationsState>(
      buildWhen: (a, b) =>
          a.notifications != b.notifications ||
          a.notificationsLoading != b.notificationsLoading ||
          a.notificationsLoadingMore != b.notificationsLoadingMore ||
          a.notificationsHasReachedMax != b.notificationsHasReachedMax ||
          a.notificationsError != b.notificationsError,
      builder: (context, state) {
        if (state.notificationsLoading && state.notifications.isEmpty) {
          return _LoadingShimmer(isDark: widget.isDark);
        }

        if (state.notificationsError != null && state.notifications.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 40, color: scheme.error.withValues(alpha: 0.6)),
                const SizedBox(height: 10),
                Text(
                  state.notificationsError!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        if (state.notifications.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none_rounded,
                    size: 48,
                    color: widget.isDark
                        ? Colors.grey.shade600
                        : Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  l10n.t('notificationNoResultsFound'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: widget.isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        final total = state.notificationsTotal > 0
            ? state.notificationsTotal
            : state.notifications.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                notificationCountLabel(l10n, total),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (widget.expandVertically)
              Expanded(
                child: ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: state.notifications.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) => NotificationItemCard(
                    notification: state.notifications[index],
                    isDark: widget.isDark,
                  ),
                ),
              )
            else
              ListView.separated(
                controller: _scroll,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: state.notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) => NotificationItemCard(
                  notification: state.notifications[index],
                  isDark: widget.isDark,
                ),
              ),
            if (state.notificationsLoadingMore)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (state.notificationsHasReachedMax &&
                state.notifications.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    l10n.t('allNotificationsLoaded'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: widget.isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    required this.isDark,
    required this.icon,
  });

  final T value;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T?> onChanged;
  final bool isDark;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.expand_more_rounded, size: 16),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          dropdownColor:
              isDark ? const Color(0xFF1E293B) : Colors.white,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon,
                            size: 14, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(label(item)),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ReadToggle extends StatelessWidget {
  const _ReadToggle({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  final String selected;
  final bool isDark;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    const options = ['ALL', 'UNREAD', 'READ'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return GestureDetector(
          onTap: () => onChanged(opt),
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? scheme.primary
                  : (isDark
                      ? const Color(0xFF0F172A)
                      : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? scheme.primary
                    : (isDark
                        ? Colors.grey.shade700
                        : Colors.grey.shade300),
              ),
            ),
            child: Text(
              notificationReadFilterLabel(l10n, opt),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF263348) : Colors.grey.shade100;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: List.generate(
          5,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 72,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
