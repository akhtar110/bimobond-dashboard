import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/category_entity.dart';

/// Displays a category icon from [iconUrl] or a themed placeholder.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    this.category,
    this.iconUrl,
    this.name,
    this.size = 24,
    this.borderRadius,
    this.backgroundColor,
    this.iconColor,
    this.fallbackIcon = Icons.category_rounded,
  });

  final CategoryEntity? category;
  final String? iconUrl;
  final String? name;
  final double size;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? iconColor;
  final IconData fallbackIcon;

  String? get _resolvedUrl {
    final raw = iconUrl ?? category?.iconUrl;
    if (raw == null || raw.trim().isEmpty) return null;
    return resolveMediaUrl(raw.trim());
  }

  String get _label => name ?? category?.name ?? '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(size * 0.28);
    final bg = backgroundColor ?? scheme.surfaceContainerHighest;
    final fg = iconColor ?? scheme.onSurfaceVariant;
    final url = _resolvedUrl;

    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: size,
          height: size,
          child: CachedNetworkImage(
            key: ValueKey(url),
            imageUrl: url,
            cacheKey: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => _Placeholder(
              size: size,
              radius: radius,
              backgroundColor: bg,
              iconColor: fg,
              icon: fallbackIcon,
            ),
            errorWidget: (_, __, ___) => _Placeholder(
              size: size,
              radius: radius,
              backgroundColor: bg,
              iconColor: fg,
              icon: fallbackIcon,
              label: _initial,
            ),
          ),
        ),
      );
    }

    return _Placeholder(
      size: size,
      radius: radius,
      backgroundColor: bg,
      iconColor: fg,
      icon: fallbackIcon,
      label: _initial,
    );
  }

  String get _initial {
    final n = _label.trim();
    if (n.isEmpty) return '';
    return n[0].toUpperCase();
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.size,
    required this.radius,
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    this.label,
  });

  final double size;
  final BorderRadius radius;
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final showLetter = label != null && label!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      child: showLetter
          ? Text(
              label!,
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.42,
              ),
            )
          : Icon(icon, size: size * 0.52, color: iconColor),
    );
  }
}

/// Row helper: icon + label for dropdowns and chips.
class CategoryIconLabel extends StatelessWidget {
  const CategoryIconLabel({
    super.key,
    required this.category,
    this.iconSize = 18,
    this.textStyle,
    this.maxLines = 1,
    this.prefix,
  });

  final CategoryEntity category;
  final double iconSize;
  final TextStyle? textStyle;
  final int maxLines;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CategoryIcon(category: category, size: iconSize),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${prefix ?? ''}${category.name}',
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ],
    );
  }
}
