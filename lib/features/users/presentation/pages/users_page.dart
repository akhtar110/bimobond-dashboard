import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/user_entity.dart';
import '../bloc/users_bloc.dart';
import '../utils/responsive.dart';
import '../widgets/users_analytics_cards.dart';
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

  void _navigateToUserDetail(UserEntity user) {
    Navigator.of(context).pushNamed(
      AppRoutes.userDetail,
      arguments: user,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UsersBloc, UsersState>(
      listenWhen: (previous, current) {
        if (current is! UsersLoaded) return false;
        final prev = previous is UsersLoaded ? previous : null;
        final hasNewBulk = current.bulkActionMessage != null &&
            prev?.bulkActionMessage != current.bulkActionMessage;
        final hasNewExport = current.exportMessage != null &&
            prev?.exportMessage != current.exportMessage;
        return hasNewBulk || hasNewExport;
      },
      listener: (context, state) {
        if (state is! UsersLoaded) return;
        final scheme = Theme.of(context).colorScheme;

        final bulkMsg = state.bulkActionMessage;
        if (bulkMsg != null) {
          final text = state.bulkActionIsError
              ? bulkMsg
              : context.l10n.tOr(bulkMsg, bulkMsg);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor:
                  state.bulkActionIsError ? scheme.errorContainer : null,
              content: Text(
                text,
                style: TextStyle(
                  color: state.bulkActionIsError
                      ? scheme.onErrorContainer
                      : null,
                ),
              ),
            ),
          );
          context.read<UsersBloc>().add(ClearUsersBulkFeedbackEvent());
        }

        final exportMsg = state.exportMessage;
        if (exportMsg != null) {
          final text = state.exportIsError
              ? exportMsg
              : context.l10n.tOr(exportMsg, exportMsg);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor:
                  state.exportIsError ? scheme.errorContainer : null,
              content: Text(
                text,
                style: TextStyle(
                  color: state.exportIsError ? scheme.onErrorContainer : null,
                ),
              ),
            ),
          );
          context.read<UsersBloc>().add(ClearUsersExportFeedbackEvent());
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: NotificationListener<ScrollNotification>(
            onNotification: (_) => false,
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
                      const UsersAnalyticsCards(),
                      SizedBox(height: metrics.sectionSpacing),
                      UsersSelectionHeader(metrics: metrics),
                      SizedBox(height: metrics.sectionSpacing),
                      Expanded(
                        child: UsersTablePanel(
                          metrics: metrics,
                          horizontalScrollController:
                              _horizontalScrollController,
                          listScrollController: _listScrollController,
                          onUserTap: _navigateToUserDetail,
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
