import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/user_entity.dart';
import '../bloc/users_bloc.dart';
import '../utils/responsive.dart';
import '../widgets/users_page_header.dart';
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
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _listScrollController.addListener(_onListScroll);
  }

  @override
  void dispose() {
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
