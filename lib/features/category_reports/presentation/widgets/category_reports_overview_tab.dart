import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../analytics/presentation/widgets/analytics_kpi_card.dart';
import '../../domain/entities/category_report_entities.dart';
import '../bloc/category_reports_bloc.dart';
import '../utils/category_report_format.dart';

class CategoryReportsOverviewTab extends StatelessWidget {
  const CategoryReportsOverviewTab({super.key, required this.state});

  final CategoryReportsLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.isOverviewLoading && state.overview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.overviewError != null && state.overview == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.overviewError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context
                  .read<CategoryReportsBloc>()
                  .add(LoadCategoryReportsOverviewEvent()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final overview = state.overview;
    if (overview == null) {
      return const Center(child: Text('No overview data'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final days in [7, 30, 90])
                FilterChip(
                  label: Text('Last $days days'),
                  selected: state.days == days,
                  onSelected: (_) => context
                      .read<CategoryReportsBloc>()
                      .add(ChangeCategoryReportsDaysEvent(days)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 1100
                  ? 4
                  : constraints.maxWidth > 700
                      ? 2
                      : 1;
              final width = (constraints.maxWidth - (cols - 1) * 12) / cols;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: AnalyticsKpiCard(
                      title: 'Categories',
                      value: '${overview.totalCategories}',
                      subtitle:
                          '${overview.mainCategories} main · ${overview.subcategories} sub',
                      icon: Icons.label_outlined,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: AnalyticsKpiCard(
                      title: 'Total posts',
                      value: formatCategoryReportCount(overview.totalPosts),
                      subtitle:
                          '${formatCategoryReportCount(overview.postsWithCategory)} categorized',
                      icon: Icons.grid_view_outlined,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: AnalyticsKpiCard(
                      title: 'Uncategorized',
                      value: formatCategoryReportCount(
                        overview.postsWithoutCategory,
                      ),
                      subtitle: 'Needs attention',
                      icon: Icons.warning_amber_outlined,
                      accent: Colors.orange,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: AnalyticsKpiCard(
                      title: 'Posts created',
                      value: formatCategoryReportCount(overview.postsCreated),
                      subtitle:
                          '${formatCategoryReportCount(overview.uncategorizedPosts)} uncategorized in period',
                      icon: Icons.add_chart_outlined,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          AnalyticsSectionCard(
            title: 'Top categories by posts',
            child: _TopCategoriesList(items: overview.topByPosts),
          ),
          const SizedBox(height: 16),
          AnalyticsSectionCard(
            title: 'Top categories by views',
            child: _TopCategoriesList(items: overview.topByViews),
          ),
        ],
      ),
    );
  }
}

class _TopCategoriesList extends StatelessWidget {
  const _TopCategoriesList({required this.items});

  final List<CategoryReportTopCategorySummary> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('No data for this period');
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(formatCategoryReportCount(item.postCount)),
                const SizedBox(width: 12),
                Text(formatCategoryReportCount(item.views)),
              ],
            ),
          ),
      ],
    );
  }
}
