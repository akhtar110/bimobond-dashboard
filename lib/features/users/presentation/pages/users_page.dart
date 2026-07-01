import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/user_entity.dart';
import '../bloc/users_bloc.dart';
import '../utils/responsive.dart';
import '../widgets/users_filter_chips.dart';
import '../widgets/users_page_header.dart';
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
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();
  Timer? _searchDebounce;
  String _lastSubmittedQuery = '';

  static const _searchDebounceDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _listScrollController.addListener(_onListScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
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

  void _submitSearch(String rawQuery, {bool immediate = false}) {
    final query = rawQuery.trim();
    if (query == _lastSubmittedQuery) return;

    void dispatch() {
      if (!mounted) return;
      _lastSubmittedQuery = query;
      context.read<UsersBloc>().add(SearchUsersEvent(query));
    }

    _searchDebounce?.cancel();
    if (immediate) {
      dispatch();
      return;
    }

    _searchDebounce = Timer(_searchDebounceDuration, dispatch);
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
            backgroundColor:
                state.bulkActionIsError ? scheme.errorContainer : null,
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
                final metrics =
                    UsersLayoutMetrics(getDeviceType(constraints.maxWidth));

                final search = UsersSearchBar(
                  controller: _searchController,
                  metrics: metrics,
                  onChanged: _submitSearch,
                  onSubmitted: (value) =>
                      _submitSearch(value, immediate: true),
                );
                final filters = UsersFilterChips(
                  metrics: metrics,
                  onChanged: (filter) => context.read<UsersBloc>().add(
                        FilterUsersEvent(filter),
                      ),
                );

                final Widget searchFiltersSection;
                if (metrics.searchFiltersInRow) {
                  searchFiltersSection = Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 6, child: search),
                      const SizedBox(width: 20),
                      Expanded(flex: 5, child: filters),
                    ],
                  );
                } else {
                  searchFiltersSection = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      search,
                      SizedBox(height: metrics.searchFilterGap),
                      filters,
                    ],
                  );
                }

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
                        onRefresh: () => context.read<UsersBloc>().add(
                              LoadUsersEvent(refresh: true),
                            ),
                      ),
                      SizedBox(height: metrics.sectionSpacing),
                      Container(
                        padding:
                            EdgeInsets.all(metrics.filterSectionPadding),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: searchFiltersSection,
                      ),
                      SizedBox(height: metrics.isMobile ? 8 : 10),
                      UsersSelectionHeader(metrics: metrics),
                      SizedBox(height: metrics.isMobile ? 8 : 10),
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
