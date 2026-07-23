import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/admin_settings_bloc.dart';

/// KPI overview strip for admin settings.
class SettingsOverviewCards extends StatelessWidget {
  const SettingsOverviewCards({super.key});

  static const _stripHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminSettingsBloc, AdminSettingsState>(
      buildWhen: (prev, next) =>
          prev.isLoading != next.isLoading ||
          prev.totalSettings != next.totalSettings ||
          prev.publicCount != next.publicCount ||
          prev.privateCount != next.privateCount ||
          prev.currencyCount != next.currencyCount ||
          prev.featureFlagCount != next.featureFlagCount ||
          prev.uploadSettingsCount != next.uploadSettingsCount,
      builder: (context, state) {
        if (state.isLoading && state.settings.isEmpty) {
          return const _SettingsOverviewSkeleton();
        }

        final l10n = context.l10n;
        final number = NumberFormat.compact();

        final items = [
          (
            l10n.tOr('settingsKpiTotal', 'Total'),
            number.format(state.totalSettings),
            Icons.tune_outlined,
          ),
          (
            l10n.tOr('settingsKpiPublic', 'Public'),
            number.format(state.publicCount),
            Icons.public_outlined,
          ),
          (
            l10n.tOr('settingsKpiPrivate', 'Private'),
            number.format(state.privateCount),
            Icons.lock_outline,
          ),
          (
            l10n.tOr('settingsKpiCurrencies', 'Currencies'),
            number.format(state.currencyCount),
            Icons.payments_outlined,
          ),
          (
            l10n.tOr('settingsKpiFeatureFlags', 'Feature flags'),
            number.format(state.featureFlagCount),
            Icons.flag_outlined,
          ),
          (
            l10n.tOr('settingsKpiUploadSettings', 'Upload settings'),
            number.format(state.uploadSettingsCount),
            Icons.cloud_upload_outlined,
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final useWrap = constraints.maxWidth < 720;

            final tiles = [
              for (final item in items)
                _OverviewKpiTile(
                  label: item.$1,
                  value: item.$2,
                  icon: item.$3,
                ),
            ];

            if (useWrap) {
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: tiles,
              );
            }

            return SizedBox(
              height: _stripHeight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.hardEdge,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      tiles[i],
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SettingsOverviewSkeleton extends StatelessWidget {
  const _SettingsOverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const widths = [72.0, 68.0, 78.0, 84.0, 92.0, 96.0];

    return SizedBox(
      height: SettingsOverviewCards._stripHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            for (var i = 0; i < widths.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Container(
                width: widths[i],
                height: SettingsOverviewCards._stripHeight,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverviewKpiTile extends StatelessWidget {
  const _OverviewKpiTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: '$value · $label',
      child: Container(
        constraints: const BoxConstraints(
          minHeight: SettingsOverviewCards._stripHeight,
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(10, 5, 12, 5),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: scheme.primary),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                        height: 1.15,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
