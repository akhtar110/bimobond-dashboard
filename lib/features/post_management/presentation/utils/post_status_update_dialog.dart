import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/utils/post_status_utils.dart';
import '../bloc/post_management_bloc.dart';
import '../utils/post_detail_labels.dart';
import '../widgets/investigation/investigation_theme.dart';

/// Dialog to update post moderation status with reason and internal note.
Future<void> showPostStatusUpdateDialog(
  BuildContext context, {
  required String currentStatus,
  String? initialStatus,
}) async {
  var selected = normalizePostStatus(initialStatus ?? currentStatus);
  if (!kPostAdminStatuses.contains(selected)) {
    selected = kPostAdminStatuses.first;
  }

  final result = await showDialog<_StatusUpdateResult>(
    context: context,
    builder: (ctx) => _PostStatusUpdateDialog(initialStatus: selected),
  );

  if (result != null && context.mounted) {
    context.read<PostManagementBloc>().add(
          UpdatePostStatusEvent(
            result.status,
            reason: result.reason,
            note: result.note,
          ),
        );
  }
}

class _StatusUpdateResult {
  const _StatusUpdateResult({
    required this.status,
    required this.reason,
    this.note,
  });

  final String status;
  final String reason;
  final String? note;
}

class _PostStatusUpdateDialog extends StatefulWidget {
  const _PostStatusUpdateDialog({required this.initialStatus});

  final String initialStatus;

  @override
  State<_PostStatusUpdateDialog> createState() =>
      _PostStatusUpdateDialogState();
}

class _PostStatusUpdateDialogState extends State<_PostStatusUpdateDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _reasonController;
  late final TextEditingController _noteController;
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialStatus;
    _reasonController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _StatusUpdateResult(
        status: _selected,
        reason: _reasonController.text.trim(),
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
      ),
      title: Text(l10n.tOr('updateStatus', 'Update Status')),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _selected,
                  decoration: InvestigationTheme.fieldDecoration(
                    context,
                    labelText: l10n.t('postStatus'),
                  ),
                  items: kPostAdminStatuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(postStatusLabel(l10n, status)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selected = value);
                  },
                ),
                const SizedBox(height: InvestigationTheme.s12),
                TextFormField(
                  controller: _reasonController,
                  decoration: InvestigationTheme.fieldDecoration(
                    context,
                    labelText: l10n.tOr('reason', 'Reason'),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.tOr(
                        'reasonRequired',
                        'Reason is required',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: InvestigationTheme.s12),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InvestigationTheme.fieldDecoration(
                    context,
                    labelText: l10n.tOr('internalNote', 'Internal Note'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.tOr('update', 'Update')),
        ),
      ],
    );
  }
}
