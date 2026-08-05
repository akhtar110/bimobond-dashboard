import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../gifts/presentation/widgets/gifts_active_filters.dart';
import '../../../gifts/presentation/widgets/gifts_filter_chip.dart';
import '../../../gifts/presentation/widgets/gifts_filter_footer.dart';
import '../../../gifts/presentation/widgets/gifts_filter_models.dart';
import '../../../gifts/presentation/widgets/gifts_filter_section.dart';
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
  late final TextEditingController _locationController;
  String? _role;
  DateTime? _createdFrom;
  DateTime? _createdTo;

  @override
  void initState() {
    super.initState();
    _status = widget.appliedStatus;
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

  void _reset() {
    setState(() {
      _status = UsersUiFilter.all;
      _locationController.clear();
      _role = null;
      _createdFrom = null;
      _createdTo = null;
    });
  }

  void _apply(BuildContext context) {
    final bloc = context.read<UsersBloc>();
    final location = _locationController.text.trim();

    if (bloc.activeFilter != _status) {
      bloc.add(FilterUsersEvent(_status));
    }

    bloc.add(
      ApplyUsersListFiltersEvent(
        search: bloc.activeQuery,
        location: location,
        role: _role,
        createdFrom: _createdFrom,
        createdTo: _createdTo,
      ),
    );

    _close(context);
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _createdFrom != null && _createdTo != null
          ? DateTimeRange(start: _createdFrom!, end: _createdTo!)
          : _createdFrom != null
              ? DateTimeRange(start: _createdFrom!, end: _createdFrom!)
              : null,
    );

    if (picked != null) {
      setState(() {
        _createdFrom = picked.start;
        _createdTo = picked.end;
      });
    }
  }

  String _sectionTitle(String text, BuildContext context) {
    if (context.isRtl) return text;
    return text.toUpperCase();
  }

  List<GiftsActiveFilterItem> _activeItems(AppLocalizations l10n) {
    final items = <GiftsActiveFilterItem>[];
    if (_status != UsersUiFilter.all) {
      items.add(
        GiftsActiveFilterItem(
          id: 'status',
          label: usersStatusLabel(l10n, _status),
          onRemove: () => setState(() => _status = UsersUiFilter.all),
        ),
      );
    }
    if (_locationController.text.trim().isNotEmpty) {
      items.add(
        GiftsActiveFilterItem(
          id: 'location',
          label: _locationController.text.trim(),
          onRemove: () => _locationController.clear(),
        ),
      );
    }
    if (_role != null && _role!.isNotEmpty) {
      items.add(
        GiftsActiveFilterItem(
          id: 'role',
          label: l10n.tArgs('roleFilterPrefix', {'role': _role!}),
          onRemove: () => setState(() => _role = null),
        ),
      );
    }
    if (_createdFrom != null || _createdTo != null) {
      final df = DateFormat('yyyy-MM-dd');
      final label = _createdFrom != null && _createdTo != null
          ? '${df.format(_createdFrom!)} - ${df.format(_createdTo!)}'
          : _createdFrom != null
              ? l10n.tArgs('dateFromFilter', {'date': df.format(_createdFrom!)})
              : l10n.tArgs('dateUntilFilter', {'date': df.format(_createdTo!)});
      items.add(
        GiftsActiveFilterItem(
          id: 'dateRange',
          label: label,
          onRemove: () => setState(() {
            _createdFrom = null;
            _createdTo = null;
          }),
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(16);

    final roleOptions = <({String? value, String label})>[
      (value: null, label: l10n.t('all')),
      (value: 'user', label: l10n.t('roleUser')),
      (value: 'admin', label: l10n.t('roleAdmin')),
      (value: 'moderator', label: l10n.t('roleModerator')),
      (value: 'superAdmin', label: l10n.t('roleSuperAdmin')),
    ];

    return Material(
      color: scheme.surface,
      elevation: 10,
      shadowColor: scheme.shadow.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.75)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: widget.width ?? 420,
        height: widget.maxHeight,
        child: Column(
          children: [
            if (widget.showDragHandle)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 2),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.tOr('filters', 'Filters'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.t('close'),
                    onPressed: () => _close(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  GiftsActiveFilters(items: _activeItems(l10n)),

                  // Status filter
                  GiftsFilterSection(
                    title: _sectionTitle(l10n.t('status'), context),
                    child: GiftsFilterChipWrap(
                      children: [
                        for (final status in UsersUiFilter.values)
                          GiftsFilterChoiceChip(
                            label: usersStatusLabel(l10n, status),
                            selected: _status == status,
                            onTap: () => setState(() => _status = status),
                          ),
                      ],
                    ),
                  ),

                  // Role filter
                  GiftsFilterSection(
                    title: _sectionTitle(l10n.tOr('userRole', 'User Role'), context),
                    child: GiftsFilterChipWrap(
                      children: [
                        for (final opt in roleOptions)
                          GiftsFilterChoiceChip(
                            label: opt.label,
                            selected: _role == opt.value,
                            onTap: () => setState(() => _role = opt.value),
                          ),
                      ],
                    ),
                  ),

                  // Registration Date Range
                  GiftsFilterSection(
                    title: _sectionTitle(l10n.tOr('registrationDate', 'Registration Date'), context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => _pickDateRange(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: scheme.outlineVariant),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _createdFrom != null || _createdTo != null
                                        ? '${_createdFrom != null ? DateFormat('yyyy-MM-dd').format(_createdFrom!) : l10n.tOr('startDate', 'Start')} → ${_createdTo != null ? DateFormat('yyyy-MM-dd').format(_createdTo!) : l10n.tOr('endDate', 'End')}'
                                        : l10n.tOr('selectDateRange', 'Select Date Range'),
                                    style: TextStyle(
                                      fontSize: 13,
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
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () => setState(() {
                                      _createdFrom = null;
                                      _createdTo = null;
                                    }),
                                    visualDensity: VisualDensity.compact,
                                  )
                                else
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: scheme.onSurfaceVariant,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _QuickDateChip(
                              label: l10n.tOr('today', 'Today'),
                              onTap: () {
                                final now = DateTime.now();
                                setState(() {
                                  _createdFrom = DateTime(now.year, now.month, now.day);
                                  _createdTo = now;
                                });
                              },
                            ),
                            _QuickDateChip(
                              label: l10n.tOr('last7Days', 'Last 7 Days'),
                              onTap: () {
                                final now = DateTime.now();
                                setState(() {
                                  _createdFrom = now.subtract(const Duration(days: 7));
                                  _createdTo = now;
                                });
                              },
                            ),
                            _QuickDateChip(
                              label: l10n.tOr('last30Days', 'Last 30 Days'),
                              onTap: () {
                                final now = DateTime.now();
                                setState(() {
                                  _createdFrom = now.subtract(const Duration(days: 30));
                                  _createdTo = now;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Location filter
                  GiftsFilterSection(
                    title: _sectionTitle(l10n.t('location'), context),
                    child: TextField(
                      controller: _locationController,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: l10n.t('filterUsersByPlace'),
                        prefixIcon: const Icon(Icons.place_outlined, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: scheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: scheme.outlineVariant),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GiftsFilterFooter(
              onReset: _reset,
              onCancel: () => _close(context),
              onApply: () => _apply(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickDateChip extends StatelessWidget {
  const _QuickDateChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

String usersStatusLabel(AppLocalizations l10n, UsersUiFilter filter) {
  return switch (filter) {
    UsersUiFilter.all => l10n.t('all'),
    UsersUiFilter.verified => l10n.t('verified'),
    UsersUiFilter.banned => l10n.t('banned'),
    UsersUiFilter.online => l10n.tOr('online', 'Online'),
    UsersUiFilter.offline => l10n.tOr('offline', 'Offline'),
  };
}
