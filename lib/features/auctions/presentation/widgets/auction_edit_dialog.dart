import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/auction_entity.dart';
import '../../domain/entities/auction_pricing_preview_entity.dart';
import '../../domain/entities/auction_update_body.dart';
import '../../domain/usecases/preview_auction_pricing_usecase.dart';

Future<AuctionUpdateBody?> showAuctionEditDialog(
  BuildContext context, {
  required AuctionEntity auction,
}) {
  return showDialog<AuctionUpdateBody>(
    context: context,
    barrierDismissible: true,
    builder: (_) => AuctionEditDialog(auction: auction),
  );
}

/// Admin edit dialog — sends dirty PATCH fields only (never `currencyCode` or
/// `targetPriceCoins` on update).
class AuctionEditDialog extends StatefulWidget {
  const AuctionEditDialog({super.key, required this.auction});

  final AuctionEntity auction;

  @override
  State<AuctionEditDialog> createState() => _AuctionEditDialogState();
}

class _AuctionEditDialogState extends State<AuctionEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _startingPriceController;
  late final TextEditingController _targetPriceController;

  late final AuctionSnapshot _original;
  final _previewPricing = sl<PreviewAuctionPricing>();

  Timer? _previewDebounce;
  AuctionPricingPreviewEntity? _preview;
  bool _previewLoading = false;
  String? _previewError;

  @override
  void initState() {
    super.initState();
    final auction = widget.auction;
    _original = AuctionSnapshot.fromEntity(auction);
    _nameController = TextEditingController(text: auction.itemName ?? '');
    _startingPriceController = TextEditingController(
      text: auction.startingPrice?.toString() ?? '',
    );
    _targetPriceController = TextEditingController(
      text: auction.targetPrice?.toString() ?? '',
    );

    _targetPriceController.addListener(_schedulePreview);
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _nameController.dispose();
    _startingPriceController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }

  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 450), _fetchPreview);
  }

  Future<void> _fetchPreview() async {
    final targetPrice = double.tryParse(_targetPriceController.text.trim());
    if (targetPrice == null || targetPrice <= 0) {
      if (!mounted) return;
      setState(() {
        _preview = null;
        _previewLoading = false;
        _previewError = null;
      });
      return;
    }

    setState(() {
      _previewLoading = true;
      _previewError = null;
    });

    try {
      final preview = await _previewPricing(
        targetPrice: targetPrice,
      );
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _previewLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewLoading = false;
        _previewError = e.toString();
      });
    }
  }

  AuctionUpdateBody _buildDirtyBody() {
    final startingPrice = double.tryParse(_startingPriceController.text.trim());
    final targetPrice = double.tryParse(_targetPriceController.text.trim());

    return AuctionUpdateBody.diff(
      original: _original,
      itemName: _nameController.text,
      startingPrice: startingPrice,
      targetPrice: targetPrice,
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final body = _buildDirtyBody();
    if (body.isEmpty) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context, body);
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    IconData? icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final auction = widget.auction;
    final screenW = MediaQuery.sizeOf(context).width;
    final dialogW = screenW < 560 ? screenW * 0.92 : 480.0;
    final canSave = !_buildDirtyBody().isEmpty;

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
                Icons.gavel_rounded,
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
                  l10n.tOr('editAuction', 'Edit auction'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tOr(
                    'editAuctionHint',
                    'Update listing details. Coin goal and currency are managed by the server.',
                  ),
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: _fieldDecoration(
                  context,
                  label: l10n.t('auctionItemName'),
                  icon: Icons.inventory_2_outlined,
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.tOr('auctionItemNameRequired', 'Item name is required');
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _ReadOnlyPricingCard(auction: auction),
              const SizedBox(height: 16),
              TextFormField(
                controller: _startingPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: _fieldDecoration(
                  context,
                  label: l10n.tOr('auctionStartingMoney', 'Starting price (money)'),
                  icon: Icons.price_change_outlined,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final parsed = double.tryParse(text);
                  if (parsed == null || parsed < 0) {
                    return l10n.tOr(
                      'auctionStartingMoneyInvalid',
                      'Enter a valid starting price',
                    );
                  }
                  final target = double.tryParse(_targetPriceController.text.trim());
                  if (target != null && parsed > target) {
                    return l10n.tOr(
                      'auctionStartAboveTarget',
                      'Starting price cannot exceed target price',
                    );
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: _fieldDecoration(
                  context,
                  label: l10n.tOr('auctionTargetMoney', 'Target price (money)'),
                  icon: Icons.payments_outlined,
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return l10n.tOr(
                      'auctionTargetMoneyInvalid',
                      'Enter a valid target price',
                    );
                  }
                  final start = double.tryParse(_startingPriceController.text.trim());
                  if (start != null && parsed < start) {
                    return l10n.tOr(
                      'auctionTargetBelowStarting',
                      'Target must be greater than or equal to starting price',
                    );
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: _PreviewStrip(
                  loading: _previewLoading,
                  preview: _preview,
                  error: _previewError,
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
        FilledButton(
          onPressed: canSave ? _save : null,
          child: Text(l10n.t('save')),
        ),
      ],
    );
  }
}

class _ReadOnlyPricingCard extends StatelessWidget {
  const _ReadOnlyPricingCard({required this.auction});

  final AuctionEntity auction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.tOr('auctionCurrentPricing', 'Current pricing'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PricingFact(
                    icon: Icons.monetization_on_outlined,
                    label: l10n.t('auctionGoal'),
                    value: CoinFormat.coins(auction.targetPriceCoins),
                  ),
                ),
                if (auction.hasMoneyTarget) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PricingFact(
                      icon: Icons.attach_money_rounded,
                      label: l10n.tOr('auctionTargetValue', 'Target value'),
                      value: MoneyFormat.format(
                        auction.targetPrice!,
                        auction.currencyCode!,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (auction.currencyCode != null &&
                auction.currencyCode!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${l10n.tOr('currencyCode', 'Currency')}: ${auction.currencyCode}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PricingFact extends StatelessWidget {
  const _PricingFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewStrip extends StatelessWidget {
  const _PreviewStrip({
    required this.loading,
    required this.preview,
    required this.error,
  });

  final bool loading;
  final AuctionPricingPreviewEntity? preview;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    if (loading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: scheme.primary,
          ),
        ),
      );
    }

    if (error != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          error!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.error,
              ),
        ),
      );
    }

    if (preview == null) {
      return const SizedBox.shrink();
    }

    final coins = preview!.resolvedTargetPriceCoins;
    final spend = preview!.estimatedBidderSpendCoins;
    final parts = <String>[
      if (coins != null)
        l10n.tOr('auctionPreviewGoal', 'Goal: {coins} coins')
            .replaceAll('{coins}', CoinFormat.coins(coins)),
      if (spend != null)
        l10n.tOr('auctionPreviewSpend', 'Est. gift spend: {coins}')
            .replaceAll('{coins}', CoinFormat.coins(spend)),
    ];

    if (parts.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            parts.join(' · '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
