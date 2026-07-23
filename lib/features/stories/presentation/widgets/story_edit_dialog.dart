import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/story_entity.dart';
import '../bloc/stories_bloc.dart';
import '../bloc/stories_event.dart';
import '../bloc/stories_state.dart';
import '../utils/stories_admin_l10n.dart';

Future<bool?> showStoryEditDialog(
  BuildContext context, {
  required StoryEntity story,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: context.read<StoriesBloc>(),
      child: StoryEditDialog(story: story),
    ),
  );
}

class StoryEditDialog extends StatefulWidget {
  const StoryEditDialog({super.key, required this.story});

  final StoryEntity story;

  @override
  State<StoryEditDialog> createState() => _StoryEditDialogState();
}

class _StoryEditDialogState extends State<StoryEditDialog> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _ttlController;
  late String _status;
  late String _privacy;
  late bool _allowReplies;
  late bool _allowSharing;
  late bool _allowReactions;
  String? _ttlError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final story = widget.story;
    _descriptionController = TextEditingController(text: story.description);
    _ttlController = TextEditingController(text: '${story.ttlHours}');
    _status = story.status.toUpperCase();
    _privacy = story.privacyStatus.toUpperCase();
    _allowReplies = story.allowReplies;
    _allowSharing = story.allowSharing;
    _allowReactions = story.allowReactions;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _ttlController.dispose();
    super.dispose();
  }

  bool _validateTtl() {
    final value = int.tryParse(_ttlController.text.trim());
    if (value == null || value < 1 || value > 168) {
      setState(
        () => _ttlError = StoriesAdminL10n.ttlValidation(context),
      );
      return false;
    }
    setState(() => _ttlError = null);
    return true;
  }

  Future<void> _submit() async {
    if (_submitting || !_validateTtl()) return;

    final bloc = context.read<StoriesBloc>();
    if (bloc.state is! StoriesLoaded) return;

    setState(() => _submitting = true);
    bloc.add(
      UpdateStoryEvent(
        UpdateStoryParams(
          id: widget.story.id,
          description: _descriptionController.text.trim(),
          status: _status,
          privacyStatus: _privacy,
          allowReplies: _allowReplies,
          allowSharing: _allowSharing,
          allowReactions: _allowReactions,
          ttlHours: int.parse(_ttlController.text.trim()),
        ),
      ),
    );

    await bloc.stream.firstWhere(
      (state) => state is StoriesLoaded && !state.isMutating,
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final saving = _submitting ||
        context.select<StoriesBloc, bool>(
          (bloc) {
            final state = bloc.state;
            return state is StoriesLoaded && state.isMutating;
          },
        );

    return AlertDialog(
      title: Text(StoriesAdminL10n.editStory(context)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                enabled: !saving,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const ['PUBLISHED', 'HIDDEN', 'EXPIRED']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _status = value);
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _privacy,
                decoration: const InputDecoration(
                  labelText: 'Privacy',
                  border: OutlineInputBorder(),
                ),
                items: const ['PUBLIC', 'PRIVATE', 'FRIENDS']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _privacy = value);
                      },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ttlController,
                enabled: !saving,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'TTL (hours)',
                  border: const OutlineInputBorder(),
                  errorText: _ttlError,
                  helperText: '1 – 168',
                ),
                onChanged: (_) {
                  if (_ttlError != null) _validateTtl();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow replies'),
                value: _allowReplies,
                onChanged: saving
                    ? null
                    : (value) => setState(() => _allowReplies = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow sharing'),
                value: _allowSharing,
                onChanged: saving
                    ? null
                    : (value) => setState(() => _allowSharing = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow reactions'),
                value: _allowReactions,
                onChanged: saving
                    ? null
                    : (value) => setState(() => _allowReactions = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: saving ? null : _submit,
          child: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(MaterialLocalizations.of(context).saveButtonLabel),
        ),
      ],
    );
  }
}
