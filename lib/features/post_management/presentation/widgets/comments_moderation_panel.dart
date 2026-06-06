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
    required this.isDark,
    required this.isBusy,
    this.highlightCommentId,
  });

  final PostManagementLoaded state;
  final bool isDark;
  final bool isBusy;
  final String? highlightCommentId;

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
  bool get isDark => widget.isDark;
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

    return PostSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: InvestigationTheme.s8),
          Wrap(
            spacing: InvestigationTheme.s16,
            runSpacing: InvestigationTheme.s4,
            children: [
              _HeaderStat(
                label: l10n.t('comments'),
                value: '${state.comments.length}',
                isDark: isDark,
              ),
              if (widget.highlightCommentId != null)
                _HeaderStat(
                  label: l10n.t('filterReported'),
                  value: '1',
                  isDark: isDark,
                  accent: Colors.orange,
                ),
            ],
          ),
          const SizedBox(height: InvestigationTheme.s12),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.t('searchComments'),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F1421) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: l10n.t('filterRecent'),
                  selected: _filter == _CommentFilter.recent,
                  onTap: () => setState(() => _filter = _CommentFilter.recent),
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: l10n.t('filterOldest'),
                  selected: _filter == _CommentFilter.oldest,
                  onTap: () => setState(() => _filter = _CommentFilter.oldest),
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: l10n.t('filterReported'),
                  selected: _filter == _CommentFilter.reported,
                  onTap: () => setState(() => _filter = _CommentFilter.reported),
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: l10n.t('filterHidden'),
                  selected: _filter == _CommentFilter.hidden,
                  onTap: () => setState(() => _filter = _CommentFilter.hidden),
                  isDark: isDark,
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
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PostManagementBloc bloc,
    AppLocalizations l10n,
    ThemeData theme,
    List<CommentEntity> filtered,
  ) {
    if (state.isCommentsLoading && state.comments.isEmpty) {
      return _CommentsSkeleton(isDark: isDark);
    }

    if (state.commentsError != null && state.comments.isEmpty) {
      return _CommentsMessage(
        icon: Icons.error_outline_rounded,
        message: state.commentsError!,
        actionLabel: l10n.t('tryAgain'),
        onAction: () => bloc.add(LoadPostCommentsEvent()),
        isDark: isDark,
      );
    }

    if (state.comments.isEmpty) {
      return _CommentsMessage(
        icon: Icons.chat_bubble_outline_rounded,
        message: l10n.t('noCommentsOnPost'),
        actionLabel: l10n.t('refresh'),
        onAction: () => bloc.add(LoadPostCommentsEvent()),
        isDark: isDark,
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
        isDark: isDark,
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
                if (mounted) _scrollToHighlight();
              });
            }
            return _CommentCard(
              key: key,
              comment: comment,
              isDark: isDark,
              isDeleting: isDeleting,
              highlighted: highlighted,
              disabled: isBusy || state.deletingCommentId != null,
              onDelete: () => _confirmDeleteComment(context, bloc, comment),
              onBanUser: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.t('banUserComingSoon')),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              onViewProfile: () => _openUserProfile(context, comment),
              onHide: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.t('banUserComingSoon')),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
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
            style: TextStyle(fontSize: 12, color: Colors.red.shade400),
          ),
        ],
      ],
    );
  }

  void _openUserProfile(BuildContext context, CommentEntity comment) {
    final user = UserEntity(
      id: comment.userId,
      username: comment.username ?? comment.userId,
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
    required this.isDark,
    this.accent,
  });

  final String label;
  final String value;
  final bool isDark;
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
            color: InvestigationTheme.mutedText(context, isDark),
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
    required this.isDark,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
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
                ? primary.withValues(alpha: 0.12)
                : (isDark ? const Color(0xFF0F1421) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.5)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? primary : InvestigationTheme.mutedText(context, isDark),
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
    required this.isDark,
    required this.isDeleting,
    required this.highlighted,
    required this.disabled,
    required this.onDelete,
    required this.onBanUser,
    required this.onViewProfile,
    required this.onHide,
  });

  final CommentEntity comment;
  final bool isDark;
  final bool isDeleting;
  final bool highlighted;
  final bool disabled;
  final VoidCallback onDelete;
  final VoidCallback onBanUser;
  final VoidCallback onViewProfile;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final dateFormat = DateFormat('MMM d, yyyy · HH:mm');
    final borderColor = highlighted
        ? Colors.orange.shade600
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));

    return AnimatedContainer(
      duration: const Duration(milliseconds: InvestigationTheme.animMs),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? Colors.orange.withValues(alpha: 0.06)
            : (isDark ? const Color(0xFF0F1421) : const Color(0xFFFAFBFC)),
        borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
        border: Border.all(
          color: borderColor,
          width: highlighted ? 1.5 : 1,
        ),
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
                      size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                  Text(
                    l10n.t('selectedActivity'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: comment.avatarUrl != null &&
                        comment.avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(comment.avatarUrl!)
                    : null,
                child: comment.avatarUrl == null || comment.avatarUrl!.isEmpty
                    ? Text(
                        comment.displayName.isNotEmpty
                            ? comment.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 13),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            comment.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          dateFormat.format(comment.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: InvestigationTheme.mutedText(context, isDark),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      comment.content,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.45,
                        color: isDark
                            ? Colors.grey.shade300
                            : const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MetaChip(
                          icon: Icons.favorite_border,
                          label: '${comment.likeCount}',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 12),
                        _MetaChip(
                          icon: Icons.reply_rounded,
                          label: '${comment.replyCount} ${l10n.t('replies')}',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isDeleting)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _ActionBtn(
                  icon: Icons.visibility_off_outlined,
                  label: l10n.t('hideComment'),
                  onPressed: disabled ? null : onHide,
                  isDark: isDark,
                ),
                _ActionBtn(
                  icon: Icons.delete_outline,
                  label: l10n.t('delete'),
                  onPressed: disabled ? null : onDelete,
                  isDark: isDark,
                  danger: true,
                ),
                _ActionBtn(
                  icon: Icons.block_outlined,
                  label: l10n.t('banUser'),
                  onPressed: disabled ? null : onBanUser,
                  isDark: isDark,
                ),
                _ActionBtn(
                  icon: Icons.person_outline,
                  label: l10n.t('viewProfile'),
                  onPressed: disabled ? null : onViewProfile,
                  isDark: isDark,
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
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: InvestigationTheme.mutedText(context, isDark)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: InvestigationTheme.mutedText(context, isDark),
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
    required this.isDark,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isDark;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red.shade600 : InvestigationTheme.mutedText(context, isDark);
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
  const _CommentsSkeleton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
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
    required this.isDark,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F1421)
                  : const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 36,
              color: InvestigationTheme.mutedText(context, isDark),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: InvestigationTheme.mutedText(context, isDark),
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
