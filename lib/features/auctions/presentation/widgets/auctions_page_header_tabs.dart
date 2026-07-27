import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../utils/auctions_page_tab.dart';

/// Segmented Auctions / Seller verification control — responsive labels.
class AuctionsPageHeaderTabs extends StatelessWidget {
  const AuctionsPageHeaderTabs({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.compact,
    this.fullWidth = false,
  });

  final AuctionsPageTab activeTab;
  final ValueChanged<AuctionsPageTab> onTabChanged;
  final bool compact;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final tabs = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final iconOnly = w < 220;
            final shortLabels = w < 340;

            return Row(
              children: [
                Expanded(
                  child: _TabSegment(
                    selected: activeTab == AuctionsPageTab.auctions,
                    icon: Icons.gavel_outlined,
                    selectedIcon: Icons.gavel_rounded,
                    label: l10n.t('auctions'),
                    shortLabel: l10n.t('auctions'),
                    iconOnly: iconOnly,
                    useShortLabel: shortLabels,
                    compact: compact,
                    onTap: () => onTabChanged(AuctionsPageTab.auctions),
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: _TabSegment(
                    selected: activeTab == AuctionsPageTab.sellerVerification,
                    icon: Icons.verified_user_outlined,
                    selectedIcon: Icons.verified_user_rounded,
                    label: l10n.tOr(
                      'sellerVerificationTab',
                      'Seller verification',
                    ),
                    shortLabel: l10n.tOr('sellerVerificationShort', 'Sellers'),
                    iconOnly: iconOnly,
                    useShortLabel: shortLabels,
                    compact: compact,
                    onTap: () =>
                        onTabChanged(AuctionsPageTab.sellerVerification),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    if (fullWidth) return tabs;

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: compact ? 320 : 380,
          minWidth: compact ? 180 : 220,
        ),
        child: tabs,
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  const _TabSegment({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.shortLabel,
    required this.iconOnly,
    required this.useShortLabel,
    required this.compact,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String shortLabel;
  final bool iconOnly;
  final bool useShortLabel;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    final displayLabel = useShortLabel ? shortLabel : label;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: compact ? 34 : 38,
            padding: EdgeInsets.symmetric(
              horizontal: iconOnly ? 6 : (compact ? 8 : 10),
            ),
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: compact ? 15 : 17,
                  color: fg,
                ),
                if (!iconOnly) ...[
                  SizedBox(width: compact ? 5 : 6),
                  Flexible(
                    child: Text(
                      displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w600,
                            fontSize: compact ? 11.5 : 12.5,
                            height: 1.1,
                            color: fg,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
