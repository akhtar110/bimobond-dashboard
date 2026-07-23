import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/sound_entities.dart';
import '../services/sound_preview_service.dart';
import 'sound_preview_widgets.dart';

const double kSoundsTableHeaderHeight = 40;
const double _kCellHPad = 10;
const double _kRowVPad = 10;

enum SoundsTableDensity { wide, medium, narrow }

SoundsTableDensity soundsTableDensityForWidth(double width) {
  if (width >= 1100) return SoundsTableDensity.wide;
  if (width >= 820) return SoundsTableDensity.medium;
  return SoundsTableDensity.narrow;
}

class SoundsTable extends StatelessWidget {
  const SoundsTable({
    super.key,
    required this.sounds,
    required this.selectedIds,
    required this.preview,
    required this.onToggleSelection,
    required this.onSelectAll,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final List<SoundEntity> sounds;
  final Set<String> selectedIds;
  final SoundPreviewService preview;
  final ValueChanged<String> onToggleSelection;
  final VoidCallback onSelectAll;
  final ValueChanged<SoundEntity> onEdit;
  final ValueChanged<SoundEntity> onToggleActive;
  final ValueChanged<SoundEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allSelected =
        sounds.isNotEmpty && sounds.every((s) => selectedIds.contains(s.id));
    final someSelected = selectedIds.isNotEmpty && !allSelected;

    return LayoutBuilder(
      builder: (context, constraints) {
        final density = soundsTableDensityForWidth(constraints.maxWidth);

        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SoundsTableHeader(
                  density: density,
                  allSelected: allSelected,
                  someSelected: someSelected,
                  onSelectAll: onSelectAll,
                ),
                for (var i = 0; i < sounds.length; i++)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: i == sounds.length - 1
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                    ),
                    child: SoundsTableRow(
                      sound: sounds[i],
                      density: density,
                      isSelected: selectedIds.contains(sounds[i].id),
                      preview: preview,
                      onToggleSelection: () =>
                          onToggleSelection(sounds[i].id),
                      onEdit: () => onEdit(sounds[i]),
                      onToggleActive: () => onToggleActive(sounds[i]),
                      onDelete: () => onDelete(sounds[i]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SoundsTableHeader extends StatelessWidget {
  const SoundsTableHeader({
    super.key,
    required this.density,
    required this.allSelected,
    required this.someSelected,
    required this.onSelectAll,
  });

  final SoundsTableDensity density;
  final bool allSelected;
  final bool someSelected;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
          fontSize: 11,
          letterSpacing: 0.1,
        );

    return Container(
      height: kSoundsTableHeaderHeight,
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: _SoundsTableRowLayout(
        density: density,
        checkbox: Checkbox(
          tristate: true,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          value: allSelected ? true : (someSelected ? null : false),
          onChanged: (_) => onSelectAll(),
        ),
        cover: Text(
          density == SoundsTableDensity.narrow ? '' : l10n.t('thumbnail'),
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        name: Text(l10n.t('soundName'), style: style),
        author: density == SoundsTableDensity.narrow
            ? const SizedBox.shrink()
            : Text(l10n.t('soundAuthor'), style: style),
        duration: density != SoundsTableDensity.narrow
            ? Text(l10n.t('soundDuration'), style: style)
            : const SizedBox.shrink(),
        usage: Text(l10n.t('soundUsageCount'), style: style),
        status: Text(l10n.t('status'), style: style),
        published: density == SoundsTableDensity.wide
            ? Text(l10n.t('soundColPublished'), style: style)
            : const SizedBox.shrink(),
        actions: Icon(
          Icons.more_horiz_rounded,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class SoundsTableRow extends StatefulWidget {
  const SoundsTableRow({
    super.key,
    required this.sound,
    required this.density,
    required this.isSelected,
    required this.preview,
    required this.onToggleSelection,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final SoundEntity sound;
  final SoundsTableDensity density;
  final bool isSelected;
  final SoundPreviewService preview;
  final VoidCallback onToggleSelection;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  State<SoundsTableRow> createState() => _SoundsTableRowState();
}

class _SoundsTableRowState extends State<SoundsTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = NumberFormat.compact();
    final dateFmt = DateFormat.yMMMd();
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
          height: 1.25,
        );

    final bg = widget.isSelected
        ? scheme.primaryContainer.withValues(alpha: 0.18)
        : _hovered
            ? scheme.surfaceContainerHighest
            : scheme.surface;

    return MouseRegion(
      onEnter: (_) {
        if (!_hovered) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: Material(
        color: bg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: _kRowVPad,
          ),
          child: _SoundsTableRowLayout(
            density: widget.density,
            checkbox: Checkbox(
              value: widget.isSelected,
              onChanged: (_) => widget.onToggleSelection(),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            cover: _SoundCoverThumb(
              sound: widget.sound,
              size: widget.density == SoundsTableDensity.narrow ? 36 : 42,
            ),
            name: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.sound.name,
                  maxLines: widget.density == SoundsTableDensity.narrow ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                SoundTablePlaybackStrip(
                  sound: widget.sound,
                  preview: widget.preview,
                ),
              ],
            ),
            author: widget.density == SoundsTableDensity.narrow
                ? const SizedBox.shrink()
                : Text(
                    widget.sound.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cellStyle,
                  ),
            duration: widget.density != SoundsTableDensity.narrow
                ? Text(
                    _formatDuration(widget.sound.duration),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cellStyle?.copyWith(color: scheme.onSurfaceVariant),
                  )
                : const SizedBox.shrink(),
            usage: Text(
              compact.format(widget.sound.useCount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cellStyle,
            ),
            status: SoundStatusBadge(isActive: widget.sound.isActive),
            published: widget.density == SoundsTableDensity.wide
                ? Text(
                    widget.sound.createdAt != null
                        ? dateFmt.format(widget.sound.createdAt!)
                        : '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cellStyle?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  )
                : const SizedBox.shrink(),
            actions: _SoundRowActions(
              sound: widget.sound,
              onEdit: widget.onEdit,
              onToggleActive: widget.onToggleActive,
              onDelete: widget.onDelete,
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }
}

class _SoundsTableRowLayout extends StatelessWidget {
  const _SoundsTableRowLayout({
    required this.density,
    required this.checkbox,
    required this.cover,
    required this.name,
    required this.author,
    required this.duration,
    required this.usage,
    required this.status,
    required this.published,
    required this.actions,
  });

  final SoundsTableDensity density;
  final Widget checkbox;
  final Widget cover;
  final Widget name;
  final Widget author;
  final Widget duration;
  final Widget usage;
  final Widget status;
  final Widget published;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final showAuthor = density != SoundsTableDensity.narrow;
    final showDuration = density != SoundsTableDensity.narrow;
    final showPublished = density == SoundsTableDensity.wide;
    final coverWidth = density == SoundsTableDensity.narrow ? 38.0 : 46.0;

    final nameFlex = switch (density) {
      SoundsTableDensity.wide => 5,
      SoundsTableDensity.medium => 5,
      SoundsTableDensity.narrow => 6,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 34, child: checkbox),
        SizedBox(width: coverWidth, child: cover),
        Expanded(flex: nameFlex, child: _cell(name)),
        if (showAuthor) Expanded(flex: 3, child: _cell(author)),
        if (showDuration) Expanded(flex: 1, child: _cell(duration)),
        Expanded(flex: 1, child: _cell(usage)),
        Expanded(flex: 2, child: _cell(status)),
        if (showPublished) Expanded(flex: 2, child: _cell(published)),
        SizedBox(width: 40, child: Center(child: actions)),
      ],
    );
  }

  Widget _cell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kCellHPad),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: child,
      ),
    );
  }
}

class _SoundCoverThumb extends StatelessWidget {
  const _SoundCoverThumb({required this.sound, this.size = 42});

  final SoundEntity sound;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cover = sound.coverUrl;

    if (cover != null && cover.isNotEmpty) {
      final url = resolveMediaUrl(cover);
      if (url != null && url.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _fallback(scheme),
          ),
        );
      }
    }

    return _fallback(scheme);
  }

  Widget _fallback(ColorScheme scheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: scheme.onPrimaryContainer,
        size: size * 0.45,
      ),
    );
  }
}

class _SoundRowActions extends StatelessWidget {
  const _SoundRowActions({
    required this.sound,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final SoundEntity sound;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.t('actions'),
      padding: EdgeInsets.zero,
      iconSize: 20,
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
          case 'toggle':
            onToggleActive();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text(l10n.t('edit'))),
        PopupMenuItem(
          value: 'toggle',
          child: Text(
            sound.isActive
                ? l10n.t('soundDeactivate')
                : l10n.t('soundActivate'),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            l10n.t('delete'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
      icon: const Icon(Icons.more_horiz_rounded),
    );
  }
}
