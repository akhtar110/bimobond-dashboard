import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/enums/gifts_view_type.dart';
import '../bloc/gifts_bloc.dart';

class GiftsViewToggle extends StatelessWidget {
  const GiftsViewToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<GiftsBloc, GiftsState, GiftsViewType>(
      selector: (state) => switch (state) {
        GiftsLoaded(:final viewType) => viewType,
        _ => GiftsViewType.grid,
      },
      builder: (context, viewType) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GiftsViewToggleButton(
                icon: Icons.grid_view_rounded,
                tooltip: l10n.t('postsGridView'),
                isSelected: viewType == GiftsViewType.grid,
                onTap: () => context.read<GiftsBloc>().add(
                      ChangeGiftsViewEvent(GiftsViewType.grid),
                    ),
              ),
              Container(
                width: 1,
                height: 28,
                color: scheme.outlineVariant,
              ),
              _GiftsViewToggleButton(
                icon: Icons.view_list_rounded,
                tooltip: l10n.t('postsListView'),
                isSelected: viewType == GiftsViewType.list,
                onTap: () => context.read<GiftsBloc>().add(
                      ChangeGiftsViewEvent(GiftsViewType.list),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GiftsViewToggleButton extends StatefulWidget {
  const _GiftsViewToggleButton({
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
  State<_GiftsViewToggleButton> createState() => _GiftsViewToggleButtonState();
}

class _GiftsViewToggleButtonState extends State<_GiftsViewToggleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.isSelected;
    final bg = selected
        ? scheme.primaryContainer
        : _hovered
            ? scheme.surfaceContainerHigh
            : scheme.surface;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

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
