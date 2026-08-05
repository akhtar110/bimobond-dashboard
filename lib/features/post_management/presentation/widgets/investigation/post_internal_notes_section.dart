import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/localization.dart';
import '../../bloc/post_management_bloc.dart';
import 'investigation_theme.dart';
import 'post_surface_card.dart';

class PostInternalNotesSection extends StatefulWidget {
  const PostInternalNotesSection({super.key, required this.isBusy});

  final bool isBusy;

  @override
  State<PostInternalNotesSection> createState() =>
      _PostInternalNotesSectionState();
}

class _PostInternalNotesSectionState extends State<PostInternalNotesSection> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<PostManagementBloc>().add(
          SubmitPostInternalNoteEvent(_controller.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocListener<PostManagementBloc, PostManagementState>(
      listenWhen: (prev, curr) =>
          curr is PostManagementLoaded &&
          curr.successMessage == 'noteAdded' &&
          (prev is! PostManagementLoaded ||
              prev.successMessage != curr.successMessage),
      listener: (context, state) {
        _controller.clear();
      },
      child: BlocSelector<PostManagementBloc, PostManagementState, bool>(
        selector: (s) =>
            s is PostManagementLoaded ? s.isSubmittingNote : false,
        builder: (context, submitting) {
          final disabled = widget.isBusy || submitting;
          return PostSurfaceCard(
            dense: true,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.tOr('internalNotes', 'Internal Notes'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: InvestigationTheme.mutedText(context),
                    ),
                  ),
                  const SizedBox(height: InvestigationTheme.s8),
                  TextFormField(
                    controller: _controller,
                    maxLines: 3,
                    enabled: !disabled,
                    decoration: InvestigationTheme.fieldDecoration(
                      context,
                      hintText: l10n.tOr(
                        'internalNoteHint',
                        'Add an internal moderation note…',
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.tOr(
                          'internalNoteRequired',
                          'Please enter a note',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: InvestigationTheme.s8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: disabled ? null : _submit,
                      icon: submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.note_add_outlined, size: 18),
                      label: Text(l10n.tOr('addNote', 'Add Note')),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
