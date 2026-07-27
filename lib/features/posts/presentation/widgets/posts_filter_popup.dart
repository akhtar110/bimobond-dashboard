import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/post_filters.dart';
import '../bloc/posts_bloc.dart';
import '../bloc/posts_filter_draft_cubit.dart';
import 'posts_filter_button.dart';

/// Opens the adaptive gifts-style filter panel for posts.
Future<void> showPostsFilterPopup({
  required BuildContext context,
  required PostFilters filters,
  required Rect anchorRect,
}) {
  final postsBloc = context.read<PostsBloc>();
  final width = MediaQuery.sizeOf(context).width;

  Widget wrap(Widget child) => MultiBlocProvider(
        providers: [
          BlocProvider<PostsBloc>.value(value: postsBloc),
          BlocProvider(create: (_) => PostsFilterDraftCubit(filters)),
        ],
        child: child,
      );

  if (width < 600) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: wrap(
          PostsFilterPopup(
            appliedFilters: filters,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
        ),
      ),
    );
  }

  if (width < 900) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: Align(
          alignment: Alignment.center,
          child: wrap(
            PostsFilterPopup(
              appliedFilters: filters,
              width: 400,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.78,
            ),
          ),
        ),
      ),
    );
  }

  const panelWidth = 380.0;
  final media = MediaQuery.sizeOf(context);
  final padding = MediaQuery.paddingOf(context);
  final isRtl = Directionality.of(context) == TextDirection.rtl;

  var left = isRtl ? anchorRect.right - panelWidth : anchorRect.left;
  left = left.clamp(12.0, media.width - panelWidth - 12);
  var top = anchorRect.bottom + 8;
  final maxPanelHeight = media.height * 0.72;
  if (top + 320 > media.height - padding.bottom) {
    top = (anchorRect.top - 8 - maxPanelHeight)
        .clamp(padding.top + 12.0, media.height - 320.0);
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                ),
                alignment: Alignment.topCenter,
                child: wrap(
                  PostsFilterPopup(
                    appliedFilters: filters,
                    width: panelWidth,
                    maxHeight: maxPanelHeight,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class PostsFilterPopup extends StatelessWidget {
  const PostsFilterPopup({
    super.key,
    required this.appliedFilters,
    this.width,
    this.maxHeight = 520,
    this.borderRadius,
  });

  final PostFilters appliedFilters;
  final double? width;
  final double maxHeight;
  final BorderRadius? borderRadius;

  void _close(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  void _apply(BuildContext context) {
    final draft = context.read<PostsFilterDraftCubit>();
    final postsBloc = context.read<PostsBloc>();
    postsBloc.add(
      UpdatePostFiltersEvent(
        draft.toAppliedFilters(postsBloc.activeFilters),
      ),
    );
    _close(context);
  }

  void _clearAndClose(BuildContext context) {
    context.read<PostsFilterDraftCubit>().reset();
    context.read<PostsBloc>().add(ClearPostFiltersEvent());
    _close(context);
  }

  InputDecoration _decoration(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(20);

    return Material(
      color: scheme.surface,
      elevation: 10,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width ?? 400,
          maxHeight: maxHeight,
          minWidth: width ?? 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 20, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.tOr('filters', 'Filters'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.t('close'),
                    onPressed: () => _close(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BlocSelector<PostsFilterDraftCubit, PostsFilterDraftState,
                        PostTypeFilter>(
                      selector: (s) => s.postType,
                      builder: (context, postType) {
                        return DropdownButtonFormField<PostTypeFilter>(
                          key: ValueKey('draft_postType_$postType'),
                          initialValue: postType,
                          isExpanded: true,
                          decoration: _decoration(
                            context,
                            l10n.t('postFilterPostType'),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: PostTypeFilter.all,
                              child: Text(l10n.t('postFilterAuctionAll')),
                            ),
                            DropdownMenuItem(
                              value: PostTypeFilter.auction,
                              child: Text(l10n.t('postFilterAuctionOnly')),
                            ),
                            DropdownMenuItem(
                              value: PostTypeFilter.ads,
                              child: Text(
                                context.trOr('postFilterAdsOnly', 'Ads only'),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            context
                                .read<PostsFilterDraftCubit>()
                                .setPostType(v);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    BlocSelector<PostsFilterDraftCubit, PostsFilterDraftState,
                        String?>(
                      selector: (s) => s.type,
                      builder: (context, type) {
                        return DropdownButtonFormField<String?>(
                          key: ValueKey('draft_type_$type'),
                          initialValue: type,
                          isExpanded: true,
                          decoration: _decoration(
                            context,
                            l10n.t('postFilterType'),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(l10n.t('postFilterTypeAll')),
                            ),
                            DropdownMenuItem(
                              value: 'VIDEO',
                              child: Text(l10n.t('postFilterTypeVideo')),
                            ),
                            DropdownMenuItem(
                              value: 'IMAGE',
                              child: Text(l10n.t('postFilterTypeImage')),
                            ),
                            DropdownMenuItem(
                              value: 'CAROUSEL',
                              child: Text(l10n.t('postFilterTypeCarousel')),
                            ),
                          ],
                          onChanged: (v) =>
                              context.read<PostsFilterDraftCubit>().setType(v),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    BlocSelector<PostsFilterDraftCubit, PostsFilterDraftState,
                        String>(
                      selector: (s) => s.sort,
                      builder: (context, sort) {
                        return DropdownButtonFormField<String>(
                          key: ValueKey('draft_sort_$sort'),
                          initialValue: sort,
                          isExpanded: true,
                          decoration: _decoration(
                            context,
                            l10n.t('postFilterSort'),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'LATEST',
                              child: Text(l10n.t('postFilterSortLatest')),
                            ),
                            DropdownMenuItem(
                              value: 'POPULAR',
                              child: Text(l10n.t('postFilterSortPopular')),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            context.read<PostsFilterDraftCubit>().setSort(v);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  BlocSelector<PostsFilterDraftCubit, PostsFilterDraftState,
                      int>(
                    selector: (s) => s.activeCount,
                    builder: (context, draftCount) {
                      final canClear = postsAppliedFilterCount(appliedFilters) >
                              0 ||
                          draftCount > 0;
                      return TextButton(
                        onPressed: canClear
                            ? () => _clearAndClose(context)
                            : null,
                        child: Text(l10n.t('clearAllFilters')),
                      );
                    },
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => _apply(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n.tOr('apply', 'Apply')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
