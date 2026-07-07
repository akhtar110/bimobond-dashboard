import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';

void showSeedCatalogDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => BlocProvider.value(
      value: context.read<FiltersEffectsBloc>(),
      child: const SeedCatalogDialog(),
    ),
  );
}

class SeedCatalogDialog extends StatelessWidget {
  const SeedCatalogDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.grass_rounded, color: scheme.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l10n.tOr('feSeedDefaults', 'Seed defaults')),
          ),
        ],
      ),
      content: Text(
        l10n.tOr(
          'feSeedDefaultsMessage',
          'This will replace the catalog with default filters and effects. Continue?',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: () {
            context.read<FiltersEffectsBloc>().add(
                  const SeedFiltersEffectsCatalogEvent(),
                );
            Navigator.of(context).pop();
          },
          child: Text(l10n.tOr('feSeedConfirm', 'Seed catalog')),
        ),
      ],
    );
  }
}
