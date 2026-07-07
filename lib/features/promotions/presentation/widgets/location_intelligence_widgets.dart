import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../core/widgets/toolbar_filter_style.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/presentation/widgets/admin_user_search_field.dart';
import '../../../search_history/presentation/widgets/search_history_date_range_dialog.dart';
import '../../domain/entities/pagination_meta.dart';
import '../../domain/entities/promotion_entities.dart';
import '../../domain/enums/promotion_enums.dart';
import '../bloc/location_intelligence_bloc.dart';
import '../utils/location_responsive.dart';
import 'location_map_panel.dart';

abstract final class LocationSpace {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

const double kLocationRowHeight = 56;
const double kLocationTableHeaderHeight = 36;
const double _kCellHPad = 6;

class LocationLoadMoreIndicator extends StatelessWidget {
  const LocationLoadMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class LocationEndOfListLabel extends StatelessWidget {
  const LocationEndOfListLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 24, height: 1, color: scheme.outlineVariant),
          const SizedBox(width: 8),
          Text(
            context.l10n.tOr('allLocationsLoaded', 'All locations loaded'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
          ),
          const SizedBox(width: 8),
          Container(width: 24, height: 1, color: scheme.outlineVariant),
        ],
      ),
    );
  }
}

class LocationDashboardCard extends StatelessWidget {
  const LocationDashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(LocationSpace.md),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class LocationHeaderSection extends StatelessWidget {
  const LocationHeaderSection({
    super.key,
    required this.isUserDetail,
    this.metrics,
    this.compact = false,
  });

  final bool isUserDetail;
  final LocationLayoutMetrics? metrics;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final device = metrics?.deviceType ??
        getLocationDeviceType(MediaQuery.sizeOf(context).width);
    final compactHeader =
        compact || device != LocationDeviceType.desktop;
    final titleStyle = (compactHeader
            ? Theme.of(context).textTheme.titleMedium
            : Theme.of(context).textTheme.headlineSmall)
        ?.copyWith(fontWeight: FontWeight.w800);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.t('promoLocationTitle'),
          style: titleStyle,
        ),
        SizedBox(
          height: compactHeader
              ? (metrics?.toolbarFilterGap ?? 4)
              : (metrics?.sectionGap ?? LocationSpace.sm),
        ),
        Text(
          isUserDetail
              ? l10n.t('promoLocationLog')
              : l10n.t('promoLocationOverviewHint'),
          maxLines: compactHeader ? 2 : 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: compactHeader ? 12 : null,
                height: compactHeader ? 1.3 : null,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class LocationToolbar extends StatelessWidget {
  const LocationToolbar({
    super.key,
    required this.state,
    this.fixedUser,
    this.metrics,
    this.showLimitFilter = true,
  });

  final LocationIntelligenceState state;
  final UserEntity? fixedUser;
  final LocationLayoutMetrics? metrics;
  final bool showLimitFilter;

  static const _sourceWidth = 118.0;
  static const _limitWidth = 92.0;
  static const _dateWidth = 168.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final loaded = switch (state) {
      LocationIntelligenceLoaded s => s,
      _ => null,
    };
    final bloc = context.read<LocationIntelligenceBloc>();
    final hasActiveFilters = loaded != null &&
        (loaded.source != null ||
            loaded.dateRange != null ||
            (showLimitFilter && loaded.limit != 50));

    return LayoutBuilder(
      builder: (context, constraints) {
        final m = metrics ??
            LocationLayoutMetrics(
              getLocationDeviceType(constraints.maxWidth),
            );
        final gap = showLimitFilter ? m.filterGap : m.toolbarFilterGap;
        final controlHeight = m.toolbarControlHeight;
        final veryNarrow = constraints.maxWidth < 520;
        final narrow = constraints.maxWidth < 760;
        final medium = constraints.maxWidth < 1120;
        final lockUser = fixedUser != null;

        final userSearch = lockUser
            ? null
            : AdminUserSearchField(
                compact: true,
                compactFilterStyle: true,
                hintText: l10n.tOr('promoSearchUserHintShort', 'Search user'),
                selectedUser: loaded?.selectedUser,
                onUserSelected: (user) {
                  if (user == null) {
                    bloc.add(ClearLocationUserEvent());
                  } else {
                    bloc.add(SelectLocationUserEvent(user));
                  }
                },
              );

        final lockedUserChip = lockUser
            ? SelectedUserChip(
                user: fixedUser!,
                onClear: null,
              )
            : null;

        final sourceFilter = _FilterDropdown<String?>(
          hint: l10n.tOr('promoFilterSource', 'Source'),
          value: loaded?.source,
          items: [
            null,
            ...LocationSource.values.map((s) => s.apiValue),
          ],
          itemLabel: (v) => v ?? l10n.t('all'),
          onChanged: (v) => bloc.add(
            UpdateLocationFiltersEvent(
              source: v,
              clearSource: v == null,
            ),
          ),
        );

        final limitFilter = showLimitFilter
            ? _FilterDropdown<int>(
                hint: l10n.tOr('promoFilterLimit', 'Limit'),
                value: loaded?.limit ?? 50,
                items: const [25, 50, 100],
                itemLabel: (v) => '$v',
                onChanged: (v) {
                  if (v != null) {
                    bloc.add(UpdateLocationFiltersEvent(limit: v));
                  }
                },
              )
            : null;

        final dateFilter = LocationDateRangeFilter(
          dateRange: loaded?.dateRange,
          onPresetSelected: (range) {
            if (range == null) {
              bloc.add(UpdateDateRangeFilterEvent());
            } else {
              bloc.add(
                UpdateDateRangeFilterEvent(
                  from: range.start,
                  to: range.end,
                ),
              );
            }
          },
        );

        Widget sizedFilter(Widget filter, {double? width}) {
          return SizedBox(
            width: width,
            height: controlHeight,
            child: filter,
          );
        }

        final clearButton = hasActiveFilters
            ? IconButton(
                tooltip: l10n.tOr('promoFilterClear', 'Clear'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: controlHeight - 4,
                  minHeight: controlHeight - 4,
                ),
                onPressed: () => bloc.add(ClearLocationFiltersEvent()),
                icon: Icon(
                  Icons.filter_alt_off_outlined,
                  size: 17,
                  color: scheme.error,
                ),
              )
            : null;

        Widget filterRow({
          required List<Widget> filters,
          bool inlineClear = false,
        }) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < filters.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Expanded(child: sizedFilter(filters[i])),
              ],
              if (inlineClear && clearButton != null) ...[
                SizedBox(width: gap),
                clearButton,
              ],
            ],
          );
        }

        final topWidgets = <Widget>[
          if (userSearch != null) userSearch,
          if (lockedUserChip != null) lockedUserChip,
        ];

        Widget? topSection;
        if (topWidgets.length == 1) {
          topSection = topWidgets.first;
        } else if (topWidgets.length > 1) {
          topSection = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              topWidgets.first,
              SizedBox(height: gap),
              topWidgets.last,
            ],
          );
        }

        final secondaryFilters = <Widget>[
          sizedFilter(sourceFilter),
          if (limitFilter != null) sizedFilter(limitFilter),
          sizedFilter(dateFilter),
        ];

        if (!showLimitFilter) {
          if (veryNarrow || narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (topSection != null) ...[
                  topSection,
                  SizedBox(height: gap),
                ],
                filterRow(
                  filters: [sourceFilter, dateFilter],
                  inlineClear: true,
                ),
              ],
            );
          }

          if (medium) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (userSearch != null) ...[
                  Expanded(flex: 3, child: userSearch),
                  SizedBox(width: gap),
                ],
                if (lockedUserChip != null) ...[
                  lockedUserChip,
                  SizedBox(width: gap),
                ],
                Expanded(child: sizedFilter(sourceFilter)),
                SizedBox(width: gap),
                Expanded(
                  flex: 2,
                  child: sizedFilter(dateFilter),
                ),
                if (clearButton != null) clearButton,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (userSearch != null) ...[
                Expanded(flex: 3, child: userSearch),
                SizedBox(width: gap),
              ],
              if (lockedUserChip != null) ...[
                lockedUserChip,
                SizedBox(width: gap),
              ],
              sizedFilter(sourceFilter, width: _sourceWidth),
              SizedBox(width: gap),
              sizedFilter(dateFilter, width: _dateWidth),
              if (clearButton != null) clearButton,
            ],
          );
        }

        if (veryNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (topSection != null) ...[
                topSection,
                SizedBox(height: gap),
              ],
              ...secondaryFilters.expand(
                (w) => [w, SizedBox(height: gap)],
              ).toList()
                ..removeLast(),
              if (clearButton != null) ...[
                SizedBox(height: gap),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: clearButton,
                ),
              ],
            ],
          );
        }

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (topSection != null) ...[
                topSection,
                SizedBox(height: gap),
              ],
              filterRow(
                filters: [
                  sourceFilter,
                  if (limitFilter != null) limitFilter,
                ],
                inlineClear: true,
              ),
              SizedBox(height: gap),
              sizedFilter(dateFilter),
            ],
          );
        }

        if (medium) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (userSearch != null) ...[
                Expanded(flex: 3, child: userSearch),
                SizedBox(width: gap),
              ],
              if (lockedUserChip != null) ...[
                lockedUserChip,
                SizedBox(width: gap),
              ],
              Expanded(child: sizedFilter(sourceFilter)),
              SizedBox(width: gap),
              Expanded(child: sizedFilter(limitFilter!)),
              SizedBox(width: gap),
              Expanded(
                flex: 2,
                child: sizedFilter(dateFilter),
              ),
              if (clearButton != null) clearButton,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (userSearch != null) ...[
              Expanded(flex: 3, child: userSearch),
              SizedBox(width: gap),
            ],
            if (lockedUserChip != null) ...[
              lockedUserChip,
              SizedBox(width: gap),
            ],
            sizedFilter(sourceFilter, width: _sourceWidth),
            SizedBox(width: gap),
            sizedFilter(limitFilter!, width: _limitWidth),
            SizedBox(width: gap),
            sizedFilter(dateFilter, width: _dateWidth),
            if (clearButton != null) clearButton,
          ],
        );
      },
    );
  }
}

enum _DateRangePreset { all, today, last7, last30, custom }

class LocationDateRangeFilter extends StatelessWidget {
  const LocationDateRangeFilter({
    super.key,
    required this.dateRange,
    required this.onPresetSelected,
    this.width,
  });

  final DateTimeRange? dateRange;
  final ValueChanged<DateTimeRange?> onPresetSelected;
  final double? width;

  static const _controlHeight = ToolbarFilterStyle.controlHeight;

  _DateRangePreset _activePreset() {
    if (dateRange == null) return _DateRangePreset.all;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    if (_sameDay(dateRange!.start, startOfToday) &&
        dateRange!.end.difference(now).inMinutes.abs() < 5) {
      return _DateRangePreset.today;
    }
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    if (_sameDay(dateRange!.start, sevenDaysAgo)) {
      return _DateRangePreset.last7;
    }
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    if (_sameDay(dateRange!.start, thirtyDaysAgo)) {
      return _DateRangePreset.last30;
    }
    return _DateRangePreset.custom;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final range = dateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
    final result = await showSearchHistoryDateRangeDialog(
      context,
      initialFrom: range.start,
      initialTo: range.end,
    );
    if (result == null) return;
    if (result.clear) {
      onPresetSelected(null);
      return;
    }
    final picked = result.range;
    if (picked == null) return;
    onPresetSelected(
      DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final preset = _activePreset();

    String label;
    switch (preset) {
      case _DateRangePreset.today:
        label = l10n.t('promoDateRangeToday');
      case _DateRangePreset.last7:
        label = l10n.t('promoDateRange7Days');
      case _DateRangePreset.last30:
        label = l10n.t('promoDateRange30Days');
      case _DateRangePreset.custom:
        if (dateRange != null) {
          final fmt = DateFormat.MMMd();
          label = '${fmt.format(dateRange!.start)} – ${fmt.format(dateRange!.end)}';
        } else {
          label = l10n.t('promoDateRangeCustom');
        }
      case _DateRangePreset.all:
        label = l10n.tOr('promoFilterDate', 'Date');
    }

    final isActive = preset != _DateRangePreset.all;

    return SizedBox(
      height: _controlHeight,
      width: width,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: ToolbarFilterStyle.radius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: PopupMenuButton<_DateRangePreset>(
          tooltip: l10n.tOr('promoFilterDate', 'Date'),
          offset: const Offset(0, _controlHeight),
          padding: EdgeInsets.zero,
          onSelected: (value) {
            final now = DateTime.now();
            switch (value) {
              case _DateRangePreset.all:
                onPresetSelected(null);
              case _DateRangePreset.today:
                onPresetSelected(
                  DateTimeRange(
                    start: DateTime(now.year, now.month, now.day),
                    end: now,
                  ),
                );
              case _DateRangePreset.last7:
                onPresetSelected(
                  DateTimeRange(
                    start: now.subtract(const Duration(days: 7)),
                    end: now,
                  ),
                );
              case _DateRangePreset.last30:
                onPresetSelected(
                  DateTimeRange(
                    start: now.subtract(const Duration(days: 30)),
                    end: now,
                  ),
                );
              case _DateRangePreset.custom:
                _pickCustomRange(context);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _DateRangePreset.all,
              child: Text(l10n.t('all')),
            ),
            PopupMenuItem(
              value: _DateRangePreset.today,
              child: Text(l10n.t('promoDateRangeToday')),
            ),
            PopupMenuItem(
              value: _DateRangePreset.last7,
              child: Text(l10n.t('promoDateRange7Days')),
            ),
            PopupMenuItem(
              value: _DateRangePreset.last30,
              child: Text(l10n.t('promoDateRange30Days')),
            ),
            PopupMenuItem(
              value: _DateRangePreset.custom,
              child: Text(l10n.t('promoDateRangeCustom')),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(
                  Icons.date_range_outlined,
                  size: 16,
                  color: isActive ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isActive
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
                ),
                Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final safeValue = items.contains(value) ? value : null;

    return Container(
      height: ToolbarFilterStyle.controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: ToolbarFilterStyle.boxDecoration(scheme),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: safeValue,
          isExpanded: true,
          isDense: true,
          borderRadius: ToolbarFilterStyle.radius,
          dropdownColor: scheme.surface,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurface),
          hint: Text(
            hint,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          icon: Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          items: items
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(
                    itemLabel(v),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class LocationMapCard extends StatelessWidget {
  const LocationMapCard({
    super.key,
    required this.points,
    required this.polylinePoints,
    required this.showMovementPath,
    required this.selectedUser,
    this.userMarkers,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
    this.height,
    this.minZoom = 3,
    this.showZoomControls = false,
  });

  final List<LocationPointEntity> points;
  final List<LocationPointEntity> polylinePoints;
  final bool showMovementPath;
  final UserEntity? selectedUser;
  final List<LocationUserMapMarker>? userMarkers;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final double? height;
  final double minZoom;
  final bool showZoomControls;

  @override
  Widget build(BuildContext context) {
    return LocationDashboardCard(
      padding: const EdgeInsets.all(LocationSpace.sm),
      child: LocationMapPanel(
        points: points,
        polylinePoints: polylinePoints,
        height: height,
        showMovementPath: showMovementPath,
        selectedUser: selectedUser,
        userMarkers: userMarkers,
        isLoading: isLoading,
        errorMessage: errorMessage,
        onRetry: onRetry,
        minZoom: minZoom,
        showZoomControls: showZoomControls,
      ),
    );
  }
}

class LocationTableCard extends StatelessWidget {
  const LocationTableCard({
    super.key,
    required this.state,
    this.singleUserOnly = false,
    this.metrics,
    this.listScrollController,
  });

  final LocationIntelligenceLoaded state;
  final bool singleUserOnly;
  final LocationLayoutMetrics? metrics;
  final ScrollController? listScrollController;

  EdgeInsets _cardPadding(LocationLayoutMetrics? m) {
    final p = m?.cardPadding ?? LocationSpace.md;
    return EdgeInsets.fromLTRB(p, p, p, p * 0.75);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<LocationIntelligenceBloc>();
    final m = metrics ??
        LocationLayoutMetrics(
          getLocationDeviceType(MediaQuery.sizeOf(context).width),
        );

    final tableTitle = l10n.t('promoLocationLog');
    final useInfiniteScroll = m.useInfiniteScroll;

    final table = LocationHistoryTable(
      history: state.history,
      metrics: m,
      scrollController: listScrollController,
      canLoadMore: !useInfiniteScroll &&
          state.historyMeta != null &&
          state.historyMeta!.page < state.historyMeta!.totalPages,
      isLoadingMore: state.isLoadingMoreHistory,
      hasReachedMax: state.hasReachedMaxHistory,
      onLoadMore: () => bloc.add(
        LoadLocationHistoryEvent(
          page: state.historyMeta!.page + 1,
        ),
      ),
    );

    if (singleUserOnly) {
      return LocationDashboardCard(
        padding: _cardPadding(m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: table),
          ],
        ),
      );
    }

    final overviewTableTitle = state.isUserDetail
        ? tableTitle
        : l10n.t('promoAllUsersOverview');

    final overviewOrHistoryTable = state.isUserDetail
        ? table
        : LocationOverviewTable(
            entries: state.overviewEntries,
            metrics: m,
            scrollController: listScrollController,
            isLoadingMore: state.isLoadingMoreOverview,
            hasReachedMax: state.hasReachedMaxOverview,
            onViewUser: (user) => bloc.add(SelectLocationUserEvent(user)),
          );

    return LocationDashboardCard(
      padding: _cardPadding(m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stackTitle = constraints.maxWidth < 520 &&
                  state.isUserDetail &&
                  state.selectedUser != null;

              if (stackTitle) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      overviewTableTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(height: m.filterGap),
                    SelectedUserChip(
                      user: state.selectedUser!,
                      onClear: () => bloc.add(ClearLocationUserEvent()),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      overviewTableTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  if (state.isUserDetail && state.selectedUser != null)
                    SelectedUserChip(
                      user: state.selectedUser!,
                      onClear: () => bloc.add(ClearLocationUserEvent()),
                    ),
                ],
              );
            },
          ),
          SizedBox(height: m.sectionGap),
          Expanded(child: overviewOrHistoryTable),
          if (!state.isUserDetail &&
              state.overviewMeta != null &&
              m.useDesktopPagination)
            LocationPaginationFooter(
              meta: state.overviewMeta!,
              metrics: m,
            ),
        ],
      ),
    );
  }
}

class LocationPaginationFooter extends StatelessWidget {
  const LocationPaginationFooter({
    super.key,
    required this.meta,
    this.metrics,
  });

  final PaginationMeta meta;
  final LocationLayoutMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<LocationIntelligenceBloc>();
    final scheme = Theme.of(context).colorScheme;
    final m = metrics ??
        LocationLayoutMetrics(
          getLocationDeviceType(MediaQuery.sizeOf(context).width),
        );
    final fullUserLocations = switch (bloc.state) {
      LocationIntelligenceLoaded s => s.fullUserLocations,
      _ => false,
    };

    void paginate(int page) {
      bloc.add(
        LoadLocationOverviewEvent(
          page: page,
          fullUserLocations: fullUserLocations,
        ),
      );
    }

    final start = meta.total == 0 ? 0 : ((meta.page - 1) * meta.limit) + 1;
    final end = (meta.page * meta.limit).clamp(0, meta.total);
    final compact = m.isMobile;
    final tablet = m.deviceType == LocationDeviceType.tablet;

    final summary = compact
        ? 'Page ${meta.page} / ${meta.totalPages}'
        : l10n.tArgs('promoShowingUsersRange', {
            'start': '$start',
            'end': '$end',
            'total': '${meta.total}',
          });

    final visiblePages = <int>{
      for (var i = meta.page - 2; i <= meta.page + 2; i++)
        if (i >= 1 && i <= meta.totalPages) i,
    };

    Widget pageButton(int page) {
      final isActive = page == meta.page;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => paginate(page),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        scheme.primary,
                        scheme.primary.withValues(alpha: 0.8),
                      ],
                    )
                  : null,
              color: isActive ? null : scheme.surface,
              border: Border.all(
                color: isActive ? Colors.transparent : scheme.outlineVariant,
              ),
            ),
            child: Text(
              '$page',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isActive ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      );
    }

    Widget navIcon({
      required IconData icon,
      required bool enabled,
      required VoidCallback onTap,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: enabled
                    ? scheme.outlineVariant
                    : scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: enabled
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
      );
    }

    final pageControls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        navIcon(
          icon: Icons.chevron_left_rounded,
          enabled: meta.page > 1,
          onTap: () => paginate(meta.page - 1),
        ),
        const SizedBox(width: 4),
        if (!compact && !tablet)
          for (final page in visiblePages) ...[
            pageButton(page),
            const SizedBox(width: 4),
          ]
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '${meta.page}/${meta.totalPages}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        navIcon(
          icon: Icons.chevron_right_rounded,
          enabled: meta.page < meta.totalPages,
          onTap: () => paginate(meta.page + 1),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(top: m.sectionGap),
      child: compact
          ? Column(
              children: [
                Text(
                  summary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                ),
                SizedBox(height: m.filterGap),
                pageControls,
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                  ),
                ),
                pageControls,
              ],
            ),
    );
  }
}

class LocationSourceBadge extends StatelessWidget {
  const LocationSourceBadge({super.key, required this.source});

  final String? source;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = source ?? '—';
    if (source == null || source!.isEmpty) {
      return Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      );
    }

    final (bg, fg) = switch (source) {
      'APP_OPEN' => (
          scheme.primaryContainer.withValues(alpha: 0.55),
          scheme.onPrimaryContainer,
        ),
      'FEED' => (
          scheme.secondaryContainer.withValues(alpha: 0.55),
          scheme.onSecondaryContainer,
        ),
      'MANUAL' => (
          scheme.tertiaryContainer.withValues(alpha: 0.55),
          scheme.onTertiaryContainer,
        ),
      'BACKGROUND' => (
          scheme.errorContainer.withValues(alpha: 0.45),
          scheme.onErrorContainer,
        ),
      _ => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class LocationOverviewTable extends StatelessWidget {
  const LocationOverviewTable({
    super.key,
    required this.entries,
    required this.onViewUser,
    this.metrics,
    this.scrollController,
    this.isLoadingMore = false,
    this.hasReachedMax = true,
  });

  final List<UserLocationSummary> entries;
  final ValueChanged<UserEntity> onViewUser;
  final LocationLayoutMetrics? metrics;
  final ScrollController? scrollController;
  final bool isLoadingMore;
  final bool hasReachedMax;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat.yMMMd().add_jm();
    final m = metrics ??
        LocationLayoutMetrics(
          getLocationDeviceType(MediaQuery.sizeOf(context).width),
        );

    if (entries.isEmpty) {
      return Center(child: Text(l10n.t('noData')));
    }

    if (m.useCompactTable) {
      final itemCount = entries.length +
          (isLoadingMore ? 1 : 0) +
          (hasReachedMax && entries.isNotEmpty ? 1 : 0);

      return ListView.builder(
        controller: scrollController,
        physics: m.listScrollPhysics,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index < entries.length) {
            return _OverviewCompactCard(
              entry: entries[index],
              dateFmt: dateFmt,
              onViewUser: () => onViewUser(entries[index].user),
            );
          }
          if (isLoadingMore) return const LocationLoadMoreIndicator();
          return const LocationEndOfListLabel();
        },
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showRegion = constraints.maxWidth >= 900;
            final showAccuracy = constraints.maxWidth >= 680;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: kLocationTableHeaderHeight,
                  color: scheme.surfaceContainerLow,
                  padding: const EdgeInsets.symmetric(horizontal: LocationSpace.xs),
                  child: _OverviewRowLayout(
                    showRegion: showRegion,
                    showAccuracy: showAccuracy,
                    user: Text(
                      l10n.tOr('promoColUser', 'User'),
                      style: _headerStyle(context),
                    ),
                    time: Text(l10n.t('time'), style: _headerStyle(context)),
                    city: Text(l10n.t('city'), style: _headerStyle(context)),
                    region: Text(l10n.t('region'), style: _headerStyle(context)),
                    country: Text(l10n.t('country'), style: _headerStyle(context)),
                    source: Text(
                      l10n.tOr('promoFilterSource', 'Source'),
                      style: _headerStyle(context),
                    ),
                    accuracy: Text(
                      l10n.tOr('promoColAccuracy', 'Acc.'),
                      style: _headerStyle(context),
                    ),
                    actions: Icon(
                      Icons.more_horiz_rounded,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    physics: m.listScrollPhysics,
                    padding: EdgeInsets.zero,
                    itemCount: entries.length +
                        (m.useInfiniteScroll && isLoadingMore ? 1 : 0) +
                        (m.useInfiniteScroll &&
                                hasReachedMax &&
                                entries.isNotEmpty
                            ? 1
                            : 0),
                    separatorBuilder: (context, index) {
                      if (index >= entries.length - 1) {
                        return const SizedBox.shrink();
                      }
                      return Divider(
                        height: 1,
                        color: scheme.outlineVariant.withValues(alpha: 0.35),
                      );
                    },
                    itemBuilder: (context, i) {
                      if (i < entries.length) {
                        return _OverviewTableRow(
                          entry: entries[i],
                          dateFmt: dateFmt,
                          striped: i.isOdd,
                          showRegion: showRegion,
                          showAccuracy: showAccuracy,
                          onViewUser: () => onViewUser(entries[i].user),
                        );
                      }
                      if (isLoadingMore) {
                        return const LocationLoadMoreIndicator();
                      }
                      return const LocationEndOfListLabel();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  TextStyle? _headerStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 10,
          letterSpacing: 0.2,
        );
  }
}

class _OverviewCompactCard extends StatelessWidget {
  const _OverviewCompactCard({
    required this.entry,
    required this.dateFmt,
    required this.onViewUser,
  });

  final UserLocationSummary entry;
  final DateFormat dateFmt;
  final VoidCallback onViewUser;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = entry.user;
    final point = entry.latestPoint;

    return Material(
      color: scheme.surface,
      child: InkWell(
        onTap: onViewUser,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: scheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName?.isNotEmpty == true
                          ? user.fullName!
                          : user.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      point != null
                          ? '${point.city ?? '—'} · ${dateFmt.format(point.createdAt)}'
                          : '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    if (point != null) ...[
                      const SizedBox(height: 4),
                      LocationSourceBadge(source: point.source),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewTableRow extends StatefulWidget {
  const _OverviewTableRow({
    required this.entry,
    required this.dateFmt,
    required this.striped,
    required this.showRegion,
    required this.showAccuracy,
    required this.onViewUser,
  });

  final UserLocationSummary entry;
  final DateFormat dateFmt;
  final bool striped;
  final bool showRegion;
  final bool showAccuracy;
  final VoidCallback onViewUser;

  @override
  State<_OverviewTableRow> createState() => _OverviewTableRowState();
}

class _OverviewTableRowState extends State<_OverviewTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final user = widget.entry.user;
    final point = widget.entry.latestPoint;
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11.5,
          height: 1.25,
        );

    Color rowColor;
    if (_hovered) {
      rowColor = scheme.surfaceContainerHighest;
    } else if (widget.striped) {
      rowColor = scheme.surfaceContainerHighest.withValues(alpha: 0.35);
    } else {
      rowColor = scheme.surface;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: rowColor,
        child: InkWell(
          onTap: widget.onViewUser,
          child: SizedBox(
            height: kLocationRowHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: LocationSpace.xs),
              child: _OverviewRowLayout(
                showRegion: widget.showRegion,
                showAccuracy: widget.showAccuracy,
                user: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName?.isNotEmpty == true
                          ? user.fullName!
                          : user.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cellStyle?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cellStyle?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                time: Text(
                  point != null ? widget.dateFmt.format(point.createdAt) : '—',
                  style: cellStyle,
                ),
                city: Text(point?.city ?? '—', style: cellStyle),
                region: Text(point?.region ?? '—', style: cellStyle),
                country: Text(point?.country ?? '—', style: cellStyle),
                source: LocationSourceBadge(source: point?.source),
                accuracy: Text(
                  point?.accuracy?.toStringAsFixed(1) ?? '—',
                  style: cellStyle?.copyWith(color: scheme.onSurfaceVariant),
                ),
                actions: IconButton(
                  tooltip: l10n.t('promoViewUserTrail'),
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onViewUser,
                  icon: const Icon(Icons.route_outlined, size: 18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewRowLayout extends StatelessWidget {
  const _OverviewRowLayout({
    required this.user,
    required this.time,
    required this.city,
    required this.region,
    required this.country,
    required this.source,
    required this.accuracy,
    required this.actions,
    this.showRegion = true,
    this.showAccuracy = true,
  });

  final Widget user;
  final Widget time;
  final Widget city;
  final Widget region;
  final Widget country;
  final Widget source;
  final Widget accuracy;
  final Widget actions;
  final bool showRegion;
  final bool showAccuracy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 4, child: _cell(user)),
        Expanded(flex: 3, child: _cell(time)),
        Expanded(flex: 2, child: _cell(city)),
        if (showRegion) Expanded(flex: 2, child: _cell(region)),
        Expanded(flex: 2, child: _cell(country)),
        Expanded(flex: 2, child: _cell(source)),
        if (showAccuracy)
          Expanded(flex: 1, child: _cell(accuracy, alignEnd: true)),
        SizedBox(width: 36, child: Center(child: actions)),
      ],
    );
  }

  Widget _cell(Widget child, {bool alignEnd = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kCellHPad),
      child: Align(
        alignment: alignEnd
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: child,
      ),
    );
  }
}

class LocationHistoryTable extends StatelessWidget {
  const LocationHistoryTable({
    super.key,
    required this.history,
    required this.canLoadMore,
    required this.onLoadMore,
    this.metrics,
    this.scrollController,
    this.isLoadingMore = false,
    this.hasReachedMax = true,
  });

  final List<LocationPointEntity> history;
  final bool canLoadMore;
  final VoidCallback onLoadMore;
  final LocationLayoutMetrics? metrics;
  final ScrollController? scrollController;
  final bool isLoadingMore;
  final bool hasReachedMax;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat.yMMMd().add_jm();
    final m = metrics ??
        LocationLayoutMetrics(
          getLocationDeviceType(MediaQuery.sizeOf(context).width),
        );

    if (history.isEmpty) {
      return Center(child: Text(l10n.t('promoNoLocationForUser')));
    }

    if (m.useCompactTable) {
      final itemCount = history.length +
          (isLoadingMore ? 1 : 0) +
          (hasReachedMax && history.isNotEmpty ? 1 : 0);

      return ListView.builder(
        controller: scrollController,
        physics: m.listScrollPhysics,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index < history.length) {
            return _HistoryCompactCard(
              point: history[index],
              dateFmt: dateFmt,
            );
          }
          if (isLoadingMore) return const LocationLoadMoreIndicator();
          return const LocationEndOfListLabel();
        },
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showRegion = constraints.maxWidth >= 920;
            final showAccuracy = constraints.maxWidth >= 700;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: kLocationTableHeaderHeight,
                  color: scheme.surfaceContainerLow,
                  padding: const EdgeInsets.symmetric(horizontal: LocationSpace.xs),
                  child: _HistoryRowLayout(
                    showRegion: showRegion,
                    showAccuracy: showAccuracy,
                    time: Text(l10n.t('time'), style: _headerStyle(context)),
                    city: Text(l10n.t('city'), style: _headerStyle(context)),
                    region: Text(l10n.t('region'), style: _headerStyle(context)),
                    country: Text(l10n.t('country'), style: _headerStyle(context)),
                    source: Text(
                      l10n.tOr('promoFilterSource', 'Source'),
                      style: _headerStyle(context),
                    ),
                    accuracy: Text(
                      l10n.tOr('promoColAccuracy', 'Acc.'),
                      style: _headerStyle(context),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    physics: m.listScrollPhysics,
                    padding: EdgeInsets.zero,
                    itemCount: history.length +
                        (m.useInfiniteScroll && isLoadingMore ? 1 : 0) +
                        (m.useInfiniteScroll &&
                                hasReachedMax &&
                                history.isNotEmpty
                            ? 1
                            : 0),
                    separatorBuilder: (context, index) {
                      if (index >= history.length - 1) {
                        return const SizedBox.shrink();
                      }
                      return Divider(
                        height: 1,
                        color: scheme.outlineVariant.withValues(alpha: 0.35),
                      );
                    },
                    itemBuilder: (context, i) {
                      if (i < history.length) {
                        return _HistoryTableRow(
                          point: history[i],
                          dateFmt: dateFmt,
                          striped: i.isOdd,
                          showRegion: showRegion,
                          showAccuracy: showAccuracy,
                        );
                      }
                      if (isLoadingMore) {
                        return const LocationLoadMoreIndicator();
                      }
                      return const LocationEndOfListLabel();
                    },
                  ),
                ),
                if (canLoadMore)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Padding(
                      padding: EdgeInsets.all(m.sectionGap),
                      child: OutlinedButton(
                        onPressed: onLoadMore,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(l10n.t('loadMore')),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  TextStyle? _headerStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 10,
          letterSpacing: 0.2,
        );
  }
}

class _HistoryCompactCard extends StatelessWidget {
  const _HistoryCompactCard({
    required this.point,
    required this.dateFmt,
  });

  final LocationPointEntity point;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFmt.format(point.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${point.city ?? '—'} · ${point.country ?? '—'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                LocationSourceBadge(source: point.source),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTableRow extends StatefulWidget {
  const _HistoryTableRow({
    required this.point,
    required this.dateFmt,
    required this.striped,
    required this.showRegion,
    required this.showAccuracy,
  });

  final LocationPointEntity point;
  final DateFormat dateFmt;
  final bool striped;
  final bool showRegion;
  final bool showAccuracy;

  @override
  State<_HistoryTableRow> createState() => _HistoryTableRowState();
}

class _HistoryTableRowState extends State<_HistoryTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11.5,
          height: 1.25,
        );

    Color rowColor;
    if (_hovered) {
      rowColor = scheme.surfaceContainerHighest;
    } else if (widget.striped) {
      rowColor = scheme.surfaceContainerHighest.withValues(alpha: 0.35);
    } else {
      rowColor = scheme.surface;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: rowColor,
        child: SizedBox(
          height: kLocationRowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: LocationSpace.xs),
            child: _HistoryRowLayout(
              showRegion: widget.showRegion,
              showAccuracy: widget.showAccuracy,
              time: Text(
                widget.dateFmt.format(widget.point.createdAt),
                style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              city: Text(widget.point.city ?? '—', style: cellStyle),
              region: Text(widget.point.region ?? '—', style: cellStyle),
              country: Text(widget.point.country ?? '—', style: cellStyle),
              source: LocationSourceBadge(source: widget.point.source),
              accuracy: Text(
                widget.point.accuracy?.toStringAsFixed(1) ?? '—',
                style: cellStyle?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryRowLayout extends StatelessWidget {
  const _HistoryRowLayout({
    required this.time,
    required this.city,
    required this.region,
    required this.country,
    required this.source,
    required this.accuracy,
    this.showRegion = true,
    this.showAccuracy = true,
  });

  final Widget time;
  final Widget city;
  final Widget region;
  final Widget country;
  final Widget source;
  final Widget accuracy;
  final bool showRegion;
  final bool showAccuracy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 3, child: _cell(time)),
        Expanded(flex: 2, child: _cell(city)),
        if (showRegion) Expanded(flex: 2, child: _cell(region)),
        Expanded(flex: 2, child: _cell(country)),
        Expanded(flex: 2, child: _cell(source)),
        if (showAccuracy)
          Expanded(flex: 1, child: _cell(accuracy, alignEnd: true)),
      ],
    );
  }

  Widget _cell(Widget child, {bool alignEnd = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kCellHPad),
      child: Align(
        alignment: alignEnd
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: child,
      ),
    );
  }
}

class SelectedUserChip extends StatelessWidget {
  const SelectedUserChip({
    super.key,
    required this.user,
    this.onClear,
  });

  final UserEntity user;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = user.fullName?.isNotEmpty == true
        ? '${user.fullName} (@${user.username})'
        : '@${user.username}';

    return InputChip(
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      avatar: CircleAvatar(
        radius: 12,
        child: Text(
          user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 11),
        ),
      ),
      deleteIcon: onClear != null ? const Icon(Icons.close, size: 18) : null,
      onDeleted: onClear,
      backgroundColor: scheme.primaryContainer.withValues(alpha: 0.35),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
    );
  }
}


class LocationContentSection extends StatelessWidget {
  const LocationContentSection({
    super.key,
    required this.state,
    this.singleUserOnly = false,
    this.fixedUser,
    this.mapMinZoom = 3,
    this.showZoomControls = false,
    this.metrics,
    this.listScrollController,
  });

  final LocationIntelligenceState state;
  final bool singleUserOnly;
  final UserEntity? fixedUser;
  final double mapMinZoom;
  final bool showZoomControls;
  final LocationLayoutMetrics? metrics;
  final ScrollController? listScrollController;

  bool _isCurrentUserLoaded(LocationIntelligenceLoaded loaded) {
    if (!singleUserOnly) return true;
    final userId = fixedUser?.id;
    return userId != null && loaded.selectedUser?.id == userId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<LocationIntelligenceBloc>();

    void retry() {
      if (singleUserOnly && fixedUser != null) {
        bloc.add(SelectLocationUserEvent(fixedUser!));
      } else {
        bloc.add(LoadLocationOverviewEvent());
      }
    }

    final current = state;
    if (singleUserOnly &&
        current is LocationIntelligenceLoaded &&
        !_isCurrentUserLoaded(current)) {
      return const Center(child: LoadingView());
    }

    return switch (state) {
      LocationIntelligenceLoading() => const Center(child: LoadingView()),
      LocationIntelligenceError(:final message) => Center(
          child: ErrorView(
            message: message,
            retryLabel: l10n.t('retry'),
            onRetry: retry,
          ),
        ),
      LocationIntelligenceLoaded loaded when _isCurrentUserLoaded(loaded) =>
        _LoadedLayout(
          state: loaded,
          singleUserOnly: singleUserOnly,
          mapMinZoom: mapMinZoom,
          showZoomControls: showZoomControls,
          metrics: metrics,
          listScrollController: listScrollController,
        ),
      LocationIntelligenceInitial() => const Center(child: LoadingView()),
      _ => const Center(child: LoadingView()),
    };
  }
}

class _LoadedLayout extends StatelessWidget {
  const _LoadedLayout({
    required this.state,
    this.singleUserOnly = false,
    this.mapMinZoom = 3,
    this.showZoomControls = false,
    this.metrics,
    this.listScrollController,
  });

  final LocationIntelligenceLoaded state;
  final bool singleUserOnly;
  final double mapMinZoom;
  final bool showZoomControls;
  final LocationLayoutMetrics? metrics;
  final ScrollController? listScrollController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final m = metrics ??
            LocationLayoutMetrics(getLocationDeviceType(width));
        final stackVertically = m.stackMapBelowTable;
        final tableFlex = width >= 1400 ? 5 : 5;
        final mapFlex = width >= 1400 ? 6 : 5;

        final mapHeight = stackVertically
            ? (constraints.maxHeight.isFinite
                ? (constraints.maxHeight * m.mapHeightFraction)
                    .clamp(m.mapMinHeight, m.mapMaxHeight)
                : m.mapMaxHeight)
            : null;

        final mapCard = BlocSelector<
            LocationIntelligenceBloc,
            LocationIntelligenceState,
            _MapViewData>(
          selector: (s) {
            if (s is LocationIntelligenceLoaded) {
              final userMarkers = s.isUserDetail
                  ? null
                  : [
                      for (final entry in s.overviewEntries)
                        if (entry.latestPoint != null)
                          LocationUserMapMarker(
                            user: entry.user,
                            point: entry.latestPoint!,
                            isLatest: true,
                          ),
                    ];
              return _MapViewData(
                points: s.mapPoints,
                polylinePoints: s.movementPolylinePoints,
                showMovementPath: s.isUserDetail,
                selectedUser: s.selectedUser,
                userMarkers: userMarkers,
              );
            }
            return const _MapViewData(
              points: [],
              polylinePoints: [],
              showMovementPath: false,
            );
          },
          builder: (context, mapData) {
            return LocationMapCard(
              points: mapData.points,
              polylinePoints: mapData.polylinePoints,
              showMovementPath: mapData.showMovementPath,
              selectedUser: mapData.selectedUser,
              userMarkers: mapData.userMarkers,
              isLoading: false,
              height: mapHeight,
              minZoom: mapMinZoom,
              showZoomControls: showZoomControls,
            );
          },
        );

        final tableCard = LocationTableCard(
          state: state,
          singleUserOnly: singleUserOnly,
          metrics: m,
          listScrollController: listScrollController,
        );

        if (stackVertically) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tableCard),
              SizedBox(height: m.tableMapGap),
              mapCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: tableFlex, child: tableCard),
            SizedBox(width: m.tableMapGap),
            Expanded(flex: mapFlex, child: mapCard),
          ],
        );
      },
    );
  }
}

class _MapViewData {
  const _MapViewData({
    required this.points,
    required this.polylinePoints,
    required this.showMovementPath,
    this.selectedUser,
    this.userMarkers,
  });

  final List<LocationPointEntity> points;
  final List<LocationPointEntity> polylinePoints;
  final bool showMovementPath;
  final UserEntity? selectedUser;
  final List<LocationUserMapMarker>? userMarkers;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MapViewData &&
          showMovementPath == other.showMovementPath &&
          selectedUser?.id == other.selectedUser?.id &&
          _userMarkersEqual(userMarkers, other.userMarkers) &&
          _listEquals(points, other.points) &&
          _listEquals(polylinePoints, other.polylinePoints);

  @override
  int get hashCode => Object.hash(
        showMovementPath,
        selectedUser?.id,
        _userMarkersHash(userMarkers),
        Object.hashAll(points.map((p) => p.id)),
        Object.hashAll(polylinePoints.map((p) => p.id)),
      );

  static bool _userMarkersEqual(
    List<LocationUserMapMarker>? a,
    List<LocationUserMapMarker>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].user.id != b[i].user.id ||
          a[i].point.id != b[i].point.id ||
          a[i].isLatest != b[i].isLatest) {
        return false;
      }
    }
    return true;
  }

  static int _userMarkersHash(List<LocationUserMapMarker>? markers) {
    if (markers == null) return 0;
    return Object.hashAll(
      markers.map(
        (m) => Object.hash(m.user.id, m.point.id, m.isLatest),
      ),
    );
  }

  static bool _listEquals(
    List<LocationPointEntity> a,
    List<LocationPointEntity> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}
