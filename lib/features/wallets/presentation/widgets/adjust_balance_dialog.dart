import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/wallet_entities.dart';
import '../../domain/enums/wallet_enums.dart';

class AdjustBalanceDialog extends StatefulWidget {
  const AdjustBalanceDialog({super.key});

  @override
  State<AdjustBalanceDialog> createState() => _AdjustBalanceDialogState();
}

class _AdjustBalanceDialogState extends State<AdjustBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  LedgerAction _action = LedgerAction.credit;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());
    Navigator.of(context).pop(
      AdjustBalanceData(
        action: _action,
        amountCoins: amount,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Adjust balance'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<LedgerAction>(
                segments: const [
                  ButtonSegment(
                    value: LedgerAction.credit,
                    label: Text('Credit'),
                    icon: Icon(Icons.add),
                  ),
                  ButtonSegment(
                    value: LedgerAction.debit,
                    label: Text('Debit'),
                    icon: Icon(Icons.remove),
                  ),
                ],
                selected: {_action},
                onSelectionChanged: (values) {
                  setState(() => _action = values.first);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (coins)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a positive amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Text(
                'Creates an ADMIN_ADJUSTMENT ledger entry.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

Future<AdjustBalanceData?> showAdjustBalanceDialog(BuildContext context) {
  return showDialog<AdjustBalanceData>(
    context: context,
    builder: (_) => const AdjustBalanceDialog(),
  );
}
