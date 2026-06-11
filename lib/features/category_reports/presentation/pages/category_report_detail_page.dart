import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/category_report_entities.dart';
import '../../../reports/presentation/utils/report_detail_labels.dart';
import '../../../reports/presentation/widgets/reports_embedded_panel.dart';
import '../bloc/category_report_detail_bloc.dart';
import '../utils/category_report_format.dart';

class CategoryReportDetailPage extends StatelessWidget {
  const CategoryReportDetailPage({
    super.key,
    required this.categoryId,
    this.onClose,
  });

  final String categoryId;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<CategoryReportDetailBloc>()
        ..add(LoadCategoryReportDetailEvent(categoryId: categoryId)),
      child: _CategoryReportDetailView(onClose: onClose),
    );
  }
}

class _CategoryReportDetailView extends StatelessWidget {
  const _CategoryReportDetailView({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final actions = <Widget>[
      BlocBuilder<CategoryReportDetailBloc, CategoryReportDetailState>(
        builder: (context, state) {
          final days =
              state is CategoryReportDetailLoaded ? state.days : 30;
          return PopupMenuButton<int>(
            tooltip: ReportDetailLabels.period(l10n),
            icon: const Icon(Icons.date_range_outlined),
            onSelected: (value) => context
                .read<CategoryReportDetailBloc>()
                .add(ChangeCategoryReportDetailDaysEvent(value)),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 7,
                child: Text(
                  ReportDetailLabels.lastNDays(l10n, 7, selected: days == 7),
                ),
              ),
              PopupMenuItem(
                value: 30,
                child: Text(
                  ReportDetailLabels.lastNDays(l10n, 30, selected: days == 30),
                ),
              ),
              PopupMenuItem(
                value: 90,
                child: Text(
                  ReportDetailLabels.lastNDays(l10n, 90, selected: days == 90),
                ),
              ),
            ],
          );
        },
      ),
      IconButton(
        tooltip: l10n.t('refresh'),
        onPressed: () => context
            .read<CategoryReportDetailBloc>()
            .add(RefreshCategoryReportDetailEvent()),
        icon: const Icon(Icons.refresh_rounded),
      ),
    ];

    return ReportsDetailShell(
      title: ReportDetailLabels.categoryReportTitle(l10n),
      subtitle: ReportDetailLabels.categoryReportSubtitle(l10n),
      onClose: onClose,
      actions: actions,
      body: BlocBuilder<CategoryReportDetailBloc, CategoryReportDetailState>(
        builder: (context, state) {
          if (state is CategoryReportDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CategoryReportDetailError) {
            return Center(child: Text(state.message));
          }
          if (state is CategoryReportDetailLoaded) {
            return _DetailBody(
              detail: state.detail,
              days: state.days,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.days});

  final CategoryReportDetailEntity detail;
  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final category = detail.category;
    final l10n = context.l10n;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: category.iconUrl != null &&
                            category.iconUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: category.iconUrl!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 72,
                            height: 72,
                            color: scheme.primaryContainer,
                            child: Icon(Icons.label, color: scheme.primary),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          category.slug,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard(
                    label: ReportDetailLabels.directPosts(l10n),
                    value: formatCategoryReportCount(
                      detail.counts.directPosts ?? detail.counts.posts,
                    ),
                  ),
                  _MetricCard(
                    label: l10n.t('views'),
                    value: formatCategoryReportCount(detail.postMetrics.views),
                  ),
                  _MetricCard(
                    label: ReportDetailLabels.periodPosts(l10n, days),
                    value: formatCategoryReportCount(detail.periodPostsCreated),
                  ),
                  _MetricCard(
                    label: ReportDetailLabels.subcategories(l10n),
                    value: formatCategoryReportCount(
                      detail.counts.subcategories ?? detail.counts.children,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (detail.subcategoryStats.isNotEmpty) ...[
                _Section(
                  title: ReportDetailLabels.subcategories(l10n),
                  child: Column(
                    children: [
                      for (final sub in detail.subcategoryStats)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(sub.name),
                          trailing: Text(
                            formatCategoryReportCount(sub.postCount),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 560;
                  final posts = _Section(
                    title: ReportDetailLabels.topPosts(l10n),
                    child: _PostsList(posts: detail.topPosts),
                  );
                  final authors = _Section(
                    title: ReportDetailLabels.topAuthors(l10n),
                    child: _AuthorsList(authors: detail.topAuthors),
                  );
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: posts),
                        const SizedBox(width: 16),
                        Expanded(child: authors),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      posts,
                      const SizedBox(height: 16),
                      authors,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _Section(
                title: ReportDetailLabels.recentPosts(l10n),
                child: _PostsList(posts: detail.recentPosts),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PostsList extends StatelessWidget {
  const _PostsList({required this.posts});

  final List<CategoryReportPostSummary> posts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (posts.isEmpty) {
      return Text(ReportDetailLabels.noPosts(l10n));
    }
    return Column(
      children: [
        for (final post in posts)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: post.thumbnailUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: post.thumbnailUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
            title: Text(
              post.description ?? post.id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: post.views != null
                ? Text(
                    ReportDetailLabels.viewsCount(
                      l10n,
                      formatCategoryReportCount(post.views!),
                    ),
                  )
                : null,
          ),
      ],
    );
  }
}

class _AuthorsList extends StatelessWidget {
  const _AuthorsList({required this.authors});

  final List<CategoryReportTopAuthor> authors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (authors.isEmpty) {
      return Text(ReportDetailLabels.noAuthors(l10n));
    }
    return Column(
      children: [
        for (final author in authors)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(author.user.displayName),
            subtitle: Text(
              ReportDetailLabels.postsCount(l10n, author.postCount),
            ),
            trailing: Text(formatCategoryReportCount(author.views)),
          ),
      ],
    );
  }
}
