import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/wallet_entities.dart';

class CoinPackageDialog extends StatefulWidget {
  const CoinPackageDialog({super.key, this.existing});

  final CoinPackageEntity? existing;

  @override
  State<CoinPackageDialog> createState() => _CoinPackageDialogState();
}

class _CoinPackageDialogState extends State<CoinPackageDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _coinAmountController;
  late final TextEditingController _priceController;
  late final TextEditingController _currencyController;
  late bool _isActive;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _coinAmountController = TextEditingController(
      text: existing != null ? existing.coinAmount.toString() : '',
    );
    _priceController = TextEditingController(
      text: existing != null ? existing.price.toString() : '',
    );
    _currencyController = TextEditingController(
      text: existing?.currencyCode ?? 'USD',
    );
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _coinAmountController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final coinAmount = double.parse(_coinAmountController.text.trim());
    final price = double.parse(_priceController.text.trim());
    final currencyCode = _currencyController.text.trim().toUpperCase();
    final name = _nameController.text.trim();

    if (isEditing) {
      Navigator.of(context).pop(
        UpdateCoinPackageData(
          name: name,
          coinAmount: coinAmount,
          price: price,
          currencyCode: currencyCode,
          isActive: _isActive,
        ),
      );
    } else {
      Navigator.of(context).pop(
        CreateCoinPackageData(
          name: name,
          coinAmount: coinAmount,
          price: price,
          currencyCode: currencyCode,
          isActive: _isActive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(isEditing ? 'Edit coin package' : 'Create coin package'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _coinAmountController,
                decoration: const InputDecoration(
                  labelText: 'Coin amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: _positiveNumberValidator,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Store price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: _positiveNumberValidator,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _currencyController,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        hintText: 'USD',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: (v) {
                        final code = v?.trim() ?? '';
                        if (code.length != 3) return 'ISO 4217 code';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Format price with currency code — never hardcode \$',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
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
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  String? _positiveNumberValidator(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return 'Enter a positive number';
    return null;
  }
}

Future<Object?> showCoinPackageDialog(
  BuildContext context, {
  CoinPackageEntity? existing,
}) {
  return showDialog<Object?>(
    context: context,
    builder: (_) => CoinPackageDialog(existing: existing),
  );
}
