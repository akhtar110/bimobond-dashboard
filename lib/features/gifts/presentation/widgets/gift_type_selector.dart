import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/enums/gift_type.dart';

/// Segmented IMAGE / AUDIO control used in create & edit gift dialogs.
class GiftTypeSelector extends StatelessWidget {
  const GiftTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final GiftType value;
  final ValueChanged<GiftType>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.tOr('giftType', 'Gift type'),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.tOr(
            'giftTypeChooseHint',
            'Choose image or audio gift first',
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: _TypeOption(
                    selected: value == GiftType.image,
                    icon: Icons.image_rounded,
                    label: l10n.tOr('giftTypeImage', 'IMAGE'),
                    hint: l10n.tOr('giftTypeImageHint', 'Animation optional'),
                    accent: scheme.primary,
                    selectedBg: scheme.primaryContainer,
                    selectedFg: scheme.onPrimaryContainer,
                    onTap: enabled && onChanged != null
                        ? () => onChanged!(GiftType.image)
                        : null,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _TypeOption(
                    selected: value == GiftType.audio,
                    icon: Icons.audiotrack_rounded,
                    label: l10n.tOr('giftTypeAudio', 'AUDIO'),
                    hint: l10n.tOr('giftTypeAudioHint', 'Audio required'),
                    accent: scheme.secondary,
                    selectedBg: scheme.secondaryContainer,
                    selectedFg: scheme.onSecondaryContainer,
                    onTap: enabled && onChanged != null
                        ? () => onChanged!(GiftType.audio)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.selected,
    required this.icon,
    required this.label,
    required this.hint,
    required this.accent,
    required this.selectedBg,
    required this.selectedFg,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final String hint;
  final Color accent;
  final Color selectedBg;
  final Color selectedFg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? selectedBg : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.55)
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.18)
                      : scheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: selected ? selectedFg : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: selected ? selectedFg : scheme.onSurface,
                      ),
                    ),
                    Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        color: selected
                            ? selectedFg.withValues(alpha: 0.85)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 140),
                opacity: selected ? 1 : 0,
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 15,
                  color: selectedFg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact type chip for preview headers.
class GiftTypePreviewBanner extends StatelessWidget {
  const GiftTypePreviewBanner({super.key, required this.type});

  final GiftType type;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isAudio = type == GiftType.audio;
    final bg = isAudio ? scheme.secondaryContainer : scheme.primaryContainer;
    final fg =
        isAudio ? scheme.onSecondaryContainer : scheme.onPrimaryContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isAudio ? scheme.secondary : scheme.primary)
              .withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAudio ? Icons.audiotrack_rounded : Icons.image_rounded,
            size: 18,
            color: fg,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAudio
                      ? l10n.tOr('giftTypeAudio', 'AUDIO')
                      : l10n.tOr('giftTypeImage', 'IMAGE'),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: fg,
                  ),
                ),
                Text(
                  isAudio
                      ? l10n.tOr(
                          'giftTypeAudioPreviewHint',
                          'This gift plays with audio',
                        )
                      : l10n.tOr(
                          'giftTypeImagePreviewHint',
                          'This gift uses image / animation',
                        ),
                  style: TextStyle(
                    fontSize: 11,
                    color: fg.withValues(alpha: 0.9),
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
