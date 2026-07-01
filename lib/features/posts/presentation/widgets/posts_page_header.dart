import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../bloc/posts_bloc.dart';
import '../utils/posts_page_refresh.dart';
import '../utils/posts_responsive.dart';
import 'posts_filter_bar.dart';
import 'posts_view_toggle.dart';

class PostsPageHeader extends StatelessWidget {
  const PostsPageHeader({super.key, this.metrics});

  final PostsLayoutMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(
        metrics?.headerPadding ?? 12,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final m = metrics ??
              PostsLayoutMetrics(getPostsDeviceType(constraints.maxWidth));
          final desktop = constraints.maxWidth >= 1040;
          final compactHeader = m.isMobile;
          final title = PostsHeaderTitle(
            l10n: l10n,
            theme: theme,
            compact: compactHeader,
          );
          final toolbar = PostsHeaderFilterToolbar(metrics: m);

          if (desktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                title,
                SizedBox(width: m.filterGap + 8),
                Expanded(child: toolbar),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              SizedBox(height: m.filterGap + 2),
              toolbar,
            ],
          );
        },
      ),
    );
  }
}

class PostsHeaderTitle extends StatelessWidget {
  const PostsHeaderTitle({
    required this.l10n,
    required this.theme,
    this.compact = false,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final titleStyle = (compact ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)
        ?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.45,
          color: scheme.onSurface,
          height: 1.05,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.t('posts'),
          style: titleStyle,
        ),
        const SizedBox(height: 4),
        BlocSelector<PostsBloc, PostsState, String?>(
          selector: (state) => switch (state) {
            PostsLoaded(:final filters) => filters.categoryName,
            PostsEmpty(:final filters) => filters.categoryName,
            _ => null,
          },
          builder: (ctx, categoryNameFromState) {
            final catName = categoryNameFromState ??
                ctx.read<PostsBloc>().activeFilters.categoryName;
            return Text(
              catName != null
                  ? ctx.tr('showingPostsIn', {'name': catName})
                  : l10n.t('allCategories'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.2,
              ),
            );
          },
        ),
      ],
    );
  }
}

class PostsHeaderFilterToolbar extends StatelessWidget {
  const PostsHeaderFilterToolbar({this.metrics});

  final PostsLayoutMetrics? metrics;

  void _openCreatePost(BuildContext context) {
    final l10n = context.l10n;
    Navigator.pushNamed(context, AppRoutes.createPost).then((result) {
      if (!context.mounted) return;
      if (result == 'published' || result == 'draft') {
        refreshPostsPageFeed(context);
        final msg = result == 'draft'
            ? l10n.t('postDraftSaved')
            : l10n.t('postCreatedSuccess');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final m = metrics ??
            PostsLayoutMetrics(getPostsDeviceType(constraints.maxWidth));
        final narrow = constraints.maxWidth < 760;
        final createButton = PostsCreatePostButton(
          iconOnly: narrow,
          onPressed: () => _openCreatePost(context),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PostsFilterBar(isDark: isDark, compact: true, metrics: m),
              SizedBox(height: m.filterGap + 1),
              Row(
                children: [
                  const PostsViewToggle(),
                  const Spacer(),
                  createButton,
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: PostsFilterBar(isDark: isDark, compact: true, metrics: m)),
            SizedBox(width: m.filterGap + 1),
            const PostsViewToggle(),
            SizedBox(width: m.filterGap + 1),
            createButton,
          ],
        );
      },
    );
  }
}

class PostsCreatePostButton extends StatefulWidget {
  const PostsCreatePostButton({
    required this.onPressed,
    this.iconOnly = false,
  });

  final VoidCallback onPressed;
  final bool iconOnly;

  @override
  State<PostsCreatePostButton> createState() => PostsCreatePostButtonState();
}

class PostsCreatePostButtonState extends State<PostsCreatePostButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    if (widget.iconOnly) {
      return IconButton.filled(
        onPressed: widget.onPressed,
        tooltip: l10n.t('createPost'),
        icon: const Icon(Icons.add_rounded, size: 20),
      );
    }

    final bg = _hovered
        ? scheme.primary.withValues(alpha: 0.85)
        : scheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: FilledButton.icon(
          onPressed: widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: scheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(
            l10n.t('createPost'),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
