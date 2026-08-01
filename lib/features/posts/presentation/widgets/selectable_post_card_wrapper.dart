import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../bloc/posts_bloc.dart';
import '../utils/post_card_layout.dart';
import 'post_card.dart';
import 'post_list_location.dart';

/// Wraps [PostCard] with a selection checkbox without modifying the card design.
class SelectablePostCard extends StatelessWidget {
  const SelectablePostCard({
    super.key,
    required this.post,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onTap,
    this.metrics,
  });

  final ManagedPostEntity post;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final VoidCallback onTap;
  final PostCardMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    final borderRadius = metrics?.borderRadius ?? 12;
    final inset = metrics?.compact == true ? 8.0 : 10.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        PostCard(
          key: ValueKey('post_card_${post.id}'),
          post: post,
          onTap: onTap,
          metrics: metrics,
        ),
        PositionedDirectional(
          top: inset,
          start: inset,
          child: _GlassSelectionCheckbox(
            isSelected: isSelected,
            onChanged: onSelectionChanged,
            compact: metrics?.compact ?? false,
          ),
        ),
        if (isSelected)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: PostCardPremiumColors.accentGold.withValues(
                      alpha: 0.72,
                    ),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: PostCardPremiumColors.accentGold.withValues(
                        alpha: 0.18,
                      ),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GlassSelectionCheckbox extends StatefulWidget {
  const _GlassSelectionCheckbox({
    required this.isSelected,
    required this.onChanged,
    this.compact = false,
  });

  final bool isSelected;
  final ValueChanged<bool?> onChanged;
  final bool compact;

  @override
  State<_GlassSelectionCheckbox> createState() =>
      _GlassSelectionCheckboxState();
}

class _GlassSelectionCheckboxState extends State<_GlassSelectionCheckbox> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 20.0 : 22.0;
    final iconSize = widget.compact ? 12.0 : 13.0;
    final radius = BorderRadius.circular(4);
    final selected = widget.isSelected;

    final fill = selected
        ? PostCardPremiumColors.accentGold.withValues(
            alpha: _hovered ? 0.92 : 0.85,
          )
        : Colors.white.withValues(alpha: _hovered ? 0.36 : 0.22);

    final border = selected
        ? PostCardPremiumColors.accentGold.withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: _hovered ? 0.7 : 0.5);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onChanged(!selected),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: fill,
            border: Border.all(color: border, width: selected ? 1.3 : 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.35 : 0.28),
                blurRadius: _hovered ? 12 : 8,
                offset: const Offset(0, 2),
              ),
              if (selected)
                BoxShadow(
                  color: PostCardPremiumColors.accentGold.withValues(
                    alpha: 0.28,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 140),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: selected
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey('checked'),
                    size: iconSize,
                    color: PostCardPremiumColors.black,
                  )
                : SizedBox(
                    key: const ValueKey('unchecked'),
                    width: iconSize,
                    height: iconSize,
                  ),
          ),
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
