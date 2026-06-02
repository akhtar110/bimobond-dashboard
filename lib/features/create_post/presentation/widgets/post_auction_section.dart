import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/create_post_entity.dart';
import '../../domain/entities/create_post_field.dart';
import 'create_post_field_listener.dart';

class PostAuctionSection extends StatefulWidget {
  const PostAuctionSection({
    super.key,
    required this.form,
    required this.onFieldUpdate,
  });

  final CreatePostEntity form;
  final CreatePostFieldUpdater onFieldUpdate;

  @override
  State<PostAuctionSection> createState() => _PostAuctionSectionState();
}

class _PostAuctionSectionState extends State<PostAuctionSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _startPriceController;
  late final TextEditingController _targetPriceController;

  @override
  void initState() {
    super.initState();
    final a = widget.form.auction;
    _nameController = TextEditingController(text: a?.itemName ?? '');
    _imageUrlController = TextEditingController(text: a?.itemImageUrl ?? '');
    _startPriceController = TextEditingController(
      text: a?.startingPriceUsd?.toString() ?? '',
    );
    _targetPriceController = TextEditingController(
      text: a?.targetPriceUsd?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant PostAuctionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final a = widget.form.auction;
    if (oldWidget.form.auction?.itemName != a?.itemName) {
      _nameController.text = a?.itemName ?? '';
    }
    if (oldWidget.form.auction?.itemImageUrl != a?.itemImageUrl) {
      _imageUrlController.text = a?.itemImageUrl ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    _startPriceController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auction = widget.form.auction;
    if (!widget.form.isAuctionable || auction == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.t('auctionDetails'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: l10n.t('auctionItemName'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (v) =>
              widget.onFieldUpdate(CreatePostField.auctionItemName, v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _imageUrlController,
          decoration: InputDecoration(
            labelText: l10n.t('auctionItemImageUrl'),
            hintText: l10n.t('auctionItemImageUrlHint'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (v) =>
              widget.onFieldUpdate(CreatePostField.auctionItemImageUrl, v),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _startPriceController,
                decoration: InputDecoration(
                  labelText: l10n.t('auctionStartingPrice'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                onChanged: (v) => widget.onFieldUpdate(
                  CreatePostField.auctionStartingPriceUsd,
                  v.isEmpty ? null : double.tryParse(v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _targetPriceController,
                decoration: InputDecoration(
                  labelText: l10n.t('auctionTargetPrice'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                onChanged: (v) => widget.onFieldUpdate(
                  CreatePostField.auctionTargetPriceUsd,
                  v.isEmpty ? null : double.tryParse(v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DateField(
          label: l10n.t('auctionStartDate'),
          value: auction.startedAt,
          onChanged: (d) =>
              widget.onFieldUpdate(CreatePostField.auctionStartedAt, d),
        ),
        const SizedBox(height: 12),
        _DateField(
          label: l10n.t('auctionEndDate'),
          value: auction.endedAt,
          onChanged: (d) =>
              widget.onFieldUpdate(CreatePostField.auctionEndedAt, d),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final display =
        value != null ? '${value!.toLocal()}'.split('.').first : '';

    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: now.subtract(const Duration(days: 1)),
          lastDate: now.add(const Duration(days: 365 * 2)),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value ?? now),
        );
        if (time == null) return;
        onChanged(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          display.isEmpty ? '—' : display,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
