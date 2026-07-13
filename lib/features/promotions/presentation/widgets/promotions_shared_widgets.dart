import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/enums/promotion_enums.dart';
import 'promotions_dashboard_widgets.dart';

class CampaignStatusBadge extends StatelessWidget {
  const CampaignStatusBadge({super.key, required this.status});

  final String status;

  Color _color(ColorScheme scheme) {
    switch (CampaignStatus.tryParse(status)) {
      case CampaignStatus.active:
        return scheme.primary;
      case CampaignStatus.pendingPayment:
        return const Color(0xFFED6C02); // amber/orange — readable border + text
      case CampaignStatus.paused:
        return scheme.tertiary;
      case CampaignStatus.rejected:
      case CampaignStatus.cancelled:
        return scheme.error;
      case CampaignStatus.completed:
        return const Color(0xFF2E7D32); // green — avoid weak scheme.outline
      default:
        return scheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final color = _color(scheme);
    final label = switch (CampaignStatus.tryParse(status)) {
      CampaignStatus.pendingPayment => l10n.t('promoStatusPendingPayment'),
      CampaignStatus.active => l10n.t('promoStatusActive'),
      CampaignStatus.paused => l10n.t('promoStatusPaused'),
      CampaignStatus.completed => l10n.t('promoStatusCompleted'),
      CampaignStatus.cancelled => l10n.t('promoStatusCancelled'),
      CampaignStatus.rejected => l10n.t('promoStatusRejected'),
      _ => status,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.25),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class PromotionsSearchField extends StatefulWidget {
  const PromotionsSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.initialValue = '',
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final String initialValue;

  @override
  State<PromotionsSearchField> createState() => _PromotionsSearchFieldState();
}

class _PromotionsSearchFieldState extends State<PromotionsSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(PromotionsSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return TextField(
      controller: _controller,
      onChanged: (value) {
        setState(() {});
        widget.onChanged(value);
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Icon(Icons.search_rounded, color: scheme.primary),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                tooltip: l10n.t('clearSelection'),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
                icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
              )
            : null,
        filled: true,
        fillColor: scheme.surface,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

class PromotionsFilterDropdown extends StatelessWidget {
  const PromotionsFilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String?> items;
  final String Function(String?) itemLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final safeValue = items.contains(value) ? value : null;
    final isActive = safeValue != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? scheme.primary.withValues(alpha: 0.45)
                  : scheme.outlineVariant,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: safeValue,
              isExpanded: true,
              hint: Text(
                context.l10n.t('all'),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              icon: Icon(Icons.expand_more_rounded, color: scheme.onSurfaceVariant),
              items: items
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(
                        itemLabel(v),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class PromotionsFilterToolbar extends StatelessWidget {
  const PromotionsFilterToolbar({
    super.key,
    required this.search,
    required this.filters,
    this.stackBelowWidth = 900,
    this.hasActiveFilters = false,
    this.onClearFilters,
    this.showHeader = true,
  });

  final Widget search;
  final List<Widget> filters;
  final double stackBelowWidth;
  final bool hasActiveFilters;
  final VoidCallback? onClearFilters;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final stack = width < stackBelowWidth;

        return DashboardCard(
          padding: const EdgeInsets.all(PromotionsSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHeader) ...[
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: PromotionsSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('filters'),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (hasActiveFilters)
                            Text(
                              l10n.t('promoFiltersActive'),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    if (hasActiveFilters && onClearFilters != null)
                      TextButton.icon(
                        onPressed: onClearFilters,
                        icon: const Icon(Icons.filter_alt_off_outlined,
                            size: 18),
                        label: Text(l10n.t('clearFilters')),
                      ),
                  ],
                ),
                const SizedBox(height: PromotionsSpace.lg),
              ] else if (hasActiveFilters && onClearFilters != null) ...[
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: onClearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: Text(l10n.t('clearFilters')),
                  ),
                ),
                const SizedBox(height: PromotionsSpace.sm),
              ],
              if (stack)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    search,
                    if (filters.isNotEmpty) ...[
                      const SizedBox(height: PromotionsSpace.md),
                      for (var i = 0; i < filters.length; i++) ...[
                        if (i > 0) const SizedBox(height: PromotionsSpace.md),
                        filters[i],
                      ],
                    ],
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    search,
                    if (filters.isNotEmpty) ...[
                      const SizedBox(height: PromotionsSpace.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < filters.length; i++) ...[
                            if (i > 0) const SizedBox(width: PromotionsSpace.md),
                            Expanded(child: filters[i]),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class BulkActionToolbar extends StatelessWidget {
  const BulkActionToolbar({
    super.key,
    required this.selectedCount,
    required this.actions,
    this.allVisibleSelected = false,
    this.someVisibleSelected = false,
    this.onSelectAll,
    this.onClear,
  });

  final int selectedCount;
  final List<Widget> actions;
  final bool allVisibleSelected;
  final bool someVisibleSelected;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    if (selectedCount <= 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return DashboardCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Checkbox(
            tristate: true,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            value: allVisibleSelected
                ? true
                : someVisibleSelected
                    ? null
                    : false,
            onChanged: onSelectAll == null ? null : (_) => onSelectAll!(),
          ),
          Text(
            context.tr('promoSelectedCount', {'count': '$selectedCount'}),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
          ),
          if (onSelectAll != null)
            TextButton.icon(
              onPressed: onSelectAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.select_all_rounded, size: 17),
              label: Text(
                l10n.t('selectAllVisible'),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          if (onClear != null)
            TextButton.icon(
              onPressed: onClear,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.clear_all_rounded, size: 17),
              label: Text(
                l10n.t('clearSelection'),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ...actions,
        ],
      ),
    );
  }
}
