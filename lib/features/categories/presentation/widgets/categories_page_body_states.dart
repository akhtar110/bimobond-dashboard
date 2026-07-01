import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import 'category_form_dialog.dart';

class CategoriesLoadingView extends StatelessWidget {
  const CategoriesLoadingView({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: scheme.primary),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.t('loading'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ]),
    );
  }
}

class CategoriesEmptyView extends StatelessWidget {
  const CategoriesEmptyView({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primary = scheme.primary;
    final outlineBorder = scheme.outlineVariant;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: outlineBorder),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: 0.15),
                    primary.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: primary.withValues(alpha: 0.2)),
              ),
              child:
                  Icon(Icons.category_outlined, size: 40, color: primary),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.t('noCategoriesYet'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.t('createFirstCategoryHint'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => showCategoryForm(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.t('createFirstCategory')),
              style: FilledButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class CategoriesErrorView extends StatelessWidget {
  const CategoriesErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final danger = scheme.error;
    final outlineBorder = scheme.outlineVariant;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: danger.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 36, color: danger),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.t('couldNotLoadCategories'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.t('tryAgain')),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: outlineBorder),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
