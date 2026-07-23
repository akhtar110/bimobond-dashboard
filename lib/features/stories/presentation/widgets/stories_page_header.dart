import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../posts/presentation/utils/posts_responsive.dart';
import '../bloc/stories_bloc.dart';
import '../bloc/stories_state.dart';
import '../utils/stories_admin_l10n.dart';
import 'stories_view_toggle.dart';
import 'story_filters.dart';

class StoriesPageHeader extends StatelessWidget {
  const StoriesPageHeader({super.key, this.metrics});

  final PostsLayoutMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(metrics?.headerPadding ?? 12),
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
          final title = _StoriesHeaderTitle(theme: theme, compact: m.isMobile);
          final toolbar = _StoriesHeaderFilterToolbar(metrics: m);

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

class _StoriesHeaderTitle extends StatelessWidget {
  const _StoriesHeaderTitle({
    required this.theme,
    this.compact = false,
  });

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
        Text(
          StoriesAdminL10n.pageTitle(context),
          style: titleStyle,
        ),
        const SizedBox(height: 4),
        BlocSelector<StoriesBloc, StoriesState, int?>(
          selector: (state) => switch (state) {
            StoriesLoaded(:final total) => total,
            _ => null,
          },
          builder: (context, total) {
            return Text(
              total != null
                  ? context.l10n.tOr('storiesTotalCount', '$total stories')
                      .replaceAll('{count}', '$total')
                  : StoriesAdminL10n.pageSubtitle(context),
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

class _StoriesHeaderFilterToolbar extends StatelessWidget {
  const _StoriesHeaderFilterToolbar({this.metrics});

  final PostsLayoutMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final m = metrics ??
            PostsLayoutMetrics(getPostsDeviceType(constraints.maxWidth));
        final narrow = constraints.maxWidth < 760;

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StoryFiltersBar(compact: true, metrics: m),
              SizedBox(height: m.filterGap + 1),
              const Align(
                alignment: AlignmentDirectional.centerEnd,
                child: StoriesViewToggle(),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: StoryFiltersBar(compact: true, metrics: m),
            ),
            SizedBox(width: m.filterGap + 1),
            const StoriesViewToggle(),
          ],
        );
      },
    );
  }
}
