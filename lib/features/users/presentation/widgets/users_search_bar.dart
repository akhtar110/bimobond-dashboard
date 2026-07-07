import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../utils/responsive.dart';

class UsersSearchBar extends StatelessWidget {
  const UsersSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.metrics,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final UsersLayoutMetrics metrics;

  static const _borderRadius = 14.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final compact = metrics.isMobile;

    final borderRadius = BorderRadius.circular(_borderRadius);
    final enabledBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: scheme.primary, width: 1.5),
    );

    final verticalPadding = (metrics.searchFieldHeight - 20) / 2;

    return SizedBox(
      height: metrics.searchFieldHeight,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: compact ? 14 : null,
        ),
        decoration: InputDecoration(
          hintText: l10n.t('searchUsers'),
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: compact ? 14 : null,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: scheme.onSurfaceVariant,
            size: compact ? 20 : 22,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: l10n.t('clear'),
                icon: Icon(
                  Icons.close_rounded,
                  size: compact ? 18 : 20,
                  color: scheme.onSurfaceVariant,
                ),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  controller.clear();
                  onSubmitted('');
                },
              );
            },
          ),
          filled: true,
          fillColor: scheme.surface,
          isDense: true,
          contentPadding: EdgeInsetsDirectional.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: verticalPadding,
          ),
          border: enabledBorder,
          enabledBorder: enabledBorder,
          focusedBorder: focusedBorder,
          disabledBorder: enabledBorder,
          errorBorder: enabledBorder,
          focusedErrorBorder: focusedBorder,
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}
