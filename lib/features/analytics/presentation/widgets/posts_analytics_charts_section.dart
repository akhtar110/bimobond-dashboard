import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';



import '../../../../core/localization/localization.dart';

import '../../domain/entities/analytics_entities.dart';

import '../../domain/entities/post_status_count_entity.dart';

import '../../domain/entities/post_type_count_entity.dart';

import '../bloc/analytics_bloc.dart';

import '../utils/analytics_format.dart';
import '../utils/analytics_l10n.dart';

import 'analytics_charts.dart';

import 'analytics_kpi_card.dart';



class PostsAnalyticsChartsSection extends StatelessWidget {

  const PostsAnalyticsChartsSection({

    super.key,

    required this.state,

  });



  final AnalyticsLoaded state;



  @override

  Widget build(BuildContext context) {

    final posts = state.posts;

    final bloc = context.read<AnalyticsBloc>();

    final l10n = context.l10n;

    final scheme = Theme.of(context).colorScheme;

    final palette = AnalyticsChartColors.seriesPalette(scheme);



    return AnalyticsSectionCard(

      title: l10n.t('analyticsPostsSection'),

      error: state.errorFor('posts'),

      onRetry: () => bloc.add(const LoadPostsAnalyticsEvent()),

      child: posts == null

          ? const Center(child: CircularProgressIndicator())

          : Column(

              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                Text(

                  l10n.t('analyticsPlatformBreakdownAllTime'),

                  style: Theme.of(context).textTheme.labelLarge?.copyWith(

                        fontWeight: FontWeight.w700,

                      ),

                ),

                const SizedBox(height: 12),

                _TypeDonut(

                  title: l10n.t('analyticsPostTypes'),

                  items: posts.byType,

                  palette: palette,

                  total: posts.typeTotal,

                ),

                const SizedBox(height: 16),

                _StatusBars(

                  title: l10n.t('analyticsPostStatus'),

                  items: posts.byStatus,

                  scheme: scheme,

                  total: posts.statusTotal,

                ),

                const SizedBox(height: 20),

                Text(

                  l10n.t('analyticsCreatedInPeriod'),

                  style: Theme.of(context).textTheme.labelLarge?.copyWith(

                        fontWeight: FontWeight.w700,

                      ),

                ),

                const SizedBox(height: 12),

                _TypeDonut(

                  title: l10n.t('analyticsTypesInPeriod'),

                  items: posts.byTypeInPeriod,

                  palette: palette,

                  total: posts.typeInPeriodTotal,

                ),

                const SizedBox(height: 16),

                _StatusBars(

                  title: l10n.t('analyticsStatusInPeriod'),

                  items: posts.byStatusInPeriod,

                  scheme: scheme,

                  total: posts.statusInPeriodTotal,

                ),

              ],

            ),

    );

  }

}



class _TypeDonut extends StatelessWidget {

  const _TypeDonut({

    required this.title,

    required this.items,

    required this.palette,

    required this.total,

  });



  final String title;

  final List<PostTypeCountEntity> items;

  final List<Color> palette;

  final int total;



  @override

  Widget build(BuildContext context) {

    if (total == 0) {

      return _EmptyChartMessage(title: title);

    }



    return Column(

      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [

        Text(

          title,

          style: Theme.of(context).textTheme.labelMedium?.copyWith(

                fontWeight: FontWeight.w600,

              ),

        ),

        const SizedBox(height: 8),

        AnalyticsPieChart(

          donut: true,

          size: 160,

          entries: [

            for (var i = 0; i < items.length; i++)

              AnalyticsPieEntry(

                label: AnalyticsL10n.postType(context, items[i].type),

                value: items[i].count.toDouble(),

                color: palette[i % palette.length],

              ),

          ],

        ),

      ],

    );

  }

}



class _StatusBars extends StatelessWidget {

  const _StatusBars({

    required this.title,

    required this.items,

    required this.scheme,

    required this.total,

  });



  final String title;

  final List<PostStatusCountEntity> items;

  final ColorScheme scheme;

  final int total;



  @override

  Widget build(BuildContext context) {

    if (total == 0) {

      return _EmptyChartMessage(title: title);

    }



    return Column(

      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [

        Text(

          title,

          style: Theme.of(context).textTheme.labelMedium?.copyWith(

                fontWeight: FontWeight.w600,

              ),

        ),

        const SizedBox(height: 8),

        AnalyticsBarChart(

          height: 180,

          horizontal: true,

          entries: [

            for (var i = 0; i < items.length; i++)

              AnalyticsBarEntry(

                label: AnalyticsL10n.postStatus(context, items[i].status),

                value: items[i].count.toDouble(),

                color: scheme.primary.withValues(

                  alpha: 1 - (i * 0.15).clamp(0, 0.5),

                ),

              ),

          ],

        ),

      ],

    );

  }

}



class _EmptyChartMessage extends StatelessWidget {

  const _EmptyChartMessage({required this.title});



  final String title;



  @override

  Widget build(BuildContext context) {

    final l10n = context.l10n;

    return Column(

      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [

        Text(

          title,

          style: Theme.of(context).textTheme.labelMedium?.copyWith(

                fontWeight: FontWeight.w600,

              ),

        ),

        const SizedBox(height: 8),

        Padding(

          padding: const EdgeInsets.symmetric(vertical: 24),

          child: Text(

            l10n.t('analyticsNoActivityInPeriod'),

            textAlign: TextAlign.center,

            style: Theme.of(context).textTheme.bodySmall?.copyWith(

                  color: Theme.of(context).colorScheme.onSurfaceVariant,

                ),

          ),

        ),

      ],

    );

  }

}

