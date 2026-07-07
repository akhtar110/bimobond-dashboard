import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/localization.dart';
import '../../../domain/entities/activity_context.dart';
import '../../../domain/entities/managed_post_entity.dart';
import '../../bloc/post_management_bloc.dart';
import '../post_author_card.dart';
import 'activity_context_card.dart';
import 'activity_relationship_banner.dart';
import 'investigation_theme.dart';
import 'moderation_sidebar.dart';
import '../post_media_snapshot.dart';
import 'portrait_media_panel.dart';
import 'post_content_section.dart';
import 'post_engagement_panel.dart';
import 'post_status_actions_panel.dart';
import 'post_user_sidebar.dart';

/// Modern 3-column moderation workspace.
class PostInvestigationLayout extends StatelessWidget {
  const PostInvestigationLayout({
    super.key,
    required this.isBusy,
    required this.isSaving,
    required this.dirty,
    this.hideComments = false,
    required this.captionController,
    required this.onCaptionChanged,
    required this.onCategorySelected,
    required this.onPrivacyChanged,
    required this.onDraftToggle,
    required this.onChangeStatus,
    required this.onSave,
    required this.onDelete,
  });

  final bool isBusy;
  final bool isSaving;
  final bool dirty;
  final bool hideComments;
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
          isBusy: isBusy,
          isSaving: isSaving,
          dirty: dirty,
          hideComments: hideComments,
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
    required this.isBusy,
    required this.isSaving,
    required this.dirty,
    required this.hideComments,
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
  final bool isBusy;
  final bool isSaving;
  final bool dirty;
  final bool hideComments;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget moderationSidebar() {
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

    Widget centerContent() {
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
                hideComments: hideComments,
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

    Widget leftMedia() {
      return BlocSelector<PostManagementBloc, PostManagementState,
          PostMediaSnapshot?>(
        selector: (s) =>
            s is PostManagementLoaded ? PostMediaSnapshot.fromPost(s.post) : null,
        builder: (context, snapshot) {
          if (snapshot == null) return const SizedBox.shrink();
          return PortraitMediaPanel(snapshot: snapshot);
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= InvestigationTheme.desktop;
        final isTablet =
            width >= InvestigationTheme.tablet && width < InvestigationTheme.desktop;

        Widget columns;
        Widget centeredMedia({double? maxWidth}) {
          final width = maxWidth ?? 750.0;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width),
              child: leftMedia(),
            ),
          );
        }

        if (isDesktop) {
          columns = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 30,
                child: SingleChildScrollView(child: moderationSidebar()),
              ),
              const SizedBox(width: InvestigationTheme.s16),
              Expanded(
                flex: 40,
                child: centeredMedia(),
              ),
              const SizedBox(width: InvestigationTheme.s16),
              Expanded(flex: 30, child: centerContent()),
            ],
          );
        } else if (isTablet) {
          columns = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              centeredMedia(maxWidth: 750.0),
              const SizedBox(height: InvestigationTheme.s16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: centerContent()),
                  const SizedBox(width: InvestigationTheme.s16),
                  Expanded(flex: 2, child: moderationSidebar()),
                ],
              ),
            ],
          );
        } else {
          columns = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              centeredMedia(maxWidth: 750.0),
              const SizedBox(height: InvestigationTheme.s16),
              centerContent(),
              const SizedBox(height: InvestigationTheme.s16),
              moderationSidebar(),
            ],
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1920),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        columns,
                        const SizedBox(height: InvestigationTheme.s24),
                        PostEngagementPanel(
                          isBusy: isBusy,
                          hideComments: hideComments,
                          highlightCommentId: highlightId,
                          initialTabIndex: _engagementTabIndex(
                            state.activityContext,
                            hideComments: hideComments,
                          ),
                        ),
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

  int _engagementTabIndex(
    ActivityContext? context, {
    bool hideComments = false,
  }) {
    if (context == null) return 0;
    return switch (context.type) {
      ActivityType.mention => hideComments ? 2 : 3,
      ActivityType.like => hideComments ? 1 : 2,
      ActivityType.comment => 0,
      _ => 0,
    };
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
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 0,
      color: scheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.edit_note_rounded, color: scheme.primary),
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
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
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
