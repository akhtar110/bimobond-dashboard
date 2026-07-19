import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../../../core/utils/coins_converter.dart';
import '../../../../core/widgets/dashboard/empty_state_card.dart';
import '../../../../core/widgets/toolbar_filter_style.dart';
import '../../../wallets/presentation/utils/wallet_labels.dart';
import '../../../wallets/presentation/utils/wallets_responsive.dart';
import '../../../wallets/presentation/widgets/wallets_page_widgets.dart';
import '../../../wallets/presentation/widgets/wallets_pagination_bar.dart';
import '../../domain/entities/platform_profit_entities.dart';
import '../bloc/platform_profit_bloc.dart';

// ---------------------------------------------------------------------------
// Design tokens (visual-only; scaled down from desktop for smaller devices)
// ---------------------------------------------------------------------------

class ProfitDesign {
  const ProfitDesign(this.metrics);

  final WalletsLayoutMetrics metrics;

  double get sectionGap => switch (metrics.deviceType) {
        WalletsDeviceType.mobileSmall => 18,
        WalletsDeviceType.mobileLarge => 20,
        WalletsDeviceType.tablet => 26,
        WalletsDeviceType.desktop => 32,
      };

  double get cardPadding => switch (metrics.deviceType) {
        WalletsDeviceType.mobileSmall => 14,
        WalletsDeviceType.mobileLarge => 16,
        WalletsDeviceType.tablet => 20,
        WalletsDeviceType.desktop => 24,
      };

  double get cardRadius => switch (metrics.deviceType) {
        WalletsDeviceType.mobileSmall => 14,
        WalletsDeviceType.mobileLarge => 16,
        WalletsDeviceType.tablet => 18,
        WalletsDeviceType.desktop => 20,
      };

  double get kpiRadius => cardRadius - 4;

  bool get isMobile => metrics.isMobile;
}

ProfitDesign profitDesignOf(BuildContext context) =>
    ProfitDesign(walletsMetricsOf(context));

List<BoxShadow> _softShadow(ColorScheme scheme, {bool hovered = false}) {
  return [
    BoxShadow(
      color: scheme.shadow.withValues(alpha: hovered ? 0.10 : 0.05),
      blurRadius: hovered ? 18 : 10,
      offset: Offset(0, hovered ? 6 : 3),
    ),
  ];
}

String _percentLabel(double fraction) {
  final pct = fraction * 100;
  if (!pct.isFinite) return '0%';
  return pct >= 10 || pct == 0
      ? '${pct.round()}%'
      : '${pct.toStringAsFixed(1)}%';
}

String? _fiatSubtitle(BuildContext context, num coins, double? rate) {
  return CoinsConverter.approxFiatLabel(coins, rate);
}

// ---------------------------------------------------------------------------
// Reusable visual indicators
// ---------------------------------------------------------------------------

enum TrendDirection { up, down, flat }

class TrendChip extends StatelessWidget {
  const TrendChip({
    super.key,
    required this.label,
    this.direction = TrendDirection.flat,
  });

  final String label;
  final TrendDirection direction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg, icon) = switch (direction) {
      TrendDirection.up => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
          Icons.trending_up_rounded,
        ),
      TrendDirection.down => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          Icons.trending_down_rounded,
        ),
      TrendDirection.flat => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
          Icons.trending_flat_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                ),
          ),
        ],
      ),
    );
  }
}

class RevenueBadge extends StatelessWidget {
  const RevenueBadge({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

class RevenueProgressBar extends StatelessWidget {
  const RevenueProgressBar({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.fraction,
    required this.color,
  });

  final String label;
  final String valueLabel;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final f = fraction.isFinite ? fraction.clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              valueLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(width: 6),
            Text(
              _percentLabel(f),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10.5,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: f),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 6,
              color: color,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ),
      ],
    );
  }
}

class MetricCircle extends StatelessWidget {
  const MetricCircle({
    super.key,
    required this.label,
    required this.centerValue,
    required this.fraction,
    required this.color,
    this.size = 86,
  });

  final String label;
  final String centerValue;
  final double fraction;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final f = fraction.isFinite ? fraction.clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: f),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => CircularProgressIndicator(
                  value: v,
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  color: color,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              Center(
                child: Text(
                  centerValue,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// KPI card + responsive grid (desktop 4 / tablet 2 / mobile 1 columns)
// ---------------------------------------------------------------------------

class ProfitKpiCard extends StatefulWidget {
  const ProfitKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
    this.chip,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Widget? chip;
  final bool highlight;

  @override
  State<ProfitKpiCard> createState() => _ProfitKpiCardState();
}

class _ProfitKpiCardState extends State<ProfitKpiCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final design = profitDesignOf(context);

    final accent = widget.highlight ? scheme.primary : scheme.onSurfaceVariant;
    final iconBg = widget.highlight
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest.withValues(alpha: 0.8);
    final iconFg =
        widget.highlight ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        constraints: const BoxConstraints(minHeight: 112),
        padding: EdgeInsets.all(design.isMobile ? 14 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(design.kpiRadius),
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: widget.highlight
                ? [
                    scheme.primaryContainer.withValues(alpha: 0.55),
                    scheme.surfaceContainerLow,
                  ]
                : [
                    scheme.surfaceContainerLow,
                    scheme.surfaceContainerLow.withValues(alpha: 0.6),
                  ],
          ),
          border: Border.all(
            color: _hovered
                ? scheme.primary.withValues(alpha: 0.45)
                : scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: _softShadow(scheme, hovered: _hovered),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, size: 18, color: iconFg),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.1,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                widget.value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: design.isMobile ? 17 : 20,
                      height: 1.1,
                    ),
              ),
            ),
            if (widget.subtitle != null || widget.chip != null) ...[
              const SizedBox(height: 7),
              Row(
                children: [
                  if (widget.subtitle != null)
                    Flexible(
                      child: Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 10.5,
                            ),
                      ),
                    ),
                  if (widget.subtitle != null && widget.chip != null)
                    const SizedBox(width: 8),
                  if (widget.chip != null) widget.chip!,
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ProfitKpiGrid extends StatelessWidget {
  const ProfitKpiGrid({super.key, required this.cards, this.maxColumns = 4});

  final List<Widget> cards;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        var columns = w >= 1100
            ? 4
            : w >= 640
                ? 2
                : 1;
        if (columns > maxColumns) columns = maxColumns;
        const gap = 12.0;
        final tileWidth = (w - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(width: tileWidth, child: card),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Section container: collapsible analytics panel with state memory
// ---------------------------------------------------------------------------

class ProfitPanel extends StatefulWidget {
  const ProfitPanel({
    super.key,
    required this.panelId,
    required this.title,
    required this.icon,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  final String panelId;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final Widget child;

  /// Session memory so panels keep their expanded state across rebuilds
  /// and section switches.
  static final Map<String, bool> _memory = {};

  @override
  State<ProfitPanel> createState() => _ProfitPanelState();
}

class _ProfitPanelState extends State<ProfitPanel> {
  bool? _expanded;

  bool _resolveExpanded(BuildContext context) {
    final remembered = ProfitPanel._memory[widget.panelId];
    if (remembered != null) return remembered;
    // Collapsed by default on mobile to keep the page scannable.
    return !walletsMetricsOf(context).isMobile;
  }

  void _toggle() {
    final next = !(_expanded ?? _resolveExpanded(context));
    ProfitPanel._memory[widget.panelId] = next;
    setState(() => _expanded = next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final design = profitDesignOf(context);
    final expanded = _expanded ?? _resolveExpanded(context);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(design.cardRadius),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: _softShadow(scheme),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                design.cardPadding,
                design.isMobile ? 14 : 18,
                design.cardPadding,
                design.isMobile ? 14 : 18,
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 19,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: design.isMobile ? 14 : 15.5,
                                  ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: design.isMobile ? 11 : 12,
                                  height: 1.3,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 8),
                    widget.trailing!,
                  ],
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: EdgeInsets.fromLTRB(
                      design.cardPadding,
                      0,
                      design.cardPadding,
                      design.cardPadding,
                    ),
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filters bar (floating card, fixed height — used as a sticky header)
// ---------------------------------------------------------------------------

class PlatformProfitFiltersBar extends StatelessWidget {
  const PlatformProfitFiltersBar({
    super.key,
    required this.preset,
    required this.query,
    this.refreshing = false,
  });

  final PlatformProfitRangePreset preset;
  final PlatformProfitQuery query;
  final bool refreshing;

  String _presetLabel(BuildContext context, PlatformProfitRangePreset p) {
    if (p == PlatformProfitRangePreset.custom &&
        preset == PlatformProfitRangePreset.custom &&
        query.from != null) {
      final fmt = DateFormat.MMMd();
      final from = fmt.format(query.from!.toLocal());
      final to = fmt.format((query.to ?? DateTime.now()).toLocal());
      return '$from – $to';
    }
    return switch (p) {
      PlatformProfitRangePreset.today =>
        walletL10nOr(context, 'walletProfitRangeToday', 'Today'),
      PlatformProfitRangePreset.last7Days =>
        walletL10nOr(context, 'walletProfitRange7d', 'Last 7 Days'),
      PlatformProfitRangePreset.last30Days =>
        walletL10nOr(context, 'walletProfitRange30d', 'Last 30 Days'),
      PlatformProfitRangePreset.last90Days =>
        walletL10nOr(context, 'walletProfitRange90d', 'Last 90 Days'),
      PlatformProfitRangePreset.custom =>
        walletL10nOr(context, 'walletProfitRangeCustom', 'Custom Range'),
    };
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final bloc = context.read<PlatformProfitBloc>();
    final now = DateTime.now();
    final result = await showDialog<(DateTime?, DateTime?)>(
      context: context,
      builder: (ctx) => _ProfitDateRangeDialog(
        initialFrom: query.from?.toLocal(),
        initialTo: query.to?.toLocal(),
        theme: Theme.of(context),
      ),
    );
    if (result == null) return;

    final (from, to) = result;
    if (from == null && to == null) {
      // Cleared: fall back to the default preset.
      bloc.add(
        const ChangeDateRange(preset: PlatformProfitRangePreset.last30Days),
      );
      return;
    }

    final start = from ?? to!;
    final end = to ?? now;
    bloc.add(ChangeDateRange(
      preset: PlatformProfitRangePreset.custom,
      from: DateTime(start.year, start.month, start.day),
      to: DateTime(end.year, end.month, end.day, 23, 59, 59),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final design = profitDesignOf(context);

    return Container(
      height: design.isMobile ? 50 : 56,
      padding: EdgeInsetsDirectional.only(
        start: design.isMobile ? 8 : 12,
        end: 6,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: _softShadow(scheme, hovered: true),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 9),
              itemCount: PlatformProfitRangePreset.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final p = PlatformProfitRangePreset.values[index];
                final selected = p == preset;
                return _FilterChipButton(
                  label: _presetLabel(context, p),
                  selected: selected,
                  onTap: () {
                    if (p == PlatformProfitRangePreset.custom) {
                      _pickCustomRange(context);
                    } else {
                      context
                          .read<PlatformProfitBloc>()
                          .add(ChangeDateRange(preset: p));
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            height: 24,
            child: VerticalDivider(
              width: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          IconButton(
            tooltip: walletL10nOr(context, 'walletProfitRefresh', 'Refresh'),
            visualDensity: VisualDensity.compact,
            onPressed: refreshing
                ? null
                : () => context
                    .read<PlatformProfitBloc>()
                    .add(const RefreshPlatformProfit()),
            icon: refreshing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  )
                : Icon(Icons.refresh_rounded, size: 20, color: scheme.primary),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Same compact From/To date-range dialog used by the gifts filters.
/// Pops `null` on cancel, `(null, null)` on clear, `(from, to)` on apply.
class _ProfitDateRangeDialog extends StatefulWidget {
  const _ProfitDateRangeDialog({
    required this.initialFrom,
    required this.initialTo,
    required this.theme,
  });

  final DateTime? initialFrom;
  final DateTime? initialTo;
  final ThemeData theme;

  @override
  State<_ProfitDateRangeDialog> createState() => _ProfitDateRangeDialogState();
}

class _ProfitDateRangeDialogState extends State<_ProfitDateRangeDialog> {
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _from = widget.initialFrom;
    _to = widget.initialTo;
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Not set';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _from ?? _to ?? DateTime.now(),
      builder: (ctx, child) => Theme(data: widget.theme, child: child!),
    );
    if (picked == null) return;
    setState(() {
      _from = picked;
      if (_to != null && _to!.isBefore(_from!)) _to = _from;
    });
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _to ?? _from ?? DateTime.now(),
      builder: (ctx, child) => Theme(data: widget.theme, child: child!),
    );
    if (picked == null) return;
    setState(() {
      _to = picked;
      if (_from != null && _from!.isAfter(_to!)) _from = _to;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.t('dateRange')),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProfitDatePickRow(
              label: l10n.t('from'),
              value: _fmt(_from),
              onTap: _pickFrom,
            ),
            const SizedBox(height: 10),
            _ProfitDatePickRow(
              label: l10n.t('to'),
              value: _fmt(_to),
              onTap: _pickTo,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop<(DateTime?, DateTime?)>(null),
          child: Text(l10n.t('cancel')),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop<(DateTime?, DateTime?)>((null, null)),
          child: Text(l10n.t('clear')),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop<(DateTime?, DateTime?)>((_from, _to)),
          child: Text(l10n.t('apply')),
        ),
      ],
    );
  }
}

class _ProfitDatePickRow extends StatelessWidget {
  const _ProfitDatePickRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_rounded, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero revenue summary (full-width premium card)
// ---------------------------------------------------------------------------

class PlatformRevenueSummarySection extends StatelessWidget {
  const PlatformRevenueSummarySection({super.key, required this.data});

  final PlatformProfitEntity data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final design = profitDesignOf(context);
    final rate = data.coinsPerPriceUnit;

    final total = data.totalPlatformRevenueCoins;
    final gift = data.giftCommissionCoins;
    final promo = data.promotionRevenueCoins;
    final giftShare = total > 0 ? gift / total : 0.0;
    final promoShare = total > 0 ? promo / total : 0.0;
    final fiat = _fiatSubtitle(context, total, rate);
    final cashInflow = data.monetization?.completedPurchaseVolume;

    final totalBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [scheme.primary, scheme.tertiary],
                ),
              ),
              child: Icon(
                Icons.workspace_premium_outlined,
                color: scheme.onPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                walletL10nOr(context,
                  'walletProfitTotalRevenue',
                  'Total Platform Revenue',
                ),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text.rich(
            TextSpan(
              text: CoinFormat.coinsAmount(total),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: design.isMobile ? 28 : 36,
                    height: 1.05,
                  ),
              children: [
                TextSpan(
                  text: '  ${walletL10nOr(context, 'walletCoinsSuffix', 'coins')}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (fiat != null) ...[
          const SizedBox(height: 6),
          Text(
            fiat,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (data.giftRevenue != null)
              TrendChip(
                label:
                    '${walletL10nOr(context, 'walletProfitGiftRevenue', 'Gift Revenue')} ${_percentLabel(giftShare)}',
                direction: TrendDirection.up,
              ),
            if (data.promotionRevenue != null)
              TrendChip(
                label:
                    '${walletL10nOr(context, 'walletProfitPromotionRevenue', 'Promotion Revenue')} ${_percentLabel(promoShare)}',
                direction: TrendDirection.up,
              ),
          ],
        ),
      ],
    );

    final breakdownBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (data.giftRevenue != null) ...[
          RevenueProgressBar(
            label: walletL10nOr(context,
              'walletProfitGiftRevenue',
              'Gift Revenue',
            ),
            valueLabel: CoinFormat.coinsAmount(gift),
            fraction: giftShare,
            color: scheme.primary,
          ),
          const SizedBox(height: 14),
        ],
        if (data.promotionRevenue != null) ...[
          RevenueProgressBar(
            label: walletL10nOr(context,
              'walletProfitPromotionRevenue',
              'Promotion Revenue',
            ),
            valueLabel: CoinFormat.coinsAmount(promo),
            fraction: promoShare,
            color: scheme.tertiary,
          ),
          const SizedBox(height: 14),
        ],
        if (cashInflow != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: RevenueBadge(
              label: walletL10nOr(context,
                'walletProfitCashInflow',
                'Fiat Cash Inflow',
              ),
              value: CoinFormat.purchaseVolume(cashInflow),
              color: scheme.secondary,
            ),
          ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(design.cardPadding + 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(design.cardRadius),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.45),
            scheme.surfaceContainerLow,
            scheme.surfaceContainerLow,
          ],
        ),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: _softShadow(scheme),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                totalBlock,
                const SizedBox(height: 20),
                breakdownBlock,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 5, child: totalBlock),
              const SizedBox(width: 28),
              Expanded(flex: 5, child: breakdownBlock),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Donut chart with center total, legend, and touch highlight
// ---------------------------------------------------------------------------

class ProfitDonutEntry {
  const ProfitDonutEntry({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class ProfitDonutChart extends StatefulWidget {
  const ProfitDonutChart({
    super.key,
    required this.entries,
    required this.centerLabel,
    this.size = 170,
    this.valueLabel,
  });

  final List<ProfitDonutEntry> entries;
  final String centerLabel;
  final double size;
  final String Function(double value)? valueLabel;

  @override
  State<ProfitDonutChart> createState() => _ProfitDonutChartState();
}

class _ProfitDonutChartState extends State<ProfitDonutChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = widget.entries.fold<double>(0, (s, e) => s + e.value);

    if (total <= 0) {
      return SizedBox(
        height: widget.size,
        child: Center(
          child: Text(
            walletL10nOr(context, 'walletProfitEmptyLedger', 'No data'),
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final visible = widget.entries.where((e) => e.value > 0).toList();
    final format = widget.valueLabel ??
        (double v) => CoinFormat.coinsAmount(v);

    final donut = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: widget.size * 0.31,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  final index =
                      response?.touchedSection?.touchedSectionIndex ?? -1;
                  setState(() => _touched = index >= 0 ? index : null);
                },
              ),
              sections: [
                for (var i = 0; i < visible.length; i++)
                  PieChartSectionData(
                    value: visible[i].value,
                    color: visible[i].color,
                    radius: _touched == i
                        ? widget.size * 0.185
                        : widget.size * 0.16,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  format(total),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  widget.centerLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final legend = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          RevenueProgressBar(
            label: visible[i].label,
            valueLabel: format(visible[i].value),
            fraction: visible[i].value / total,
            color: visible[i].color,
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 460;
        if (!wide) {
          return Column(
            children: [
              donut,
              const SizedBox(height: 16),
              legend,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            donut,
            const SizedBox(width: 24),
            Expanded(child: legend),
          ],
        );
      },
    );
  }
}

/// Revenue breakdown across the main streams (donut + share bars).
class RevenueBreakdownChart extends StatelessWidget {
  const RevenueBreakdownChart({super.key, required this.data});

  final PlatformProfitEntity data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ProfitDonutChart(
      centerLabel: walletL10nOr(context,
        'walletProfitBreakdownCenter',
        'Revenue',
      ),
      entries: [
        if (data.giftRevenue != null)
          ProfitDonutEntry(
            label: walletL10nOr(context,
              'walletProfitGiftRevenue',
              'Gift Revenue',
            ),
            value: data.giftCommissionCoins.toDouble(),
            color: scheme.primary,
          ),
        if (data.promotionRevenue != null)
          ProfitDonutEntry(
            label: walletL10nOr(context,
              'walletProfitPromotionRevenue',
              'Promotion Revenue',
            ),
            value: data.promotionRevenueCoins.toDouble(),
            color: scheme.tertiary,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Monetization analytics (ADMIN only): KPI cards + breakdown chart
// ---------------------------------------------------------------------------

class MonetizationAnalyticsSection extends StatelessWidget {
  const MonetizationAnalyticsSection({
    super.key,
    required this.monetization,
    this.coinsPerPriceUnit,
    this.breakdownData,
  });

  final MonetizationAnalyticsEntity monetization;
  final double? coinsPerPriceUnit;

  /// When provided, a revenue breakdown donut renders beside the KPI cards
  /// on wide screens.
  final PlatformProfitEntity? breakdownData;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final design = profitDesignOf(context);
    final m = monetization;
    final rate = coinsPerPriceUnit;

    final cards = [
      ProfitKpiCard(
        label: walletL10nOr(context, 'walletProfitGiftProfit', 'Gift Profit'),
        value: CoinFormat.coins(m.giftProfitCoins),
        subtitle: _fiatSubtitle(context, m.giftProfitCoins, rate),
        icon: Icons.trending_up_rounded,
        highlight: true,
      ),
      ProfitKpiCard(
        label: walletL10nOr(context,
          'walletProfitCashInflow',
          'Fiat Cash Inflow',
        ),
        value: CoinFormat.purchaseVolume(m.completedPurchaseVolume),
        subtitle: walletL10nArgs(context,
          'walletProfitFiatPurchasesCount',
          {'count': '${m.fiatPurchaseCount}'},
          '${m.fiatPurchaseCount} completed purchases',
        ),
        icon: Icons.attach_money_rounded,
      ),
      ProfitKpiCard(
        label: walletL10nOr(context,
          'walletProfitWalletLiability',
          'Wallet Liability',
        ),
        value: CoinFormat.coins(m.totalBalanceCoins),
        subtitle: _fiatSubtitle(context, m.totalBalanceCoins, rate),
        icon: Icons.account_balance_outlined,
      ),
      ProfitKpiCard(
        label: walletL10nOr(context,
          'walletProfitWithdrawalRequests',
          'Withdrawal Requests',
        ),
        value: '${m.withdrawalRequests}',
        subtitle:
            '${walletL10nOr(context, 'walletProfitPendingWithdrawals', 'Pending Withdrawals')}: ${m.pendingWithdrawals}',
        icon: Icons.outbox_outlined,
      ),
      ProfitKpiCard(
        label: walletL10nOr(context,
          'walletProfitGiftTransactions',
          'Gift Transactions',
        ),
        value: '${m.giftTransactions}',
        icon: Icons.swap_horiz_rounded,
      ),
    ];

    final hasBreakdown = breakdownData != null &&
        (breakdownData!.giftRevenue != null ||
            breakdownData!.promotionRevenue != null);

    return ProfitPanel(
      panelId: 'monetization',
      icon: Icons.insights_outlined,
      title: walletL10nOr(context,
        'walletProfitMonetizationSection',
        'Monetization Analytics',
      ),
      subtitle: walletL10nOr(context,
        'walletProfitMonetizationSubtitle',
        'Gift profit, cash inflow, liability, and withdrawals for the selected period.',
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide = hasBreakdown && constraints.maxWidth >= 1150;

          final chartCard = hasBreakdown
              ? Container(
                  padding: EdgeInsets.all(design.cardPadding),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(design.kpiRadius),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        walletL10nOr(context,
                          'walletProfitBreakdownTitle',
                          'Revenue Breakdown',
                        ),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 14),
                      RevenueBreakdownChart(data: breakdownData!),
                    ],
                  ),
                )
              : null;

          if (sideBySide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: ProfitKpiGrid(cards: cards, maxColumns: 2),
                ),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: chartCard!),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfitKpiGrid(cards: cards),
              if (chartCard != null) ...[
                const SizedBox(height: 16),
                chartCard,
              ],
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gift commission (ADMIN + MODERATOR)
// ---------------------------------------------------------------------------

class GiftRevenueSection extends StatelessWidget {
  const GiftRevenueSection({
    super.key,
    required this.giftRevenue,
    this.coinsPerPriceUnit,
  });

  final GiftRevenueOverviewEntity giftRevenue;
  final double? coinsPerPriceUnit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final design = profitDesignOf(context);
    final g = giftRevenue;
    final rate = coinsPerPriceUnit;

    final allTimeLabel =
        walletL10nOr(context, 'walletProfitAllTime', 'All-Time');
    final periodLabel =
        walletL10nOr(context, 'walletProfitSelectedPeriod', 'Selected Period');

    Widget groupLabel(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text(
                text.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      fontSize: 10,
                    ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Divider(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        );

    final distributionCard = Container(
      padding: EdgeInsets.all(design.cardPadding),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(design.kpiRadius),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            walletL10nOr(context,
              'walletProfitGiftDistribution',
              'Gift Distribution',
            ),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            walletL10nOr(context,
              'walletProfitGiftDistributionSubtitle',
              'Where gifts were sent in the selected period.',
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
          ),
          const SizedBox(height: 16),
          ProfitDonutChart(
            size: design.isMobile ? 140 : 170,
            centerLabel: walletL10nOr(context,
              'walletProfitTransactions',
              'Transactions',
            ),
            valueLabel: (v) => NumberFormat.decimalPattern().format(v.round()),
            entries: [
              ProfitDonutEntry(
                label:
                    walletL10nOr(context, 'walletProfitPostGifts', 'Post Gifts'),
                value: g.toPost.toDouble(),
                color: scheme.primary,
              ),
              ProfitDonutEntry(
                label:
                    walletL10nOr(context, 'walletProfitLiveGifts', 'Live Gifts'),
                value: g.toLive.toDouble(),
                color: scheme.tertiary,
              ),
              ProfitDonutEntry(
                label: walletL10nOr(context,
                  'walletProfitAuctionGifts',
                  'Auction Gifts',
                ),
                value: g.toAuction.toDouble(),
                color: scheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );

    final allTimeCards = ProfitKpiGrid(
      maxColumns: 3,
      cards: [
        ProfitKpiCard(
          label: walletL10nOr(context,
            'walletProfitTotalGiftSpend',
            'Total Gift Spend',
          ),
          value: CoinFormat.coins(g.allTimeSpendCoins),
          subtitle: _fiatSubtitle(context, g.allTimeSpendCoins, rate),
          icon: Icons.card_giftcard_outlined,
        ),
        ProfitKpiCard(
          label: walletL10nOr(context,
            'walletProfitCreatorContribution',
            'Creator Contribution',
          ),
          value: CoinFormat.coins(g.allTimeContributionCoins),
          subtitle: _fiatSubtitle(context, g.allTimeContributionCoins, rate),
          icon: Icons.volunteer_activism_outlined,
        ),
        ProfitKpiCard(
          label: walletL10nOr(context,
            'walletProfitPlatformCommission',
            'Platform Commission',
          ),
          value: CoinFormat.coins(g.allTimeCommissionCoins),
          subtitle: _fiatSubtitle(context, g.allTimeCommissionCoins, rate),
          icon: Icons.percent_rounded,
          highlight: true,
          chip: g.allTimeSpendCoins > 0
              ? TrendChip(
                  label: _percentLabel(
                    g.allTimeCommissionCoins / g.allTimeSpendCoins,
                  ),
                  direction: TrendDirection.up,
                )
              : null,
        ),
      ],
    );

    final periodCards = ProfitKpiGrid(
      cards: [
        ProfitKpiCard(
          label: walletL10nOr(context,
            'walletProfitTransactions',
            'Transactions',
          ),
          value: '${g.transactions}',
          icon: Icons.receipt_long_outlined,
        ),
        ProfitKpiCard(
          label:
              walletL10nOr(context, 'walletProfitSpendCoins', 'Spend Coins'),
          value: CoinFormat.coins(g.spendCoins),
          subtitle: _fiatSubtitle(context, g.spendCoins, rate),
          icon: Icons.payments_outlined,
        ),
        ProfitKpiCard(
          label: walletL10nOr(context,
            'walletProfitContributionCoins',
            'Contribution Coins',
          ),
          value: CoinFormat.coins(g.contributionCoins),
          subtitle: _fiatSubtitle(context, g.contributionCoins, rate),
          icon: Icons.handshake_outlined,
        ),
        ProfitKpiCard(
          label: walletL10nOr(context,
            'walletProfitCommissionCoins',
            'Commission Coins',
          ),
          value: CoinFormat.coins(g.commissionCoins),
          subtitle: _fiatSubtitle(context, g.commissionCoins, rate),
          icon: Icons.savings_outlined,
          highlight: true,
          chip: g.spendCoins > 0
              ? TrendChip(
                  label: _percentLabel(g.commissionCoins / g.spendCoins),
                  direction: TrendDirection.up,
                )
              : null,
        ),
      ],
    );

    return ProfitPanel(
      panelId: 'gift_commission',
      icon: Icons.card_giftcard_outlined,
      title: walletL10nOr(context, 'walletProfitGiftSection', 'Gift Commission'),
      subtitle: walletL10nOr(context,
        'walletProfitGiftSectionSubtitle',
        'Platform cut of gift sends: spend minus creator contribution.',
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide = constraints.maxWidth >= 1150;

          final kpis = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              groupLabel(allTimeLabel),
              allTimeCards,
              const SizedBox(height: 20),
              groupLabel(periodLabel),
              periodCards,
            ],
          );

          if (sideBySide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: kpis),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: distributionCard),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              kpis,
              const SizedBox(height: 16),
              distributionCard,
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Promotions revenue (ADMIN + MODERATOR)
// ---------------------------------------------------------------------------

class PromotionRevenueSection extends StatelessWidget {
  const PromotionRevenueSection({
    super.key,
    required this.promotionRevenue,
    this.coinsPerPriceUnit,
  });

  final PromotionRevenueEntity promotionRevenue;
  final double? coinsPerPriceUnit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final design = profitDesignOf(context);
    final p = promotionRevenue;
    final rate = coinsPerPriceUnit;

    final budgetUsage =
        p.activeBudgetCoins > 0 ? p.activeSpentCoins / p.activeBudgetCoins : 0.0;
    final activeCampaignShare =
        p.totalCampaigns > 0 ? p.activeCampaigns / p.totalCampaigns : 0.0;

    final cards = ProfitKpiGrid(
      cards: [
        ProfitKpiCard(
          label: walletL10nOr(context,
            'walletProfitTotalPromotionRevenue',
            'Total Promotion Revenue',
          ),
          value: CoinFormat.coins(p.totalSpentCoins),
          subtitle: _fiatSubtitle(context, p.totalSpentCoins, rate),
          icon: Icons.campaign_outlined,
          highlight: true,
        ),
        ProfitKpiCard(
          label:
              walletL10nOr(context, 'walletProfitActiveBudget', 'Active Budget'),
          value: CoinFormat.coins(p.activeBudgetCoins),
          subtitle: _fiatSubtitle(context, p.activeBudgetCoins, rate),
          icon: Icons.account_balance_wallet_outlined,
        ),
        ProfitKpiCard(
          label:
              walletL10nOr(context, 'walletProfitActiveSpend', 'Active Spend'),
          value: CoinFormat.coins(p.activeSpentCoins),
          subtitle: _fiatSubtitle(context, p.activeSpentCoins, rate),
          icon: Icons.trending_down_rounded,
          chip: p.activeBudgetCoins > 0
              ? TrendChip(
                  label: _percentLabel(budgetUsage),
                  direction: TrendDirection.flat,
                )
              : null,
        ),
        ProfitKpiCard(
          label: walletL10nOr(context, 'walletProfitImpressions', 'Impressions'),
          value: CoinFormat.coinsAmount(p.totalImpressions),
          subtitle: walletL10nArgs(context,
            'walletProfitImpressions24h',
            {'count': CoinFormat.coinsAmount(p.last24HoursImpressions)},
            '{count} in last 24h',
          ),
          icon: Icons.visibility_outlined,
        ),
      ],
    );

    final circles = Container(
      padding: EdgeInsets.all(design.cardPadding),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(design.kpiRadius),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Wrap(
        spacing: 26,
        runSpacing: 18,
        alignment: WrapAlignment.spaceEvenly,
        children: [
          MetricCircle(
            label: walletL10nOr(context,
              'walletProfitBudgetUsage',
              'Budget Usage',
            ),
            centerValue: _percentLabel(budgetUsage),
            fraction: budgetUsage,
            color: scheme.tertiary,
          ),
          MetricCircle(
            label: walletL10nOr(context,
              'walletProfitActiveCampaigns',
              'Active Campaigns',
            ),
            centerValue: '${p.activeCampaigns}/${p.totalCampaigns}',
            fraction: activeCampaignShare,
            color: scheme.primary,
          ),
          MetricCircle(
            label: walletL10nOr(context, 'walletProfitPackages', 'Packages'),
            centerValue: '${p.activePackages}/${p.totalPackages}',
            fraction:
                p.totalPackages > 0 ? p.activePackages / p.totalPackages : 0.0,
            color: scheme.secondary,
          ),
        ],
      ),
    );

    return ProfitPanel(
      panelId: 'promotions',
      icon: Icons.campaign_outlined,
      title: walletL10nOr(context,
        'walletProfitPromotionSection',
        'Promotions Revenue',
      ),
      subtitle: walletL10nOr(context,
        'walletProfitPromotionSubtitle',
        'Campaign budgets are fully platform income (all-time totals).',
      ),
      trailing: RevenueBadge(
        label: walletL10nOr(context,
          'walletProfitActiveCampaigns',
          'Active Campaigns',
        ),
        value: '${p.activeCampaigns}',
        color: scheme.tertiary,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide = constraints.maxWidth >= 1150;
          if (sideBySide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: cards),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: circles),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cards,
              const SizedBox(height: 16),
              circles,
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ledger (accountingByType): search + type chips + sortable table / cards
// ---------------------------------------------------------------------------

enum _LedgerSort { amountDesc, amountAsc, countDesc, countAsc, type }

class PlatformLedgerSection extends StatefulWidget {
  const PlatformLedgerSection({
    super.key,
    required this.entries,
    this.coinsPerPriceUnit,
  });

  final List<AccountingTypeEntity> entries;
  final double? coinsPerPriceUnit;

  @override
  State<PlatformLedgerSection> createState() => _PlatformLedgerSectionState();
}

class _PlatformLedgerSectionState extends State<PlatformLedgerSection> {
  static const _pageSize = 8;

  final _searchController = TextEditingController();
  Timer? _debounce;
  var _sort = _LedgerSort.amountDesc;
  var _page = 1;
  var _search = '';
  String? _typeFilter;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _search = value;
        _page = 1;
      });
    });
  }

  List<AccountingTypeEntity> get _filtered {
    final term = _search.trim().toUpperCase();
    var list = widget.entries;
    if (_typeFilter != null) {
      list = list.where((e) => e.type == _typeFilter).toList(growable: false);
    }
    if (term.isNotEmpty) {
      list = list
          .where((e) => e.type.toUpperCase().contains(term))
          .toList(growable: false);
    }
    final sorted = [...list]..sort((a, b) {
        return switch (_sort) {
          _LedgerSort.amountDesc => b.amountCoins.compareTo(a.amountCoins),
          _LedgerSort.amountAsc => a.amountCoins.compareTo(b.amountCoins),
          _LedgerSort.countDesc => b.count.compareTo(a.count),
          _LedgerSort.countAsc => a.count.compareTo(b.count),
          _LedgerSort.type => a.type.compareTo(b.type),
        };
      });
    return sorted;
  }

  List<String> get _availableTypes {
    final sorted = [...widget.entries]
      ..sort((a, b) => b.amountCoins.compareTo(a.amountCoins));
    return sorted.map((e) => e.type).take(6).toList();
  }

  void _toggleAmountSort() {
    setState(() {
      _sort = _sort == _LedgerSort.amountDesc
          ? _LedgerSort.amountAsc
          : _LedgerSort.amountDesc;
      _page = 1;
    });
  }

  void _toggleCountSort() {
    setState(() {
      _sort = _sort == _LedgerSort.countDesc
          ? _LedgerSort.countAsc
          : _LedgerSort.countDesc;
      _page = 1;
    });
  }

  void _sortByType() {
    setState(() {
      _sort = _LedgerSort.type;
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = walletsMetricsOf(context);
    final rate = widget.coinsPerPriceUnit;

    final filtered = _filtered;
    final totalPages =
        filtered.isEmpty ? 1 : ((filtered.length - 1) ~/ _pageSize) + 1;
    final page = _page.clamp(1, totalPages);
    final pageItems = metrics.useCompactTable
        ? filtered
        : filtered.skip((page - 1) * _pageSize).take(_pageSize).toList();
    final types = _availableTypes;

    final contentKey =
        ValueKey('$_sort|$page|$_search|${_typeFilter ?? ''}');

    return ProfitPanel(
      panelId: 'ledger',
      icon: Icons.receipt_long_outlined,
      title: walletL10nOr(context, 'walletProfitLedgerTitle', 'Ledger Summary'),
      subtitle: walletL10nOr(context,
        'walletProfitLedgerSubtitle',
        'Coin movement grouped by transaction type for the selected period.',
      ),
      trailing: RevenueBadge(
        label: walletL10nOr(context, 'walletProfitColType', 'Transaction Type'),
        value: '${widget.entries.length}',
        color: scheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: ToolbarFilterStyle.controlHeight,
            child: TextField(
              controller: _searchController,
              style: Theme.of(context).textTheme.bodySmall,
              decoration: ToolbarFilterStyle.inputDecoration(
                scheme,
                hintText: walletL10nOr(context,
                  'walletProfitSearchType',
                  'Search transaction type',
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () {
                          _debounce?.cancel();
                          _searchController.clear();
                          setState(() {
                            _search = '';
                            _page = 1;
                          });
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (types.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: types.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _FilterChipButton(
                      label: walletL10nOr(context,
                        'walletProfitAllTypes',
                        'All types',
                      ),
                      selected: _typeFilter == null,
                      onTap: () => setState(() {
                        _typeFilter = null;
                        _page = 1;
                      }),
                    );
                  }
                  final type = types[index - 1];
                  return _FilterChipButton(
                    label: ledgerTypeLabel(context, type),
                    selected: _typeFilter == type,
                    onTap: () => setState(() {
                      _typeFilter = _typeFilter == type ? null : type;
                      _page = 1;
                    }),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: contentKey,
              child: filtered.isEmpty
                  ? EmptyStateCard(
                      title: walletL10nOr(context,
                        'walletProfitEmptyLedger',
                        'No ledger data',
                      ),
                      message: walletL10nOr(context,
                        'walletProfitEmptyLedgerMsg',
                        'Ledger entries will appear when coin transactions are recorded.',
                      ),
                      icon: Icons.receipt_long_outlined,
                    )
                  : metrics.useCompactTable
                      ? Column(
                          children: [
                            for (var i = 0; i < pageItems.length; i++) ...[
                              if (i > 0) const SizedBox(height: 8),
                              _LedgerMobileCard(
                                entry: pageItems[i],
                                rate: rate,
                                index: i,
                              ),
                            ],
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _LedgerDesktopTable(
                                entries: pageItems,
                                rate: rate,
                                sort: _sort,
                                onSortType: _sortByType,
                                onSortCount: _toggleCountSort,
                                onSortAmount: _toggleAmountSort,
                              ),
                            ),
                            WalletsPaginationBar(
                              page: page,
                              totalPages: totalPages,
                              total: filtered.length,
                              onPage: (p) => setState(() => _page = p),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _ledgerTypeColor(ColorScheme scheme, String type) {
  final palette = [scheme.primary, scheme.tertiary, scheme.secondary];
  return palette[type.hashCode.abs() % palette.length];
}

class _LedgerTypeBadge extends StatelessWidget {
  const _LedgerTypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _ledgerTypeColor(scheme, type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        ledgerTypeLabel(context, type),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
              color: scheme.onSurface,
            ),
      ),
    );
  }
}

class _LedgerMobileCard extends StatelessWidget {
  const _LedgerMobileCard({
    required this.entry,
    required this.index,
    this.rate,
  });

  final AccountingTypeEntity entry;
  final int index;
  final double? rate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fiat = CoinsConverter.approxFiatLabel(entry.amountCoins, rate);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _LedgerTypeBadge(type: entry.type),
                ),
                const SizedBox(height: 8),
                Text(
                  walletL10nArgs(context,
                    'walletLedgerTypeEntries',
                    {'count': '${entry.count}'},
                    '${entry.count} entries',
                  ),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CoinFormat.coins(entry.amountCoins),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
              ),
              if (fiat != null) ...[
                const SizedBox(height: 2),
                Text(
                  fiat,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LedgerDesktopTable extends StatelessWidget {
  const _LedgerDesktopTable({
    required this.entries,
    required this.sort,
    required this.onSortType,
    required this.onSortCount,
    required this.onSortAmount,
    this.rate,
  });

  final List<AccountingTypeEntity> entries;
  final _LedgerSort sort;
  final VoidCallback onSortType;
  final VoidCallback onSortCount;
  final VoidCallback onSortAmount;
  final double? rate;

  Widget _sortableHeader(
    BuildContext context, {
    required String label,
    required bool active,
    required bool ascending,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          WalletsTableHeaderLabel(label),
          const SizedBox(width: 2),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: active ? 1 : 0,
            child: AnimatedRotation(
              turns: ascending ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.arrow_downward_rounded,
                size: 12,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: kWalletsTableHeaderHeight,
            color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _sortableHeader(
                      context,
                      label: walletL10nOr(context,
                        'walletProfitColType',
                        'Transaction Type',
                      ),
                      active: sort == _LedgerSort.type,
                      ascending: false,
                      onTap: onSortType,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _sortableHeader(
                      context,
                      label:
                          walletL10nOr(context, 'walletProfitColCount', 'Count'),
                      active: sort == _LedgerSort.countDesc ||
                          sort == _LedgerSort.countAsc,
                      ascending: sort == _LedgerSort.countAsc,
                      onTap: onSortCount,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _sortableHeader(
                      context,
                      label: walletL10nOr(context,
                        'walletProfitColAmount',
                        'Amount (Coins)',
                      ),
                      active: sort == _LedgerSort.amountDesc ||
                          sort == _LedgerSort.amountAsc,
                      ascending: sort == _LedgerSort.amountAsc,
                      onTap: onSortAmount,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: WalletsTableHeaderLabel(
                    walletL10nOr(context,
                      'walletProfitColFiat',
                      'Approx Fiat Value',
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            WalletsHoverTableRow(
              striped: i.isOdd,
              height: 46,
              child: _LedgerRow(entry: entries[i], rate: rate),
            ),
          ],
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry, this.rate});

  final AccountingTypeEntity entry;
  final double? rate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cellStyle = walletsTableCellStyle(context);
    final fiat = CoinsConverter.approxFiatLabel(entry.amountCoins, rate);

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: _LedgerTypeBadge(type: entry.type),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text('${entry.count}', style: cellStyle),
        ),
        Expanded(
          flex: 3,
          child: Text(
            CoinFormat.coins(entry.amountCoins),
            style: cellStyle?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            fiat ?? '—',
            style: cellStyle?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
