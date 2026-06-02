import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../bloc/auctions_bloc.dart';
import '../widgets/auction_card.dart';

/// Responsive column count for admin catalog grids.
int adminGridColumnCount(double width) {
  if (width > 1600) return 6;
  if (width > 1300) return 5;
  if (width > 1000) return 4;
  if (width > 700) return 3;
  if (width > 500) return 2;
  return 1;
}

class AuctionsPage extends StatefulWidget {
  const AuctionsPage({super.key});

  @override
  State<AuctionsPage> createState() => _AuctionsPageState();
}

class _AuctionsPageState extends State<AuctionsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AuctionsBloc>().add(LoadAllAuctionsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FC),
      body: BlocConsumer<AuctionsBloc, AuctionsState>(
        listener: (context, state) {},
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              _SliverHeader(theme: theme, isDark: isDark, state: state),
              if (state is AuctionsLoaded) ...[
                _SliverStats(loaded: state, theme: theme, isDark: isDark),
                _SliverFilters(loaded: state, theme: theme),
                _SliverGrid(loaded: state),
              ] else if (state is AuctionsLoading) ...[
                const _SliverSkeletons(),
              ] else if (state is AuctionsError) ...[
                _SliverError(message: state.message),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
      ),
    );
  }
}

// ─── Sliver Header ────────────────────────────────────────────────────────────

class _SliverHeader extends StatelessWidget {
  const _SliverHeader({
    required this.theme,
    required this.isDark,
    required this.state,
  });

  final ThemeData theme;
  final bool isDark;
  final AuctionsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor =
        isDark ? Colors.grey.shade500 : const Color(0xFF6B7280);
    final dividerColor =
        isDark ? const Color(0xFF2E3440) : const Color(0xFFE8ECF0);
    final isLoading = state is AuctionsLoading;

    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('auctions'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: titleColor,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Monitor and manage all auction activities',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: subtitleColor,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: isLoading
                            ? null
                            : () => context
                                .read<AuctionsBloc>()
                                .add(LoadAllAuctionsEvent()),
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: isLoading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : const Color(0xFF4B5563),
                                    ),
                                  )
                                : Icon(
                                    Icons.refresh_rounded,
                                    size: 20,
                                    color: isDark
                                        ? Colors.grey.shade300
                                        : const Color(0xFF4B5563),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, thickness: 1, color: dividerColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _SliverStats extends StatelessWidget {
  const _SliverStats({
    required this.loaded,
    required this.theme,
    required this.isDark,
  });

  final AuctionsLoaded loaded;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(
                  label: l10n.t('total'),
                  value: loaded.allAuctions.length.toString(),
                  icon: Icons.gavel_rounded,
                  color: theme.colorScheme.primary,
                  isDark: isDark,
                ),
                _StatChip(
                  label: l10n.t('active'),
                  value: loaded.activeCount.toString(),
                  icon: Icons.play_circle_rounded,
                  color: const Color(0xFF16A34A),
                  isDark: isDark,
                ),
                _StatChip(
                  label: l10n.t('completed'),
                  value: loaded.completedCount.toString(),
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF2563EB),
                  isDark: isDark,
                ),
                _StatChip(
                  label: l10n.t('cancelled'),
                  value: loaded.cancelledCount.toString(),
                  icon: Icons.cancel_rounded,
                  color: const Color(0xFFDC2626),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final outlineBorder =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Chips ─────────────────────────────────────────────────────────────

class _SliverFilters extends StatelessWidget {
  const _SliverFilters({required this.loaded, required this.theme});

  final AuctionsLoaded loaded;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final filters = [
      (null, l10n.t('all')),
      ('ACTIVE', l10n.t('active')),
      ('COMPLETED', l10n.t('completed')),
      ('CANCELLED', l10n.t('cancelled')),
    ];

    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final (status, label) = filters[index];
                  final selected = loaded.filter == status;
                  return FilterChip(
                    label: Text(label, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    onSelected: (v) {
                      context.read<AuctionsBloc>().add(
                            FilterAuctionsEvent(v ? status : null),
                          );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: isDark
                        ? const Color(0xFF1A1F2E)
                        : Colors.white,
                    side: BorderSide(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Grid ─────────────────────────────────────────────────────────────────────

class _SliverGrid extends StatelessWidget {
  const _SliverGrid({required this.loaded});
  final AuctionsLoaded loaded;

  @override
  Widget build(BuildContext context) {
    final auctions = loaded.displayed;

    if (auctions.isEmpty) {
      return const _SliverEmptyState(
        icon: Icons.gavel_rounded,
        titleKey: 'noAuctionsFound',
        subtitleKey: 'tryDifferentFilter',
      );
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = adminGridColumnCount(constraints.crossAxisExtent);
        final rowCount = (auctions.length / columns).ceil();
        const gap = 12.0;

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, rowIndex) {
                final start = rowIndex * columns;
                final end = (start + columns).clamp(0, auctions.length);
                final rowAuctions = auctions.sublist(start, end);

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: rowIndex < rowCount - 1 ? gap : 0,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < columns; i++) ...[
                          if (i > 0) SizedBox(width: gap),
                          Expanded(
                            child: i < rowAuctions.length
                                ? AuctionCard(
                                    auction: rowAuctions[i],
                                    onViewDetails: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.auctionDetail,
                                        arguments: rowAuctions[i],
                                      );
                                    },
                                    onCancel: rowAuctions[i].isActive
                                        ? () {
                                            _confirmCancel(
                                              context,
                                              rowAuctions[i].id,
                                              rowAuctions[i].itemName,
                                            );
                                          }
                                        : null,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              childCount: rowCount,
            ),
          ),
        );
      },
    );
  }

  void _confirmCancel(BuildContext context, String id, String? name) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.t('forceCancelAuctionTitle')),
        content: Text(
          'Cancel "${name ?? 'this auction'}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('keep')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<AuctionsBloc>()
                  .add(AdminCancelAuctionFromListEvent(id));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.t('cancelAuction')),
          ),
        ],
      ),
    );
  }
}

// ─── Skeletons ────────────────────────────────────────────────────────────────

class _SliverSkeletons extends StatelessWidget {
  const _SliverSkeletons();

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = adminGridColumnCount(constraints.crossAxisExtent);
        const gap = 12.0;
        const rows = 2;

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, rowIndex) {
                return Padding(
                  padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? gap : 0),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < columns; i++) ...[
                          if (i > 0) const SizedBox(width: gap),
                          const Expanded(child: AuctionCardSkeleton()),
                        ],
                      ],
                    ),
                  ),
                );
              },
              childCount: rows,
            ),
          ),
        );
      },
    );
  }
}

// ─── Empty / Error ────────────────────────────────────────────────────────────

class _SliverEmptyState extends StatelessWidget {
  const _SliverEmptyState({
    required this.icon,
    required this.titleKey,
    this.subtitleKey,
  });

  final IconData icon;
  final String titleKey;
  final String? subtitleKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: isDark ? Colors.grey.shade600 : const Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.t(titleKey),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                ),
              ),
              if (subtitleKey != null) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.t(subtitleKey!),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey.shade600 : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverError extends StatelessWidget {
  const _SliverError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.t('failedToLoadAuction'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () =>
                    context.read<AuctionsBloc>().add(LoadAllAuctionsEvent()),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(l10n.t('retry')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
