import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/promoted_post_entities.dart';
import '../../domain/enums/promotion_enums.dart';
import '../bloc/promotion_analytics_bloc.dart';
import '../widgets/campaign_detail_sheet.dart';
import '../widgets/promoted_post_widgets.dart';
import '../widgets/promotions_dashboard_widgets.dart';

class PromotedPostAnalyticsPage extends StatelessWidget {
  const PromotedPostAnalyticsPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return PersistentBlocProvider<PromotionAnalyticsBloc>(
      debugLabel: 'PromotedPostAnalyticsPage',
      create: () => di.sl<PromotionAnalyticsBloc>()
        ..add(LoadPromotionAnalyticsEvent(postId: postId)),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(context.l10n.t('promoPostAnalytics')),
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerLowest,
          scrolledUnderElevation: 0,
        ),
        body: PromotedPostAnalyticsBody(
          postId: postId,
          onOpenCampaign: (id) => showCampaignDetailSheet(context, id),
        ),
      ),
    );
  }
}

class PromotedPostAnalyticsBody extends StatelessWidget {
  const PromotedPostAnalyticsBody({
    super.key,
    required this.postId,
    this.embedded = false,
    this.onOpenCampaign,
  });

  final String postId;
  final bool embedded;
  final ValueChanged<String>? onOpenCampaign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<PromotionAnalyticsBloc, PromotionAnalyticsState>(
      listenWhen: (p, c) =>
          c is PromotionAnalyticsLoaded &&
          c.message != null &&
          (p is! PromotionAnalyticsLoaded || p.message != c.message),
      listener: (context, state) {
        if (state is! PromotionAnalyticsLoaded || state.message == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message!),
            backgroundColor: state.isError ? scheme.error : null,
          ),
        );
      },
      builder: (context, state) {
        final content = switch (state) {
          PromotionAnalyticsLoading() =>
            const Center(child: LoadingView()),
          PromotionAnalyticsError(:final message) => Center(
              child: ErrorView(
                message: message,
                retryLabel: l10n.t('retry'),
                onRetry: () => context.read<PromotionAnalyticsBloc>().add(
                      LoadPromotionAnalyticsEvent(
                        postId: postId,
                        refresh: true,
                      ),
                    ),
              ),
            ),
          PromotionAnalyticsEmpty() => Center(
              child: EmptyView(message: l10n.t('promoNoPromotedPosts')),
            ),
          PromotionAnalyticsLoaded(:final stats, :final isActioning) => Stack(
              children: [
                _AnalyticsContent(
                  stats: stats,
                  isActioning: isActioning,
                  embedded: embedded,
                  onOpenCampaign: onOpenCampaign,
                ),
                if (isActioning)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          _ => const SizedBox.shrink(),
        };

        return content;
      },
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({
    required this.stats,
    required this.isActioning,
    required this.embedded,
    this.onOpenCampaign,
  });

  final PostPromotionStatsEntity stats;
  final bool isActioning;
  final bool embedded;
  final ValueChanged<String>? onOpenCampaign;

  @override
  Widget build(BuildContext context) {
    final primary = stats.primaryCampaign;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= PromotionsBreakpoints.smallDesktop;
            if (wide && primary != null) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: PromotedPostPreviewCard(post: stats.post),
                  ),
                  const SizedBox(width: PromotionsSpace.md),
                  Expanded(
                    flex: 2,
                    child: PrimaryCampaignCard(campaign: primary),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PromotedPostPreviewCard(post: stats.post),
                if (primary != null) ...[
                  const SizedBox(height: PromotionsSpace.md),
                  PrimaryCampaignCard(campaign: primary),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: PromotionsSpace.lg),
        PromotionKpiGrid(stats: stats, compact: true),
        const SizedBox(height: PromotionsSpace.lg),
        PromotionImpressionChart(
          buckets: stats.charts.impressionsLast7Days,
        ),
        const SizedBox(height: PromotionsSpace.lg),
        CampaignHistoryTable(
          campaigns: stats.campaigns,
          isActioning: isActioning,
          onOpenCampaign: onOpenCampaign ??
              (id) => showCampaignDetailSheet(context, id),
          onPause: (id) => context.read<PromotionAnalyticsBloc>().add(
                UpdateCampaignStatusFromAnalyticsEvent(
                  id,
                  CampaignStatus.paused.apiValue,
                ),
              ),
          onActivate: (id) => context.read<PromotionAnalyticsBloc>().add(
                UpdateCampaignStatusFromAnalyticsEvent(
                  id,
                  CampaignStatus.active.apiValue,
                ),
              ),
          onReject: (id) => context.read<PromotionAnalyticsBloc>().add(
                UpdateCampaignStatusFromAnalyticsEvent(
                  id,
                  CampaignStatus.rejected.apiValue,
                ),
              ),
        ),
        if (embedded) const SizedBox(height: PromotionsSpace.xl),
      ],
    );

    if (embedded) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [body],
      );
    }

    return PromotionsDashboardShell(child: body);
  }
}
