import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/user_entity.dart';
import '../bloc/users_bloc.dart';
import '../utils/responsive.dart';
import '../widgets/user_detail_drawer.dart';
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
  UserEntity? _selectedDrawerUser;

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

  void _openUserDrawer(UserEntity user) {
    setState(() => _selectedDrawerUser = user);
  }

  void _closeUserDrawer() {
    setState(() => _selectedDrawerUser = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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

        if (state.bulkActionMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
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
        } else if (state.exportMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.exportMessage!),
                behavior: SnackBarBehavior.floating,
                backgroundColor:
                    state.exportIsError ? scheme.error : scheme.primary,
              ),
            );
          context.read<UsersBloc>().add(ClearUsersExportFeedbackEvent());
        }
      },
      child: Stack(
        children: [
          Container(
            color: scheme.surfaceContainerLowest,
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
                          const SizedBox(height: 8),
                          const UsersAnalyticsCards(),
                          const SizedBox(height: 8),
                          UsersSelectionHeader(metrics: metrics),
                          SizedBox(height: metrics.isMobile ? 6 : 8),
                          Expanded(
                            child: UsersTablePanel(
                              metrics: metrics,
                              horizontalScrollController:
                                  _horizontalScrollController,
                              listScrollController: _listScrollController,
                              onUserTap: _openUserDrawer,
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

          // Right-Side Slide Drawer Overlay
          if (_selectedDrawerUser != null) ...[
            GestureDetector(
              onTap: _closeUserDrawer,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
            Align(
              alignment: context.isRtl ? Alignment.centerLeft : Alignment.centerRight,
              child: SlideTransition(
                position: AlwaysStoppedAnimation(const Offset(0, 0)),
                child: UserDetailDrawer(
                  user: _selectedDrawerUser!,
                  onClose: _closeUserDrawer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
