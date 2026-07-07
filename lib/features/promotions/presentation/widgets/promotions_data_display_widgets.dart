import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../core/widgets/toolbar_filter_style.dart';
import 'promotions_dashboard_widgets.dart';

const double kPromotionsDataRowHeight = 56;
const double kPromotionsDataTableHeaderHeight = 36;

/// Outer card matching [LocationDashboardCard] on user locations.
class PromotionsDataCard extends StatelessWidget {
  const PromotionsDataCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PromotionsSpace.lg),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Section card with optional title and footer (pagination).
class PromotionsDataSection extends StatelessWidget {
  const PromotionsDataSection({
    super.key,
    required this.child,
    this.title,
    this.footer,
    this.padding,
  });

  final Widget child;
  final String? title;
  final Widget? footer;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return PromotionsDataCard(
      padding: padding ??
          EdgeInsets.fromLTRB(
            PromotionsSpace.lg,
            PromotionsSpace.lg,
            PromotionsSpace.lg,
            PromotionsSpace.md,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: PromotionsSpace.md),
          ],
          child,
          if (footer != null) ...[
            const SizedBox(height: PromotionsSpace.sm),
            footer!,
          ],
        ],
      ),
    );
  }
}

BoxDecoration promotionsInnerTableDecoration(ColorScheme scheme) {
  return BoxDecoration(
    color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
  );
}

TextStyle? promotionsTableHeaderStyle(BuildContext context) {
  return Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 10,
        letterSpacing: 0.2,
      );
}

/// Loading / error / empty / content inside a data card.
class PromotionsDataBody extends StatelessWidget {
  const PromotionsDataBody({
    super.key,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.isEmpty = false,
    this.emptyMessage,
    this.minHeight = 280,
    required this.child,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool isEmpty;
  final String? emptyMessage;
  final double minHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    Widget content;
    if (isLoading) {
      content = const Center(child: LoadingView());
    } else if (errorMessage != null) {
      content = Center(
        child: ErrorView(
          message: errorMessage!,
          retryLabel: l10n.t('retry'),
          onRetry: onRetry ?? () {},
        ),
      );
    } else if (isEmpty) {
      content = Center(
        child: Text(
          emptyMessage ?? l10n.t('noData'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    } else {
      content = child;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: content,
    );
  }
}

class PromotionsLoadMoreIndicator extends StatelessWidget {
  const PromotionsLoadMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class PromotionsEndOfListLabel extends StatelessWidget {
  const PromotionsEndOfListLabel({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = label ?? context.l10n.tOr('allItemsLoaded', 'All items loaded');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 24, height: 1, color: scheme.outlineVariant),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
          ),
          const SizedBox(width: 8),
          Container(width: 24, height: 1, color: scheme.outlineVariant),
        ],
      ),
    );
  }
}

/// Compact toolbar search field matching user locations filters.
class PromotionsToolbarSearchField extends StatefulWidget {
  const PromotionsToolbarSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.initialValue = '',
    this.height = ToolbarFilterStyle.controlHeight,
    this.compact = false,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final String initialValue;
  final double height;
  final bool compact;

  @override
  State<PromotionsToolbarSearchField> createState() =>
      _PromotionsToolbarSearchFieldState();
}

class _PromotionsToolbarSearchFieldState
    extends State<PromotionsToolbarSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(PromotionsToolbarSearchField oldWidget) {
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
    final fontSize = widget.compact ? 12.0 : 13.0;

    return SizedBox(
      height: widget.height,
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          setState(() {});
          widget.onChanged(value);
        },
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: fontSize),
        textInputAction: TextInputAction.search,
        decoration: ToolbarFilterStyle.inputDecoration(
          scheme,
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: fontSize,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: widget.compact ? 16 : 18,
            color: scheme.onSurfaceVariant,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: widget.compact ? 14 : 16,
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
