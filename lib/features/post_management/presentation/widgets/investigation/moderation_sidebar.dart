import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/localization.dart';
import '../../../domain/entities/managed_post_entity.dart';
import '../../bloc/post_management_bloc.dart';
import '../../utils/post_detail_labels.dart';
import 'post_surface_card.dart';

class ModerationSidebar extends StatelessWidget {
  const ModerationSidebar({
    super.key,
    required this.post,
    required this.draft,
    required this.isBusy,
    required this.isSaving,
    required this.onChangeStatus,
    required this.onDraftToggle,
  });

  final ManagedPostEntity post;
  final ManagedPostEntity draft;
  final bool isBusy;
  final bool isSaving;
  final VoidCallback onChangeStatus;
  final void Function(ManagedPostEntity Function(ManagedPostEntity) updater)
      onDraftToggle;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PostManagementBloc>();
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PostSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.t('postStatistics'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              _StatsGrid(post: post),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PostSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.t('moderationSettings'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              _ToggleRow(
                label: l10n.t('allowComments'),
                value: draft.allowComments,
                isBusy: isBusy,
                onChanged: (v) =>
                    onDraftToggle((d) => d.copyWith(allowComments: v)),
              ),
              const SizedBox(height: 8),
              _ToggleRow(
                label: l10n.t('allowDuets'),
                value: draft.allowDuets,
                isBusy: isBusy,
                onChanged: (v) => onDraftToggle((d) => d.copyWith(allowDuets: v)),
              ),
              const SizedBox(height: 8),
              _ToggleRow(
                label: l10n.t('allowStitch'),
                value: draft.allowStitch,
                isBusy: isBusy,
                onChanged: (v) =>
                    onDraftToggle((d) => d.copyWith(allowStitch: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PostSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.t('adminActions'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionButton(
                    icon: Icons.visibility_off_outlined,
                    label: l10n.t('hidePost'),
                    color: Colors.orange.shade700,
                    disabled: isBusy,
                    onPressed: () => bloc.add(HidePostEvent()),
                  ),
                  _ActionButton(
                    icon: Icons.block_outlined,
                    label: l10n.t('banPost'),
                    color: Colors.red.shade700,
                    disabled: isBusy,
                    onPressed: () => bloc.add(BanPostEvent()),
                  ),
                  _ActionButton(
                    icon: Icons.swap_horiz_outlined,
                    label: l10n.t('changeStatus'),
                    color: Colors.purple.shade700,
                    disabled: isBusy,
                    onPressed: onChangeStatus,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: isBusy ? null : () => bloc.add(UpdateManagedPostEvent()),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.t('saveChangesPost')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.post});
  final ManagedPostEntity post;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = <({String k, int v})>[
      (k: l10n.t('views'), v: post.viewCount),
      (k: l10n.t('likes'), v: post.likeCount),
      (k: l10n.t('comments'), v: post.commentCount),
      (k: l10n.t('shares'), v: post.shareCount),
      (k: l10n.t('saves'), v: post.saveCount),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.72,
      ),
      itemBuilder: (context, i) {
        final it = items[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                compactNumber(it.v),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                it.k,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      },
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Switch.adaptive(value: value, onChanged: isBusy ? null : onChanged),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.disabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: disabled ? null : onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: disabled ? Colors.grey.shade300 : color.withValues(alpha: 0.45),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
