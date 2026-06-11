import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
import '../bloc/category_reports_bloc.dart';
import '../widgets/category_reports_overview_tab.dart';
import '../widgets/category_reports_table_panel.dart';

class CategoryReportsPage extends StatefulWidget {
  const CategoryReportsPage({super.key});

  @override
  State<CategoryReportsPage> createState() => _CategoryReportsPageState();
}

class _CategoryReportsPageState extends State<CategoryReportsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (_) => di.sl<CategoryReportsBloc>()
        ..add(LoadCategoryReportsListEvent(refresh: true))
        ..add(LoadCategoryReportsOverviewEvent()),
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
                                  'Category Reports',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hierarchy analytics, post metrics, and uncategorized tracking',
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
                            onPressed: () => context
                                .read<CategoryReportsBloc>()
                                .add(RefreshCategoryReportsEvent()),
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TabBar(
                        controller: _tabController,
                        onTap: (index) {
                          final bloc = context.read<CategoryReportsBloc>();
                          if (index == 0) {
                            bloc.add(LoadCategoryReportsOverviewEvent());
                          } else {
                            bloc.add(LoadCategoryReportsListEvent(refresh: true));
                          }
                        },
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Categories'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child:
                            BlocBuilder<CategoryReportsBloc, CategoryReportsState>(
                          builder: (context, state) {
                            if (state is CategoryReportsInitial ||
                                state is CategoryReportsLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (state is CategoryReportsError) {
                              return Center(child: Text(state.message));
                            }
                            if (state is CategoryReportsLoaded) {
                              return TabBarView(
                                controller: _tabController,
                                children: [
                                  CategoryReportsOverviewTab(state: state),
                                  CategoryReportsTablePanel(
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
