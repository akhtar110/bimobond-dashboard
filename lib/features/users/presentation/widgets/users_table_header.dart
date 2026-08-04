import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../users_location_sort.dart';
import 'users_table_config.dart';

const double kUsersTableHeaderHeight = 36;

class UsersTableHeader extends StatelessWidget {
  const UsersTableHeader({
    super.key,
    required this.config,
    required this.locationSort,
    required this.onLocationSortTap,
  });

  final UsersTableConfig config;
  final UsersLocationSortOrder locationSort;
  final VoidCallback onLocationSortTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
      fontSize: 10,
      letterSpacing: 0.2,
    );

    return Container(
      height: kUsersTableHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: scheme.surfaceContainerLow,
      child: Row(
        children: [
          SizedBox(
            width: config.checkboxWidth,
            child: Text('', style: labelStyle),
          ),
          Expanded(
            flex: config.showAccount ? 26 : 32,
            child: Text(l10n.t('userColumn'), style: labelStyle),
          ),
          if (config.showAccount)
            Expanded(
              flex: 20,
              child: Text(l10n.t('accountColumn'), style: labelStyle),
            ),
          const SizedBox(width: 8),
          Expanded(
            flex: 13,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l10n.t('status'), style: labelStyle),
            ),
          ),
          if (config.showOnlineStatus) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 16,
              child: Text(
                l10n.tOr('onlineStatus', 'Online / Last Seen'),
                style: labelStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (config.showEngagement) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 14,
              child: Text(l10n.t('engagement'), style: labelStyle),
            ),
          ],
          if (config.showLocation) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 14,
              child: _LocationSortHeader(
                label: l10n.t('location'),
                labelStyle: labelStyle,
                sort: locationSort,
                onTap: onLocationSortTap,
              ),
            ),
          ],
          Expanded(
            flex: config.showAccount ? 26 : 30,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(l10n.t('actions'), style: labelStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationSortHeader extends StatelessWidget {
  const _LocationSortHeader({
    required this.label,
    required this.labelStyle,
    required this.sort,
    required this.onTap,
  });

  final String label;
  final TextStyle? labelStyle;
  final UsersLocationSortOrder sort;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = sort != UsersLocationSortOrder.none;

    final IconData icon;
    switch (sort) {
      case UsersLocationSortOrder.ascending:
        icon = Icons.arrow_upward_rounded;
      case UsersLocationSortOrder.descending:
        icon = Icons.arrow_downward_rounded;
      case UsersLocationSortOrder.none:
        icon = Icons.unfold_more_rounded;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle?.copyWith(
                    color: active ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                icon,
                size: 14,
                color: active ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
