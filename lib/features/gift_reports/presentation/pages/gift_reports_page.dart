import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
import '../bloc/gift_reports_bloc.dart';
import '../widgets/gift_reports_overview_tab.dart';
import '../widgets/gift_reports_table_panel.dart';

class GiftReportsPage extends StatefulWidget {
  const GiftReportsPage({super.key});

  @override
  State<GiftReportsPage> createState() => _GiftReportsPageState();
}

class _GiftReportsPageState extends State<GiftReportsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final GiftReportsBloc _bloc;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bloc = di.sl<GiftReportsBloc>()
      ..add(LoadGiftReportsOverviewEvent())
      ..add(LoadGiftReportsListEvent(refresh: true));
    if (kDebugMode) {
      debugPrint('GiftReportsBloc created — LoadGiftReports dispatched');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('GiftReportsPage rebuilt');
    final scheme = Theme.of(context).colorScheme;

    return BlocProvider<GiftReportsBloc>.value(
      value: _bloc,
      child: Builder(
        builder: (context) {
          return Container(
            color: scheme.surfaceContainerLowest,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1480),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gift Reports',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Catalog analytics, revenue, and send context',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Refresh',
                            onPressed: () => context
                                .read<GiftReportsBloc>()
                                .add(RefreshGiftReportsEvent()),
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TabBar(
                        controller: _tabController,
                        onTap: (index) {
                          final bloc = context.read<GiftReportsBloc>();
                          if (index == 0) {
                            bloc.add(LoadGiftReportsOverviewEvent());
                          } else {
                            bloc.add(LoadGiftReportsListEvent(refresh: true));
                          }
                        },
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Gifts'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: BlocBuilder<GiftReportsBloc, GiftReportsState>(
                          builder: (context, state) {
                            if (state is GiftReportsLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (state is GiftReportsError) {
                              return Center(child: Text(state.message));
                            }
                            if (state is GiftReportsLoaded) {
                              return TabBarView(
                                controller: _tabController,
                                children: [
                                  GiftReportsOverviewTab(state: state),
                                  GiftReportsTablePanel(
                                    state: state,
                                    searchController: _searchController,
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
