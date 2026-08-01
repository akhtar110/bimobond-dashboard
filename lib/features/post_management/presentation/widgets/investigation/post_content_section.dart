import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/localization.dart';
import '../../../../categories/presentation/bloc/categories_bloc.dart';
import '../../../../categories/presentation/widgets/category_icon.dart';
import '../../../../posts/presentation/utils/post_date_format.dart';
import '../../../domain/entities/managed_post_entity.dart';
import '../../utils/post_detail_labels.dart';
import 'engagement_metric_cards.dart';
import 'investigation_theme.dart';
import 'post_location_section.dart';
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
    final locale = Localizations.localeOf(context).languageCode;
    final width = MediaQuery.sizeOf(context).width;
    final showPreview = width < InvestigationTheme.threeColumn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPreview) ...[
          PostPreviewCard(post: draft, dense: true),
          const SizedBox(height: InvestigationTheme.s8),
        ],
        PostSurfaceCard(
          dense: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wideMeta = constraints.maxWidth >= 560;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.t('postInformation'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: InvestigationTheme.s8),
                  BlocBuilder<CategoriesBloc, CategoriesState>(
                    builder: (context, catState) {
                      final categoryLabel =
                          _resolveCategoryLabel(draft, catState);
                      return Wrap(
                        spacing: InvestigationTheme.s8,
                        runSpacing: InvestigationTheme.s8,
                        children: [
                          if (categoryLabel != null &&
                              categoryLabel.isNotEmpty)
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
                  if (wideMeta)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _PostMetaFacts(
                            draft: draft,
                            locale: locale,
                            l10n: l10n,
                          ),
                        ),
                        const SizedBox(width: InvestigationTheme.s16),
                        Expanded(
                          flex: 2,
                          child: PostLocationSection(location: draft.location),
                        ),
                      ],
                    )
                  else ...[
                    _PostMetaFacts(
                      draft: draft,
                      locale: locale,
                      l10n: l10n,
                    ),
                    const SizedBox(height: InvestigationTheme.s12),
                    Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: InvestigationTheme.s12),
                    PostLocationSection(location: draft.location),
                  ],
                  const SizedBox(height: InvestigationTheme.s12),
                  TextField(
                    controller: captionController,
                    maxLines: 3,
                    enabled: !isBusy,
                    onChanged: (_) => onCaptionChanged(),
                    decoration: InvestigationTheme.fieldDecoration(
                      context,
                      labelText: l10n.t('caption'),
                    ),
                  ),
                  const SizedBox(height: InvestigationTheme.s12),
                  LayoutBuilder(
                    builder: (context, fieldConstraints) {
                      final sideBySide =
                          fieldConstraints.maxWidth >=
                          InvestigationTheme.compact + 80;
                      final category = _CategoryDropdown(
                        draft: draft,
                        isBusy: isBusy,
                        onCategorySelected: onCategorySelected,
                      );
                      final privacy = DropdownButtonFormField<String>(
                        initialValue:
                            const [
                              'PUBLIC',
                              'PRIVATE',
                              'FRIENDS',
                            ].contains(draft.privacyStatus)
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
                            const SizedBox(height: InvestigationTheme.s8),
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
              );
            },
          ),
        ),
        const SizedBox(height: InvestigationTheme.s8),
        PostSurfaceCard(
          dense: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.t('engagementSummary'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    _updatedLabel(l10n, draft, locale),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: InvestigationTheme.s8),
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
            ],
          ),
        ),
      ],
    );
  }

  String _updatedLabel(AppLocalizations l10n, ManagedPostEntity draft, String locale) {
    final stamp = formatPostCreatedDateTime(
      draft.updatedAt,
      locale: locale,
      compact: true,
    );
    if (draft.updatedAt.difference(draft.createdAt).inMinutes.abs() < 1) {
      return l10n.tOr('createdAtShort', 'Created $stamp');
    }
    return l10n.tOr('updatedAtShort', 'Updated $stamp');
  }
}

class _PostMetaFacts extends StatelessWidget {
  const _PostMetaFacts({
    required this.draft,
    required this.locale,
    required this.l10n,
  });

  final ManagedPostEntity draft;
  final String locale;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final facts = <({IconData icon, String label, String value})>[
      (
        icon: Icons.category_outlined,
        label: l10n.t('type'),
        value: draft.displayContentType,
      ),
      (
        icon: Icons.calendar_today_outlined,
        label: l10n.t('created'),
        value: formatPostCreatedDateTime(
          draft.createdAt,
          locale: locale,
          compact: true,
        ),
      ),
      if (draft.media.isNotEmpty)
        (
          icon: Icons.collections_outlined,
          label: l10n.tOr('mediaItems', 'Media items'),
          value: '${draft.media.length}',
        ),
    ];

    return Wrap(
      spacing: InvestigationTheme.s8,
      runSpacing: InvestigationTheme.s8,
      children: facts
          .map(
            (fact) => _MetaFactChip(
              icon: fact.icon,
              label: fact.label,
              value: fact.value,
              color: scheme.onSurfaceVariant,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MetaFactChip extends StatelessWidget {
  const _MetaFactChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InvestigationTheme.s8,
        vertical: InvestigationTheme.s8,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.color});

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

String? _resolveCategoryLabel(
  ManagedPostEntity draft,
  CategoriesState catState,
) {
  if (draft.category != null && draft.category!.trim().isNotEmpty) {
    return draft.category;
  }

  final entityId = draft.categoryEntity?.id;
  if (entityId != null && entityId.isNotEmpty && catState is CategoriesLoaded) {
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
          key: ValueKey(
            'cat_${draft.id}_${selectedId ?? draft.category ?? ''}',
          ),
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
