import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/campaigns_bloc.dart';
import '../bloc/packages_bloc.dart';
import '../bloc/promoted_posts_bloc.dart';
import '../bloc/promotions_overview_bloc.dart';
import '../utils/promotions_responsive.dart';
import 'campaigns_page.dart';
import 'packages_page.dart';
import 'promoted_posts_page.dart';
import 'promotions_overview_page.dart';

enum PromotionsSection { overview, campaigns, promotedPosts, packages }

class PromotionsShellPage extends StatefulWidget {
  const PromotionsShellPage({super.key});

  @override
  State<PromotionsShellPage> createState() => _PromotionsShellPageState();
}

class _PromotionsShellPageState extends State<PromotionsShellPage> {
  PromotionsSection _section = PromotionsSection.overview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              di.sl<PromotionsOverviewBloc>()..add(LoadPromotionsOverviewEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<CampaignsBloc>()..add(LoadCampaignsEvent()),
        ),
        BlocProvider(
          create: (_) =>
              di.sl<PromotedPostsBloc>()..add(const LoadPromotedPostsEvent()),
        ),
        BlocProvider(create: (_) => di.sl<BulkActionsBloc>()),
        BlocProvider(
          create: (_) => di.sl<PackagesBloc>()..add(LoadPackagesEvent()),
        ),
      ],
      child: ColoredBox(
        color: scheme.surfaceContainerLowest,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useTopNav = promotionsUseTopNav(constraints.maxWidth);

            if (useTopNav) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PromotionsTopNav(
                    section: _section,
                    onChanged: (s) => setState(() => _section = s),
                  ),
                  Expanded(
                    child: ClipRect(
                      child: _PromotionsSectionView(section: _section),
                    ),
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PromotionsSideNav(
                  section: _section,
                  onChanged: (s) => setState(() => _section = s),
                ),
                Expanded(
                  child: ClipRect(
                    child: _PromotionsSectionView(section: _section),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PromotionsSectionView extends StatelessWidget {
  const _PromotionsSectionView({required this.section});

  final PromotionsSection section;

  @override
  Widget build(BuildContext context) {
    final page = switch (section) {
      PromotionsSection.overview => const PromotionsOverviewPage(
          key: ValueKey('promotions_section_overview'),
        ),
      PromotionsSection.campaigns => const CampaignsPage(
          key: ValueKey('promotions_section_campaigns'),
        ),
      PromotionsSection.promotedPosts => const PromotedPostsPage(
          key: ValueKey('promotions_section_promoted_posts'),
        ),
      PromotionsSection.packages => const PackagesPage(
          key: ValueKey('promotions_section_packages'),
        ),
    };

    return page;
  }
}

List<(PromotionsSection, IconData, String Function(AppLocalizations))>
    _promotionsNavItems() {
  return [
    (
      PromotionsSection.overview,
      Icons.dashboard_outlined,
      (l10n) => l10n.t('promoNavOverview'),
    ),
    (
      PromotionsSection.campaigns,
      Icons.campaign_outlined,
      (l10n) => l10n.t('promoNavCampaigns'),
    ),
    (
      PromotionsSection.promotedPosts,
      Icons.video_library_outlined,
      (l10n) => l10n.t('promotedPosts'),
    ),
    (
      PromotionsSection.packages,
      Icons.inventory_2_outlined,
      (l10n) => l10n.t('promoNavPackages'),
    ),
  ];
}

class _PromotionsSideNav extends StatelessWidget {
  const _PromotionsSideNav({
    required this.section,
    required this.onChanged,
  });

  final PromotionsSection section;
  final ValueChanged<PromotionsSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final items = _promotionsNavItems();

    return Material(
      elevation: 2,
      shadowColor: scheme.shadow.withValues(alpha: 0.12),
      color: scheme.surfaceContainerLow,
      child: SizedBox(
        width: 240,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.t('promotions'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.t('promoShellSubtitle'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              for (final item in items)
                _NavTile(
                  selected: section == item.$1,
                  icon: item.$2,
                  label: item.$3(l10n),
                  onTap: () => onChanged(item.$1),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromotionsTopNav extends StatelessWidget {
  const _PromotionsTopNav({
    required this.section,
    required this.onChanged,
  });

  final PromotionsSection section;
  final ValueChanged<PromotionsSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final items = _promotionsNavItems();
    final metrics = promotionsMetricsOf(context);

    return Material(
      elevation: 1,
      shadowColor: scheme.shadow.withValues(alpha: 0.08),
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          metrics.pageHorizontalPadding,
          metrics.isMobile ? 8 : 12,
          metrics.pageHorizontalPadding,
          metrics.isMobile ? 8 : 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.t('promotions'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    fontSize: metrics.isMobile ? 17 : null,
                  ),
            ),
            if (!metrics.isMobile) ...[
              const SizedBox(height: 4),
              Text(
                l10n.t('promoShellSubtitle'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
              ),
            ],
            SizedBox(height: metrics.isMobile ? 8 : 10),
            SizedBox(
              height: metrics.isMobile ? 36 : 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    SizedBox(width: metrics.toolbarFilterGap),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = section == item.$1;
                  return _TopNavChip(
                    selected: selected,
                    icon: item.$2,
                    label: item.$3(l10n),
                    compact: metrics.isMobile,
                    onTap: () => onChanged(item.$1),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopNavChip extends StatelessWidget {
  const _TopNavChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surface,
      borderRadius: BorderRadius.circular(compact ? 10 : 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: compact ? 16 : 18,
                color: selected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              SizedBox(width: compact ? 6 : 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 12 : 13,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
