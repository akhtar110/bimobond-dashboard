import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/empty_state_card.dart';
import '../bloc/admin_settings_bloc.dart';
import 'settings_group_card.dart';

/// All categories in collapsible groups using filtered settings.
class GeneralSettingsTab extends StatelessWidget {
  const GeneralSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<AdminSettingsBloc, AdminSettingsState>(
      buildWhen: (prev, next) =>
          prev.filteredGrouped != next.filteredGrouped ||
          prev.isLoading != next.isLoading,
      builder: (context, state) {
        if (state.isLoading && state.settings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final grouped = state.filteredGrouped;
        if (grouped.isEmpty) {
          return EmptyStateCard(
            icon: Icons.settings_outlined,
            title: l10n.tOr('noSettings', 'No settings'),
            message: l10n.tOr(
              'settingsNoResultsMessage',
              'Try adjusting search or filters.',
            ),
          );
        }

        final categories = grouped.keys.toList()..sort();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < categories.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              SettingsGroupCard(
                category: categories[i],
                settings: grouped[categories[i]]!,
                initiallyExpanded: i == 0,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Dedicated panel for settings in a single category.
class CategorySettingsTab extends StatelessWidget {
  const CategorySettingsTab({
    super.key,
    required this.category,
    this.keyFilter,
    this.emptyIcon = Icons.settings_outlined,
  });

  final String category;
  final Iterable<String>? keyFilter;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<AdminSettingsBloc, AdminSettingsState>(
      buildWhen: (prev, next) =>
          prev.filteredSettings != next.filteredSettings ||
          prev.isLoading != next.isLoading ||
          prev.isSaving != next.isSaving,
      builder: (context, state) {
        if (state.isLoading && state.settings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        var settings = state.settingsForCategory(category);
        if (keyFilter != null) {
          final keys = keyFilter!.toSet();
          settings = settings.where((s) => keys.contains(s.key)).toList();
        }

        if (settings.isEmpty) {
          return EmptyStateCard(
            icon: emptyIcon,
            title: l10n.tOr('noSettings', 'No settings'),
            message: l10n.tOr(
              'settingsCategoryEmpty',
              'No settings in this category.',
            ),
          );
        }

        return SettingsGroupCard(
          category: category,
          settings: settings,
        );
      },
    );
  }
}
