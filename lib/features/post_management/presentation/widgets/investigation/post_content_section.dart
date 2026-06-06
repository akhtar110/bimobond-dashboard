import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/localization/localization.dart';
import '../../../../categories/presentation/bloc/categories_bloc.dart';
import '../../../domain/entities/managed_post_entity.dart';
import '../../utils/post_detail_labels.dart';
import '../post_media_carousel.dart';
import 'investigation_theme.dart';
import 'post_surface_card.dart';

class PostContentSection extends StatelessWidget {
  const PostContentSection({
    super.key,
    required this.draft,
    required this.isBusy,
    required this.captionController,
    required this.onCaptionChanged,
    required this.onCategorySelected,
    required this.onPrivacyChanged,
  });

  final ManagedPostEntity draft;
  final bool isBusy;
  final TextEditingController captionController;
  final VoidCallback onCaptionChanged;
  final void Function(CategoryEntity) onCategorySelected;
  final ValueChanged<String> onPrivacyChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PostSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Wrap(
              spacing: InvestigationTheme.s8,
              runSpacing: InvestigationTheme.s8,
              children: [
                if (draft.category != null && draft.category!.isNotEmpty)
                  _Badge(
                    icon: Icons.category_outlined,
                    label: draft.category!,
                    color: const Color(0xFF6366F1),
                    isDark: isDark,
                  ),
                _Badge(
                  icon: Icons.lock_outline_rounded,
                  label: privacyLabel(l10n, draft.privacyStatus),
                  color: const Color(0xFF64748B),
                  isDark: isDark,
                ),
                _StatusBadge(status: draft.status, l10n: l10n),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.zero,
              top: Radius.zero,
            ),
            child: PostMediaCarousel(post: draft, height: 360),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.t('postInformation'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: InvestigationTheme.s12),
                TextField(
                  controller: captionController,
                  maxLines: 4,
                  enabled: !isBusy,
                  onChanged: (_) => onCaptionChanged(),
                  decoration: InputDecoration(
                    labelText: l10n.t('caption'),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0F1421)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(InvestigationTheme.radiusSm),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(InvestigationTheme.radiusSm),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
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
                      decoration: InputDecoration(
                        labelText: l10n.t('privacy'),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F1421)
                            : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            InvestigationTheme.radiusSm,
                          ),
                        ),
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
                const SizedBox(height: InvestigationTheme.s16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F1421)
                        : const Color(0xFFF8FAFC),
                    borderRadius:
                        BorderRadius.circular(InvestigationTheme.radiusSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.t('engagementSummary'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: InvestigationTheme.mutedText(context, isDark),
                        ),
                      ),
                      const SizedBox(height: InvestigationTheme.s8),
                      Wrap(
                        spacing: InvestigationTheme.s16,
                        runSpacing: InvestigationTheme.s8,
                        children: [
                          _EngagementStat(
                            icon: Icons.visibility_outlined,
                            value: compactNumber(draft.viewCount),
                            isDark: isDark,
                          ),
                          _EngagementStat(
                            icon: Icons.favorite_border,
                            value: compactNumber(draft.likeCount),
                            isDark: isDark,
                          ),
                          _EngagementStat(
                            icon: Icons.chat_bubble_outline,
                            value: compactNumber(draft.commentCount),
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: InvestigationTheme.s8),
                      Text(
                        context.tr('postTimestamps', {
                          'created': DateFormat('MMM dd, yyyy · HH:mm')
                              .format(draft.createdAt),
                          'updated': DateFormat('MMM dd, yyyy · HH:mm')
                              .format(draft.updatedAt),
                        }),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: InvestigationTheme.mutedText(context, isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
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
    final color = postStatusColor(s);
    return _Badge(
      icon: postStatusIcon(s),
      label: postStatusLabel(l10n, s),
      color: color,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
  }
}

class _EngagementStat extends StatelessWidget {
  const _EngagementStat({
    required this.icon,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: InvestigationTheme.mutedText(context, isDark)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CategoriesBloc, CategoriesState>(
      builder: (context, catState) {
        if (catState is CategoriesInitial || catState is CategoriesLoading) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.t('categoryName'),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
              ),
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

        final cats = catState.categories;
        String? resolvedId = draft.categoryEntity?.id;
        if (resolvedId == null || !cats.any((c) => c.id == resolvedId)) {
          resolvedId = cats
              .where((c) => c.name == draft.category)
              .map((c) => c.id)
              .firstOrNull;
        }
        final selectedId =
            (resolvedId != null && cats.any((c) => c.id == resolvedId))
                ? resolvedId
                : null;

        return DropdownButtonFormField<String?>(
          initialValue: selectedId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.t('categoryName'),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F1421) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
            ),
          ),
          items: cats
              .map(
                (cat) => DropdownMenuItem<String?>(
                  value: cat.id,
                  child: Text(
                    cat.isRoot ? cat.name : '  ↳ ${cat.name}',
                    overflow: TextOverflow.ellipsis,
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
