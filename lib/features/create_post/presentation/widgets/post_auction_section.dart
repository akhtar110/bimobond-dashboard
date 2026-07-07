import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../../../core/utils/money_format.dart';
import '../../domain/entities/create_post_auction_entity.dart';
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
  late TextEditingController _nameController;
  late TextEditingController _startCoinsController;
  late TextEditingController _targetCoinsController;
  late TextEditingController _startMoneyController;
  late TextEditingController _targetMoneyController;
  late TextEditingController _currencyController;

  @override
  void initState() {
    super.initState();
    final a = widget.form.auction;
    _nameController = TextEditingController(text: a?.itemName ?? '');
    _startCoinsController = TextEditingController(
      text: _coinFieldText(a?.startingPriceCoins ?? 0),
    );
    _targetCoinsController = TextEditingController(
      text: _coinFieldText(a?.targetPriceCoins),
    );
    _startMoneyController = TextEditingController(
      text: _coinFieldText(a?.startingPrice),
    );
    _targetMoneyController = TextEditingController(
      text: _coinFieldText(a?.targetPrice),
    );
    _currencyController = TextEditingController(
      text: a?.currencyCode ?? 'USD',
    );
  }

  void _syncControllersIfNeeded(CreatePostAuctionEntity? auction) {
    if (auction == null) return;
    _nameController.text = auction.itemName;
    _startCoinsController.text =
        _coinFieldText(auction.startingPriceCoins ?? 0);
    _targetCoinsController.text = _coinFieldText(auction.targetPriceCoins);
    _startMoneyController.text = _coinFieldText(auction.startingPrice);
    _targetMoneyController.text = _coinFieldText(auction.targetPrice);
    _currencyController.text = auction.currencyCode;
  }

  @override
  void didUpdateWidget(covariant PostAuctionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldAuction = oldWidget.form.auction;
    final newAuction = widget.form.auction;
    if (oldWidget.form.isAuctionable != widget.form.isAuctionable) {
      _syncControllersIfNeeded(newAuction);
      return;
    }
    if (oldAuction?.pricingMode != newAuction?.pricingMode) {
      _syncControllersIfNeeded(newAuction);
    }
  }

  static String _coinFieldText(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startCoinsController.dispose();
    _targetCoinsController.dispose();
    _startMoneyController.dispose();
    _targetMoneyController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final auction = widget.form.auction;
    if (!widget.form.isAuctionable || auction == null) {
      return const SizedBox.shrink();
    }

    final isMoney = auction.isMoneyMode;
    final coinsSuffix = l10n.t('auctionCoinsSuffix');
    final targetInvalid = !isMoney &&
        auction.targetPriceCoins != null &&
        auction.targetPriceCoins! < (auction.startingPriceCoins ?? 0);
    final moneyTargetInvalid = isMoney &&
        auction.targetPrice != null &&
        auction.targetPrice! < (auction.startingPrice ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.t('auctionDetails'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.t('auctionGiftBiddingHint'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<AuctionPricingMode>(
          segments: [
            ButtonSegment(
              value: AuctionPricingMode.money,
              label: Text(l10n.tOr('auctionMoneyMode', 'Money target')),
              icon: const Icon(Icons.payments_outlined, size: 18),
            ),
            ButtonSegment(
              value: AuctionPricingMode.coins,
              label: Text(l10n.tOr('auctionCoinsMode', 'Coin target')),
              icon: const Icon(Icons.monetization_on_outlined, size: 18),
            ),
          ],
          selected: {auction.pricingMode},
          onSelectionChanged: (s) => widget.onFieldUpdate(
            CreatePostField.auctionPricingMode,
            s.first,
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
        if (isMoney) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _currencyController,
                  decoration: InputDecoration(
                    labelText: l10n.tOr('currencyCode', 'Currency'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                    LengthLimitingTextInputFormatter(3),
                  ],
                  onChanged: (v) => widget.onFieldUpdate(
                    CreatePostField.auctionCurrencyCode,
                    v.trim().toUpperCase(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startMoneyController,
                  decoration: InputDecoration(
                    labelText: l10n.tOr('auctionStartingPriceMoney', 'Starting price'),
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
                    CreatePostField.auctionStartingPrice,
                    v.isEmpty ? null : (double.tryParse(v) ?? 0),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _targetMoneyController,
                  decoration: InputDecoration(
                    labelText: l10n.t('auctionTargetPrice'),
                    errorText: moneyTargetInvalid
                        ? l10n.t('auctionTargetBelowStarting')
                        : null,
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
                    CreatePostField.auctionTargetPrice,
                    v.isEmpty ? null : double.tryParse(v),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startCoinsController,
                  decoration: InputDecoration(
                    labelText: l10n.t('auctionStartingPrice'),
                    suffixText: coinsSuffix,
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
                    CreatePostField.auctionStartingPriceCoins,
                    v.isEmpty ? 0.0 : (double.tryParse(v) ?? 0),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _targetCoinsController,
                  decoration: InputDecoration(
                    labelText: l10n.t('auctionTargetPrice'),
                    suffixText: coinsSuffix,
                    errorText: targetInvalid
                        ? l10n.t('auctionTargetBelowStarting')
                        : null,
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
                    CreatePostField.auctionTargetPriceCoins,
                    v.isEmpty ? null : double.tryParse(v),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (auction.hasValidPricing)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _AuctionSummaryCard(auction: auction),
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

class _AuctionSummaryCard extends StatelessWidget {
  const _AuctionSummaryCard({required this.auction});

  final CreatePostAuctionEntity auction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final auction = this.auction;

    final String summary;
    final String subtitle;
    if (auction.isMoneyMode) {
      final target = auction.targetPrice ?? 0;
      summary = l10n.tArgs('auctionTargetSummaryMoney', {
        'target': MoneyFormat.format(target, auction.currencyCode),
      });
      subtitle = l10n.tOr(
        'auctionMoneyConversionHint',
        'Server converts to coins using COINS_PER_PRICE_UNIT on save',
      );
    } else {
      final starting = auction.startingPriceCoins ?? 0;
      final target = auction.targetPriceCoins ?? 0;
      summary = l10n.tArgs('auctionTargetSummary', {
        'target': CoinFormat.coinsAmount(target),
      });
      subtitle = CoinFormat.coinsProgress(current: starting, target: target);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.gavel_outlined, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
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
