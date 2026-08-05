import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../posts/presentation/widgets/posts_filter_panel_ui.dart';
import '../bloc/users_bloc.dart';
import '../users_ui_filter.dart';

int usersAppliedFilterCount({
  UsersUiFilter filter = UsersUiFilter.all,
  String locationQuery = '',
  String? role,
  DateTime? createdFrom,
  DateTime? createdTo,
}) {
  var count = 0;
  if (filter != UsersUiFilter.all) count++;
  if (locationQuery.trim().isNotEmpty) count++;
  if (role != null && role.isNotEmpty) count++;
  if (createdFrom != null || createdTo != null) count++;
  return count;
}

Future<void> showUsersFilterPopup({
  required BuildContext context,
  required UsersUiFilter statusFilter,
  required String locationQuery,
  String? roleFilter,
  DateTime? createdFrom,
  DateTime? createdTo,
  required Rect anchorRect,
}) {
  final bloc = context.read<UsersBloc>();
  final width = MediaQuery.sizeOf(context).width;

  Widget wrap(Widget child) => BlocProvider<UsersBloc>.value(
        value: bloc,
        child: child,
      );

  if (width < 600) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => wrap(
        UsersFilterPopup(
          appliedStatus: statusFilter,
          appliedLocation: locationQuery,
          appliedRole: roleFilter,
          appliedCreatedFrom: createdFrom,
          appliedCreatedTo: createdTo,
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.90,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          showDragHandle: true,
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Align(
          alignment: Alignment.center,
          child: wrap(
            UsersFilterPopup(
              appliedStatus: statusFilter,
              appliedLocation: locationQuery,
              appliedRole: roleFilter,
              appliedCreatedFrom: createdFrom,
              appliedCreatedTo: createdTo,
              width: 440,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
            ),
          ),
        ),
      ),
    );
  }

  const panelWidth = 420.0;
  final media = MediaQuery.sizeOf(context);
  final padding = MediaQuery.paddingOf(context);
  final isRtl = context.isRtl;

  var left = isRtl ? anchorRect.right - panelWidth : anchorRect.left;
  left = left.clamp(12.0, media.width - panelWidth - 12);
  var top = anchorRect.bottom + 6;
  final maxPanelHeight = media.height * 0.78;
  if (top + 420 > media.height - padding.bottom) {
    top = (anchorRect.top - 6 - maxPanelHeight).clamp(
      padding.top + 12.0,
      media.height - 420.0,
    );
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.15),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                alignment: Alignment.topCenter,
                child: wrap(
                  UsersFilterPopup(
                    appliedStatus: statusFilter,
                    appliedLocation: locationQuery,
                    appliedRole: roleFilter,
                    appliedCreatedFrom: createdFrom,
                    appliedCreatedTo: createdTo,
                    width: panelWidth,
                    maxHeight: maxPanelHeight,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class UsersFilterPopup extends StatefulWidget {
  const UsersFilterPopup({
    super.key,
    required this.appliedStatus,
    required this.appliedLocation,
    this.appliedRole,
    this.appliedCreatedFrom,
    this.appliedCreatedTo,
    this.width,
    this.maxHeight = 620,
    this.borderRadius,
    this.showDragHandle = false,
  });

  final UsersUiFilter appliedStatus;
  final String appliedLocation;
  final String? appliedRole;
  final DateTime? appliedCreatedFrom;
  final DateTime? appliedCreatedTo;
  final double? width;
  final double maxHeight;
  final BorderRadius? borderRadius;
  final bool showDragHandle;

  @override
  State<UsersFilterPopup> createState() => _UsersFilterPopupState();
}

class _UsersFilterPopupState extends State<UsersFilterPopup> {
  late UsersUiFilter _status;
  UsersPresenceFilter _presenceStatus = UsersPresenceFilter.all;
  late final TextEditingController _locationController;
  String? _role;
  DateTime? _createdFrom;
  DateTime? _createdTo;

  @override
  void initState() {
    super.initState();
    if (widget.appliedStatus == UsersUiFilter.online) {
      _presenceStatus = UsersPresenceFilter.online;
      _status = UsersUiFilter.all;
    } else if (widget.appliedStatus == UsersUiFilter.offline) {
      _presenceStatus = UsersPresenceFilter.offline;
      _status = UsersUiFilter.all;
    } else {
      _status = widget.appliedStatus;
    }
    _locationController = TextEditingController(text: widget.appliedLocation);
    _role = widget.appliedRole;
    _createdFrom = widget.appliedCreatedFrom;
    _createdTo = widget.appliedCreatedTo;
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _close(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  void _notifyBloc() {
    final bloc = context.read<UsersBloc>();
    final location = _locationController.text.trim();

    bloc.add(
      ApplyUsersListFiltersEvent(
        search: bloc.activeQuery,
        location: location,
        role: _role,
        createdFrom: _createdFrom,
        createdTo: _createdTo,
        statusFilter: _status,
        presenceFilter: _presenceStatus,
      ),
    );
  }

  void _reset() {
    setState(() {
      _status = UsersUiFilter.all;
      _presenceStatus = UsersPresenceFilter.all;
      _locationController.clear();
      _role = null;
      _createdFrom = null;
      _createdTo = null;
    });
    _notifyBloc();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final result = await showUsersDateRangeDialog(
      context,
      initialFrom: _createdFrom,
      initialTo: _createdTo,
    );

    if (result != null) {
      if (result.clear) {
        setState(() {
          _createdFrom = null;
          _createdTo = null;
        });
      } else {
        setState(() {
          _createdFrom = result.start;
          _createdTo = result.end;
        });
      }
      _notifyBloc();
    }
  }

  bool _isTodaySelected() {
    if (_createdFrom == null || _createdTo == null) return false;
    final now = DateTime.now();
    return _createdFrom!.year == now.year &&
        _createdFrom!.month == now.month &&
        _createdFrom!.day == now.day &&
        _createdTo!.year == now.year &&
        _createdTo!.month == now.month &&
        _createdTo!.day == now.day;
  }

  bool _isLast7DaysSelected() {
    if (_createdFrom == null || _createdTo == null) return false;
    final now = DateTime.now();
    final expectedStart = now.subtract(const Duration(days: 6));
    return _createdFrom!.year == expectedStart.year &&
        _createdFrom!.month == expectedStart.month &&
        _createdFrom!.day == expectedStart.day &&
        _createdTo!.year == now.year &&
        _createdTo!.month == now.month &&
        _createdTo!.day == now.day;
  }

  bool _isLast30DaysSelected() {
    if (_createdFrom == null || _createdTo == null) return false;
    final now = DateTime.now();
    final expectedStart = now.subtract(const Duration(days: 29));
    return _createdFrom!.year == expectedStart.year &&
        _createdFrom!.month == expectedStart.month &&
        _createdFrom!.day == expectedStart.day &&
        _createdTo!.year == now.year &&
        _createdTo!.month == now.month &&
        _createdTo!.day == now.day;
  }

  List<({String id, String label})> _activeItems(AppLocalizations l10n) {
    final isRtl = context.isRtl;
    final items = <({String id, String label})>[];
    if (_status != UsersUiFilter.all) {
      items.add((
        id: 'status',
        label: usersStatusLabel(l10n, _status, context: context),
      ));
    }
    if (_presenceStatus != UsersPresenceFilter.all) {
      items.add((
        id: 'presence',
        label: _presenceStatus == UsersPresenceFilter.online
            ? '🟢 ${l10n.tOr('online', isRtl ? 'متصل' : 'Online')}'
            : '⚪ ${l10n.tOr('offline', isRtl ? 'غير متصل' : 'Offline')}',
      ));
    }
    if (_locationController.text.trim().isNotEmpty) {
      items.add((
        id: 'location',
        label: _locationController.text.trim(),
      ));
    }
    if (_role != null && _role!.isNotEmpty) {
      items.add((
        id: 'role',
        label: l10n.tArgs('roleFilterPrefix', {'role': _role!}),
      ));
    }
    if (_createdFrom != null || _createdTo != null) {
      final df = DateFormat('yyyy-MM-dd');
      final label = _createdFrom != null && _createdTo != null
          ? '${df.format(_createdFrom!)} - ${df.format(_createdTo!)}'
          : _createdFrom != null
              ? l10n.tArgs('dateFromFilter', {'date': df.format(_createdFrom!)})
              : l10n.tArgs('dateUntilFilter', {'date': df.format(_createdTo!)});
      items.add((
        id: 'dateRange',
        label: label,
      ));
    }
    return items;
  }

  void _removeActiveItem(String id) {
    setState(() {
      switch (id) {
        case 'status':
          _status = UsersUiFilter.all;
          break;
        case 'presence':
          _presenceStatus = UsersPresenceFilter.all;
          break;
        case 'location':
          _locationController.clear();
          break;
        case 'role':
          _role = null;
          break;
        case 'dateRange':
          _createdFrom = null;
          _createdTo = null;
          break;
      }
    });
    _notifyBloc();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(16);
    final activeTags = _activeItems(l10n);

    final roleOptions = <({String? value, String label})>[
      (value: null, label: l10n.t('all')),
      (value: 'user', label: l10n.t('roleUser')),
      (value: 'admin', label: l10n.t('roleAdmin')),
      (value: 'moderator', label: l10n.t('roleModerator')),
      (value: 'superAdmin', label: l10n.t('roleSuperAdmin')),
    ];

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: radius,
      child: PostsFilterGlassShell(
        borderRadius: radius,
        child: SizedBox(
          width: widget.width ?? 420,
          height: widget.maxHeight,
          child: Column(
            children: [
              if (widget.showDragHandle)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 2),
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              PostsFilterPanelHeader(onClose: () => _close(context)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: PostsFilterPanelTokens.spacing),
                  children: [
                    PostsFilterActiveTags(
                      labels: activeTags,
                      onRemove: _removeActiveItem,
                    ),

                    // Status filter (Account status: All, Verified, Banned)
                    PostsFilterSection(
                      title: l10n.t('status'),
                      icon: Icons.flag_outlined,
                      showDivider: false,
                      child: PostsFilterChipGrid(
                        children: [
                          for (final status in [UsersUiFilter.all, UsersUiFilter.verified, UsersUiFilter.banned])
                            PostsFilterChoiceChip(
                              label: usersStatusLabel(l10n, status, context: context),
                              selected: _status == status,
                              onTap: () {
                                setState(() => _status = status);
                                _notifyBloc();
                              },
                            ),
                        ],
                      ),
                    ),

                    // Presence Status filter — Online (متصل) / Offline (غير متصل)
                    PostsFilterSection(
                      title: l10n.tOr('onlinePresence', context.isRtl ? 'حالة الاتصال (متصل / غير متصل)' : 'Presence Status (Online / Offline)'),
                      icon: Icons.sensors_outlined,
                      child: PostsFilterChipGrid(
                        children: [
                          PostsFilterChoiceChip(
                            label: l10n.t('all'),
                            selected: _presenceStatus == UsersPresenceFilter.all,
                            onTap: () {
                              setState(() => _presenceStatus = UsersPresenceFilter.all);
                              _notifyBloc();
                            },
                          ),
                          PostsFilterChoiceChip(
                            label: '🟢 ${l10n.tOr('online', context.isRtl ? 'متصل' : 'Online')}',
                            selected: _presenceStatus == UsersPresenceFilter.online,
                            onTap: () {
                              setState(() => _presenceStatus = UsersPresenceFilter.online);
                              _notifyBloc();
                            },
                          ),
                          PostsFilterChoiceChip(
                            label: '⚪ ${l10n.tOr('offline', context.isRtl ? 'غير متصل' : 'Offline')}',
                            selected: _presenceStatus == UsersPresenceFilter.offline,
                            onTap: () {
                              setState(() => _presenceStatus = UsersPresenceFilter.offline);
                              _notifyBloc();
                            },
                          ),
                        ],
                      ),
                    ),

                    // Role filter
                    PostsFilterSection(
                      title: l10n.tOr('userRole', 'User Role'),
                      icon: Icons.admin_panel_settings_outlined,
                      child: PostsFilterChipGrid(
                        children: [
                          for (final opt in roleOptions)
                            PostsFilterChoiceChip(
                              label: opt.label,
                              selected: _role == opt.value,
                              onTap: () {
                                setState(() => _role = opt.value);
                                _notifyBloc();
                              },
                            ),
                        ],
                      ),
                    ),

                    // Registration Date Range (Calendar)
                    PostsFilterSection(
                      title: l10n.tOr('registrationDate', 'Registration Date'),
                      icon: Icons.calendar_today_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          InkWell(
                            onTap: () => _pickDateRange(context),
                            borderRadius: BorderRadius.circular(PostsFilterPanelTokens.chipRadius),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.onSurface.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(PostsFilterPanelTokens.chipRadius),
                                border: Border.all(
                                  color: _createdFrom != null || _createdTo != null
                                      ? scheme.primary.withValues(alpha: 0.4)
                                      : scheme.outlineVariant.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 15,
                                    color: scheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _createdFrom != null || _createdTo != null
                                          ? '${_createdFrom != null ? DateFormat('yyyy-MM-dd').format(_createdFrom!) : l10n.tOr('startDate', 'Start')} → ${_createdTo != null ? DateFormat('yyyy-MM-dd').format(_createdTo!) : l10n.tOr('endDate', 'End')}'
                                          : l10n.tOr('selectDateRange', 'Select Date Range'),
                                      style: TextStyle(
                                        fontSize: PostsFilterPanelTokens.bodySize,
                                        fontWeight: _createdFrom != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: _createdFrom != null
                                            ? scheme.onSurface
                                            : scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  if (_createdFrom != null || _createdTo != null)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _createdFrom = null;
                                          _createdTo = null;
                                        });
                                        _notifyBloc();
                                      },
                                      child: Icon(Icons.clear, size: 14, color: scheme.onSurfaceVariant),
                                    )
                                  else
                                    Icon(
                                      Icons.arrow_drop_down,
                                      size: 18,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: PostsFilterPanelTokens.spacing),
                          PostsFilterChipGrid(
                            children: [
                              PostsFilterChoiceChip(
                                label: l10n.tOr('today', 'Today'),
                                selected: _isTodaySelected(),
                                onTap: () {
                                  final now = DateTime.now();
                                  setState(() {
                                    _createdFrom = DateTime(now.year, now.month, now.day, 0, 0, 0);
                                    _createdTo = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
                                  });
                                  _notifyBloc();
                                },
                              ),
                              PostsFilterChoiceChip(
                                label: l10n.tOr('last7Days', 'Last 7 Days'),
                                selected: _isLast7DaysSelected(),
                                onTap: () {
                                  final now = DateTime.now();
                                  final start = now.subtract(const Duration(days: 6));
                                  setState(() {
                                    _createdFrom = DateTime(start.year, start.month, start.day, 0, 0, 0);
                                    _createdTo = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
                                  });
                                  _notifyBloc();
                                },
                              ),
                              PostsFilterChoiceChip(
                                label: l10n.tOr('last30Days', 'Last 30 Days'),
                                selected: _isLast30DaysSelected(),
                                onTap: () {
                                  final now = DateTime.now();
                                  final start = now.subtract(const Duration(days: 29));
                                  setState(() {
                                    _createdFrom = DateTime(start.year, start.month, start.day, 0, 0, 0);
                                    _createdTo = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
                                  });
                                  _notifyBloc();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Location filter
                    PostsFilterSection(
                      title: l10n.t('location'),
                      icon: Icons.place_outlined,
                      child: TextField(
                        controller: _locationController,
                        onChanged: (_) {
                          setState(() {});
                          _notifyBloc();
                        },
                        textInputAction: TextInputAction.done,
                        style: TextStyle(fontSize: PostsFilterPanelTokens.bodySize),
                        decoration: InputDecoration(
                          hintText: l10n.t('filterUsersByPlace'),
                          prefixIcon: const Icon(Icons.place_outlined, size: 16),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          filled: true,
                          fillColor: scheme.onSurface.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(PostsFilterPanelTokens.chipRadius),
                            borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(PostsFilterPanelTokens.chipRadius),
                            borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(PostsFilterPanelTokens.chipRadius),
                            borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.6)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: PostsFilterPanelTokens.spacing),
                  ],
                ),
              ),
              PostsFilterPanelFooter(onReset: _reset),
            ],
          ),
        ),
      ),
    );
  }
}

String usersStatusLabel(
  AppLocalizations l10n,
  UsersUiFilter filter, {
  BuildContext? context,
}) {
  final isRtl = context != null ? context.isRtl : false;
  return switch (filter) {
    UsersUiFilter.all => l10n.t('all'),
    UsersUiFilter.verified => l10n.t('verified'),
    UsersUiFilter.banned => l10n.t('banned'),
    UsersUiFilter.online => l10n.tOr('online', isRtl ? 'متصل' : 'Online'),
    UsersUiFilter.offline => l10n.tOr('offline', isRtl ? 'غير متصل' : 'Offline'),
  };
}

class UsersDateRangeResult {
  const UsersDateRangeResult({this.start, this.end, this.clear = false});
  final DateTime? start;
  final DateTime? end;
  final bool clear;
}

Future<UsersDateRangeResult?> showUsersDateRangeDialog(
  BuildContext context, {
  DateTime? initialFrom,
  DateTime? initialTo,
}) {
  return showDialog<UsersDateRangeResult>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _SmartDateRangeDialog(
      initialFrom: initialFrom,
      initialTo: initialTo,
    ),
  );
}

class _SmartDateRangeDialog extends StatefulWidget {
  const _SmartDateRangeDialog({
    this.initialFrom,
    this.initialTo,
  });

  final DateTime? initialFrom;
  final DateTime? initialTo;

  @override
  State<_SmartDateRangeDialog> createState() => _SmartDateRangeDialogState();
}

class _SmartDateRangeDialogState extends State<_SmartDateRangeDialog> {
  late DateTime _displayedMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _hoverDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialFrom;
    _endDate = widget.initialTo;
    final base = _startDate ?? _endDate ?? DateTime.now();
    _displayedMonth = DateTime(base.year, base.month);
  }

  void _selectDay(DateTime day) {
    if (day.isAfter(DateTime.now())) return;

    final targetStart = DateTime(day.year, day.month, day.day, 0, 0, 0);
    final targetEnd = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);

    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = targetStart;
        _endDate = null;
      } else {
        if (targetStart.isBefore(_startDate!)) {
          _startDate = targetStart;
          _endDate = null;
        } else {
          _endDate = targetEnd;
        }
      }
    });
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isInRange(DateTime day) {
    if (_startDate == null) return false;
    final targetEnd = _endDate ?? _hoverDate;
    if (targetEnd == null) return false;

    final d = DateTime(day.year, day.month, day.day);
    final s = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final e = DateTime(targetEnd.year, targetEnd.month, targetEnd.day);

    if (s.isBefore(e)) {
      return (d.isAfter(s) || d.isAtSameMomentAs(s)) && (d.isBefore(e) || d.isAtSameMomentAs(e));
    } else {
      return (d.isAfter(e) || d.isAtSameMomentAs(e)) && (d.isBefore(s) || d.isAtSameMomentAs(s));
    }
  }

  String _durationText(BuildContext context) {
    final isRtl = context.isRtl;
    if (_startDate == null) return isRtl ? 'اختر تاريخ البداية' : 'Select Start Date';
    if (_endDate == null) return isRtl ? 'اختر تاريخ النهاية' : 'Select End Date';

    final s = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final e = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    final diff = e.difference(s).inDays + 1;

    if (diff == 1) return isRtl ? 'يوم واحد' : '1 Day';
    return isRtl ? '$diff أيام' : '$diff Days';
  }

  void _applyPreset(DateTime start, DateTime end) {
    setState(() {
      _startDate = DateTime(start.year, start.month, start.day, 0, 0, 0);
      _endDate = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
      _displayedMonth = DateTime(end.year, end.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isRtl = context.isRtl;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday;
    final monthName = DateFormat.yMMMM(isRtl ? 'ar' : 'en').format(_displayedMonth);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 440,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900.withValues(alpha: 0.95) : scheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
              blurRadius: 32,
              spreadRadius: 4,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                border: Border(
                  bottom: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary,
                          scheme.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.date_range_rounded, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tOr('registrationDate', isRtl ? 'نطاق التاريخ الذكي' : 'Smart Date Range'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.tOr('selectDateRangeSub', isRtl ? 'اختر بداية ونهاية النطاق مباشرة' : 'Select start and end directly on calendar'),
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Live Selection Banner
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _startDate != null
                              ? scheme.primary.withValues(alpha: 0.35)
                              : scheme.outlineVariant.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : (isRtl ? 'البداية' : 'Start'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _startDate != null ? FontWeight.bold : FontWeight.normal,
                                    color: _startDate != null ? scheme.primary : scheme.onSurfaceVariant,
                                  ),
                                ),
                                Icon(
                                  isRtl ? Icons.arrow_back : Icons.arrow_forward,
                                  size: 14,
                                  color: scheme.onSurfaceVariant,
                                ),
                                Text(
                                  _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : (isRtl ? 'النهاية' : 'End'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _endDate != null ? FontWeight.bold : FontWeight.normal,
                                    color: _endDate != null ? scheme.primary : scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _startDate != null && _endDate != null
                                  ? scheme.primaryContainer
                                  : scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _durationText(context),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: _startDate != null && _endDate != null
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Smart Presets Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      child: Row(
                        children: [
                          _PresetChip(
                            label: l10n.tOr('today', isRtl ? 'اليوم' : 'Today'),
                            onTap: () => _applyPreset(today, today),
                          ),
                          const SizedBox(width: 6),
                          _PresetChip(
                            label: isRtl ? 'الأمس' : 'Yesterday',
                            onTap: () => _applyPreset(yesterday, yesterday),
                          ),
                          const SizedBox(width: 6),
                          _PresetChip(
                            label: l10n.tOr('last7Days', isRtl ? 'آخر 7 أيام' : 'Last 7 Days'),
                            onTap: () => _applyPreset(today.subtract(const Duration(days: 6)), today),
                          ),
                          const SizedBox(width: 6),
                          _PresetChip(
                            label: l10n.tOr('last30Days', isRtl ? 'آخر 30 يوم' : 'Last 30 Days'),
                            onTap: () => _applyPreset(today.subtract(const Duration(days: 29)), today),
                          ),
                          const SizedBox(width: 6),
                          _PresetChip(
                            label: isRtl ? 'هذا الشهر' : 'This Month',
                            onTap: () => _applyPreset(DateTime(today.year, today.month, 1), today),
                          ),
                        ],
                      ),
                    ),

                    // Month Navigation Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, size: 20),
                            onPressed: () {
                              setState(() {
                                _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
                              });
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                          Text(
                            monthName,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, size: 20),
                            onPressed: _displayedMonth.year < today.year ||
                                    (_displayedMonth.year == today.year && _displayedMonth.month < today.month)
                                ? () {
                                    setState(() {
                                      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
                                    });
                                  }
                                : null,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),

                    // Weekday Headers
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          for (final day in isRtl
                              ? ['إثن', 'ثلا', 'أرب', 'خميس', 'جمعة', 'سبت', 'أحد']
                              : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                            Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Calendar Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (firstWeekday - 1) + daysInMonth,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 3,
                          crossAxisSpacing: 3,
                          childAspectRatio: 1.15,
                        ),
                        itemBuilder: (context, index) {
                          if (index < firstWeekday - 1) {
                            return const SizedBox.shrink();
                          }
                          final dayNum = index - (firstWeekday - 2);
                          final dayDate = DateTime(_displayedMonth.year, _displayedMonth.month, dayNum);
                          final isStart = _isSameDay(dayDate, _startDate);
                          final isEnd = _isSameDay(dayDate, _endDate);
                          final isSelectedBoundary = isStart || isEnd;
                          final inRange = _isInRange(dayDate);
                          final isFuture = dayDate.isAfter(today);
                          final isToday = _isSameDay(dayDate, today);

                          return MouseRegion(
                            onEnter: (_) {
                              if (_startDate != null && _endDate == null && !isFuture) {
                                setState(() => _hoverDate = dayDate);
                              }
                            },
                            child: InkWell(
                              onTap: isFuture ? null : () => _selectDay(dayDate),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelectedBoundary
                                      ? scheme.primary
                                      : inRange
                                          ? scheme.primary.withValues(alpha: 0.18)
                                          : Colors.transparent,
                                  borderRadius: isSelectedBoundary
                                      ? BorderRadius.circular(8)
                                      : inRange
                                          ? BorderRadius.circular(3)
                                          : BorderRadius.circular(8),
                                  border: isToday && !isSelectedBoundary
                                      ? Border.all(color: scheme.primary, width: 1.2)
                                      : null,
                                ),
                                child: Text(
                                  '$dayNum',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelectedBoundary || isToday ? FontWeight.bold : FontWeight.normal,
                                    color: isSelectedBoundary
                                        ? Colors.white
                                        : isFuture
                                            ? scheme.onSurfaceVariant.withValues(alpha: 0.3)
                                            : scheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Footer Actions
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_startDate != null || _endDate != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _hoverDate = null;
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(l10n.tOr('clear', isRtl ? 'مسح' : 'Clear')),
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.error,
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.tOr('cancel', isRtl ? 'إلغاء' : 'Cancel')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _startDate == null
                        ? null
                        : () => Navigator.pop(
                              context,
                              UsersDateRangeResult(
                                start: _startDate,
                                end: _endDate ?? _startDate,
                              ),
                            ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(l10n.tOr('apply', isRtl ? 'تطبيق النطاق' : 'Apply Range')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}
