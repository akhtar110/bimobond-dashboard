import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/activity_context.dart';
import '../../domain/entities/managed_post_entity.dart';
import '../../domain/entities/post_management_route_args.dart';
import '../bloc/post_management_bloc.dart';
import '../utils/post_detail_labels.dart';
import '../widgets/investigation/post_investigation_layout.dart';

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
    return BlocProvider(
      create: (_) => sl<PostManagementBloc>()
        ..add(
          LoadManagedPostEvent(
            post,
            sourceUser: sourceUser,
            activityContext: activityContext,
          ),
        ),
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

  String? _lastDraftKey;
  String? _lastSnack;
  ManagedPostEntity? _updatedPost;

  static const _postStatuses = [
    'PUBLISHED',
    'DRAFT',
    'HIDDEN',
    'BANNED',
    'UNDER_REVIEW',
    'ARCHIVED',
  ];

  @override
  void dispose() {
    _captionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _syncDraftControllers(ManagedPostEntity draft) {
    final key = '${draft.id}_${draft.updatedAt.millisecondsSinceEpoch}';
    if (_lastDraftKey == key) return;
    _lastDraftKey = key;
    _captionController.text = draft.description ?? '';
    _categoryController.text = draft.category ?? '';
  }

  void _patchDraftFromControllers(PostManagementBloc bloc) {
    final state = bloc.state;
    if (state is! PostManagementLoaded) return;
    bloc.add(
      ChangeManagedPostFieldEvent(
        state.draft.copyWith(
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
    ManagedPostEntity Function(ManagedPostEntity draft) updater,
  ) {
    final state = bloc.state;
    if (state is! PostManagementLoaded) return;
    bloc.add(ChangeManagedPostFieldEvent(updater(state.draft)));
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    if (_lastSnack == msg) return;
    _lastSnack = msg;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Colors.green.shade700,
      ),
    );
  }

  Future<void> _showChangeStatusDialog(
    BuildContext context,
    String currentStatus,
  ) async {
    final l10n = context.l10n;
    final bloc = context.read<PostManagementBloc>();
    final scheme = Theme.of(context).colorScheme;

    var selected = _postStatuses.contains(currentStatus.toUpperCase())
        ? currentStatus.toUpperCase()
        : _postStatuses.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(l10n.t('changePostStatus')),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _postStatuses.map((status) {
                  final isSelected = selected == status;
                  final label = postStatusLabel(l10n, status);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: isSelected
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => setState(() => selected = status),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 18,
                                color: isSelected
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
          );
        },
      ),
    );

    if (confirmed == true && context.mounted) {
      bloc.add(UpdatePostStatusEvent(selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_updatedPost);
      },
      child: BlocConsumer<PostManagementBloc, PostManagementState>(
        listener: (context, state) {
          if (state is PostManagementLoaded) {
            _syncDraftControllers(state.draft);
            if (state.successMessage != null) {
              _updatedPost = state.post;
              final text = state.successMessage == 'commentDeleted'
                  ? l10n.t('commentDeleted')
                  : state.successMessage!;
              _showSnack(context, text);
            } else if (state.errorMessage != null) {
              _showSnack(context, state.errorMessage!, isError: true);
            }
          }
          if (state is PostManagementDeleted) Navigator.pop(context, true);
          if (state is PostManagementError) {
            _showSnack(context, state.message, isError: true);
          }
        },
        builder: (context, state) {
          final loaded = state is PostManagementLoaded ? state : null;
          final isBusy = loaded != null &&
              (loaded.isSaving ||
                  loaded.isDeleting ||
                  loaded.isActioning);
          final dirty = loaded != null &&
              hasDraftChanges(loaded.post, loaded.draft);

          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: theme.colorScheme.surface,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context, _updatedPost),
              ),
              titleSpacing: 0,
              title: Text(
                l10n.t('postManagementTitle'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            body: switch (state) {
              PostManagementLoading() || PostManagementInitial() =>
                const Center(child: CircularProgressIndicator()),
              PostManagementError(:final message) =>
                Center(child: Text(message)),
              PostManagementDeleted() => const SizedBox.shrink(),
              PostManagementLoaded() => PostInvestigationLayout(
                  isDark: theme.brightness == Brightness.dark,
                  isBusy: isBusy,
                  isSaving: loaded!.isSaving,
                  dirty: dirty,
                  captionController: _captionController,
                  categoryController: _categoryController,
                  onCaptionChanged: () => _patchDraftFromControllers(
                    context.read<PostManagementBloc>(),
                  ),
                  onCategoryChanged: () => _patchDraftFromControllers(
                    context.read<PostManagementBloc>(),
                  ),
                  onPrivacyChanged: (v) => _updateDraft(
                    context.read<PostManagementBloc>(),
                    (d) => d.copyWith(privacyStatus: v),
                  ),
                  onDraftToggle: (updater) => _updateDraft(
                    context.read<PostManagementBloc>(),
                    updater,
                  ),
                  onChangeStatus: () => _showChangeStatusDialog(
                    context,
                    loaded.draft.status,
                  ),
                  onSave: () => context
                      .read<PostManagementBloc>()
                      .add(UpdateManagedPostEvent()),
                ),
            },
          );
        },
      ),
    );
  }
}
