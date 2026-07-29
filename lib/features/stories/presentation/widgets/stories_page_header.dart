import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../posts/presentation/utils/posts_responsive.dart';
import '../bloc/stories_bloc.dart';
import '../bloc/stories_state.dart';
import '../utils/stories_admin_l10n.dart';
import 'stories_view_toggle.dart';
import 'story_filters.dart';

/// Compact stories top bar — no border chrome; filters stay dense so the
/// catalog keeps most of the viewport.
class StoriesPageHeader extends StatelessWidget {
  const StoriesPageHeader({super.key, this.metrics});

  final PostsLayoutMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final m = metrics ??
            PostsLayoutMetrics(getPostsDeviceType(constraints.maxWidth));
        final desktop = constraints.maxWidth >= 1040;
        final title = _StoriesHeaderTitle(theme: theme, compact: m.isMobile);
        final toolbar = _StoriesHeaderFilterToolbar(metrics: m);

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

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          StoriesAdminL10n.pageTitle(context),
          style: titleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        BlocSelector<StoriesBloc, StoriesState, int?>(
          selector: (state) => switch (state) {
            StoriesLoaded(:final total) => total,
            // Keep count chrome stable on empty search/filter results — never
            // fall back to the long page subtitle (it pushes filter fields).
            StoriesEmpty() => 0,
            _ => null,
          },
          builder: (context, total) {
            if (total == null) return const SizedBox.shrink();
            final label = context.l10n
                .tOr('storiesTotalCount', '$total stories')
                .replaceAll('{count}', '$total');
            return Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.1,
                  fontWeight: FontWeight.w500,
                ),
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
        final narrow = constraints.maxWidth < 640;

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StoryFiltersBar(compact: true, metrics: m),
              SizedBox(height: m.filterGap),
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
            SizedBox(width: m.filterGap),
            const StoriesViewToggle(),
          ],
        );
      },
    );
  }
}
