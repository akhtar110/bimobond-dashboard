import 'package:flutter/material.dart';

import '../../../../core/utils/coin_format.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/localization/localization.dart';
import '../../domain/entities/create_post_entity.dart';
import '../../domain/services/create_post_media_filter_service.dart';
import 'create_post_local_video_preview.dart';
import 'create_post_media_filter_sheet.dart';
import 'create_post_rich_description.dart';

class PostPreviewSection extends StatefulWidget {
  const PostPreviewSection({super.key, required this.form});

  final CreatePostEntity form;

  @override
  State<PostPreviewSection> createState() => _PostPreviewSectionState();
}

class _PostPreviewSectionState extends State<PostPreviewSection> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(PostPreviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final length = widget.form.localMedia.length;
    if (length == 0) {
      _selectedIndex = 0;
      return;
    }
    if (_selectedIndex >= length) {
      _selectedIndex = length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = widget.form.localMedia;

    if (media.isEmpty) {
      return Center(
        child: Text(
          l10n.t('previewEmpty'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.grey.shade500 : const Color(0xFF6B7280),
          ),
        ),
      );
    }

    final selected = media[_selectedIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B28) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3344) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l10n.t('previewAttachedMedia'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                context.tr('attachedMediaCount', {'count': '${media.length}'}),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? Colors.grey.shade500 : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.t('previewSelectMediaHint'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey.shade500 : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _MainMediaPreview(
                key: ValueKey(selected.id),
                file: selected,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: media.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final file = media[index];
                return _AttachedMediaThumb(
                  file: file,
                  index: index,
                  selected: index == _selectedIndex,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          CreatePostRichDescriptionPreview(form: widget.form),
          if (widget.form.hasLocation) ...[
            const SizedBox(height: 12),
            _LocationPreview(form: widget.form),
          ],
          if (widget.form.hasSound && widget.form.selectedSound != null) ...[
            const SizedBox(height: 12),
            _SoundPreview(sound: widget.form.selectedSound!),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _Chip(label: widget.form.type),
              _Chip(label: widget.form.status),
              _Chip(label: widget.form.privacyStatus),
              if (widget.form.category != null)
                _Chip(label: widget.form.category!),
              if (widget.form.isAuctionable) const _Chip(label: 'Auction'),
              if (widget.form.isStory) const _Chip(label: 'Story'),
            ],
          ),
          if (widget.form.isAuctionable && widget.form.auction != null)
            _AuctionPreviewSummary(auction: widget.form.auction!),
        ],
      ),
    );
  }
}

class _AuctionPreviewSummary extends StatelessWidget {
  const _AuctionPreviewSummary({required this.auction});

  final CreatePostAuctionEntity auction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final name = auction.itemName.trim();
    final hasPrices = auction.hasValidPricing;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gavel_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.t('auctionDetails'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            if (name.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(name, style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (hasPrices) ...[
              const SizedBox(height: 6),
              Text(
                auction.isMoneyMode
                    ? MoneyFormat.format(
                        auction.targetPrice ?? 0,
                        auction.currencyCode,
                      )
                    : CoinFormat.coinsProgress(
                        current: auction.startingPriceCoins ?? 0,
                        target: auction.targetPriceCoins!,
                      ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MainMediaPreview extends StatelessWidget {
  const _MainMediaPreview({super.key, required this.file});

  final LocalMediaFile file;

  @override
  Widget build(BuildContext context) {
    const filterService = CreatePostMediaFilterService();

    Widget child;
    if (file.mediaType == 'IMAGE') {
      child = Image.memory(file.bytes, fit: BoxFit.contain);
    } else {
      child = CreatePostLocalVideoPreview(
        bytes: file.bytes,
        fileName: file.name,
      );
    }

    return filterService.buildFilteredPreview(child: child, filter: file.filter);
  }
}

class _AttachedMediaThumb extends StatelessWidget {
  const _AttachedMediaThumb({
    required this.file,
    required this.index,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final LocalMediaFile file;
  final int index;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isImage = file.mediaType == 'IMAGE';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : (isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0)),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(9),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (isImage)
                        buildFilteredImagePreview(
                          bytes: file.bytes,
                          filter: file.filter,
                          fit: BoxFit.cover,
                        )
                      else
                        ColoredBox(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          child: Icon(
                            Icons.videocam_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      if (!isImage)
                        const Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.white70,
                            size: 28,
                          ),
                        ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.scrim.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: scheme.surface,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _LocationPreview extends StatelessWidget {
  const _LocationPreview({required this.form});

  final CreatePostEntity form;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final location = form.location;
    final label = location?.name ?? form.locationId ?? '';

    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('createPostLocation'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(label, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _SoundPreview extends StatelessWidget {
  const _SoundPreview({required this.sound});

  final CreatePostSoundSelectionEntity sound;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(Icons.music_note_outlined, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('createPostSound'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${sound.name} · ${sound.author}',
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
