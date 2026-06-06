import 'package:flutter/material.dart';

import '../../../../../core/localization/localization.dart';
import 'investigation_theme.dart';

class InvestigationHeader extends StatelessWidget {
  const InvestigationHeader({
    super.key,
    required this.isDark,
    required this.isBusy,
    required this.isSaving,
    required this.dirty,
    required this.onBack,
    required this.onSave,
    required this.onChangeStatus,
    required this.onDelete,
  });

  final bool isDark;
  final bool isBusy;
  final bool isSaving;
  final bool dirty;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onChangeStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1421) : scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? const Color(0xFF1E293B)
                : scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final titleBlock = Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  tooltip: l10n.t('back'),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Text(
                    l10n.t('postManagementDetails'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            );

            final actions = _ToolbarActions(
              isBusy: isBusy,
              isSaving: isSaving,
              dirty: dirty,
              onSave: onSave,
              onChangeStatus: onChangeStatus,
              onDelete: onDelete,
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titleBlock,
                  const SizedBox(height: InvestigationTheme.s12),
                  actions,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleBlock),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ToolbarActions extends StatelessWidget {
  const _ToolbarActions({
    required this.isBusy,
    required this.isSaving,
    required this.dirty,
    required this.onSave,
    required this.onChangeStatus,
    required this.onDelete,
  });

  final bool isBusy;
  final bool isSaving;
  final bool dirty;
  final VoidCallback onSave;
  final VoidCallback onChangeStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Wrap(
      spacing: InvestigationTheme.s8,
      runSpacing: InvestigationTheme.s8,
      alignment: WrapAlignment.end,
      children: [
        if (dirty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_note_rounded, size: 14, color: Colors.amber.shade800),
                const SizedBox(width: 4),
                Text(
                  l10n.t('unsavedChanges'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: isBusy ? null : onChangeStatus,
          icon: const Icon(Icons.swap_horiz_rounded, size: 16),
          label: Text(l10n.t('changeStatus')),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: isBusy ? null : onSave,
          icon: isSaving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_rounded, size: 16),
          label: Text(l10n.t('saveChangesPost')),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: isBusy ? null : onDelete,
          tooltip: l10n.t('deletePost'),
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          style: IconButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            backgroundColor: Colors.red.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }
}
