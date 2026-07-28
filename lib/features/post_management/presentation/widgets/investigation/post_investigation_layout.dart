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
    return BlocSelector<
      PostManagementBloc,
      PostManagementState,
      PostManagementLoaded?
    >(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget moderationSidebar() {
      return BlocSelector<
        PostManagementBloc,
        PostManagementState,
        ({
          ManagedPostEntity post,
          ManagedPostEntity draft,
          bool saving,
          bool deleting,
        })
      >(
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
      return BlocSelector<
        PostManagementBloc,
        PostManagementState,
        ManagedPostEntity
      >(
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
      return BlocSelector<
        PostManagementBloc,
        PostManagementState,
        PostMediaSnapshot?
      >(
        selector: (s) => s is PostManagementLoaded
            ? PostMediaSnapshot.fromPost(s.post)
            : null,
        builder: (context, snapshot) {
          if (snapshot == null) return const SizedBox.shrink();
          return PortraitMediaPanel(snapshot: snapshot);
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaWidth = MediaQuery.sizeOf(context).width;
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : mediaWidth;
        final isThreeColumn = width >= InvestigationTheme.threeColumn;
        final isWide = width >= InvestigationTheme.wide;
        final isTablet =
            width >= InvestigationTheme.tablet &&
            width < InvestigationTheme.threeColumn;
        final twoColumnSideBySide = width >= InvestigationTheme.twoColumnRow;
        final pagePadding = width < InvestigationTheme.tablet
            ? 12.0
            : width < InvestigationTheme.twoColumnRow
            ? 16.0
            : 20.0;

        Widget columns;
        Widget centeredMedia() {
          return LayoutBuilder(
            builder: (context, mediaConstraints) {
              final parentW =
                  mediaConstraints.maxWidth.isFinite &&
                      mediaConstraints.maxWidth > 0
                  ? mediaConstraints.maxWidth
                  : width;
              final cap = parentW.clamp(280.0, 750.0);
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cap),
                  child: leftMedia(),
                ),
              );
            },
          );
        }

        Widget moderationColumn() {
          return moderationSidebar();
        }

        if (isThreeColumn) {
          columns = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: isWide ? 30 : 32, child: moderationColumn()),
              const SizedBox(width: InvestigationTheme.s16),
              Expanded(flex: isWide ? 40 : 36, child: centeredMedia()),
              const SizedBox(width: InvestigationTheme.s16),
              Expanded(flex: isWide ? 30 : 32, child: centerContent()),
            ],
          );
        } else if (isTablet && twoColumnSideBySide) {
          columns = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              centeredMedia(),
              const SizedBox(height: InvestigationTheme.s16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: centerContent()),
                  const SizedBox(width: InvestigationTheme.s16),
                  Expanded(child: moderationColumn()),
                ],
              ),
            ],
          );
        } else {
          columns = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              centeredMedia(),
              const SizedBox(height: InvestigationTheme.s16),
              centerContent(),
              const SizedBox(height: InvestigationTheme.s16),
              moderationColumn(),
            ],
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(pagePadding, 8, pagePadding, 20),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: width.clamp(320.0, 1920.0),
                    ),
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
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < InvestigationTheme.compact;

    return Material(
      elevation: 0,
      color: scheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 24,
            vertical: 12,
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note_rounded, color: scheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.t('unsavedChanges'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
                )
              : Row(
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
