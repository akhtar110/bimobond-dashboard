import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/localization.dart';
import '../../../domain/entities/managed_post_entity.dart';
import '../../bloc/post_management_bloc.dart';
import '../comments_moderation_panel.dart';
import '../post_author_card.dart';
import 'activity_context_card.dart';
import 'activity_relationship_banner.dart';
import 'moderation_sidebar.dart';
import 'post_content_section.dart';
import 'post_user_sidebar.dart';

/// Three-panel moderation investigation layout.
class PostInvestigationLayout extends StatelessWidget {
  const PostInvestigationLayout({
    super.key,
    required this.isDark,
    required this.isBusy,
    required this.isSaving,
    required this.dirty,
    required this.captionController,
    required this.categoryController,
    required this.onCaptionChanged,
    required this.onCategoryChanged,
    required this.onPrivacyChanged,
    required this.onDraftToggle,
    required this.onChangeStatus,
    required this.onSave,
  });

  final bool isDark;
  final bool isBusy;
  final bool isSaving;
  final bool dirty;
  final TextEditingController captionController;
  final TextEditingController categoryController;
  final VoidCallback onCaptionChanged;
  final VoidCallback onCategoryChanged;
  final ValueChanged<String> onPrivacyChanged;
  final void Function(ManagedPostEntity Function(ManagedPostEntity) updater)
      onDraftToggle;
  final VoidCallback onChangeStatus;
  final VoidCallback onSave;

  static const _desktop = 1240.0;
  static const _tablet = 880.0;
  static const _userSidebarWidth = 280.0;
  static const _modSidebarWidth = 360.0;

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
          categoryController: categoryController,
          onCaptionChanged: onCaptionChanged,
          onCategoryChanged: onCategoryChanged,
          onPrivacyChanged: onPrivacyChanged,
          onDraftToggle: onDraftToggle,
          onChangeStatus: onChangeStatus,
          onSave: onSave,
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
    required this.categoryController,
    required this.onCaptionChanged,
    required this.onCategoryChanged,
    required this.onPrivacyChanged,
    required this.onDraftToggle,
    required this.onChangeStatus,
    required this.onSave,
  });

  final PostManagementLoaded state;
  final bool isDark;
  final bool isBusy;
  final bool isSaving;
  final bool dirty;
  final TextEditingController captionController;
  final TextEditingController categoryController;
  final VoidCallback onCaptionChanged;
  final VoidCallback onCategoryChanged;
  final ValueChanged<String> onPrivacyChanged;
  final void Function(ManagedPostEntity Function(ManagedPostEntity) updater)
      onDraftToggle;
  final VoidCallback onChangeStatus;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final highlightId = state.activityContext?.highlightCommentId;

    Widget leftSidebar() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.sourceUser != null)
            PostUserSidebar(user: state.sourceUser!, isDark: isDark),
          if (state.sourceUser != null && state.activityContext != null)
            const SizedBox(height: 12),
          if (state.activityContext != null)
            ActivityContextCard(
              activityContext: state.activityContext!,
              isDark: isDark,
            ),
          if (state.sourceUser == null && state.activityContext == null)
            PostAuthorCard(post: state.post, isDark: isDark),
        ],
      );
    }

    Widget centerContent() {
      return BlocSelector<PostManagementBloc, PostManagementState,
          ManagedPostEntity>(
        selector: (s) =>
            s is PostManagementLoaded ? s.draft : state.draft,
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
              if (state.sourceUser != null) ...[
                const SizedBox(height: 12),
                PostAuthorCard(post: state.post, isDark: isDark),
              ],
              const SizedBox(height: 16),
              PostContentSection(
                draft: draft,
                isBusy: isBusy,
                captionController: captionController,
                categoryController: categoryController,
                onCaptionChanged: onCaptionChanged,
                onCategoryChanged: onCategoryChanged,
                onPrivacyChanged: onPrivacyChanged,
              ),
              const SizedBox(height: 16),
              BlocSelector<PostManagementBloc, PostManagementState,
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
              ),
            ],
          );
        },
      );
    }

    Widget rightSidebar() {
      return BlocSelector<PostManagementBloc, PostManagementState,
          ({ManagedPostEntity post, ManagedPostEntity draft, bool saving})>(
        selector: (s) {
          if (s is! PostManagementLoaded) {
            return (post: state.post, draft: state.draft, saving: false);
          }
          return (post: s.post, draft: s.draft, saving: s.isSaving);
        },
        builder: (context, data) {
          return ModerationSidebar(
            post: data.post,
            draft: data.draft,
            isBusy: isBusy,
            isSaving: data.saving,
            onChangeStatus: onChangeStatus,
            onDraftToggle: onDraftToggle,
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final desktop = width >= PostInvestigationLayout._desktop;
        final tablet =
            width >= PostInvestigationLayout._tablet && !desktop;

        final panels = desktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: PostInvestigationLayout._userSidebarWidth,
                    child: SingleChildScrollView(child: leftSidebar()),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: SingleChildScrollView(child: centerContent()),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: PostInvestigationLayout._modSidebarWidth,
                    child: SingleChildScrollView(child: rightSidebar()),
                  ),
                ],
              )
            : tablet
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: PostInvestigationLayout._userSidebarWidth,
                        child: leftSidebar(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            centerContent(),
                            const SizedBox(height: 16),
                            rightSidebar(),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      leftSidebar(),
                      const SizedBox(height: 16),
                      centerContent(),
                      const SizedBox(height: 16),
                      rightSidebar(),
                    ],
                  );

        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1660),
                    child: desktop
                        ? panels
                        : SingleChildScrollView(child: panels),
                  ),
                ),
              ),
            ),
            if (dirty) _SaveBar(isSaving: isSaving, isBusy: isBusy, onSave: onSave),
          ],
        );
      },
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.isSaving,
    required this.isBusy,
    required this.onSave,
  });

  final bool isSaving;
  final bool isBusy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
    );
  }
}
