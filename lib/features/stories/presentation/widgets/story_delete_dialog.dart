import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/stories_bloc.dart';
import '../bloc/stories_event.dart';
import '../bloc/stories_state.dart';
import '../utils/stories_admin_l10n.dart';

Future<bool?> showStoryDeleteDialog(
  BuildContext context, {
  required String storyId,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => BlocProvider.value(
      value: context.read<StoriesBloc>(),
      child: StoryDeleteDialog(storyId: storyId),
    ),
  );
}

class StoryDeleteDialog extends StatefulWidget {
  const StoryDeleteDialog({super.key, required this.storyId});

  final String storyId;

  @override
  State<StoryDeleteDialog> createState() => _StoryDeleteDialogState();
}

class _StoryDeleteDialogState extends State<StoryDeleteDialog> {
  bool _submitting = false;

  Future<void> _confirmDelete() async {
    if (_submitting) return;

    final bloc = context.read<StoriesBloc>();
    if (bloc.state is! StoriesLoaded) return;

    setState(() => _submitting = true);
    bloc.add(DeleteStoryEvent(widget.storyId));

    await bloc.stream.firstWhere(
      (state) =>
          (state is StoriesLoaded && !state.isMutating) ||
          state is StoriesEmpty,
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final deleting = _submitting ||
        context.select<StoriesBloc, bool>(
          (bloc) {
            final state = bloc.state;
            return state is StoriesLoaded && state.isMutating;
          },
        );

    return AlertDialog(
      title: Text(StoriesAdminL10n.deleteStory(context)),
      content: Text(
        context.l10n.tOr(
          'storiesDeleteConfirm',
          'This permanently deletes the story. Continue?',
        ),
      ),
      actions: [
        TextButton(
          onPressed: deleting ? null : () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: deleting ? null : _confirmDelete,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: deleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(MaterialLocalizations.of(context).deleteButtonTooltip),
        ),
      ],
    );
  }
}
