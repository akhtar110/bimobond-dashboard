import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/localization.dart';
import '../bloc/create_post_bloc.dart';
import '../widgets/create_post_bottom_bar.dart';
import '../widgets/create_post_field_listener.dart';
import '../widgets/create_post_step_header.dart';
import '../widgets/media_upload_section.dart';
import '../widgets/post_details_section.dart';
import '../widgets/post_preview_section.dart';
import '../widgets/post_settings_section.dart';

class CreatePostPage extends StatelessWidget {
  const CreatePostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CreatePostView();
  }
}

class _CreatePostView extends StatelessWidget {
  const _CreatePostView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(l10n.t('createPostTitle')),
        centerTitle: false,
      ),
      body: BlocConsumer<CreatePostBloc, CreatePostState>(
        listenWhen: (prev, next) =>
            prev.status != next.status ||
            prev.errorMessage != next.errorMessage,
        listener: (context, state) {
          if (!context.mounted) return;

          if (state.status == CreatePostStatus.success) {
            // Pass the draft flag back so PostsPage can show the right message.
            Navigator.of(context).pop(state.wasDraft ? 'draft' : 'published');
          } else if (state.errorMessage != null) {
            final message = _localizedError(l10n, state.errorMessage!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        },
        builder: (context, state) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.t('createPostSubtitle'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.grey.shade500
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CreatePostStepHeader(
                          currentStep: state.step,
                          onStepTap: (step) {
                            context
                                .read<CreatePostBloc>()
                                .add(CreatePostStepChanged(step));
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF2A3344)
                                : const Color(0xFFE8ECF0),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _StepBody(state: state),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar:
          BlocBuilder<CreatePostBloc, CreatePostState>(
        builder: (context, state) => CreatePostBottomBar(state: state),
      ),
    );
  }

  String _localizedError(dynamic l10n, String key) {
    return switch (key) {
      'media_required' => l10n.t('mediaRequired'),
      'description_required' => l10n.t('descriptionRequired'),
      'category_required' => l10n.t('categoryRequired'),
      'auction_incomplete' => l10n.t('auctionIncomplete'),
      'media_limit_reached' => l10n.t('mediaLimitReached'),
      'sound_conflict' => l10n.t('soundConflict'),
      'location_conflict' => l10n.t('locationConflict'),
      _ => key,
    };
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.state});

  final CreatePostState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CreatePostBloc>();
    final onFieldUpdate = createPostFieldUpdater(context);

    return SingleChildScrollView(
      child: switch (state.step) {
        0 => MediaUploadSection(
            form: state.form,
            status: state.status,
            isGeneratingThumbnail: state.isGeneratingThumbnail,
            onFilesPicked: (files) => bloc.add(PickMedia(files)),
            onRemove: (id) => bloc.add(RemoveMedia(id)),
            onReorder: (oldIndex, newIndex) =>
                bloc.add(ReorderMedia(oldIndex, newIndex)),
          ),
        1 => PostDetailsSection(
            form: state.form,
            onFieldUpdate: onFieldUpdate,
          ),
        2 => PostSettingsSection(
            form: state.form,
            onFieldUpdate: onFieldUpdate,
          ),
        _ => PostPreviewSection(form: state.form),
      },
    );
  }
}
