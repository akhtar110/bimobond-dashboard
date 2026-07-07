import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/create_post_bloc.dart';

/// Sticky publish / draft / navigation actions.
class CreatePostBottomBar extends StatelessWidget {
  const CreatePostBottomBar({super.key, required this.state});

  final CreatePostState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bloc = context.read<CreatePostBloc>();
    final busy = state.isBusy;
    final isLast = state.step >= CreatePostState.stepCount - 1;

    return Material(
      elevation: 8,
      color: isDark ? const Color(0xFF151B28) : Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy) ...[
                LinearProgressIndicator(
                  value: state.status == CreatePostStatus.uploadingMedia &&
                          state.uploadProgress > 0
                      ? state.uploadProgress
                      : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                Text(
                  _progressLabel(l10n, state),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
              ],
              if (isLast) _buildPublishRow(context, l10n, bloc, busy)
              else _buildNavRow(context, l10n, bloc, busy),
            ],
          ),
        ),
      ),
    );
  }

  String _progressLabel(dynamic l10n, CreatePostState state) {
    if (state.isGeneratingThumbnail) {
      return l10n.tOr('generatingThumbnail', 'Generating thumbnail…');
    }
    return switch (state.status) {
      CreatePostStatus.uploadingMedia => l10n.t('uploadingMedia'),
      CreatePostStatus.creatingPost => l10n.t('submittingPost'),
      _ => l10n.t('submittingPost'),
    };
  }

  Widget _buildPublishRow(
    BuildContext context,
    dynamic l10n,
    CreatePostBloc bloc,
    bool busy,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 520;
        final publish = FilledButton(
          onPressed: state.canPublish
              ? () => bloc.add(CreatePostSubmitted())
              : null,
          child: Text(l10n.t('publishPost')),
        );
        final draft = OutlinedButton(
          onPressed: state.canSaveDraft ? () => bloc.add(SaveDraft()) : null,
          child: Text(l10n.t('saveDraft')),
        );
        final back = OutlinedButton(
          onPressed: busy
              ? null
              : () => bloc.add(CreatePostStepChanged(state.step - 1)),
          child: Text(l10n.t('back')),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              publish,
              const SizedBox(height: 8),
              draft,
              const SizedBox(height: 8),
              back,
            ],
          );
        }
        return Row(
          children: [
            back,
            const Spacer(),
            draft,
            const SizedBox(width: 8),
            publish,
          ],
        );
      },
    );
  }

  Widget _buildNavRow(
    BuildContext context,
    dynamic l10n,
    CreatePostBloc bloc,
    bool busy,
  ) {
    final canGoNext = state.step == 0 ? state.form.hasLocalMedia : true;

    return Row(
      children: [
        OutlinedButton(
          onPressed: busy || state.step == 0
              ? null
              : () => bloc.add(CreatePostStepChanged(state.step - 1)),
          child: Text(l10n.t('back')),
        ),
        const Spacer(),
        FilledButton(
          onPressed: busy || !canGoNext
              ? null
              : () => bloc.add(CreatePostStepChanged(state.step + 1)),
          child: Text(l10n.t('next')),
        ),
      ],
    );
  }
}
