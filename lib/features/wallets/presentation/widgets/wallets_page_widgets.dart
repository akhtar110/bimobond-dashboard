import 'package:flutter/material.dart';

import '../../../../core/widgets/toolbar_filter_style.dart';
import '../../domain/entities/wallet_entities.dart';
import '../utils/wallets_responsive.dart';
import 'wallets_dashboard_widgets.dart';
import 'wallets_pagination_bar.dart';

const double kWalletsTableRowHeight = 56;
const double kWalletsTableHeaderHeight = 36;

class WalletsPageHeader extends StatelessWidget {
  const WalletsPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.metrics,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final WalletsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = metrics.isMobile;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: (compact
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.headlineSmall)
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (subtitle != null) ...[
                SizedBox(height: metrics.toolbarFilterGap),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class WalletsToolbarSearchField extends StatefulWidget {
  const WalletsToolbarSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  State<WalletsToolbarSearchField> createState() =>
      _WalletsToolbarSearchFieldState();
}

class _WalletsToolbarSearchFieldState extends State<WalletsToolbarSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _clear() {
    widget.controller.clear();
    widget.onChanged('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: ToolbarFilterStyle.controlHeight,
      child: TextField(
        controller: widget.controller,
        style: Theme.of(context).textTheme.bodySmall,
        decoration: ToolbarFilterStyle.inputDecoration(
          scheme,
          hintText: widget.hintText,
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: _clear,
                )
              : null,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

class WalletsToolbarNumberField extends StatelessWidget {
  const WalletsToolbarNumberField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: ToolbarFilterStyle.controlHeight,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: Theme.of(context).textTheme.bodySmall,
        decoration: ToolbarFilterStyle.inputDecoration(
          scheme,
          hintText: hintText,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class WalletsToolbarDropdown<T> extends StatelessWidget {
  const WalletsToolbarDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.itemLabel,
  });

  final T? value;
  final String hint;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String Function(T value)? itemLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: ToolbarFilterStyle.controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: ToolbarFilterStyle.boxDecoration(scheme),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          borderRadius: ToolbarFilterStyle.radius,
          dropdownColor: scheme.surface,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurface),
          hint: Text(
            hint,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          icon: Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class WalletsToolbarClearButton extends StatelessWidget {
  const WalletsToolbarClearButton({
    super.key,
    required this.onPressed,
    this.controlHeight = ToolbarFilterStyle.controlHeight,
  });

  final VoidCallback onPressed;
  final double controlHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: 'Clear filters',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: controlHeight - 4,
        minHeight: controlHeight - 4,
      ),
      onPressed: onPressed,
      icon: Icon(
        Icons.filter_alt_off_outlined,
        size: 17,
        color: scheme.error,
      ),
    );
  }
}

class WalletsDataListCard extends StatelessWidget {
  const WalletsDataListCard({
    super.key,
    required this.total,
    required this.totalLabel,
    required this.isEmpty,
    required this.emptyIcon,
    required this.emptyTitle,
    this.emptySubtitle,
    required this.child,
    this.page,
    this.totalPages,
    this.onPage,
  });

  final int total;
  final String totalLabel;
  final bool isEmpty;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;
  final Widget child;
  final int? page;
  final int? totalPages;
  final ValueChanged<int>? onPage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (isEmpty) {
      return WalletsDashboardCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(emptyIcon, size: 40, color: scheme.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(
                  emptyTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (emptySubtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    emptySubtitle!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return WalletsDashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$total $totalLabel',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
          if (page != null && totalPages != null && onPage != null)
            WalletsPaginationBar(
              page: page!,
              totalPages: totalPages!,
              total: total,
              showTopBorder: true,
              onPage: onPage!,
            ),
        ],
      ),
    );
  }
}

class WalletsDesktopTableFrame extends StatelessWidget {
  const WalletsDesktopTableFrame({
    super.key,
    required this.header,
    required this.rows,
  });

  final Widget header;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: kWalletsTableHeaderHeight,
            color: scheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: header,
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: rows.length,
              separatorBuilder: (_, index) {
                if (index >= rows.length - 1) {
                  return const SizedBox.shrink();
                }
                return Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                );
              },
              itemBuilder: (_, index) => rows[index],
            ),
          ),
        ],
      ),
    );
  }
}

class WalletsTableHeaderLabel extends StatelessWidget {
  const WalletsTableHeaderLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
            letterSpacing: 0.2,
          ),
    );
  }
}

class WalletsHoverTableRow extends StatefulWidget {
  const WalletsHoverTableRow({
    super.key,
    required this.striped,
    this.onTap,
    required this.child,
    this.height = kWalletsTableRowHeight,
  });

  final bool striped;
  final VoidCallback? onTap;
  final Widget child;
  final double height;

  @override
  State<WalletsHoverTableRow> createState() => _WalletsHoverTableRowState();
}

class _WalletsHoverTableRowState extends State<WalletsHoverTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rowColor = _hovered
        ? scheme.surfaceContainerHighest
        : widget.striped
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : scheme.surface;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: rowColor,
        child: InkWell(
          onTap: widget.onTap,
          child: SizedBox(
            height: widget.height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class WalletsCompactListFrame extends StatelessWidget {
  const WalletsCompactListFrame({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.nestedInScrollView = false,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// When true, sizes to content and defers scrolling to a parent
  /// [SingleChildScrollView] (e.g. money dashboard sections).
  final bool nestedInScrollView;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: nestedInScrollView,
      physics: nestedInScrollView
          ? const NeverScrollableScrollPhysics()
          : null,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: itemBuilder,
    );
  }
}

class WalletsCompactCard extends StatelessWidget {
  const WalletsCompactCard({
    super.key,
    this.onTap,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.footer,
  });

  final VoidCallback? onTap;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    if (footer != null) ...[
                      const SizedBox(height: 6),
                      footer!,
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle? walletsTableCellStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 11.5,
        height: 1.25,
      );
}

class WalletUserAvatar extends StatelessWidget {
  const WalletUserAvatar({super.key, required this.user, this.size = 36});

  final WalletUserEntity? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = user?.avatarUrl;

    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 3),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(scheme),
        ),
      );
    }

    return _fallback(scheme);
  }

  Widget _fallback(ColorScheme scheme) {
    final name = user?.displayName ?? '?';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
