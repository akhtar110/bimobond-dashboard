import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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

/// Admin edit dialog — sends dirty PATCH fields only.
class AuctionEditDialog extends StatefulWidget {
  const AuctionEditDialog({super.key, required this.auction});

  final AuctionEntity auction;

  @override
  State<AuctionEditDialog> createState() => _AuctionEditDialogState();
}

class _AuctionEditDialogState extends State<AuctionEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _targetPriceController;

  late final AuctionSnapshot _original;
  final _previewPricing = sl<PreviewAuctionPricing>();

  DateTime? _startedAt;
  DateTime? _endedAt;
  late String _status;

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
    _targetPriceController = TextEditingController(
      text: auction.targetPrice?.toString() ?? '',
    );
    _startedAt = auction.startedAt;
    _endedAt = auction.endedAt;
    _status = auction.status;

    _targetPriceController.addListener(_schedulePreview);
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _nameController.dispose();
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
      final preview = await _previewPricing(targetPrice: targetPrice);
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
    final targetPrice = double.tryParse(_targetPriceController.text.trim());

    return AuctionUpdateBody.diff(
      original: _original,
      itemName: _nameController.text,
      targetPrice: targetPrice,
      startedAt: _startedAt,
      endedAt: _endedAt,
      status: _status,
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

  Future<void> _pickDateTime({
    required DateTime? current,
    required ValueChanged<DateTime?> onPicked,
    required bool allowClear,
  }) async {
    final now = DateTime.now();
    final initial = current ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    onPicked(DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    ));
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
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: scheme.onSurfaceVariant)
          : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _sectionLabel(
    BuildContext context, {
    required String text,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: scheme.primary,
                ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final auction = widget.auction;
    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final screenH = media.size.height;
    final dialogW = math.min(screenW * 0.94, 540.0);
    final maxContentH = math.min(screenH * 0.75, 620.0);
    final canSave = !_buildDirtyBody().isEmpty;
    final dateFmt = DateFormat.yMMMd().add_Hm();

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenW < 560 ? 12 : 24,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: scheme.surface,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: dialogW,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                border: Border(
                  bottom: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      color: scheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tOr('edit_auction', 'Edit auction'),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.tOr(
                            'editAuctionHint',
                            'Update listing details. Only changed fields are sent.',
                          ),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.25,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 20,
                    ),
                    tooltip: l10n.tOr('close', 'Close'),
                  ),
                ],
              ),
            ),
            // Form Content
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxContentH),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    shrinkWrap: true,
                    children: [
                      _sectionLabel(
                        context,
                        text: l10n.tOr('basicInformation', 'Basic information'),
                        icon: Icons.inventory_2_outlined,
                      ),
                      TextFormField(
                        controller: _nameController,
                        decoration: _fieldDecoration(
                          context,
                          label: l10n.tOr('item_name', 'Item name'),
                          icon: Icons.label_outlined,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.tOr(
                              'auctionItemNameRequired',
                              'Item name is required',
                            );
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 18),
                      _sectionLabel(
                        context,
                        text: l10n.tOr('pricing', 'Pricing'),
                        icon: Icons.payments_outlined,
                      ),
                      _ReadOnlyPricingCard(auction: auction),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _targetPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        decoration: _fieldDecoration(
                          context,
                          label: l10n.tOr(
                            'auctionTargetMoney',
                            'Target price (money)',
                          ),
                          icon: Icons.attach_money_rounded,
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return null;
                          final parsed = double.tryParse(text);
                          if (parsed == null || parsed <= 0) {
                            return l10n.tOr(
                              'auctionTargetMoneyInvalid',
                              'Enter a valid target price',
                            );
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      _PreviewStrip(
                        loading: _previewLoading,
                        preview: _preview,
                        error: _previewError,
                      ),
                      const SizedBox(height: 18),
                      _sectionLabel(
                        context,
                        text: l10n.tOr('status', 'Status'),
                        icon: Icons.flag_outlined,
                      ),
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _status,
                      decoration: _fieldDecoration(
                        context,
                        label: l10n.tOr('auctionStatus', 'Auction status'),
                        icon: Icons.tune_rounded,
                      ),
                      items: _statusOptions(context),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _status = value);
                      },
                    ),
                    if (widget.auction.isCancelled) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.tertiaryContainer.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: scheme.tertiary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: scheme.tertiary,
                            ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.tOr(
                                    'auctionCancelledReactivateHint',
                                    'Editing a cancelled auction reactivates it to ACTIVE (or set status explicitly).',
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 11.5,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _sectionLabel(
                        context,
                        text: l10n.tOr('auctionTiming', 'Auction timing'),
                        icon: Icons.schedule_rounded,
                      ),
                      _DateTimeField(
                        label: l10n.tOr('started_at', 'Started at'),
                        value: _startedAt,
                        formatter: dateFmt,
                        onTap: () => _pickDateTime(
                          current: _startedAt,
                          onPicked: (v) => setState(() => _startedAt = v),
                          allowClear: false,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DateTimeField(
                        label: l10n.tOr('ended_at', 'Ended at'),
                        value: _endedAt,
                        formatter: dateFmt,
                        onTap: () => _pickDateTime(
                          current: _endedAt ?? _startedAt ?? DateTime.now(),
                          onPicked: (v) => setState(() => _endedAt = v),
                          allowClear: true,
                        ),
                        onClear: _endedAt == null
                            ? null
                            : () => setState(() => _endedAt = null),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions Footer
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                border: Border(
                  top: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(90, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n.t('cancel')),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: canSave ? _save : null,
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        size: 18),
                    label: Text(l10n.tOr('update_auction', 'Update auction')),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(140, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _statusOptions(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statuses = const [
      'ACTIVE',
      'COMPLETED',
      'SETTLED',
      'CANCELLED',
      'BANNED',
      'DISPUTED',
    ];

    Color colorFor(String s) => switch (s) {
          'ACTIVE' => scheme.primary,
          'COMPLETED' => scheme.secondary,
          'SETTLED' => scheme.tertiary,
          'CANCELLED' => scheme.error,
          'BANNED' => scheme.onErrorContainer,
          'DISPUTED' => Colors.amber.shade700,
          _ => scheme.onSurfaceVariant,
        };

    return statuses.map((s) {
      final c = colorFor(s);
      return DropdownMenuItem(
        value: s,
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              s,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.formatter,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final DateFormat formatter;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            Icons.calendar_month_rounded,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          filled: true,
          fillColor: scheme.surfaceContainerLowest,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: onClear != null
              ? IconButton(
                  icon: Icon(
                    Icons.cancel_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  onPressed: onClear,
                )
              : null,
        ),
        child: Text(
          value != null
              ? formatter.format(value!.toLocal())
              : l10n.tOr('notSet', 'Not set'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: value != null ? scheme.onSurface : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.tOr('auctionCurrentPricing', 'Current pricing'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
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
                    fontSize: 11,
                  ),
            ),
          ],
        ],
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
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: scheme.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10.5,
                    ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.tOr('calculatingPreview', 'Calculating pricing...'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Text(
        error!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.error,
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
        l10n
            .tOr('auctionPreviewGoal', 'Goal: {coins} coins')
            .replaceAll('{coins}', CoinFormat.coins(coins)),
      if (spend != null)
        l10n
            .tOr('auctionPreviewSpend', 'Est. gift spend: {coins}')
            .replaceAll('{coins}', CoinFormat.coins(spend)),
    ];

    if (parts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 14,
            color: scheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              parts.join('  ·  '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
