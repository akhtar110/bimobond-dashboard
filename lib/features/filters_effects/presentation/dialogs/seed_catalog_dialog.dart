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
          Icon(Icons.warning_amber_rounded, color: scheme.error),
          const SizedBox(width: 10),
          Expanded(child: Text(l10n.tOr('feSeedDefaults', 'Seed defaults'))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.error.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.delete_forever_rounded, color: scheme.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.tOr(
                        'feSeedWarning',
                        'Destructive action: this permanently replaces the live '
                            'camera catalog with seeded defaults. Existing custom '
                            'filters, effects, categories, and publish history on '
                            'this environment can be overwritten and are not easy '
                            'to restore.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.tOr(
              'feSeedDefaultsMessage',
              'Only continue if you intentionally want to reset this catalog.',
            ),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
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
