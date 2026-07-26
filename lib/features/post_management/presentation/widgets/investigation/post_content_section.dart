import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/localization/localization.dart';
import '../../../../categories/presentation/bloc/categories_bloc.dart';
import '../../../../categories/presentation/widgets/category_icon.dart';
import '../../../domain/entities/managed_post_entity.dart';
import '../../utils/post_detail_labels.dart';
import 'engagement_metric_cards.dart';
import 'investigation_theme.dart';
import 'post_preview_card.dart';
import 'post_surface_card.dart';

class PostContentSection extends StatelessWidget {
  const PostContentSection({
    super.key,
    required this.draft,
    required this.isBusy,
    this.hideComments = false,
    required this.captionController,
    required this.onCaptionChanged,
    required this.onCategorySelected,
    required this.onPrivacyChanged,
  });

  final ManagedPostEntity draft;
  final bool isBusy;
  final bool hideComments;
  final TextEditingController captionController;
  final VoidCallback onCaptionChanged;
  final void Function(CategoryEntity) onCategorySelected;
  final ValueChanged<String> onPrivacyChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PostPreviewCard(post: draft),
        const SizedBox(height: InvestigationTheme.s12),
        PostSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.t('postInformation'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: InvestigationTheme.s12),
              BlocBuilder<CategoriesBloc, CategoriesState>(
                builder: (context, catState) {
                  final categoryLabel = _resolveCategoryLabel(draft, catState);
                  return Wrap(
                    spacing: InvestigationTheme.s8,
                    runSpacing: InvestigationTheme.s8,
                    children: [
                      if (categoryLabel != null && categoryLabel.isNotEmpty)
                        _Badge(
                          icon: Icons.category_outlined,
                          label: categoryLabel,
                          color: scheme.primary,
                        ),
                      _Badge(
                        icon: Icons.lock_outline_rounded,
                        label: privacyLabel(l10n, draft.privacyStatus),
                        color: scheme.secondary,
                      ),
                      _StatusBadge(status: draft.status, l10n: l10n),
                    ],
                  );
                },
              ),
              const SizedBox(height: InvestigationTheme.s12),
              _PostInfoRow(
                icon: Icons.category_outlined,
                label: l10n.t('type'),
                // Image + attached sound is still IMAGE (not VIDEO).
                value: draft.displayContentType,
              ),
              const SizedBox(height: InvestigationTheme.s8),
              _PostInfoRow(
                icon: Icons.calendar_today_outlined,
                label: l10n.t('created'),
                value: DateFormat('MMM dd, yyyy · HH:mm').format(draft.createdAt),
              ),
              if (draft.media.isNotEmpty) ...[
                const SizedBox(height: InvestigationTheme.s8),
                _PostInfoRow(
                  icon: Icons.collections_outlined,
                  label: l10n.tOr('mediaItems', 'Media items'),
                  value: '${draft.media.length}',
                ),
              ],
              const SizedBox(height: InvestigationTheme.s16),
              TextField(
                controller: captionController,
                maxLines: 4,
                enabled: !isBusy,
                onChanged: (_) => onCaptionChanged(),
                decoration: InvestigationTheme.fieldDecoration(
                  context,
                  labelText: l10n.t('caption'),
                ),
              ),
              const SizedBox(height: InvestigationTheme.s12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final sideBySide = constraints.maxWidth >= 480;
                  final category = _CategoryDropdown(
                    draft: draft,
                    isBusy: isBusy,
                    onCategorySelected: onCategorySelected,
                  );
                  final privacy = DropdownButtonFormField<String>(
                    initialValue: const ['PUBLIC', 'PRIVATE', 'FRIENDS']
                            .contains(draft.privacyStatus)
                        ? draft.privacyStatus
                        : 'PUBLIC',
                    decoration: InvestigationTheme.fieldDecoration(
                      context,
                      labelText: l10n.t('privacy'),
                    ),
                    items: const ['PUBLIC', 'PRIVATE', 'FRIENDS']
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(privacyLabel(l10n, v)),
                          ),
                        )
                        .toList(),
                    onChanged: isBusy
                        ? null
                        : (v) => v != null ? onPrivacyChanged(v) : null,
                  );
                  if (!sideBySide) {
                    return Column(
                      children: [
                        category,
                        const SizedBox(height: InvestigationTheme.s12),
                        privacy,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: category),
                      const SizedBox(width: InvestigationTheme.s12),
                      Expanded(child: privacy),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: InvestigationTheme.s12),
        PostSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.t('engagementSummary'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: InvestigationTheme.s12),
              EngagementMetricCards(
                metrics: [
                  (
                    icon: Icons.favorite_border_rounded,
                    label: l10n.t('likes'),
                    value: draft.likeCount,
                    accent: scheme.error,
                  ),
                  if (!hideComments)
                    (
                      icon: Icons.chat_bubble_outline_rounded,
                      label: l10n.t('comments'),
                      value: draft.commentCount,
                      accent: scheme.primary,
                    ),
                  (
                    icon: Icons.repeat_rounded,
                    label: l10n.t('reposts'),
                    value: draft.repostCount,
                    accent: scheme.tertiary,
                  ),
                  (
                    icon: Icons.visibility_outlined,
                    label: l10n.t('views'),
                    value: draft.viewCount,
                    accent: scheme.secondary,
                  ),
                  (
                    icon: Icons.share_outlined,
                    label: l10n.t('shares'),
                    value: draft.shareCount,
                    accent: scheme.tertiary,
                  ),
                  (
                    icon: Icons.bookmark_border_rounded,
                    label: l10n.t('saves'),
                    value: draft.saveCount,
                    accent: scheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: InvestigationTheme.s12),
              Text(
                context.tr('postTimestamps', {
                  'created': DateFormat('MMM dd, yyyy · HH:mm')
                      .format(draft.createdAt),
                  'updated': DateFormat('MMM dd, yyyy · HH:mm')
                      .format(draft.updatedAt),
                }),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostInfoRow extends StatelessWidget {
  const _PostInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.l10n});
  final String status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    final scheme = Theme.of(context).colorScheme;
    final color = postStatusColorFromScheme(scheme, s);
    return _Badge(
      icon: postStatusIcon(s),
      label: postStatusLabel(l10n, s),
      color: color,
    );
  }
}

String? _resolveCategoryLabel(ManagedPostEntity draft, CategoriesState catState) {
  if (draft.category != null && draft.category!.trim().isNotEmpty) {
    return draft.category;
  }

  final entityId = draft.categoryEntity?.id;
  if (entityId != null &&
      entityId.isNotEmpty &&
      catState is CategoriesLoaded) {
    for (final cat in catState.catalogCategories) {
      if (cat.id == entityId) return cat.name;
    }
  }

  return null;
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.draft,
    required this.isBusy,
    required this.onCategorySelected,
  });

  final ManagedPostEntity draft;
  final bool isBusy;
  final void Function(CategoryEntity) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<CategoriesBloc, CategoriesState>(
      builder: (context, catState) {
        if (catState is CategoriesInitial || catState is CategoriesLoading) {
          return InputDecorator(
            decoration: InvestigationTheme.fieldDecoration(
              context,
              labelText: l10n.t('categoryName'),
            ),
            child: const SizedBox(
              height: 20,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        if (catState is! CategoriesLoaded) return const SizedBox.shrink();

        final cats = catState.catalogCategories;
        String? resolvedId = draft.categoryEntity?.id;
        if (resolvedId == null || !cats.any((c) => c.id == resolvedId)) {
          final categoryName = draft.category?.trim();
          if (categoryName != null && categoryName.isNotEmpty) {
            resolvedId = cats
                .where(
                  (c) => c.name.toLowerCase() == categoryName.toLowerCase(),
                )
                .map((c) => c.id)
                .firstOrNull;
          }
        }
        final selectedId =
            (resolvedId != null && cats.any((c) => c.id == resolvedId))
                ? resolvedId
                : null;

        return DropdownButtonFormField<String?>(
          key: ValueKey('cat_${draft.id}_${selectedId ?? draft.category ?? ''}'),
          initialValue: selectedId,
          isExpanded: true,
          decoration: InvestigationTheme.fieldDecoration(
            context,
            labelText: l10n.t('categoryName'),
          ),
          items: cats
              .map(
                (cat) => DropdownMenuItem<String?>(
                  value: cat.id,
                  child: CategoryIconLabel(
                    category: cat,
                    prefix: cat.isRoot ? null : '  ↳ ',
                  ),
                ),
              )
              .toList(),
          onChanged: isBusy
              ? null
              : (picked) {
                  if (picked == null) return;
                  final selected = cats.firstWhere((c) => c.id == picked);
                  onCategorySelected(selected);
                },
        );
      },
    );
  }
}
