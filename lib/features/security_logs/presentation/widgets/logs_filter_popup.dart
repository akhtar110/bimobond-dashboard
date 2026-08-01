import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../gifts/presentation/widgets/gifts_active_filters.dart';
import '../../../gifts/presentation/widgets/gifts_filter_chip.dart';
import '../../../gifts/presentation/widgets/gifts_filter_footer.dart';
import '../../../gifts/presentation/widgets/gifts_filter_header.dart';
import '../../../gifts/presentation/widgets/gifts_filter_models.dart';
import '../../../gifts/presentation/widgets/gifts_filter_section.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/presentation/widgets/admin_user_search_field.dart';
import '../../domain/entities/log_entity.dart';
import '../bloc/logs_bloc.dart';
import '../bloc/logs_event.dart';
import '../utils/logs_labels.dart';

Future<void> showLogsFilterPopup({
  required BuildContext context,
  required LogsQuery query,
  required Rect anchorRect,
}) {
  final bloc = context.read<LogsBloc>();
  final width = MediaQuery.sizeOf(context).width;

  Widget wrap(Widget child) => BlocProvider<LogsBloc>.value(
        value: bloc,
        child: child,
      );

  Widget popup({
    double? width,
    required double maxHeight,
    BorderRadius? borderRadius,
  }) =>
      _LogsFilterPopup(
        query: query,
        width: width,
        maxHeight: maxHeight,
        borderRadius: borderRadius,
      );

  if (width < 600) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: wrap(
          popup(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
        ),
      ),
    );
  }

  if (width < 900) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: Align(
          alignment: Alignment.center,
          child: wrap(
            popup(
              width: 420,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
            ),
          ),
        ),
      ),
    );
  }

  const panelWidth = 420.0;
  final media = MediaQuery.sizeOf(context);
  final padding = MediaQuery.paddingOf(context);
  final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

  var left = isRtl ? anchorRect.right - panelWidth : anchorRect.left;
  left = left.clamp(12.0, media.width - panelWidth - 12);
  var top = anchorRect.bottom + 8;
  final maxPanelHeight = media.height * 0.78;
  if (top + 320 > media.height - padding.bottom) {
    top = (anchorRect.top - 8 - maxPanelHeight)
        .clamp(padding.top + 12.0, media.height - 320.0);
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: FadeTransition(
              opacity: animation,
              child: wrap(
                popup(width: panelWidth, maxHeight: maxPanelHeight),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _LogsFilterPopup extends StatefulWidget {
  const _LogsFilterPopup({
    required this.query,
    this.width,
    this.maxHeight = 560,
    this.borderRadius,
  });

  final LogsQuery query;
  final double? width;
  final double maxHeight;
  final BorderRadius? borderRadius;

  @override
  State<_LogsFilterPopup> createState() => _LogsFilterPopupState();
}

class _LogsFilterPopupState extends State<_LogsFilterPopup> {
  late UserEntity? _user;
  late String? _actorRole;
  late String? _category;
  late String? _action;
  late DateTime? _from;
  late DateTime? _to;
  late int _limit;

  @override
  void initState() {
    super.initState();
    _user = widget.query.user;
    _actorRole = widget.query.actorRole?.toUpperCase();
    _category = widget.query.category?.toUpperCase();
    _action = widget.query.action?.toUpperCase();
    _from = widget.query.from;
    _to = widget.query.to;
    _limit = widget.query.limit;
  }

  void _reset() {
    setState(() {
      _user = null;
      _actorRole = null;
      _category = null;
      _action = null;
      _from = null;
      _to = null;
      _limit = 50;
    });
  }

  void _close() {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  void _apply() {
    final userId = _user?.id.trim();
    context.read<LogsBloc>().add(
          LogsApplyFiltersEvent(
            user: _user,
            userId: (userId == null || userId.isEmpty) ? null : userId,
            actorRole: _actorRole,
            category: _category,
            action: _action,
            from: _from,
            to: _to,
            limit: _limit,
          ),
        );
    _close();
  }

  bool _selected(String? current, String? value) {
    if (value == null) {
      return current == null || current.trim().isEmpty;
    }
    return (current ?? '').toUpperCase() == value.toUpperCase();
  }

  void _toggle(String? current, String? value, ValueChanged<String?> set) {
    if (value == null) {
      set(null);
      return;
    }
    final next = value.toUpperCase();
    set(_selected(current, next) ? null : next);
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from ?? _to ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      _from = DateTime.utc(picked.year, picked.month, picked.day);
      if (_to != null && _from!.isAfter(_to!)) _to = _from;
    });
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to ?? _from ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      _to = DateTime.utc(
        picked.year,
        picked.month,
        picked.day,
        23,
        59,
        59,
        999,
      );
      if (_from != null && _from!.isAfter(_to!)) _from = _to;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(20);
    final dateFmt = DateFormat.yMMMd();

    final activeItems = <GiftsActiveFilterItem>[
      if (_user != null)
        GiftsActiveFilterItem(
          id: 'user',
          label: _user!.username,
          onRemove: () => setState(() => _user = null),
        ),
      if (_actorRole != null)
        GiftsActiveFilterItem(
          id: 'actorRole',
          label: logsActorRoleLabel(l10n, _actorRole),
          onRemove: () => setState(() => _actorRole = null),
        ),
      if (_category != null)
        GiftsActiveFilterItem(
          id: 'category',
          label: logsCategoryLabel(l10n, _category),
          onRemove: () => setState(() => _category = null),
        ),
      if (_action != null)
        GiftsActiveFilterItem(
          id: 'action',
          label: logsActionCodeLabel(l10n, _action),
          onRemove: () => setState(() => _action = null),
        ),
      if (_from != null || _to != null)
        GiftsActiveFilterItem(
          id: 'dates',
          label: [
            if (_from != null) dateFmt.format(_from!.toLocal()),
            if (_to != null) dateFmt.format(_to!.toLocal()),
          ].join(' – '),
          onRemove: () => setState(() {
            _from = null;
            _to = null;
          }),
        ),
      if (_limit != 50)
        GiftsActiveFilterItem(
          id: 'limit',
          label: l10n
              .tOr('logsPageSizeChip', 'Page size: {n}')
              .replaceAll('{n}', '$_limit'),
          onRemove: () => setState(() => _limit = 50),
        ),
    ];

    return Material(
      color: scheme.surface,
      elevation: 10,
      shadowColor: scheme.shadow.withValues(alpha: 0.22),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.none,
      child: SizedBox(
        width: widget.width ?? 420,
        height: widget.maxHeight,
        child: Column(
          children: [
            GiftsFilterHeader(onResetAll: _reset, onClose: _close),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  _LogsUserFilterSection(
                    title: l10n.tOr('logsFilterUser', 'User').toUpperCase(),
                    child: AdminUserSearchField(
                      selectedUser: _user,
                      compact: true,
                      label: l10n.tOr('logsFilterUser', 'User'),
                      hintText: l10n.tOr(
                        'logsUserSearchHint',
                        'Search by username or name…',
                      ),
                      onUserSelected: (user) => setState(() => _user = user),
                    ),
                  ),
                  GiftsFilterSection(
                    title: l10n
                        .tOr('logsFilterActorRole', 'Actor role')
                        .toUpperCase(),
                    child: GiftsFilterChipWrap(
                      children: [
                        for (final value in logsActorRoleDropdownItems())
                          GiftsFilterChoiceChip(
                            label: logsActorRoleLabel(l10n, value),
                            selected: _selected(_actorRole, value),
                            onTap: () => setState(
                              () => _toggle(
                                _actorRole,
                                value,
                                (v) => _actorRole = v,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: l10n
                        .tOr('logsFilterCategory', 'Category')
                        .toUpperCase(),
                    child: GiftsFilterChipWrap(
                      children: [
                        for (final value in logsCategoryDropdownItems())
                          GiftsFilterChoiceChip(
                            label: logsCategoryLabel(l10n, value),
                            selected: _selected(_category, value),
                            onTap: () => setState(() {
                              _toggle(_category, value, (v) {
                                _category = v;
                                if (_action == null || v == null) return;
                                final isBan = _action == 'USER_BAN';
                                final allowed =
                                    LogsQuery.actionsForCategory(v)
                                        .contains(_action) ||
                                    (isBan &&
                                        (v == 'ADMIN' || v == 'MODERATION'));
                                if (!allowed) _action = null;
                              });
                            }),
                          ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: l10n.tOr('logsFilterAction', 'Action').toUpperCase(),
                    child: GiftsFilterChipWrap(
                      children: [
                        for (final value
                            in logsActionDropdownItems(_category))
                          GiftsFilterChoiceChip(
                            label: logsActionCodeLabel(l10n, value),
                            selected: _selected(_action, value),
                            onTap: () => setState(() {
                              _toggle(_action, value, (v) {
                                _action = v;
                                // Ban/Unban → `?action=USER_BAN` only.
                                if (v == 'USER_BAN') {
                                  _category = null;
                                }
                              });
                            }),
                          ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: l10n
                        .tOr('logsFilterDateRange', 'Date range')
                        .toUpperCase(),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickFrom,
                          icon: const Icon(Icons.calendar_today_outlined, size: 16),
                          label: Text(
                            _from == null
                                ? l10n.tOr('logsFilterFrom', 'From')
                                : dateFmt.format(_from!.toLocal()),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickTo,
                          icon: const Icon(Icons.event_outlined, size: 16),
                          label: Text(
                            _to == null
                                ? l10n.tOr('logsFilterTo', 'To')
                                : dateFmt.format(_to!.toLocal()),
                          ),
                        ),
                        if (_from != null || _to != null)
                          TextButton(
                            onPressed: () => setState(() {
                              _from = null;
                              _to = null;
                            }),
                            child: Text(l10n.tOr('clear', 'Clear')),
                          ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: l10n
                        .tOr('logsFilterPageSize', 'Page size')
                        .toUpperCase(),
                    child: GiftsFilterChipWrap(
                      children: [
                        for (final size in LogsQuery.pageSizeOptions)
                          GiftsFilterChoiceChip(
                            label: '$size',
                            selected: _limit == size,
                            onTap: () => setState(() => _limit = size),
                          ),
                      ],
                    ),
                  ),
                  GiftsActiveFilters(items: activeItems),
                ],
              ),
            ),
            GiftsFilterFooter(
              onReset: _reset,
              onCancel: _close,
              onApply: _apply,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogsUserFilterSection extends StatelessWidget {
  const _LogsUserFilterSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.start,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
