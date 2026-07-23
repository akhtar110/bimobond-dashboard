import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

Future<String?> showSellerVerificationRejectDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => const _RejectDialog(),
  );
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.tOr('rejectSellerTitle', 'Reject application')),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _reasonCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.tOr('rejectionReason', 'Rejection reason'),
              hintText: l10n.tOr(
                'rejectionReasonHint',
                'Explain why this application was rejected.',
              ),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.trim().length < 3) {
                return l10n.t('requiredField');
              }
              return null;
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _reasonCtrl.text.trim());
          },
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: Text(l10n.tOr('rejectSeller', 'Reject')),
        ),
      ],
    );
  }
}
