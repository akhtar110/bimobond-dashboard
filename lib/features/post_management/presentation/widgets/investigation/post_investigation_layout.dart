import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/localization.dart';
import '../../../domain/entities/managed_post_entity.dart';
import '../../bloc/post_management_bloc.dart';
import '../comments_moderation_panel.dart';
import '../post_author_card.dart';
import 'activity_context_card.dart';
import 'activity_relationship_banner.dart';
import 'compact_analytics_grid.dart';
import 'investigation_theme.dart';
import 'moderation_sidebar.dart';
import 'post_content_section.dart';
import 'post_status_actions_panel.dart';
import 'post_surface_card.dart';
import 'post_user_sidebar.dart';

/// Modern moderation workspace — post content + investigation sidebar + comments.
class PostInvestigationLayout extends StatelessWidget {
  const PostInvestigationLayout({
    super.key,
    required this.isDark,
    required this.isBusy,
    required this.isSaving,
    required this.dirty,
    required this.captionController,
    required this.onCaptionChanged,
    required this.onCategorySelected,
    required this.onPrivacyChanged,
    required this.onDraftToggle,
    required this.onChangeStatus,
    required this.onSave,
    required this.onDelete,
  });

  final bool isDark;
  final bool isBusy;
  final bool isSaving;
  final bool dirty;
  final TextEditingController captionController;
  final VoidCallback onCaptionChanged;
  final void Function(CategoryEntity) onCategorySelected;
  final ValueChanged<String> onPrivacyChanged;
  final void Function(ManagedPostEntity Function(ManagedPostEntity) updater)
      onDraftToggle;
  final VoidCallback onChangeStatus;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PostManagementBloc, PostManagementState,
        PostManagementLoaded?>(
      selector: (s) => s is PostManagementLoaded ? s : null,
      builder: (context, loaded) {
        if (loaded == null) return const SizedBox.shrink();
        return _InvestigationBody(
          state: loaded,
          isDark: isDark,
          isBusy: isBusy,
          isSaving: isSaving,
          dirty: dirty,
          captionController: captionController,
          onCaptionChanged: onCaptionChanged,
          onCategorySelected: onCategorySelected,
          onPrivacyChanged: onPrivacyChanged,
          onDraftToggle: onDraftToggle,
          onChangeStatus: onChangeStatus,
          onSave: onSave,
          onDelete: onDelete,
        );
      },
    );
  }
}

class _InvestigationBody extends StatelessWidget {
  const _InvestigationBody({
    required this.state,
    required this.isDark,
    required this.isBusy,
    required this.isSaving,
    required this.dirty,
    required this.captionController,
    required this.onCaptionChanged,
    required this.onCategorySelected,
    required this.onPrivacyChanged,
    required this.onDraftToggle,
    required this.onChangeStatus,
    required this.onSave,
    required this.onDelete,
  });

  final PostManagementLoaded state;
  final bool isDark;
  final bool isBusy;
  final bool isSaving;
  final bool dirty;
  final TextEditingController captionController;
  final VoidCallback onCaptionChanged;
  final void Function(CategoryEntity) onCategorySelected;
  final ValueChanged<String> onPrivacyChanged;
  final void Function(ManagedPostEntity Function(ManagedPostEntity) updater)
      onDraftToggle;
  final VoidCallback onChangeStatus;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final highlightId = state.activityContext?.highlightCommentId;
    final l10n = context.l10n;

    Widget investigationSidebar() {
      return BlocSelector<PostManagementBloc, PostManagementState,
          ({ManagedPostEntity post, ManagedPostEntity draft, bool saving, bool deleting})>(
        selector: (s) {
          if (s is! PostManagementLoaded) {
            return (
              post: state.post,
              draft: state.draft,
              saving: false,
              deleting: false,
            );
          }
          return (
            post: s.post,
            draft: s.draft,
            saving: s.isSaving,
            deleting: s.isDeleting,
          );
        },
        builder: (context, data) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.sourceUser != null) ...[
                PostUserSidebar(user: state.sourceUser!, isDark: isDark),
                const SizedBox(height: InvestigationTheme.s12),
              ],
              PostAuthorCard(post: data.post, isDark: isDark),
              const SizedBox(height: InvestigationTheme.s12),
              PostSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.t('postStatistics'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: InvestigationTheme.s8),
                    CompactAnalyticsGrid(
                      isDark: isDark,
                      metrics: _metricsFor(data.post, l10n),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: InvestigationTheme.s12),
              PostStatusActionsPanel(
                currentStatus: data.draft.status,
                isBusy: isBusy,
                isDark: isDark,
              ),
              if (state.activityContext != null) ...[
                const SizedBox(height: InvestigationTheme.s12),
                ActivityContextCard(
                  activityContext: state.activityContext!,
                  isDark: isDark,
                ),
              ],
              const SizedBox(height: InvestigationTheme.s12),
              ModerationSidebar(
                post: data.post,
                draft: data.draft,
                isBusy: isBusy,
                isSaving: data.saving,
                isDeleting: data.deleting,
                onDraftToggle: onDraftToggle,
                onDelete: onDelete,
                onSave: onSave,
              ),
            ],
          );
        },
      );
    }

    Widget mainContent() {
      return BlocSelector<PostManagementBloc, PostManagementState,
          ManagedPostEntity>(
        selector: (s) => s is PostManagementLoaded ? s.draft : state.draft,
        builder: (context, draft) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.sourceUser != null &&
                  state.activityContext != null &&
                  state.sourceUser!.id != state.post.userId)
                ActivityRelationshipBanner(
                  sourceUser: state.sourceUser!,
                  post: state.post,
                  activityContext: state.activityContext!,
                ),
              if (state.sourceUser != null &&
                  state.activityContext != null &&
                  state.sourceUser!.id != state.post.userId)
                const SizedBox(height: InvestigationTheme.s12),
              PostContentSection(
                draft: draft,
                isBusy: isBusy,
                captionController: captionController,
                onCaptionChanged: onCaptionChanged,
                onCategorySelected: onCategorySelected,
                onPrivacyChanged: onPrivacyChanged,
              ),
            ],
          );
        },
      );
    }

    Widget commentsSection() {
      return BlocSelector<PostManagementBloc, PostManagementState,
          PostManagementLoaded>(
        selector: (s) => s is PostManagementLoaded ? s : state,
        builder: (context, commentsState) {
          return CommentsModerationPanel(
            state: commentsState,
            isDark: isDark,
            isBusy: isBusy,
            highlightCommentId: highlightId,
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final desktop = width >= InvestigationTheme.desktop;
        final tablet = width >= InvestigationTheme.tablet && !desktop;

        final topRow = desktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: mainContent()),
                  const SizedBox(width: InvestigationTheme.s24),
                  Expanded(flex: 3, child: investigationSidebar()),
                ],
              )
            : tablet
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: mainContent()),
                      const SizedBox(width: InvestigationTheme.s16),
                      Expanded(flex: 4, child: investigationSidebar()),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      mainContent(),
                      const SizedBox(height: InvestigationTheme.s16),
                      investigationSidebar(),
                    ],
                  );

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        topRow,
                        const SizedBox(height: InvestigationTheme.s24),
                        commentsSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (dirty)
              _FloatingSaveBar(
                isSaving: isSaving,
                isBusy: isBusy,
                onSave: onSave,
              ),
          ],
        );
      },
    );
  }

  List<({IconData icon, String label, int value, Color? color})> _metricsFor(
    ManagedPostEntity post,
    AppLocalizations l10n,
  ) {
    return [
      (
        icon: Icons.visibility_outlined,
        label: l10n.t('views'),
        value: post.viewCount,
        color: const Color(0xFF6366F1),
      ),
      (
        icon: Icons.favorite_border_rounded,
        label: l10n.t('likes'),
        value: post.likeCount,
        color: const Color(0xFFEC4899),
      ),
      (
        icon: Icons.chat_bubble_outline_rounded,
        label: l10n.t('comments'),
        value: post.commentCount,
        color: const Color(0xFF3B82F6),
      ),
      (
        icon: Icons.share_outlined,
        label: l10n.t('shares'),
        value: post.shareCount,
        color: const Color(0xFF14B8A6),
      ),
      (
        icon: Icons.bookmark_border_rounded,
        label: l10n.t('saves'),
        value: post.saveCount,
        color: const Color(0xFFF59E0B),
      ),
      (
        icon: Icons.trending_up_rounded,
        label: l10n.t('reach'),
        value: post.viewCount + post.shareCount,
        color: const Color(0xFF8B5CF6),
      ),
    ];
  }
}

class _FloatingSaveBar extends StatelessWidget {
  const _FloatingSaveBar({
    required this.isSaving,
    required this.isBusy,
    required this.onSave,
  });

  final bool isSaving;
  final bool isBusy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: InvestigationTheme.animMs),
      offset: Offset.zero,
      child: Material(
        elevation: 8,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.t('unsavedChanges'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                FilledButton.icon(
                  onPressed: isBusy ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(context.l10n.t('saveChangesPost')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
