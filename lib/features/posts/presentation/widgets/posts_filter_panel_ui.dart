import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../utils/post_date_format.dart';
import '../utils/post_time_format.dart';
import '../utils/posts_datetime_filter_utils.dart';

/// Visual tokens for the premium posts filter panel.
class PostsFilterPanelTokens {
  PostsFilterPanelTokens._();

  static const spacing = 8.0;
  static const chipHeight = 28.0;
  static const chipRadius = 6.0;
  static const fieldHeight = 34.0;
  static const sectionIconSize = 14.0;
  static const labelSize = 11.0;
  static const bodySize = 12.5;
}

/// Glass shell wrapping the filter panel content.
class PostsFilterGlassShell extends StatelessWidget {
  const PostsFilterGlassShell({
    super.key,
    required this.child,
    required this.borderRadius,
    this.blurSigma = 22,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassFill = isDark
        ? const Color(0xFF141418).withValues(alpha: 0.82)
        : const Color(0xFFFAFAFC).withValues(alpha: 0.88);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: glassFill,
            borderRadius: borderRadius,
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class PostsFilterPanelHeader extends StatelessWidget {
  const PostsFilterPanelHeader({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 4),
      child: Row(
        children: [
          Icon(Icons.tune_rounded, size: 16, color: scheme.primary),
          const SizedBox(width: PostsFilterPanelTokens.spacing),
          Expanded(
            child: Text(
              l10n.tOr('filters', 'Filters'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: scheme.onSurface,
                height: 1.1,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.t('close'),
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, size: 18, color: scheme.onSurfaceVariant),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

/// Active draft filter tags shown at the top of the panel.
class PostsFilterActiveTags extends StatelessWidget {
  const PostsFilterActiveTags({
    super.key,
    required this.labels,
    required this.onRemove,
  });

  final List<({String id, String label})> labels;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, PostsFilterPanelTokens.spacing),
      child: Wrap(
        spacing: PostsFilterPanelTokens.spacing,
        runSpacing: PostsFilterPanelTokens.spacing,
        children: [
          for (final item in labels)
            Material(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () => onRemove(item.id),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 3, 4, 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: PostsFilterPanelTokens.labelSize,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                      Icon(Icons.close_rounded, size: 12, color: scheme.primary),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PostsFilterSection extends StatelessWidget {
  const PostsFilterSection({
    super.key,
    required this.title,
    this.icon,
    required this.child,
    this.showDivider = true,
  });

  final String title;
  final IconData? icon;
  final Widget child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, PostsFilterPanelTokens.spacing, 12, 0),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: PostsFilterPanelTokens.sectionIconSize,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: PostsFilterPanelTokens.labelSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.95),
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, PostsFilterPanelTokens.spacing, 12, 0),
          child: child,
        ),
      ],
    );
  }
}

class PostsFilterChipGrid extends StatelessWidget {
  const PostsFilterChipGrid({
    super.key,
    required this.children,
    this.minCellWidth = 72,
  });

  final List<Widget> children;
  final double minCellWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite || width <= 0) {
          return Wrap(
            spacing: PostsFilterPanelTokens.spacing,
            runSpacing: PostsFilterPanelTokens.spacing,
            children: children,
          );
        }

        var columns = width >= 360 ? 3 : (width >= 240 ? 2 : 1);
        final gap = PostsFilterPanelTokens.spacing;
        var cellWidth = (width - (gap * (columns - 1))) / columns;

        while (columns > 1 && cellWidth < minCellWidth) {
          columns--;
          cellWidth = (width - (gap * (columns - 1))) / columns;
        }

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(
                width: columns == 1 ? width : cellWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class PostsFilterChoiceChip extends StatelessWidget {
  const PostsFilterChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.88);
    final bg = selected
        ? scheme.primary.withValues(alpha: 0.14)
        : scheme.onSurface.withValues(alpha: 0.04);
    final border = selected
        ? scheme.primary.withValues(alpha: 0.45)
        : scheme.outlineVariant.withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PostsFilterPanelTokens.chipRadius),
        child: Ink(
          height: PostsFilterPanelTokens.chipHeight,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(PostsFilterPanelTokens.chipRadius),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: fg),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: PostsFilterPanelTokens.labelSize,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                    height: 1,
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

/// Stacks inline filter fields vertically on narrow panels.
class PostsFilterInlinePair extends StatelessWidget {
  const PostsFilterInlinePair({
    super.key,
    required this.start,
    required this.end,
    this.stackBelowWidth = 300,
  });

  final Widget start;
  final Widget end;
  final double stackBelowWidth;

  @override
  Widget build(BuildContext context) {
    final separatorColor = Theme.of(context)
        .colorScheme
        .onSurfaceVariant
        .withValues(alpha: 0.6);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < stackBelowWidth;

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              start,
              const SizedBox(height: PostsFilterPanelTokens.spacing),
              end,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: start),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.remove_rounded, size: 14, color: separatorColor),
            ),
            Expanded(child: end),
          ],
        );
      },
    );
  }
}

/// Compact inline From — To date row for the filter panel.
class PostsFilterInlineDateRange extends StatelessWidget {
  const PostsFilterInlineDateRange({
    super.key,
    required this.from,
    required this.to,
    required this.onChanged,
  });

  final DateTime? from;
  final DateTime? to;
  final void Function(DateTime? from, DateTime? to) onChanged;

  Future<void> _pick(BuildContext context, {required bool isStart}) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bounds = postDatePickerBounds(isStart: isStart, from: from, to: to);
    final picked = await showDatePicker(
      context: context,
      firstDate: bounds.firstDate,
      lastDate: bounds.lastDate,
      initialDate: bounds.initialDate,
      helpText: isStart
          ? l10n.tOr('from', 'From')
          : l10n.tOr('to', 'To'),
      builder: (ctx, child) => Theme(data: theme, child: child!),
    );
    if (picked == null || !context.mounted) return;
    final (nextFrom, nextTo) = normalizePostDateRange(
      isStart: isStart,
      picked: picked,
      from: from,
      to: to,
    );
    onChanged(nextFrom, nextTo);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    return PostsFilterInlinePair(
      start: PostsFilterInlineField(
        label: l10n.tOr('from', 'From'),
        value: from != null ? formatPostDisplayDate(from!, locale: locale) : null,
        icon: Icons.calendar_today_outlined,
        onTap: () => _pick(context, isStart: true),
      ),
      end: PostsFilterInlineField(
        label: l10n.tOr('to', 'To'),
        value: to != null ? formatPostDisplayDate(to!, locale: locale) : null,
        icon: Icons.event_outlined,
        onTap: () => _pick(context, isStart: false),
      ),
    );
  }
}

class PostsFilterInlineTimeRange extends StatelessWidget {
  const PostsFilterInlineTimeRange({
    super.key,
    required this.fromMinutes,
    required this.toMinutes,
    required this.onChanged,
  });

  final int? fromMinutes;
  final int? toMinutes;
  final void Function(int? from, int? to) onChanged;

  Future<void> _pick(BuildContext context, {required bool isStart}) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = TimeOfDay.now();
    final initial = isStart
        ? (fromMinutes != null ? postMinutesToTime(fromMinutes!) : now)
        : (toMinutes != null ? postMinutesToTime(toMinutes!) : now);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.input,
      helpText: isStart
          ? l10n.tOr('startTime', 'Start')
          : l10n.tOr('endTime', 'End'),
      builder: (ctx, child) => Theme(data: theme, child: child!),
    );
    if (picked == null || !context.mounted) return;

    final (from, to) = normalizePostTimeRange(
      isStart: isStart,
      pickedMinutes: postTimeToMinutes(picked),
      from: fromMinutes,
      to: toMinutes,
    );
    onChanged(from, to);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    return PostsFilterInlinePair(
      start: PostsFilterInlineField(
        label: l10n.tOr('startTime', 'Start'),
        value: fromMinutes != null
            ? formatPostDisplayTime(fromMinutes!, locale: locale)
            : null,
        icon: Icons.schedule_outlined,
        onTap: () => _pick(context, isStart: true),
      ),
      end: PostsFilterInlineField(
        label: l10n.tOr('endTime', 'End'),
        value: toMinutes != null
            ? formatPostDisplayTime(toMinutes!, locale: locale)
            : null,
        icon: Icons.schedule_rounded,
        onTap: () => _pick(context, isStart: false),
      ),
    );
  }
}

class PostsFilterInlineField extends StatelessWidget {
  const PostsFilterInlineField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = value != null && value!.isNotEmpty;

    return Material(
      color: scheme.onSurface.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(PostsFilterPanelTokens.chipRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PostsFilterPanelTokens.chipRadius),
        child: Ink(
          height: PostsFilterPanelTokens.fieldHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PostsFilterPanelTokens.chipRadius),
            border: Border.all(
              color: hasValue
                  ? scheme.primary.withValues(alpha: 0.4)
                  : scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasValue ? value! : '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: PostsFilterPanelTokens.bodySize,
                        fontWeight: FontWeight.w600,
                        color: hasValue ? scheme.onSurface : scheme.onSurfaceVariant,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                icon,
                size: 14,
                color: hasValue ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostsFilterPanelFooter extends StatelessWidget {
  const PostsFilterPanelFooter({
    super.key,
    required this.onReset,
    required this.onApply,
  });

  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark
          ? Colors.black.withValues(alpha: 0.35)
          : scheme.surface.withValues(alpha: 0.92),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, PostsFilterPanelTokens.spacing, 12, 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PostsFilterPanelTokens.chipRadius),
                    ),
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    foregroundColor: scheme.onSurfaceVariant,
                    textStyle: const TextStyle(
                      fontSize: PostsFilterPanelTokens.bodySize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l10n.tOr('resetFilters', 'Reset')),
                ),
              ),
              const SizedBox(width: PostsFilterPanelTokens.spacing),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PostsFilterPanelTokens.chipRadius),
                    ),
                    textStyle: const TextStyle(
                      fontSize: PostsFilterPanelTokens.bodySize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(l10n.tOr('apply', 'Apply')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Date preset chips for the filter panel.
class PostsFilterDatePresets extends StatelessWidget {
  const PostsFilterDatePresets({
    super.key,
    required this.selected,
    required this.onPreset,
  });

  final PostsDateTimePreset selected;
  final ValueChanged<PostsDateTimePreset> onPreset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PostsFilterChipGrid(
      children: [
        for (final preset in PostsDateTimePreset.values)
          PostsFilterChoiceChip(
            label: postsDateTimePresetLabel(preset, l10n.t),
            selected: selected == preset,
            onTap: () => onPreset(preset),
          ),
      ],
    );
  }
}
