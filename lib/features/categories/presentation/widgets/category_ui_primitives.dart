import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

class CategoryStatusBadge extends StatelessWidget {
  const CategoryStatusBadge({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final color = isActive ? scheme.tertiary : scheme.onSurfaceVariant;
    final bg = isActive
        ? scheme.tertiaryContainer.withValues(alpha: 0.5)
        : scheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        isActive ? l10n.t('active') : l10n.t('inactive'),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class CategoryStatusDot extends StatelessWidget {
  const CategoryStatusDot({super.key, required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

String formatCategoryCount(int count) {
  if (count >= 1000) {
    final k = count / 1000;
    return k >= 10 ? '${k.round()}K' : '${k.toStringAsFixed(1)}K';
  }
  return '$count';
}

String formatCategoryDate(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

const categoryPalette = [
  Color(0xFF6366F1),
  Color(0xFF0EA5E9),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFFEC4899),
  Color(0xFF8B5CF6),
  Color(0xFF14B8A6),
];

Color categoryAccentColor(String slug, String name) {
  final key = slug.isNotEmpty ? slug : name.toLowerCase();
  final idx = key.codeUnits.fold(0, (a, b) => a + b) % categoryPalette.length;
  return categoryPalette[idx];
}
