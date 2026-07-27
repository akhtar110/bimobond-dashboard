import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/gifts_bloc.dart';
import '../utils/gifts_page_layout.dart';
import '../utils/gifts_responsive.dart';
import 'gift_card.dart';

class GiftsSliverSkeletons extends StatelessWidget {
  const GiftsSliverSkeletons();

  @override
  Widget build(BuildContext context) {
    final crossAxisExtent = GiftsViewportWidth.of(context);
    final columns = giftsGridColumnCount(crossAxisExtent);
    final metrics = GiftsLayoutMetrics(getGiftsDeviceType(crossAxisExtent));
    final gap = metrics.gridGap;
    const rows = 2;
    final pad = metrics.pageHorizontalPadding;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(pad, metrics.gridTopPadding, pad, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, rowIndex) => Padding(
            padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? gap : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < columns; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  const Expanded(child: GiftCardSkeleton()),
                ],
              ],
            ),
          ),
          childCount: rows,
        ),
      ),
    );
  }
}

class GiftsSliverEmptyState extends StatelessWidget {
  const GiftsSliverEmptyState({required this.icon, required this.messageKey});
  final IconData icon;
  final String messageKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: scheme.onSurfaceVariant),
              const SizedBox(height: 14),
              Text(
                l10n.t(messageKey),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GiftsSliverError extends StatelessWidget {
  const GiftsSliverError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: scheme.error),
              const SizedBox(height: 14),
              Text(
                l10n.t('failedToLoadGifts'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    context.read<GiftsBloc>().add(LoadAdminGiftsEvent()),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(l10n.t('retry')),
                style: FilledButton.styleFrom(
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
