import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/stories_bloc.dart';
import '../bloc/stories_event.dart';
import '../bloc/stories_state.dart';

class StoriesViewToggle extends StatelessWidget {
  const StoriesViewToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<StoriesBloc, StoriesState, bool>(
      selector: (state) =>
          state is StoriesLoaded ? state.useGridView : true,
      builder: (context, useGridView) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ViewToggleButton(
                icon: Icons.grid_view_rounded,
                tooltip: l10n.t('postsGridView'),
                isSelected: useGridView,
                onTap: () => context.read<StoriesBloc>().add(
                      const ChangeStoriesViewEvent(true),
                    ),
              ),
              Container(
                width: 1,
                height: 28,
                color: scheme.outlineVariant,
              ),
              _ViewToggleButton(
                icon: Icons.view_list_rounded,
                tooltip: l10n.t('postsListView'),
                isSelected: !useGridView,
                onTap: () => context.read<StoriesBloc>().add(
                      const ChangeStoriesViewEvent(false),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ViewToggleButton extends StatefulWidget {
  const _ViewToggleButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ViewToggleButton> createState() => _ViewToggleButtonState();
}

class _ViewToggleButtonState extends State<_ViewToggleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.isSelected;
    final bg = selected
        ? scheme.primary.withValues(alpha: 0.12)
        : _hovered
            ? scheme.surfaceContainerHigh
            : Colors.transparent;
    final fg = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              width: 38,
              height: 34,
              child: Icon(widget.icon, size: 18, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}
