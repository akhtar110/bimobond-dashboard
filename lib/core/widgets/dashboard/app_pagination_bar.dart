import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../localization/localization.dart';

/// Inclusive 1-based index range for the items visible on [currentPage].
class AppPaginationRange {
  const AppPaginationRange({required this.start, required this.end});

  final int start;
  final int end;

  /// Computes the visible item range for page-based lists.
  ///
  /// Prefer passing [itemCount] (items on the current page) so the last page
  /// shows an accurate end index when it is shorter than [pageSize].
  static AppPaginationRange compute({
    required int currentPage,
    required int pageSize,
    required int total,
    int? itemCount,
  }) {
    if (total <= 0 || currentPage < 1 || pageSize < 1) {
      return const AppPaginationRange(start: 0, end: 0);
    }

    final start = ((currentPage - 1) * pageSize) + 1;
    if (start > total) {
      return AppPaginationRange(start: total, end: total);
    }

    final end = itemCount != null && itemCount > 0
        ? math.min(start + itemCount - 1, total)
        : math.min(currentPage * pageSize, total);

    return AppPaginationRange(start: start, end: end);
  }
}

/// Builds a compact page list with ellipses.
///
/// Examples (lastPage = 30):
/// - page 1  → `1 2 3 … 30`
/// - page 5  → `1 … 4 5 6 … 30`
/// - page 29 → `1 … 28 29 30`
List<AppPaginationToken> buildAppPaginationTokens({
  required int currentPage,
  required int lastPage,
  int siblingCount = 1,
  int boundaryCount = 1,
}) {
  if (lastPage < 1) return const [];
  if (lastPage == 1) return const [AppPaginationToken.page(1)];

  final current = currentPage.clamp(1, lastPage);
  final siblings = math.max(siblingCount, 0);
  final boundaries = math.max(boundaryCount, 1);

  // Small totals: show every page (ellipsis not useful).
  if (lastPage <= siblings * 2 + boundaries * 2 + 3) {
    return [
      for (var page = 1; page <= lastPage; page++)
        AppPaginationToken.page(page),
    ];
  }

  final pages = <int>{
    for (var page = 1; page <= boundaries; page++) page,
    for (var page = lastPage - boundaries + 1; page <= lastPage; page++) page,
    for (var page = current - siblings; page <= current + siblings; page++)
      if (page >= 1 && page <= lastPage) page,
  };

  // Near start → `1 2 3 … last`
  if (current <= siblings + boundaries + 1) {
    final end = math.min(lastPage, boundaries + siblings + 1);
    for (var page = 1; page <= end; page++) {
      pages.add(page);
    }
  }

  // Near end → `1 … (last-2) (last-1) last`
  if (current >= lastPage - (siblings + boundaries)) {
    final start = math.max(1, lastPage - (boundaries + siblings));
    for (var page = start; page <= lastPage; page++) {
      pages.add(page);
    }
  }

  final sorted = pages.toList()..sort();
  final tokens = <AppPaginationToken>[];

  for (var i = 0; i < sorted.length; i++) {
    if (i > 0) {
      final prev = sorted[i - 1];
      final next = sorted[i];
      final gap = next - prev;
      if (gap == 2) {
        tokens.add(AppPaginationToken.page(prev + 1));
      } else if (gap > 2) {
        final jumpTo = ((prev + next) / 2).round().clamp(prev + 1, next - 1);
        tokens.add(AppPaginationToken.ellipsis(jumpTo: jumpTo));
      }
    }
    tokens.add(AppPaginationToken.page(sorted[i]));
  }

  return tokens;
}

/// A page number or an ellipsis gap in the pagination control strip.
class AppPaginationToken {
  const AppPaginationToken._({this.page, this.jumpTo})
      : assert(page != null || jumpTo != null);

  const AppPaginationToken.page(int page) : this._(page: page);

  const AppPaginationToken.ellipsis({required int jumpTo})
      : this._(jumpTo: jumpTo);

  final int? page;
  final int? jumpTo;

  bool get isEllipsis => page == null;
}

/// Shared desktop & mobile transparent responsive pagination footer.
///
/// Example controls: `‹ 1 2 3 … 30 ›` + `Go to: [ 10 ]`
class AppPaginationBar extends StatelessWidget {
  const AppPaginationBar({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.pageSize,
    required this.onPageChanged,
    this.itemCount,
    this.hideWhenSinglePage = true,
    this.showTopBorder = false,
    this.showBorder = true,
    this.showEdgeButtons = true,
    this.siblingCount = 1,
    this.boundaryCount = 1,
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.compactBreakpoint = 520,
  });

  final int currentPage;
  final int lastPage;
  final int total;
  final int pageSize;

  /// Items currently rendered on this page (improves last-page end index).
  final int? itemCount;

  final ValueChanged<int> onPageChanged;
  final bool hideWhenSinglePage;
  final bool showTopBorder;

  /// When false, renders with a transparent background without borders or shadows.
  final bool showBorder;

  /// Retained for API compatibility. First/last jump buttons are no longer
  /// shown; only previous/next arrows are rendered.
  final bool showEdgeButtons;

  /// Pages shown on each side of the current page.
  final int siblingCount;

  /// Always-visible pages at the start and end.
  final int boundaryCount;

  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final double compactBreakpoint;

  void _goTo(int page) {
    if (lastPage < 1) return;
    final next = page.clamp(1, lastPage);
    if (next == currentPage.clamp(1, lastPage)) return;
    onPageChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    if (hideWhenSinglePage && lastPage <= 1) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final safeLast = math.max(lastPage, 1);
    final safeCurrent = currentPage.clamp(1, safeLast);
    final radius = borderRadius ?? BorderRadius.circular(14);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: !showBorder
            ? Colors.transparent
            : showTopBorder
                ? Colors.transparent
                : scheme.surface.withValues(alpha: 0.85),
        borderRadius: !showBorder || showTopBorder ? null : radius,
        border: !showBorder
            ? null
            : showTopBorder
                ? Border(
                    top: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  )
                : Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
        boxShadow: !showBorder || showTopBorder
            ? null
            : [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final compact = width < compactBreakpoint;
          final tight = width < 380;
          final ultraTight = width < 320;

          final effectiveSiblings = ultraTight ? 0 : siblingCount;

          final tokens = buildAppPaginationTokens(
            currentPage: safeCurrent,
            lastPage: safeLast,
            siblingCount: effectiveSiblings,
            boundaryCount: boundaryCount,
          );

          final pageControls = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _PageIconButton(
                  icon: isRtl
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  enabled: safeCurrent > 1,
                  tooltip:
                      context.l10n.tOr('paginationPrevious', 'Previous page'),
                  onTap: () => _goTo(safeCurrent - 1),
                ),
                SizedBox(width: tight ? 4 : 6),
                for (final token in tokens)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: tight ? 2 : 4),
                    child: token.isEllipsis
                        ? _EllipsisButton(
                            onTap: () => _goTo(token.jumpTo!),
                          )
                        : _PageNumberButton(
                            page: token.page!,
                            isActive: token.page == safeCurrent,
                            onTap: () => _goTo(token.page!),
                          ),
                  ),
                SizedBox(width: tight ? 0 : 2),
                _PageIconButton(
                  icon: isRtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  enabled: safeCurrent < safeLast,
                  tooltip: context.l10n.tOr('paginationNext', 'Next page'),
                  onTap: () => _goTo(safeCurrent + 1),
                ),
              ],
            ),
          );

          final goToField = _PaginationGoToField(
            currentPage: safeCurrent,
            lastPage: safeLast,
            onSubmit: _goTo,
            compact: tight,
          );

          if (compact) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: pageControls),
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.center,
                  child: goToField,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: pageControls,
                ),
              ),
              const SizedBox(width: 12),
              goToField,
            ],
          );
        },
      ),
    );
  }
}

class _PaginationGoToField extends StatefulWidget {
  const _PaginationGoToField({
    required this.currentPage,
    required this.lastPage,
    required this.onSubmit,
    this.compact = false,
  });

  final int currentPage;
  final int lastPage;
  final ValueChanged<int> onSubmit;
  final bool compact;

  @override
  State<_PaginationGoToField> createState() => _PaginationGoToFieldState();
}

class _PaginationGoToFieldState extends State<_PaginationGoToField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentPage}');
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant _PaginationGoToField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage && !_focusNode.hasFocus) {
      _controller.text = '${widget.currentPage}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) {
      _controller.text = '${widget.currentPage}';
      return;
    }
    final next = parsed.clamp(1, widget.lastPage);
    _controller.text = '$next';
    widget.onSubmit(next);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = context.l10n.tOr('paginationGoTo', 'Go to:');
    final focused = _focusNode.hasFocus;
    final active = focused || _hovered;
    final height = widget.compact ? 36.0 : 40.0;
    final fieldWidth = widget.compact ? 48.0 : 56.0;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: active ? scheme.primary : scheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.15,
      height: 1.0,
      leadingDistribution: TextLeadingDistribution.even,
    );
    final inputStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: scheme.onSurface,
      letterSpacing: -0.3,
      height: 1.0,
      leadingDistribution: TextLeadingDistribution.even,
    );
    final metaStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
      fontWeight: FontWeight.w600,
      height: 1.0,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: height,
        padding: EdgeInsetsDirectional.only(
          start: widget.compact ? 10 : 12,
          end: 4,
        ),
        decoration: BoxDecoration(
          color: active
              ? scheme.primary.withValues(alpha: 0.08)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: focused
                ? scheme.primary.withValues(alpha: 0.65)
                : active
                    ? scheme.primary.withValues(alpha: 0.28)
                    : scheme.outlineVariant.withValues(alpha: 0.4),
            width: focused ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.shortcut_rounded,
              size: widget.compact ? 15 : 16,
              color: active
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
            SizedBox(width: widget.compact ? 6 : 8),
            Text(label, style: labelStyle),
            SizedBox(width: widget.compact ? 8 : 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: fieldWidth,
              height: height - 10,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular((height - 10) / 2),
                border: Border.all(
                  color: focused
                      ? scheme.primary.withValues(alpha: 0.45)
                      : scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.go,
                style: inputStyle,
                cursorHeight: 14,
                cursorColor: scheme.primary,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onTapOutside: (_) => _focusNode.unfocus(),
                onSubmitted: (_) => _submit(),
                onEditingComplete: _submit,
              ),
            ),
            if (!widget.compact) ...[
              const SizedBox(width: 6),
              Text('/ ${widget.lastPage}', style: metaStyle),
            ],
            SizedBox(width: widget.compact ? 6 : 8),
            Tooltip(
              message:
                  context.l10n.tOr('paginationJumpToPage', 'Go to page'),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _submit,
                  customBorder: const CircleBorder(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: height - 8,
                    height: height - 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary,
                          scheme.primary.withValues(alpha: 0.85),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.28),
                          blurRadius: active ? 8 : 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      isRtl
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded,
                      size: 16,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageNumberButton extends StatefulWidget {
  const _PageNumberButton({
    required this.page,
    required this.isActive,
    required this.onTap,
  });

  final int page;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_PageNumberButton> createState() => _PageNumberButtonState();
}

class _PageNumberButtonState extends State<_PageNumberButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = '${widget.page}';
    final width = label.length >= 3 ? 36.0 : 32.0;
    final active = widget.isActive;

    final background = active
        ? scheme.primary.withValues(alpha: 0.15)
        : _hovered
            ? scheme.primary.withValues(alpha: 0.08)
            : Colors.transparent;

    final foreground = active
        ? scheme.primary
        : scheme.onSurfaceVariant.withValues(alpha: _hovered ? 0.95 : 0.78);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: width,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active
                    ? scheme.primary.withValues(alpha: 0.3)
                    : _hovered
                        ? scheme.outlineVariant.withValues(alpha: 0.6)
                        : Colors.transparent,
              ),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: foreground,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EllipsisButton extends StatefulWidget {
  const _EllipsisButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_EllipsisButton> createState() => _EllipsisButtonState();
}

class _EllipsisButtonState extends State<_EllipsisButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: context.l10n.tOr('paginationJumpPages', 'Jump pages'),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            hoverColor: scheme.primary.withValues(alpha: 0.06),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _hovered
                    ? scheme.primary.withValues(alpha: 0.05)
                    : Colors.transparent,
              ),
              child: Text(
                '…',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant.withValues(
                        alpha: _hovered ? 0.95 : 0.7,
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageIconButton extends StatefulWidget {
  const _PageIconButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  State<_PageIconButton> createState() => _PageIconButtonState();
}

class _PageIconButtonState extends State<_PageIconButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.enabled;

    final button = MouseRegion(
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: enabled
          ? (_) => setState(() {
                _hovered = false;
                _pressed = false;
              })
          : null,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _pressed && enabled ? 0.94 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled && _hovered
                  ? scheme.primary.withValues(alpha: 0.10)
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.25),
              border: Border.all(
                color: enabled
                    ? (_hovered
                        ? scheme.primary.withValues(alpha: 0.35)
                        : scheme.outlineVariant.withValues(alpha: 0.45))
                    : scheme.outlineVariant.withValues(alpha: 0.2),
              ),
              boxShadow: enabled && _hovered
                  ? [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: enabled
                  ? scheme.onSurface.withValues(alpha: 0.85)
                  : scheme.onSurfaceVariant.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip == null || !enabled) return button;
    return Tooltip(message: widget.tooltip!, child: button);
  }
}
