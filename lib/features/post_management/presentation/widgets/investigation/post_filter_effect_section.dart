import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/localization.dart';
import '../../../../../core/utils/media_url_resolver.dart';
import '../../../domain/entities/post_applied_catalog_ref.dart';
import '../../bloc/post_management_bloc.dart';
import 'investigation_theme.dart';
import 'post_surface_card.dart';

class PostFilterEffectSection extends StatelessWidget {
  const PostFilterEffectSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostManagementBloc, PostManagementState>(
      buildWhen: (prev, curr) {
        if (curr is! PostManagementLoaded) return false;
        if (prev is! PostManagementLoaded) return true;
        return prev.post.appliedFilter != curr.post.appliedFilter ||
            prev.post.appliedEffect != curr.post.appliedEffect ||
            prev.isFilterEffectLoading != curr.isFilterEffectLoading ||
            prev.filterEffectError != curr.filterEffectError ||
            prev.postFilter?.id != curr.postFilter?.id ||
            prev.postEffect?.id != curr.postEffect?.id;
      },
      builder: (context, state) {
        if (state is! PostManagementLoaded) return const SizedBox.shrink();

        final appliedFilter = state.post.appliedFilter;
        final appliedEffect = state.post.appliedEffect;
        final hasFilter = appliedFilter?.hasData ?? false;
        final hasEffect = appliedEffect?.hasData ?? false;

        if (!hasFilter &&
            !hasEffect &&
            !state.isFilterEffectLoading &&
            state.postFilter == null &&
            state.postEffect == null) {
          return const SizedBox.shrink();
        }

        final l10n = context.l10n;
        final theme = Theme.of(context);

        return PostSurfaceCard(
          dense: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.tOr('postFilterEffectTitle', 'Filter & effect'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: InvestigationTheme.s8),
              if (state.isFilterEffectLoading &&
                  state.postFilter == null &&
                  state.postEffect == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              else ...[
                if (hasFilter)
                  _FilterEffectTile(
                    icon: Icons.auto_fix_high_outlined,
                    label: l10n.tOr('filter', 'Filter'),
                    entityLabel: state.postFilter?.displayLabel,
                    appliedRef: appliedFilter,
                    thumbnailUrl: state.postFilter?.thumbnailUrl ??
                        appliedFilter?.thumbnailUrl,
                    emoji: state.postFilter?.emoji ?? appliedFilter?.emoji,
                    isActive: state.postFilter?.isActive,
                  ),
                if (hasFilter && hasEffect)
                  const SizedBox(height: InvestigationTheme.s8),
                if (hasEffect)
                  _FilterEffectTile(
                    icon: Icons.face_retouching_natural_outlined,
                    label: l10n.tOr('effect', 'Effect'),
                    entityLabel: state.postEffect?.displayLabel,
                    appliedRef: appliedEffect,
                    thumbnailUrl: state.postEffect?.thumbnailUrl ??
                        appliedEffect?.thumbnailUrl,
                    emoji: state.postEffect?.emoji ?? appliedEffect?.emoji,
                    isActive: state.postEffect?.isActive,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FilterEffectTile extends StatelessWidget {
  const _FilterEffectTile({
    required this.icon,
    required this.label,
    required this.appliedRef,
    this.entityLabel,
    this.thumbnailUrl,
    this.emoji,
    this.isActive,
  });

  final IconData icon;
  final String label;
  final PostAppliedCatalogRef? appliedRef;
  final String? entityLabel;
  final String? thumbnailUrl;
  final String? emoji;
  final bool? isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final title = entityLabel?.trim().isNotEmpty == true
        ? entityLabel!.trim()
        : appliedRef?.primaryLabel ?? '';
    final resolvedThumb = resolveMediaUrl(thumbnailUrl);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Thumb(
            icon: icon,
            imageUrl: resolvedThumb,
            emoji: emoji,
            scheme: scheme,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isActive != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    isActive!
                        ? l10n.tOr('active', 'Active')
                        : l10n.tOr('inactive', 'Inactive'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isActive!
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.icon,
    required this.scheme,
    this.imageUrl,
    this.emoji,
  });

  final IconData icon;
  final ColorScheme scheme;
  final String? imageUrl;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _iconBox(size),
        ),
      );
    }
    if (emoji?.trim().isNotEmpty == true) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(emoji!.trim(), style: const TextStyle(fontSize: 20)),
      );
    }
    return _iconBox(size);
  }

  Widget _iconBox(double size) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: scheme.primary),
    );
  }
}
