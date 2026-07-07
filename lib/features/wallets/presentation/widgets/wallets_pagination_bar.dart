import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../utils/wallet_labels.dart';
import '../utils/wallets_responsive.dart';

class WalletsPaginationBar extends StatelessWidget {
  const WalletsPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.onPage,
    this.showTopBorder = false,
  });

  final int page;
  final int totalPages;
  final int total;
  final ValueChanged<int> onPage;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    if (!walletsMetricsOf(context).useDesktopPagination) {
      return const SizedBox.shrink();
    }

    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final scheme = Theme.of(context).colorScheme;
    final metrics = walletsMetricsOf(context);
    final compact = metrics.isMobile;
    final summary = compact
        ? walletL10nArgs(context,
            'walletPaginationCompact',
            {'page': '$page', 'totalPages': '$totalPages'},
            'Page $page / $totalPages',
          )
        : walletL10nArgs(context,
            'walletPaginationFull',
            {
              'total': '$total',
              'page': '$page',
              'totalPages': '$totalPages',
            },
            '$total total · Page $page of $totalPages',
          );

    final visiblePages = <int>{
      for (var i = page - 2; i <= page + 2; i++)
        if (i >= 1 && i <= totalPages) i,
    };

    Widget navIcon({
      required IconData icon,
      required bool enabled,
      required VoidCallback onTap,
    }) {
      return Material(
        color: scheme.surface.withValues(alpha: 0),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: enabled
                    ? scheme.outlineVariant
                    : scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: enabled
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
      );
    }

    Widget pageButton(int p) {
      final isActive = p == page;
      return Material(
        color: scheme.surface.withValues(alpha: 0),
        child: InkWell(
          onTap: () => onPage(p),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isActive ? scheme.primary : scheme.surface,
              border: Border.all(
                color: isActive ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: Text(
              '$p',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isActive ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      );
    }

    final pageControls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        navIcon(
          icon: Icons.chevron_left_rounded,
          enabled: page > 1,
          onTap: () => onPage(page - 1),
        ),
        const SizedBox(width: 4),
        for (final p in visiblePages) ...[
          pageButton(p),
          const SizedBox(width: 4),
        ],
        navIcon(
          icon: Icons.chevron_right_rounded,
          enabled: page < totalPages,
          onTap: () => onPage(page + 1),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? metrics.pageHorizontalPadding : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: showTopBorder
          ? BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            )
          : null,
      child: compact
          ? Column(
              children: [
                Text(
                  summary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                ),
                SizedBox(height: metrics.toolbarFilterGap),
                pageControls,
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
                pageControls,
              ],
            ),
    );
  }
}
