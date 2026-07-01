import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/promotion_entities.dart';
import 'promotions_dashboard_widgets.dart';

class PackageDialogResult {
  PackageDialogResult.create(this.createData)
      : updateData = const UpdatePackageData();

  PackageDialogResult.update(this.updateData)
      : createData = const CreatePackageData(
          name: '',
          priceCoins: 0,
          impressionCount: 0,
        );

  final CreatePackageData createData;
  final UpdatePackageData updateData;
}

Future<PackageDialogResult?> showPackageDialog(
  BuildContext context, {
  PromotionPackageEntity? existing,
}) {
  return showDialog<PackageDialogResult>(
    context: context,
    builder: (_) => _PackageDialog(existing: existing),
  );
}

class _PackageDialog extends StatefulWidget {
  const _PackageDialog({this.existing});
  final PromotionPackageEntity? existing;

  @override
  State<_PackageDialog> createState() => _PackageDialogState();
}

class _PackageDialogState extends State<_PackageDialog> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _impressions;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _price = TextEditingController(
      text: widget.existing?.priceCoins.toString() ?? '',
    );
    _impressions = TextEditingController(
      text: widget.existing?.impressionCount.toString() ?? '',
    );
    _active = widget.existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _impressions.dispose();
    super.dispose();
  }

  void _submit() {
    final price = double.tryParse(_price.text.trim()) ?? 0;
    final impressions = int.tryParse(_impressions.text.trim()) ?? 0;
    final isEdit = widget.existing != null;

    if (isEdit) {
      Navigator.pop(
        context,
        PackageDialogResult.update(
          UpdatePackageData(
            name: _name.text.trim(),
            priceCoins: price,
            impressionCount: impressions,
            isActive: _active,
          ),
        ),
      );
    } else {
      Navigator.pop(
        context,
        PackageDialogResult.create(
          CreatePackageData(
            name: _name.text.trim(),
            priceCoins: price,
            impressionCount: impressions,
            isActive: _active,
          ),
        ),
      );
    }
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;
    final screenW = MediaQuery.sizeOf(context).width;
    final dialogW = screenW < 560 ? screenW * 0.92 : 480.0;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenW < 560 ? 16 : 24,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                isEdit ? Icons.edit_outlined : Icons.inventory_2_outlined,
                color: scheme.onPrimaryContainer,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? l10n.t('edit') : l10n.t('create'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.t('promoPackagesTitle'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogW,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.t('promoPackage'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
              ),
              const SizedBox(height: PromotionsSpace.md),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: _fieldDecoration(
                  context,
                  label: l10n.t('name'),
                  icon: Icons.label_outline_rounded,
                ),
              ),
              const SizedBox(height: PromotionsSpace.lg),
              Text(
                l10n.t('overview'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
              ),
              const SizedBox(height: PromotionsSpace.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 360;
                  final priceField = TextField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: _fieldDecoration(
                      context,
                      label: l10n.t('promoPrice'),
                      icon: Icons.payments_outlined,
                    ),
                  );
                  final impressionsField = TextField(
                    controller: _impressions,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: _fieldDecoration(
                      context,
                      label: l10n.t('promoImpressionCount'),
                      icon: Icons.visibility_outlined,
                    ),
                  );

                  if (stacked) {
                    return Column(
                      children: [
                        priceField,
                        const SizedBox(height: PromotionsSpace.md),
                        impressionsField,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: priceField),
                      const SizedBox(width: PromotionsSpace.md),
                      Expanded(child: impressionsField),
                    ],
                  );
                },
              ),
              const SizedBox(height: PromotionsSpace.lg),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: PromotionsSpace.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  secondary: Icon(
                    _active
                        ? Icons.check_circle_outline_rounded
                        : Icons.pause_circle_outline_rounded,
                    color: _active ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  title: Text(
                    l10n.t('active'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_outlined, size: 18),
          label: Text(l10n.t('save')),
        ),
      ],
    );
  }
}
