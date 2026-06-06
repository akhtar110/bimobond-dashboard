import 'package:flutter/material.dart';

import '../../../../../core/localization/localization.dart';
import '../../../domain/entities/managed_post_entity.dart';
import 'investigation_theme.dart';
import 'post_surface_card.dart';

class ModerationSidebar extends StatelessWidget {
  const ModerationSidebar({
    super.key,
    required this.post,
    required this.draft,
    required this.isBusy,
    required this.isSaving,
    required this.isDeleting,
    required this.onDraftToggle,
    required this.onDelete,
    required this.onSave,
  });

  final ManagedPostEntity post;
  final ManagedPostEntity draft;
  final bool isBusy;
  final bool isSaving;
  final bool isDeleting;
  final void Function(ManagedPostEntity Function(ManagedPostEntity) updater)
      onDraftToggle;
  final VoidCallback onDelete;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return PostSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.t('moderation'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: InvestigationTheme.s12),
          Text(
            l10n.t('moderationSettings'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: InvestigationTheme.mutedText(
                context,
                theme.brightness == Brightness.dark,
              ),
            ),
          ),
          const SizedBox(height: InvestigationTheme.s8),
          _ToggleRow(
            label: l10n.t('allowComments'),
            value: draft.allowComments,
            isBusy: isBusy,
            onChanged: (v) => onDraftToggle((d) => d.copyWith(allowComments: v)),
          ),
          const SizedBox(height: InvestigationTheme.s8),
          _ToggleRow(
            label: l10n.t('allowDuets'),
            value: draft.allowDuets,
            isBusy: isBusy,
            onChanged: (v) => onDraftToggle((d) => d.copyWith(allowDuets: v)),
          ),
          const SizedBox(height: InvestigationTheme.s8),
          _ToggleRow(
            label: l10n.t('allowStitch'),
            value: draft.allowStitch,
            isBusy: isBusy,
            onChanged: (v) => onDraftToggle((d) => d.copyWith(allowStitch: v)),
          ),
          const SizedBox(height: InvestigationTheme.s16),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
          const SizedBox(height: InvestigationTheme.s12),
          FilledButton.icon(
            onPressed: isBusy ? null : onSave,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
              ),
            ),
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(l10n.t('saveChangesPost')),
          ),
          const SizedBox(height: InvestigationTheme.s8),
          OutlinedButton.icon(
            onPressed: isBusy ? null : onDelete,
            icon: isDeleting
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.red.shade700),
                    ),
                  )
                : const Icon(Icons.delete_forever_outlined, size: 16),
            label: Text(l10n.t('deletePost')),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              foregroundColor: Colors.red.shade700,
              side: BorderSide(
                color: isBusy ? Colors.grey.shade300 : Colors.red.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.isBusy,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool isBusy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: InvestigationTheme.animMs),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1421) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: isBusy ? null : onChanged,
          ),
        ],
      ),
    );
  }
}
