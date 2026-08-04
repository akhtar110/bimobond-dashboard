import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/post_media_preview.dart';
import '../../../../injection_container.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/activity_context.dart';
import '../../domain/entities/managed_post_entity.dart';
import '../../domain/entities/post_management_nav_result.dart';
import '../../domain/entities/post_management_route_args.dart';
import '../bloc/post_management_bloc.dart';
import '../utils/moderation_confirm_dialog.dart';
import '../utils/post_detail_labels.dart';
import '../utils/post_status_update_dialog.dart';
import '../services/post_detail_export_data.dart';
import '../services/post_detail_export_service.dart';
import '../utils/post_detail_export_menu.dart';
import '../widgets/investigation/investigation_header.dart';
import '../widgets/investigation/investigation_skeleton.dart';
import '../widgets/investigation/post_investigation_layout.dart';
import '../widgets/investigation/post_detail_supplementary_sections.dart';

class PostManagementDetailScreen extends StatelessWidget {
  const PostManagementDetailScreen({
    super.key,
    required this.post,
    this.sourceUser,
    this.activityContext,
  });

  final ManagedPostEntity post;
  final UserEntity? sourceUser;
  final ActivityContext? activityContext;

  factory PostManagementDetailScreen.fromArgs(PostManagementRouteArgs args) {
    return PostManagementDetailScreen(
      post: args.post,
      sourceUser: args.sourceUser,
      activityContext: args.activityContext,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('PostManagementDetailScreen rebuilt');
    return PersistentBlocProvider<PostManagementBloc>(
      debugLabel: 'PostManagementDetail',
      create: () => sl<PostManagementBloc>()
        ..add(
          LoadManagedPostEvent(
            post,
            sourceUser: sourceUser,
            activityContext: activityContext,
            skipComments: post.isStory,
          ),
        ),
      child: _PostManagementDetailView(seedPost: post),
    );
  }
}

class _PostManagementDetailView extends StatefulWidget {
  const _PostManagementDetailView({required this.seedPost});

  final ManagedPostEntity seedPost;

  @override
  State<_PostManagementDetailView> createState() =>
      _PostManagementDetailViewState();
}

class _PostManagementDetailViewState extends State<_PostManagementDetailView> {
  final _captionController = TextEditingController();

  String? _lastDraftKey;
  String? _lastSnack;
  ManagedPostEntity? _updatedPost;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _syncDraftControllers(ManagedPostEntity draft) {
    final key =
        '${draft.id}_${draft.description ?? ''}_${draft.category ?? ''}_${draft.categoryEntity?.id ?? ''}';
    if (_lastDraftKey == key) return;
    _lastDraftKey = key;
    _captionController.text = draft.description ?? '';
  }

  void _patchDraftFromControllers(PostManagementBloc bloc) {
    final state = bloc.state;
    if (state is! PostManagementLoaded) return;
    bloc.add(
      ChangeManagedPostFieldEvent(
        state.draft.copyWith(description: _captionController.text.trim()),
      ),
    );
  }

  void _updateDraft(
    PostManagementBloc bloc,
    ManagedPostEntity Function(ManagedPostEntity draft) updater,
  ) {
    final state = bloc.state;
    if (state is! PostManagementLoaded) return;
    bloc.add(ChangeManagedPostFieldEvent(updater(state.draft)));
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    if (_lastSnack == msg) return;
    _lastSnack = msg;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.tertiary,
        ),
      );
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context) async {
    final bloc = context.read<PostManagementBloc>();
    final confirmed = await showDeletePostConfirmDialog(context);

    if (confirmed && context.mounted) {
      bloc.add(DeleteManagedPostEvent());
    }
  }

  Future<void> _showChangeStatusDialog(
    BuildContext context,
    String currentStatus,
  ) async {
    await showPostStatusUpdateDialog(
      context,
      currentStatus: currentStatus,
    );
  }

  void _handleBack(BuildContext context) {
    PostVideoControllerCache.instance.pauseAll();
    if (_updatedPost != null) {
      Navigator.pop(context, PostManagementNavResult.updated(_updatedPost!));
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _handleExport(BuildContext context) async {
    final bloc = context.read<PostManagementBloc>();
    final state = bloc.state;
    if (state is! PostManagementLoaded) return;

    final format = await showPostDetailExportMenu(context);
    if (format == null || !context.mounted) return;

    final l10n = context.l10n;
    try {
      final data = PostDetailExportData.fromLoaded(state: state, l10n: l10n);
      await PostDetailExportService.export(data: data, format: format);
      if (!context.mounted) return;
      _showSnack(
        context,
        l10n.tOr('postDetailExportSuccess', 'Post details exported successfully'),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(
        context,
        l10n.tOr('postDetailExportFailed', 'Failed to export post details'),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return BlocConsumer<PostManagementBloc, PostManagementState>(
      listenWhen: (prev, curr) {
        if (curr is PostManagementDeleted || curr is PostManagementError) {
          return true;
        }
        if (curr is! PostManagementLoaded) return false;
        if (curr.successMessage != null || curr.errorMessage != null) {
          return true;
        }
        return prev is! PostManagementLoaded ||
            prev.draft.id != curr.draft.id ||
            prev.draft.description != curr.draft.description ||
            prev.draft.category != curr.draft.category ||
            prev.draft.categoryEntity?.id != curr.draft.categoryEntity?.id;
      },
      listener: (context, state) {
        if (state is PostManagementLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _syncDraftControllers(state.draft);
          });
          if (state.successMessage != null) {
            _updatedPost = state.post;
            final text = switch (state.successMessage) {
              'commentDeleted' => l10n.t('commentDeleted'),
              'noteAdded' => l10n.tOr('noteAdded', 'Note added successfully'),
              'statusUpdated' =>
                l10n.tOr('statusUpdated', 'Post status updated successfully'),
              _ => state.successMessage!,
            };
            _showSnack(context, text);
            context.read<PostManagementBloc>().add(
                  ClearPostManagementMessagesEvent(),
                );
          } else if (state.errorMessage != null) {
            _showSnack(context, state.errorMessage!, isError: true);
            context.read<PostManagementBloc>().add(
                  ClearPostManagementMessagesEvent(),
                );
          }
        }
        if (state is PostManagementDeleted) {
          PostVideoControllerCache.instance.pauseAll();
          Navigator.pop(context, const PostManagementNavResult.deleted());
        }
        if (state is PostManagementError) {
          _showSnack(context, state.message, isError: true);
        }
      },
      builder: (context, state) {
        final loaded = state is PostManagementLoaded ? state : null;
        final isBusy = loaded != null &&
            (loaded.isSaving ||
                loaded.isDeleting ||
                loaded.isActioning ||
                loaded.isSubmittingNote);
        final dirty =
            loaded != null && hasDraftChanges(loaded.post, loaded.draft);

        return Scaffold(
          backgroundColor: theme.colorScheme.surfaceContainerLowest,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surfaceContainerLowest,
                  theme.colorScheme.surface,
                  Color.alphaBlend(
                    theme.colorScheme.primary.withValues(alpha: 0.04),
                    theme.colorScheme.surfaceContainerLow,
                  ),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (loaded != null)
                  InvestigationHeader(
                    onBack: () => _handleBack(context),
                    exportEnabled: true,
                    onExport: () => _handleExport(context),
                    postId: loaded.post.id,
                  ),
                Expanded(
                  child: switch (state) {
                    PostManagementLoading() ||
                    PostManagementInitial() => const InvestigationSkeleton(),
                    PostManagementError(:final message) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(message, textAlign: TextAlign.center),
                      ),
                    ),
                    PostManagementDeleted() => const SizedBox.shrink(),
                    PostManagementLoaded() => PostInvestigationLayout(
                      isBusy: isBusy,
                      isSaving: loaded!.isSaving,
                      dirty: dirty,
                      hideComments: widget.seedPost.isStory,
                      captionController: _captionController,
                      detailExtras: const PostDetailSupplementarySections(),
                      onCaptionChanged: () => _patchDraftFromControllers(
                        context.read<PostManagementBloc>(),
                      ),
                      onCategorySelected: (CategoryEntity cat) => _updateDraft(
                        context.read<PostManagementBloc>(),
                        (d) =>
                            d.copyWith(category: cat.name, categoryEntity: cat),
                      ),
                      onPrivacyChanged: (v) => _updateDraft(
                        context.read<PostManagementBloc>(),
                        (d) => d.copyWith(privacyStatus: v),
                      ),
                      onDraftToggle: (updater) => _updateDraft(
                        context.read<PostManagementBloc>(),
                        updater,
                      ),
                      onChangeStatus: () =>
                          _showChangeStatusDialog(context, loaded.draft.status),
                      onSave: () => context.read<PostManagementBloc>().add(
                        UpdateManagedPostEvent(),
                      ),
                      onDelete: () => _showDeleteConfirmDialog(context),
                    ),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
