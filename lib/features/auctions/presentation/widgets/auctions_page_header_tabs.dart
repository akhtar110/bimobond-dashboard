import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../utils/auctions_page_tab.dart';

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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final iconOnly = !fullWidth && constraints.maxWidth < 280;

            return Row(
              children: [
                Expanded(
                  child: _TabSegment(
                    selected: activeTab == AuctionsPageTab.auctions,
                    icon: Icons.gavel_outlined,
                    selectedIcon: Icons.gavel_rounded,
                    label: l10n.t('auctions'),
                    iconOnly: iconOnly,
                    compact: compact,
                    onTap: () => onTabChanged(AuctionsPageTab.auctions),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _TabSegment(
                    selected: activeTab == AuctionsPageTab.sellerVerification,
                    icon: Icons.verified_user_outlined,
                    selectedIcon: Icons.verified_user_rounded,
                    label: l10n.tOr(
                      'sellerVerificationTab',
                      'Seller verification',
                    ),
                    iconOnly: iconOnly,
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
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, minWidth: 240),
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
    required this.iconOnly,
    required this.compact,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool iconOnly;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: iconOnly ? 8 : (compact ? 10 : 14),
              vertical: compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: compact ? 16 : 18,
                  color: fg,
                ),
                if (!iconOnly) ...[
                  SizedBox(width: compact ? 6 : 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w600,
                            fontSize: compact ? 12 : 13,
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
