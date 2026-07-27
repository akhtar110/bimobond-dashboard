import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../bloc/posts_bloc.dart';
import '../utils/posts_page_refresh.dart';
import '../utils/posts_responsive.dart';
import 'posts_filter_bar.dart';
import 'posts_view_toggle.dart';

/// Compact posts top bar — no border chrome; filters stay on one dense row.
class PostsPageHeader extends StatelessWidget {
  const PostsPageHeader({super.key, this.metrics});

  final PostsLayoutMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final m = metrics ??
            PostsLayoutMetrics(getPostsDeviceType(constraints.maxWidth));
        final desktop = constraints.maxWidth >= 1040;
        final title = PostsHeaderTitle(
          l10n: l10n,
          theme: theme,
          compact: m.isMobile,
        );
        final toolbar = PostsHeaderFilterToolbar(metrics: m);

        if (desktop) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: m.isMobile ? 2 : 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                title,
                SizedBox(width: m.filterGap + 6),
                Expanded(child: toolbar),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(vertical: m.isMobile ? 2 : 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              SizedBox(height: m.filterGap),
              toolbar,
            ],
          ),
        );
      },
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
    final titleStyle =
        (compact ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)
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
        Text(l10n.t('posts'), style: titleStyle),
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
                height: 1.1,
                fontWeight: FontWeight.w500,
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
        final narrow = constraints.maxWidth < 560;
        final createButton = PostsCreatePostButton(
          iconOnly: narrow || m.isMobile,
          onPressed: () => _openCreatePost(context),
        );

        // Always one horizontal row: search+filters | view | create.
        // On very narrow widths, create becomes icon-only so filters stay inline.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: PostsFilterBar(
                isDark: isDark,
                compact: true,
                metrics: m,
              ),
            ),
            SizedBox(width: m.filterGap),
            const PostsViewToggle(),
            SizedBox(width: m.filterGap),
            createButton,
          ],
        );
      },
    );
  }
}

class PostsCreatePostButton extends StatelessWidget {
  const PostsCreatePostButton({
    super.key,
    required this.onPressed,
    this.iconOnly = false,
  });

  final VoidCallback onPressed;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    if (iconOnly) {
      return IconButton.filled(
        onPressed: onPressed,
        tooltip: l10n.t('createPost'),
        icon: const Icon(Icons.add_rounded, size: 20),
        style: IconButton.styleFrom(
          minimumSize: const Size(36, 36),
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(
        l10n.t('createPost'),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}
