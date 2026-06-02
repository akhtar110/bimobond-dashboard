import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/managed_post_entity.dart';
import '../bloc/post_management_bloc.dart';
import '../widgets/comments_moderation_panel.dart';
import '../widgets/post_media_carousel.dart';

String _postStatusLabel(AppLocalizations l10n, String status) {
  switch (status.toUpperCase()) {
    case 'PUBLISHED':
      return l10n.t('postStatusPublished');
    case 'BANNED':
      return l10n.t('postStatusBanned');
    case 'DRAFT':
      return l10n.t('postStatusDraft');
    case 'HIDDEN':
      return l10n.t('postStatusHidden');
    case 'UNDER_REVIEW':
      return l10n.t('postStatusUnderReview');
    case 'ARCHIVED':
      return l10n.t('archived');
    default:
      return status;
  }
}

String _privacyLabel(AppLocalizations l10n, String value) {
  switch (value.toUpperCase()) {
    case 'PUBLIC':
      return l10n.t('public');
    case 'PRIVATE':
      return l10n.t('private');
    case 'FRIENDS':
      return l10n.t('friendsOnly');
    default:
      return value;
  }
}

class PostManagementDetailScreen extends StatelessWidget {
  const PostManagementDetailScreen({super.key, required this.post});

  final ManagedPostEntity post;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PostManagementBloc>()..add(LoadManagedPostEvent(post)),
      child: const _PostManagementDetailView(),
    );
  }
}

class _PostManagementDetailView extends StatefulWidget {
  const _PostManagementDetailView();

  @override
  State<_PostManagementDetailView> createState() =>
      _PostManagementDetailViewState();
}

class _PostManagementDetailViewState extends State<_PostManagementDetailView> {
  final _captionController = TextEditingController();
  final _categoryController = TextEditingController();
  String? _lastDraftId;
  String? _lastSnackMessage;

  @override
  void dispose() {
    _captionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _syncControllers(ManagedPostEntity draft) {
    if (_lastDraftId == '${draft.id}_${draft.updatedAt.millisecondsSinceEpoch}') {
      return;
    }
    _lastDraftId = '${draft.id}_${draft.updatedAt.millisecondsSinceEpoch}';
    _captionController.text = draft.description ?? '';
    _categoryController.text = draft.category ?? '';
  }

  void _patchDraft(PostManagementBloc bloc) {
    final current = bloc.state;
    if (current is! PostManagementLoaded) return;

    bloc.add(
      ChangeManagedPostFieldEvent(
        current.draft.copyWith(
          description: _captionController.text.trim(),
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
        ),
      ),
    );
  }

  void _updateDraft(
    PostManagementBloc bloc,
    ManagedPostEntity Function(ManagedPostEntity draft) update,
  ) {
    final current = bloc.state;
    if (current is! PostManagementLoaded) return;
    bloc.add(ChangeManagedPostFieldEvent(update(current.draft)));
  }

  String _localizedMessage(BuildContext context, String message) {
    if (message == 'commentDeleted') {
      return context.l10n.t('commentDeleted');
    }
    return message;
  }

  void _showSnack(BuildContext context, String message, {bool isError = false}) {
    if (_lastSnackMessage == message) return;
    _lastSnackMessage = message;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<PostManagementBloc, PostManagementState>(
      listener: (context, state) {
        if (state is PostManagementLoaded) {
          _syncControllers(state.draft);
          if (state.successMessage != null) {
            final msg = _localizedMessage(context, state.successMessage!);
            _showSnack(context, msg);
          } else if (state.errorMessage != null) {
            _showSnack(context, state.errorMessage!, isError: true);
          } else if (state.commentsError != null &&
              state.comments.isNotEmpty) {
            _showSnack(context, state.commentsError!, isError: true);
          }
        }
        if (state is PostManagementDeleted) {
          Navigator.pop(context, true);
        }
        if (state is PostManagementError) {
          _showSnack(context, state.message, isError: true);
        }
      },
      builder: (context, state) {
        final l10n = context.l10n;
        return Scaffold(
          backgroundColor: isDark
              ? theme.scaffoldBackgroundColor
              : const Color(0xFFF7F9FC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              l10n.t('postManagementTitle'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          body: switch (state) {
            PostManagementLoading() || PostManagementInitial() =>
              const Center(child: CircularProgressIndicator()),
            PostManagementError(:final message) => Center(child: Text(message)),
            PostManagementLoaded(
              :final draft,
              :final post,
              :final isSaving,
              :final isDeleting,
              :final isActioning,
            ) =>
              _buildContent(
                context,
                state: state,
                post: post,
                draft: draft,
                isSaving: isSaving,
                isDeleting: isDeleting,
                isActioning: isActioning,
                isDark: isDark,
                theme: theme,
              ),
            PostManagementDeleted() => const SizedBox.shrink(),
          },
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required PostManagementLoaded state,
    required ManagedPostEntity post,
    required ManagedPostEntity draft,
    required bool isSaving,
    required bool isDeleting,
    required bool isActioning,
    required bool isDark,
    required ThemeData theme,
  }) {
    final bloc = context.read<PostManagementBloc>();
    final l10n = context.l10n;
    final dateFormat = DateFormat('MMM dd, yyyy · HH:mm');
    final isBusy = isSaving || isDeleting || isActioning;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useTwoColumns = constraints.maxWidth >= 960;

              final leftColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PostMediaCarousel(
                    post: draft,
                    height: useTwoColumns ? 320 : 280,
                  ),
                  const SizedBox(height: 14),
                  _StatsRow(post: post, isDark: isDark),
                  const SizedBox(height: 10),
                  Text(
                    context.tr('postTimestamps', {
                      'created': dateFormat.format(draft.createdAt),
                      'updated': dateFormat.format(draft.updatedAt),
                    }),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? Colors.grey.shade500
                          : const Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              );

              final rightColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ModerationPanel(
                    isDark: isDark,
                    draft: draft,
                    isBusy: isBusy,
                    captionController: _captionController,
                    categoryController: _categoryController,
                    onCaptionChanged: () => _patchDraft(bloc),
                    onCategoryChanged: () => _patchDraft(bloc),
                    onDraftUpdate: (update) => _updateDraft(bloc, update),
                  ),
                  const SizedBox(height: 12),
                  _AdminActionsCard(
                    isDark: isDark,
                    isActioning: isActioning,
                    isBusy: isBusy,
                    draft: draft,
                    bloc: bloc,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: isBusy
                              ? null
                              : () => bloc.add(UpdateManagedPostEvent()),
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
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isBusy
                              ? null
                              : () => _confirmDelete(context, bloc),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isDeleting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red.shade700,
                                  ),
                                )
                              : Text(l10n.t('deletePost')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CommentsModerationPanel(
                    state: state,
                    isDark: isDark,
                    isBusy: isBusy,
                  ),
                ],
              );

              if (useTwoColumns) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: leftColumn),
                    const SizedBox(width: 20),
                    Expanded(flex: 6, child: rightColumn),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  leftColumn,
                  const SizedBox(height: 20),
                  rightColumn,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PostManagementBloc bloc,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('deletePostTitle')),
        content: Text(l10n.t('deletePostMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      bloc.add(DeleteManagedPostEvent());
    }
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.post, required this.isDark});

  final ManagedPostEntity post;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatChip(
          icon: Icons.visibility_outlined,
          label: l10n.t('views'),
          value: post.viewCount,
          isDark: isDark,
        ),
        _StatChip(
          icon: Icons.favorite_border,
          label: l10n.t('likes'),
          value: post.likeCount,
          isDark: isDark,
        ),
        _StatChip(
          icon: Icons.chat_bubble_outline,
          label: l10n.t('comments'),
          value: post.commentCount,
          isDark: isDark,
        ),
        _StatChip(
          icon: Icons.share_outlined,
          label: l10n.t('shares'),
          value: post.shareCount,
          isDark: isDark,
        ),
        _StatChip(
          icon: Icons.bookmark_border,
          label: l10n.t('saves'),
          value: post.saveCount,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final int value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3440) : const Color(0xFFE8ECF0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ModerationPanel extends StatelessWidget {
  const _ModerationPanel({
    required this.isDark,
    required this.draft,
    required this.isBusy,
    required this.captionController,
    required this.categoryController,
    required this.onCaptionChanged,
    required this.onCategoryChanged,
    required this.onDraftUpdate,
  });

  final bool isDark;
  final ManagedPostEntity draft;
  final bool isBusy;
  final TextEditingController captionController;
  final TextEditingController categoryController;
  final VoidCallback onCaptionChanged;
  final VoidCallback onCategoryChanged;
  final void Function(ManagedPostEntity Function(ManagedPostEntity) update)
      onDraftUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return _SectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.t('moderation'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.t('caption'),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: captionController,
            maxLines: 3,
            enabled: !isBusy,
            onChanged: (_) => onCaptionChanged(),
            decoration: InputDecoration(
              hintText: l10n.t('postDescriptionHint'),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: categoryController,
            enabled: !isBusy,
            onChanged: (_) => onCategoryChanged(),
            decoration: InputDecoration(
              labelText: l10n.t('categoryName'),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          // Status management has been moved to the Admin Actions section.
          // Keeping this code commented for future reference.
          /*
          _DropdownField(
            label: l10n.t('status'),
            value: draft.status,
            items: const [
              'PUBLISHED',
              'DRAFT',
              'HIDDEN',
              'BANNED',
              'UNDER_REVIEW',
              'ARCHIVED',
            ],
            itemLabel: (v) => _postStatusLabel(l10n, v),
            enabled: !isBusy,
            onChanged: (v) {
              if (v == null) return;
              onDraftUpdate((d) => d.copyWith(status: v));
            },
          ),
          */
          _DropdownField(
            label: l10n.t('privacy'),
            value: draft.privacyStatus,
            items: const ['PUBLIC', 'PRIVATE', 'FRIENDS'],
            itemLabel: (v) => _privacyLabel(l10n, v),
            enabled: !isBusy,
            onChanged: (v) {
              if (v == null) return;
              onDraftUpdate((d) => d.copyWith(privacyStatus: v));
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l10n.t('allowComments'), style: const TextStyle(fontSize: 13)),
            value: draft.allowComments,
            onChanged: isBusy
                ? null
                : (v) => onDraftUpdate((d) => d.copyWith(allowComments: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l10n.t('allowDuets'), style: const TextStyle(fontSize: 13)),
            value: draft.allowDuets,
            onChanged: isBusy
                ? null
                : (v) => onDraftUpdate((d) => d.copyWith(allowDuets: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l10n.t('allowStitch'), style: const TextStyle(fontSize: 13)),
            value: draft.allowStitch,
            onChanged: isBusy
                ? null
                : (v) => onDraftUpdate((d) => d.copyWith(allowStitch: v)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3440) : const Color(0xFFE8ECF0),
        ),
      ),
      child: child,
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String value;
  final List<String> items;
  final String Function(String value) itemLabel;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final resolved = items.contains(value) ? value : items.first;
    return DropdownButtonFormField<String>(
      value: resolved,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(itemLabel(e)),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _AdminActionsCard extends StatelessWidget {
  const _AdminActionsCard({
    required this.isDark,
    required this.isActioning,
    required this.isBusy,
    required this.draft,
    required this.bloc,
  });

  final bool isDark;
  final bool isActioning;
  final bool isBusy;
  final ManagedPostEntity draft;
  final PostManagementBloc bloc;

  bool get _disabled => isActioning || isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return _SectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l10n.t('adminActions'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isActioning) ...[
                const SizedBox(width: 10),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
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
                disabled: _disabled,
                onPressed: () => _confirmAction(
                  context,
                  title: l10n.t('hidePost'),
                  message: l10n.t('hidePostConfirm'),
                  confirmLabel: l10n.t('hide'),
                  confirmColor: Colors.orange.shade700,
                  onConfirmed: () => bloc.add(HidePostEvent()),
                ),
              ),
              _ActionButton(
                icon: Icons.block_outlined,
                label: l10n.t('banPost'),
                color: Colors.red.shade700,
                disabled: _disabled,
                onPressed: () => _confirmAction(
                  context,
                  title: l10n.t('banPost'),
                  message: l10n.t('banPostConfirm'),
                  confirmLabel: l10n.t('ban'),
                  confirmColor: Colors.red.shade700,
                  onConfirmed: () => bloc.add(BanPostEvent()),
                ),
              ),
              _ActionButton(
                icon: Icons.swap_horiz_outlined,
                label: l10n.t('changeStatus'),
                color: Colors.purple.shade700,
                disabled: _disabled,
                onPressed: () => _showChangeStatusDialog(context, draft.status),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirmed,
  }) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      onConfirmed();
    }
  }

  Future<void> _showChangeStatusDialog(
    BuildContext context,
    String currentStatus,
  ) async {
    final l10n = context.l10n;
    const statuses = [
      'PUBLISHED',
      'DRAFT',
      'HIDDEN',
      'BANNED',
      'UNDER_REVIEW',
      'ARCHIVED',
    ];

    String selected = statuses.contains(currentStatus)
        ? currentStatus
        : statuses.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.t('changePostStatus')),
          content: SizedBox(
            width: 360,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.t('newStatus'),
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selected,
                  isExpanded: true,
                  items: statuses
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(_postStatusLabel(l10n, s)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => selected = v);
                  },
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.t('apply')),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      bloc.add(UpdatePostStatusEvent(selected));
    }
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
          color: disabled ? Colors.grey.shade300 : color.withValues(alpha: 0.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
