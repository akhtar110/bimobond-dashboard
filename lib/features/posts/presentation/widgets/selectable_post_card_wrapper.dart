import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../bloc/posts_bloc.dart';
import 'post_card.dart';

/// Wraps [PostCard] with a selection checkbox without modifying the card design.
class SelectablePostCard extends StatelessWidget {
  const SelectablePostCard({
    super.key,
    required this.post,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onTap,
  });

  final ManagedPostEntity post;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        PostCard(key: ValueKey('post_card_${post.id}'), post: post, onTap: onTap),
        PositionedDirectional(
          top: 8,
          start: 8,
          child: _SelectionCheckboxOverlay(
            isSelected: isSelected,
            onChanged: onSelectionChanged,
            accentColor: scheme.primary,
          ),
        ),
        if (isSelected)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.55),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SelectionCheckboxOverlay extends StatefulWidget {
  const _SelectionCheckboxOverlay({
    required this.isSelected,
    required this.onChanged,
    required this.accentColor,
  });

  final bool isSelected;
  final ValueChanged<bool?> onChanged;
  final Color accentColor;

  @override
  State<_SelectionCheckboxOverlay> createState() =>
      _SelectionCheckboxOverlayState();
}

class _SelectionCheckboxOverlayState extends State<_SelectionCheckboxOverlay> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = scheme.surface.withValues(alpha: _hovered ? 0.98 : 0.92);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: bg,
        elevation: _hovered ? 3 : 1,
        shadowColor: scheme.shadow.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Checkbox(
          value: widget.isSelected,
          onChanged: widget.onChanged,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeColor: widget.accentColor,
          side: BorderSide(color: scheme.outline),
        ),
      ),
    );
  }
}

void togglePostSelection(BuildContext context, String postId, bool selected) {
  final bloc = context.read<PostsBloc>();
  if (selected) {
    bloc.add(SelectPostEvent(postId));
  } else {
    bloc.add(DeselectPostEvent(postId));
  }
}
