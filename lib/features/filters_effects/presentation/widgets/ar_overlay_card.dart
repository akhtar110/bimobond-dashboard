import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/ar_overlay_entities.dart';

class ArOverlayCard extends StatefulWidget {
  const ArOverlayCard({
    super.key,
    required this.overlay,
    this.onPreview,
    this.onEdit,
    this.onActivate,
    this.onDeactivate,
    this.onDelete,
  });

  final ArOverlayEntity overlay;
  final VoidCallback? onPreview;
  final VoidCallback? onEdit;
  final VoidCallback? onActivate;
  final VoidCallback? onDeactivate;
  final VoidCallback? onDelete;

  @override
  State<ArOverlayCard> createState() => _ArOverlayCardState();
}

class _ArOverlayCardState extends State<ArOverlayCard> {
  bool _hovered = false;

  Color _parseColorHex(String? input) {
    if (input == null || input.trim().isEmpty) {
      return const Color(0xFF1E88E5);
    }
    var clean = input.replaceAll('#', '').trim();
    if (clean.length == 6) clean = 'FF$clean';
    final val = int.tryParse(clean, radix: 16);
    return val != null ? Color(val) : const Color(0xFF1E88E5);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final item = widget.overlay;
    final color = _parseColorHex(item.previewColorHex);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: _hovered
            ? (Matrix4.identity()..translateByDouble(0.0, -3.0, 0.0, 1.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered
                ? scheme.primary.withValues(alpha: 0.5)
                : scheme.outlineVariant.withValues(alpha: 0.7),
            width: _hovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? scheme.primary.withValues(alpha: 0.1)
                  : scheme.shadow.withValues(alpha: 0.04),
              blurRadius: _hovered ? 12 : 6,
              offset: Offset(0, _hovered ? 4 : 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPreview,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: color.withValues(alpha: 0.85),
                        child: item.thumbnailUrl != null &&
                                item.thumbnailUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.thumbnailUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    _buildFallbackContent(item),
                                errorWidget: (context, url, error) =>
                                    _buildFallbackContent(item),
                              )
                            : _buildFallbackContent(item),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.animation_rounded,
                                size: 10,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'LOTTIE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surface.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: scheme.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                '#${item.sortOrder}',
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            _StatusChip(isActive: item.isActive),
                          ],
                        ),
                      ),
                      if (widget.onPreview != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 160),
                            opacity: _hovered ? 1 : 0.92,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              color: Colors.black.withValues(alpha: 0.45),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.play_circle_outline_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.tOr('preview', 'Preview'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.emoji != null && item.emoji!.isNotEmpty) ...[
                        Text(item.emoji!, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          item.label,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.id,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Spacer(),
                      if (widget.onPreview != null) ...[
                        _CompactAction(
                          icon: Icons.visibility_outlined,
                          tooltip: l10n.tOr('previewOverlay', 'Preview overlay'),
                          onPressed: widget.onPreview,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (widget.onEdit != null) ...[
                        _CompactAction(
                          icon: Icons.edit_rounded,
                          tooltip: l10n.t('edit'),
                          onPressed: widget.onEdit,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (item.isActive && widget.onDeactivate != null) ...[
                        _CompactAction(
                          icon: Icons.pause_circle_outline_rounded,
                          tooltip: l10n.tOr('feDeactivate', 'Deactivate'),
                          onPressed: widget.onDeactivate,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (!item.isActive && widget.onActivate != null) ...[
                        _CompactAction(
                          icon: Icons.play_circle_outline_rounded,
                          tooltip: l10n.tOr('feActivate', 'Activate'),
                          onPressed: widget.onActivate,
                          color: scheme.tertiary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (widget.onDelete != null)
                        _CompactAction(
                          icon: Icons.delete_outline_rounded,
                          tooltip: l10n.t('delete'),
                          onPressed: widget.onDelete,
                          color: scheme.error,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackContent(ArOverlayEntity item) {
    if (item.emoji != null && item.emoji!.isNotEmpty) {
      return Center(
        child: Text(item.emoji!, style: const TextStyle(fontSize: 30)),
      );
    }
    return Center(
      child: Icon(
        Icons.layers_outlined,
        size: 30,
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bg = isActive
        ? scheme.tertiaryContainer
        : scheme.errorContainer.withValues(alpha: 0.7);
    final fg = isActive ? scheme.onTertiaryContainer : scheme.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive
            ? l10n.tOr('feActive', 'Active')
            : l10n.tOr('feInactive', 'Inactive'),
        style: TextStyle(
          color: fg,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CompactAction extends StatelessWidget {
  const _CompactAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: color),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        minimumSize: const Size(28, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
    );
  }
}

class ArOverlaySkeletonCard extends StatelessWidget {
  const ArOverlaySkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(color: scheme.surfaceContainerHighest),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 96,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 9,
                  width: 64,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
