import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../utils/filters_effects_responsive.dart';

class FiltersEffectsTabBar extends StatelessWidget {
  const FiltersEffectsTabBar({
    super.key,
    required this.activeTab,
    required this.metrics,
  });

  final FiltersEffectsTab activeTab;
  final FiltersEffectsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final tabs = <(FiltersEffectsTab, String)>[
      (FiltersEffectsTab.filters, l10n.tOr('feFilters', 'Filters')),
      (
        FiltersEffectsTab.filterCategories,
        l10n.tOr('feFilterCategories', 'Filter categories'),
      ),
      (FiltersEffectsTab.effects, l10n.tOr('feEffects', 'Effects')),
      (
        FiltersEffectsTab.effectCategories,
        l10n.tOr('feEffectCategories', 'Effect categories'),
      ),
      (FiltersEffectsTab.catalog, l10n.tOr('feCatalog', 'Catalog')),
    ];

    final chips = [
      for (final tab in tabs)
        Padding(
          padding: EdgeInsetsDirectional.only(
            end: metrics.filterGap,
          ),
          child: ChoiceChip(
            label: Text(
              tab.$2,
              overflow: TextOverflow.ellipsis,
            ),
            selected: activeTab == tab.$1,
            onSelected: (_) {
              context.read<FiltersEffectsBloc>().add(
                    FiltersEffectsTabChanged(tab.$1),
                  );
            },
          ),
        ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(metrics.filterGap),
        child: metrics.isMobile
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: chips),
              )
            : Wrap(
                spacing: 0,
                runSpacing: metrics.filterGap,
                children: chips,
              ),
      ),
    );
  }
}
