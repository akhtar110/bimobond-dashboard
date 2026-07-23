import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../bloc/post_management_bloc.dart';
import '../utils/moderation_confirm_dialog.dart';
import 'investigation/investigation_theme.dart';
import 'investigation/post_surface_card.dart';

enum _CommentFilter { all, recent, oldest, reported, hidden }

class CommentsModerationPanel extends StatefulWidget {
  const CommentsModerationPanel({
    super.key,
    required this.state,
    this.isDark = false,
    required this.isBusy,
    this.highlightCommentId,
    this.embedded = false,
  });

  final PostManagementLoaded state;
  final bool isDark;
  final bool isBusy;
  final String? highlightCommentId;
  final bool embedded;

  @override
  State<CommentsModerationPanel> createState() =>
      _CommentsModerationPanelState();
}

class _CommentsModerationPanelState extends State<CommentsModerationPanel> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _highlightKeys = <String, GlobalKey>{};
  bool _didScrollToHighlight = false;
  _CommentFilter _filter = _CommentFilter.all;

  PostManagementLoaded get state => widget.state;
  bool get isBusy => widget.isBusy;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CommentsModerationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightCommentId != widget.highlightCommentId) {
      _didScrollToHighlight = false;
    }
  }

  void _scrollToHighlight() {
    final id = widget.highlightCommentId;
    if (id == null || _didScrollToHighlight) return;
    final key = _highlightKeys[id];
    if (key?.currentContext == null) return;
    _didScrollToHighlight = true;
    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
  }

  List<CommentEntity> _filteredComments() {
    var list = List<CommentEntity>.from(state.comments);
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list
          .where(
            (c) =>
                c.content.toLowerCase().contains(query) ||
                c.displayName.toLowerCase().contains(query),
          )
          .toList();
    }

    switch (_filter) {
      case _CommentFilter.recent:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _CommentFilter.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _CommentFilter.reported:
        final hid = widget.highlightCommentId;
        list = hid == null
            ? <CommentEntity>[]
            : list.where((c) => c.id == hid).toList();
      case _CommentFilter.hidden:
        list = <CommentEntity>[];
      case _CommentFilter.all:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bloc = context.read<PostManagementBloc>();
    final filtered = _filteredComments();

    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.embedded)
            Row(
              children: [
                Icon(Icons.forum_outlined, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.t('commentsInvestigation'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.t('refresh'),
                  visualDensity: VisualDensity.compact,
                  onPressed: state.isCommentsLoading || isBusy
                      ? null
                      : () => bloc.add(LoadPostCommentsEvent()),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                ),
              ],
            ),
          if (!widget.embedded) const SizedBox(height: InvestigationTheme.s8),
          Wrap(
            spacing: InvestigationTheme.s16,
            runSpacing: InvestigationTheme.s4,
            children: [
              _HeaderStat(
                label: l10n.t('comments'),
                value: '${state.comments.length}',
              ),
              if (widget.highlightCommentId != null)
                _HeaderStat(
                  label: l10n.t('filterReported'),
                  value: '1',
                  accent: theme.colorScheme.tertiary,
                ),
            ],
          ),
          const SizedBox(height: InvestigationTheme.s12),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InvestigationTheme.fieldDecoration(
              context,
              hintText: l10n.t('searchComments'),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
            ),
          ),
          const SizedBox(height: InvestigationTheme.s12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: l10n.t('filterAll'),
                  selected: _filter == _CommentFilter.all,
                  onTap: () => setState(() => _filter = _CommentFilter.all),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: l10n.t('filterRecent'),
                  selected: _filter == _CommentFilter.recent,
                  onTap: () => setState(() => _filter = _CommentFilter.recent),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: l10n.t('filterOldest'),
                  selected: _filter == _CommentFilter.oldest,
                  onTap: () => setState(() => _filter = _CommentFilter.oldest),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: l10n.t('filterReported'),
                  selected: _filter == _CommentFilter.reported,
                  onTap: () => setState(() => _filter = _CommentFilter.reported),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: l10n.t('filterHidden'),
                  selected: _filter == _CommentFilter.hidden,
                  onTap: () => setState(() => _filter = _CommentFilter.hidden),
                ),
              ],
            ),
          ),
          const SizedBox(height: InvestigationTheme.s16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: InvestigationTheme.animMs),
            child: _buildBody(context, bloc, l10n, theme, filtered),
          ),
        ],
      );

    if (widget.embedded) return content;

    return PostSurfaceCard(child: content);
  }

  Widget _buildBody(
    BuildContext context,
    PostManagementBloc bloc,
    AppLocalizations l10n,
    ThemeData theme,
    List<CommentEntity> filtered,
  ) {
    if (state.isCommentsLoading && state.comments.isEmpty) {
      return const _CommentsSkeleton();
    }

    if (state.commentsError != null && state.comments.isEmpty) {
      return _CommentsMessage(
        icon: Icons.error_outline_rounded,
        message: state.commentsError!,
        actionLabel: l10n.t('tryAgain'),
        onAction: () => bloc.add(LoadPostCommentsEvent()),
      );
    }

    if (state.comments.isEmpty) {
      return _CommentsMessage(
        icon: Icons.chat_bubble_outline_rounded,
        message: l10n.t('noCommentsOnPost'),
        actionLabel: l10n.t('refresh'),
        onAction: () => bloc.add(LoadPostCommentsEvent()),
      );
    }

    if (filtered.isEmpty) {
      return _CommentsMessage(
        icon: Icons.filter_alt_off_outlined,
        message: l10n.t('noCommentsFilter'),
        actionLabel: l10n.t('filterAll'),
        onAction: () => setState(() {
          _filter = _CommentFilter.all;
          _searchController.clear();
        }),
      );
    }

    return Column(
      key: ValueKey('comments-${filtered.length}-$_filter'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: InvestigationTheme.s8),
          itemBuilder: (context, index) {
            final comment = filtered[index];
            final isDeleting = state.deletingCommentId == comment.id;
            final highlighted = widget.highlightCommentId != null &&
                widget.highlightCommentId == comment.id;
            final key = _highlightKeys.putIfAbsent(comment.id, GlobalKey.new);
            if (highlighted && !_didScrollToHighlight) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _scrollToHighlight();
                Future.delayed(const Duration(milliseconds: 350), () {
                  if (mounted) _scrollToHighlight();
                });
              });
            }
            return _CommentCard(
              key: key,
              comment: comment,
              isDeleting: isDeleting,
              highlighted: highlighted,
              disabled: isBusy || state.deletingCommentId != null,
              onDelete: () => _confirmDeleteComment(context, bloc, comment),
              onViewProfile: () => _openUserProfile(context, comment),
            );
          },
        ),
        if (state.commentsHasMore) ...[
          const SizedBox(height: InvestigationTheme.s12),
          OutlinedButton.icon(
            onPressed: state.isCommentsLoadingMore || isBusy
                ? null
                : () => bloc.add(LoadMorePostCommentsEvent()),
            icon: state.isCommentsLoadingMore
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.expand_more_rounded, size: 18),
            label: Text(l10n.t('loadMoreComments')),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
              ),
            ),
          ),
        ],
        if (state.commentsError != null && state.comments.isNotEmpty) ...[
          const SizedBox(height: InvestigationTheme.s8),
          Text(
            state.commentsError!,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  void _openUserProfile(BuildContext context, CommentEntity comment) {
    final user = UserEntity(
      id: comment.userId,
      username: comment.username ?? comment.userId,
      fullName: comment.fullName,
      isVerified: false,
      isPrivate: false,
      allowComments: true,
      allowDirectMsgs: true,
      language: 'en',
      theme: 'light',
      followerCount: 0,
      followingCount: 0,
      postCount: 0,
      totalLikes: 0,
      isBanned: false,
      roles: const [],
      avatarUrl: comment.avatarUrl,
    );
    Navigator.pushNamed(context, AppRoutes.userDetail, arguments: user);
  }

  Future<void> _confirmDeleteComment(
    BuildContext context,
    PostManagementBloc bloc,
    CommentEntity comment,
  ) async {
    final confirmed = await showDeleteCommentConfirmDialog(context);

    if (confirmed && context.mounted) {
      bloc.add(DeletePostCommentAdminEvent(comment.id));
    }
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: InvestigationTheme.mutedText(context),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: InvestigationTheme.animMs),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.5)
                  : scheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    super.key,
    required this.comment,
    required this.isDeleting,
    required this.highlighted,
    required this.disabled,
    required this.onDelete,
    required this.onViewProfile,
  });

  final CommentEntity comment;
  final bool isDeleting;
  final bool highlighted;
  final bool disabled;
  final VoidCallback onDelete;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final dateFormat = DateFormat('MMM d, yyyy · HH:mm');
    final borderColor = highlighted
        ? scheme.tertiary.withValues(alpha: 0.65)
        : scheme.outlineVariant.withValues(alpha: 0.4);
    final username = comment.username?.trim();
    final showUsername = username != null &&
        username.isNotEmpty &&
        username != comment.displayName;

    return AnimatedContainer(
      duration: const Duration(milliseconds: InvestigationTheme.animMs),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: highlighted
            ? scheme.tertiaryContainer.withValues(alpha: 0.45)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: highlighted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (highlighted)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: scheme.onTertiaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    l10n.t('selectedActivity'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: disabled ? null : onViewProfile,
                borderRadius: BorderRadius.circular(20),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  backgroundImage: comment.avatarUrl != null &&
                          comment.avatarUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(comment.avatarUrl!)
                      : null,
                  child: comment.avatarUrl == null ||
                          comment.avatarUrl!.isEmpty
                      ? Text(
                          comment.displayName.isNotEmpty
                              ? comment.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  height: 1.2,
                                  color: scheme.onSurface,
                                ),
                              ),
                              if (showUsername)
                                Text(
                                  '@$username',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      theme.textTheme.labelSmall?.copyWith(
                                    color: InvestigationTheme.mutedText(
                                        context),
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            dateFormat.format(comment.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: InvestigationTheme.mutedText(context),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: highlighted
                              ? scheme.surface.withValues(alpha: 0.55)
                              : scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          border: Border.all(
                            color: scheme.outlineVariant
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          comment.content,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12.5,
                            height: 1.45,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isDeleting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Row(
              children: [
                _MetaChip(
                  icon: Icons.favorite_border,
                  label: '${comment.likeCount}',
                ),
                const SizedBox(width: 12),
                _MetaChip(
                  icon: Icons.reply_rounded,
                  label: '${comment.replyCount} ${l10n.t('replies')}',
                ),
                const Spacer(),
                _ActionBtn(
                  icon: Icons.person_outline,
                  label: l10n.t('viewProfile'),
                  onPressed: disabled ? null : onViewProfile,
                ),
                const SizedBox(width: 4),
                _ActionBtn(
                  icon: Icons.delete_outline,
                  label: l10n.t('delete'),
                  onPressed: disabled ? null : onDelete,
                  danger: true,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: InvestigationTheme.mutedText(context)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: InvestigationTheme.mutedText(context),
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = danger ? scheme.error : scheme.onSurfaceVariant;
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(fontSize: 11, color: color)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _CommentsSkeleton extends StatelessWidget {
  const _CommentsSkeleton();

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentsMessage extends StatelessWidget {
  const _CommentsMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 36,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
