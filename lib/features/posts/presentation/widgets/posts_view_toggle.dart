import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/enums/posts_view_type.dart';
import '../bloc/posts_bloc.dart';

/// Compact segmented view switcher — icon-only, minimal chrome.
class PostsViewToggle extends StatelessWidget {
  const PostsViewToggle({super.key, this.height = 36});

  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<PostsBloc, PostsState, PostsViewType>(
      selector: (state) => switch (state) {
        PostsLoaded(:final viewType) => viewType,
        _ => context.read<PostsBloc>().activeViewType,
      },
      builder: (context, viewType) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ViewToggleButton(
                icon: Icons.grid_view_rounded,
                tooltip: l10n.t('postsGridView'),
                isSelected: viewType == PostsViewType.grid,
                height: height,
                onTap: () => context.read<PostsBloc>().add(
                      const ChangePostsViewEvent(PostsViewType.grid),
                    ),
              ),
              Container(
                width: 1,
                height: height - 10,
                color: scheme.outline.withValues(alpha: 0.18),
              ),
              _ViewToggleButton(
                icon: Icons.view_list_rounded,
                tooltip: l10n.t('postsListView'),
                isSelected: viewType == PostsViewType.list,
                height: height,
                onTap: () => context.read<PostsBloc>().add(
                      const ChangePostsViewEvent(PostsViewType.list),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  const _ViewToggleButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.height,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = isSelected;
    final fg = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          hoverColor: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
          child: SizedBox(
            width: height + 2,
            height: height,
            child: Icon(icon, size: 17, color: fg),
          ),
        ),
      ),
    );
  }
}
