import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../rbac/presentation/bloc/rbac_bloc.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../dialogs/publish_catalog_dialog.dart';
import '../dialogs/seed_catalog_dialog.dart';
import '../utils/filters_effects_responsive.dart';

/// Title + refresh / publish / seed actions (search & filters live below).
class FiltersEffectsHeader extends StatelessWidget {
  const FiltersEffectsHeader({
    super.key,
    required this.metrics,
    this.isLoading = false,
  });

  final FiltersEffectsLayoutMetrics metrics;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final compact = metrics.isCompact;

    context.select<RbacBloc, Set<String>?>(
      (b) => b.state.authContext?.permissionKeys,
    );
    final canManage = PermissionManager.canManageCameraStudio(context);

    final titleStyle =
        (compact
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.headlineSmall)
            ?.copyWith(fontWeight: FontWeight.w800);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact) ...[
          Text(
            l10n.tOr('feModuleTitle', 'Filters & Effects'),
            textAlign: TextAlign.start,
            style: titleStyle,
          ),
          SizedBox(height: metrics.toolbarFilterGap),
          Text(
            l10n.tOr(
              'feModuleSubtitle',
              'Manage camera studio filters, effects, categories, and catalog publishing.',
            ),
            textAlign: TextAlign.start,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: metrics.toolbarSectionGap),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(
              spacing: metrics.filterGap,
              runSpacing: metrics.filterGap,
              children: [
                _RefreshButton(isLoading: isLoading),
                if (canManage) ...[
                  _PublishButton(compact: true),
                  _SeedButton(compact: true),
                ],
              ],
            ),
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.tOr('feModuleTitle', 'Filters & Effects'),
                      textAlign: TextAlign.start,
                      style: titleStyle,
                    ),
                    SizedBox(height: metrics.toolbarFilterGap),
                    Text(
                      l10n.tOr(
                        'feModuleSubtitle',
                        'Manage camera studio filters, effects, categories, and catalog publishing.',
                      ),
                      textAlign: TextAlign.start,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: metrics.filterGap),
              _RefreshButton(isLoading: isLoading),
              if (canManage) ...[
                SizedBox(width: metrics.filterGap),
                const _PublishButton(),
                SizedBox(width: metrics.filterGap),
                const _SeedButton(),
              ],
            ],
          ),
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IconButton(
      tooltip: l10n.tOr('feRefresh', 'Refresh'),
      onPressed: isLoading
          ? null
          : () => context.read<FiltersEffectsBloc>().add(
              const LoadFiltersEffects(),
            ),
      icon: const Icon(Icons.refresh_rounded),
    );
  }
}

class _PublishButton extends StatelessWidget {
  const _PublishButton({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return compact
        ? IconButton(
            tooltip: l10n.tOr('fePublishCatalog', 'Publish catalog'),
            onPressed: () => showPublishCatalogDialog(context),
            icon: const Icon(Icons.publish_rounded),
          )
        : OutlinedButton.icon(
            onPressed: () => showPublishCatalogDialog(context),
            icon: const Icon(Icons.publish_rounded, size: 18),
            label: Text(l10n.tOr('fePublishCatalog', 'Publish catalog')),
          );
  }
}

class _SeedButton extends StatelessWidget {
  const _SeedButton({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return compact
        ? IconButton(
            tooltip: l10n.tOr('feSeedDefaults', 'Seed defaults'),
            onPressed: () => showSeedCatalogDialog(context),
            icon: const Icon(Icons.grass_rounded),
          )
        : FilledButton.tonalIcon(
            onPressed: () => showSeedCatalogDialog(context),
            icon: const Icon(Icons.grass_rounded, size: 18),
            label: Text(l10n.tOr('feSeedDefaults', 'Seed defaults')),
          );
  }
}
