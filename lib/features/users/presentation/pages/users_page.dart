import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/user_entity.dart';
import '../bloc/users_bloc.dart';
import '../users_ui_filter.dart';
import '../utils/responsive.dart';
import '../utils/users_list_filter_debounce.dart';
import '../widgets/users_filter_chips.dart';
import '../widgets/users_page_header.dart';
import '../widgets/users_list_active_filters.dart';
import '../widgets/users_location_filter.dart';
import '../widgets/users_search_bar.dart';
import '../widgets/users_selection_header.dart';
import '../widgets/users_table_panel.dart';

export '../users_ui_filter.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('UsersPage rebuilt');
    return PersistentBlocProvider<UsersBloc>(
      debugLabel: 'UsersPage',
      create: () {
        if (kDebugMode) debugPrint('LoadUsers dispatched');
        return di.sl<UsersBloc>()..add(LoadUsersEvent(refresh: true));
      },
      child: const _UsersPageView(),
    );
  }
}

class _UsersPageView extends StatefulWidget {
  const _UsersPageView();

  @override
  State<_UsersPageView> createState() => _UsersPageViewState();
}

class _UsersPageViewState extends State<_UsersPageView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();
  Timer? _filtersDebounce;
  String _lastSubmittedQuery = '';
  String _lastSubmittedLocation = '';

  static const _filterDebounceDuration = usersListFilterDebounce;

  @override
  void initState() {
    super.initState();
    _listScrollController.addListener(_onListScroll);
  }

  @override
  void dispose() {
    _filtersDebounce?.cancel();
    _searchController.dispose();
    _locationController.dispose();
    _horizontalScrollController.dispose();
    _listScrollController.removeListener(_onListScroll);
    _listScrollController.dispose();
    super.dispose();
  }

  void _onListScroll() {
    if (!mounted || !_listScrollController.hasClients) return;

    final width = MediaQuery.sizeOf(context).width;
    if (!UsersLayoutMetrics(getDeviceType(width)).useInfiniteScroll) return;

    final position = _listScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<UsersBloc>().add(LoadMoreUsersEvent());
    }
  }

  void _scheduleCombinedFilterRefresh({bool immediate = false}) {
    final search = _searchController.text.trim();
    final location = _locationController.text.trim();
    if (search == _lastSubmittedQuery && location == _lastSubmittedLocation) {
      return;
    }

    void dispatch() {
      if (!mounted) return;
      final nextSearch = _searchController.text.trim();
      final nextLocation = _locationController.text.trim();
      if (nextSearch == _lastSubmittedQuery &&
          nextLocation == _lastSubmittedLocation) {
        return;
      }
      _lastSubmittedQuery = nextSearch;
      _lastSubmittedLocation = nextLocation;
      context.read<UsersBloc>().add(
        ApplyUsersListFiltersEvent(
          search: nextSearch,
          location: nextLocation,
        ),
      );
    }

    _filtersDebounce?.cancel();
    if (immediate) {
      dispatch();
      return;
    }

    _filtersDebounce = Timer(_filterDebounceDuration, dispatch);
  }

  void _submitSearch(String rawQuery, {bool immediate = false}) {
    _scheduleCombinedFilterRefresh(immediate: immediate);
  }

  void _submitLocationFilter(String rawQuery, {bool immediate = false}) {
    _scheduleCombinedFilterRefresh(immediate: immediate);
  }

  void _clearSearchFilter() {
    _filtersDebounce?.cancel();
    _searchController.clear();
    _lastSubmittedQuery = '';
    context.read<UsersBloc>().add(
      ApplyUsersListFiltersEvent(
        search: '',
        location: _locationController.text.trim(),
      ),
    );
  }

  void _clearLocationFilter() {
    _filtersDebounce?.cancel();
    _locationController.clear();
    _lastSubmittedLocation = '';
    context.read<UsersBloc>().add(
      ApplyUsersListFiltersEvent(
        search: _searchController.text.trim(),
        location: '',
      ),
    );
  }

  void _clearStatusFilter() {
    context.read<UsersBloc>().add(FilterUsersEvent(UsersUiFilter.all));
  }

  void _clearAllListFilters() {
    _filtersDebounce?.cancel();
    _searchController.clear();
    _locationController.clear();
    _lastSubmittedQuery = '';
    _lastSubmittedLocation = '';
    context.read<UsersBloc>().add(ClearUsersListFiltersEvent());
  }

  void _openUserDetail(UserEntity user) {
    Navigator.pushNamed(context, AppRoutes.userDetail, arguments: user);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocListener<UsersBloc, UsersState>(
      listenWhen: (previous, current) =>
          current is UsersLoaded &&
          current.bulkActionMessage != null &&
          (previous is! UsersLoaded ||
              previous.bulkActionMessage != current.bulkActionMessage),
      listener: (context, state) {
        if (state is! UsersLoaded || state.bulkActionMessage == null) return;
        final scheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: state.bulkActionIsError
                ? scheme.errorContainer
                : null,
            content: Text(
              state.bulkActionMessage!,
              style: TextStyle(
                color: state.bulkActionIsError
                    ? scheme.onErrorContainer
                    : scheme.onInverseSurface,
              ),
            ),
          ),
        );
        context.read<UsersBloc>().add(ClearUsersBulkFeedbackEvent());
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surfaceContainerLowest,
              scheme.surface,
              Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.06),
                scheme.surfaceContainerLow,
              ),
            ],
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1680),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final metrics = UsersLayoutMetrics(
                  getDeviceType(constraints.maxWidth),
                );

                final search = UsersSearchBar(
                  controller: _searchController,
                  metrics: metrics,
                  onChanged: _submitSearch,
                  onSubmitted: (value) => _submitSearch(value, immediate: true),
                );
                final locationFilter = UsersLocationFilter(
                  controller: _locationController,
                  metrics: metrics,
                  onChanged: _submitLocationFilter,
                  onSubmitted: (value) =>
                      _submitLocationFilter(value, immediate: true),
                );
                final filters = UsersFilterChips(
                  metrics: metrics,
                  onChanged: (filter) =>
                      context.read<UsersBloc>().add(FilterUsersEvent(filter)),
                );

                return Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    metrics.pageHorizontalPadding,
                    metrics.pageTopPadding,
                    metrics.pageHorizontalPadding,
                    metrics.pageBottomPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      UsersPageHeader(
                        metrics: metrics,
                        searchBar: search,
                        locationFilter: locationFilter,
                        filters: filters,
                        onRefresh: () => context.read<UsersBloc>().add(
                          LoadUsersEvent(refresh: true),
                        ),
                      ),
                      UsersListActiveFilters(
                        metrics: metrics,
                        onClearSearch: _clearSearchFilter,
                        onClearLocation: _clearLocationFilter,
                        onClearStatus: _clearStatusFilter,
                        onClearAll: _clearAllListFilters,
                      ),
                      SizedBox(height: metrics.sectionSpacing),
                      UsersSelectionHeader(metrics: metrics),
                      SizedBox(height: metrics.isMobile ? 6 : 8),
                      Expanded(
                        child: UsersTablePanel(
                          metrics: metrics,
                          horizontalScrollController:
                              _horizontalScrollController,
                          listScrollController: _listScrollController,
                          onUserTap: _openUserDetail,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
